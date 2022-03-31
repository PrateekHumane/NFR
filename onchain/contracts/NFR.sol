// contracts/MyNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./MERGE.sol";
import "./RareRelics.sol";

contract NFR is ERC721Enumerable, Ownable  {

    // some are hiddenCards and some are regular cards. Some ERC721 or ERC20

    uint256 public constant MINT_PRICE = .05 ether;
    uint16 public constant MAX_MINTABLE = 5000;
    uint16 public packsMinted;
    bool public gameOngoing;

    // if we need more info than merkleRoot per card, then create a struct that the ID maps to
    // map from hiddenCardId -> merkleRoot
    uint16[9] public baseCardCopyCounts = [0, 0, 0, 0, 0, 0, 0, 0, 0];
    uint256[9] public baseCardHashedDescription = [0x01649792131254809c4b0f4287aaeb9a5229812249af54b3a86c8dcfecda625a, 0, 0, 0, 0, 0, 0, 0, 0];

    struct Artifact {
        uint8 num;
        uint16 copyNum;
        // HIDDEN VALUES:
        uint256 longDescriptionHashed;
        uint256 privateKey;
    }

    mapping(uint256 => Artifact) public publicArtifacts; // private or public?

    uint256 public cardCopiesHashed; // TODO: make private

    MERGE merge;
    RareRelics rareRelics;

    address BlackMarketAddress;
    bool BlackMarketAddressSet;

    uint256 private _nonce;

    constructor(address _merge, address _rareRelics) ERC721("NFR island", "NFR") {
        packsMinted = 0;
        gameOngoing = false;
        merge = MERGE(_merge);
        rareRelics = RareRelics(_rareRelics);
        BlackMarketAddressSet = false;
    }

    function mintPack(uint8 artifact1, uint8 artifact2, uint8 artifact3) external payable returns (uint256[4] memory){
        // TODO: comment back in after testing
        //        require(msg.value >= MINT_PRICE);
        require(packsMinted < MAX_MINTABLE, "MAX PACKS MINTED");
        // three cards decided must be base cards
        require(artifact1 <= 50 && artifact1 >= 42, "CAN ONLY REQUEST BASE CARD");
        require(artifact2 <= 50 && artifact2 >= 42, "CAN ONLY REQUEST BASE CARD");
        require(artifact3 <= 50 && artifact3 >= 42, "CAN ONLY REQUEST BASE CARD");

        // additional card based on when you mint the pack
        uint8[4] memory artifactNums = [artifact1, artifact2, artifact3, uint8(packsMinted % 9 + 42)];
        uint256[4] memory results;
        for (uint i = 0; i < 4; i++) {
            Artifact memory artifactToMint;
            artifactToMint.num = artifactNums[i];
            baseCardCopyCounts[artifactNums[i] - 42] += 1;
            artifactToMint.copyNum = baseCardCopyCounts[artifactNums[i] - 42];
            artifactToMint.longDescriptionHashed = baseCardHashedDescription[artifactNums[i] - 42];
            artifactToMint.privateKey = 0;

            // create a merkle tree out of each card
            uint256 merkleRoot = getArtifactMerkleRoot(artifactToMint);
            publicArtifacts[merkleRoot] = artifactToMint;
            _safeMint(msg.sender, merkleRoot);
            // _msgSender() instead?
            // TODO: do I need to ensure the root is unique beforehand?
            results[i] = merkleRoot;
        }

        // allow black market to control these tokens for when you stake
        setApprovalForAll(BlackMarketAddress, true);
        rareRelics.mintFromPack(msg.sender);
        merge.mint(msg.sender, 5000000);

        packsMinted += 1;

        // Once someone buys the last pack, begin the game!
        if (packsMinted == MAX_MINTABLE)
            startGame();

        return results;
    }

    function startGame() internal {
        gameOngoing = true;
        // 1024 bit preimage representing the hidden card amounts for cards other than baseCardCopyCounts
        // cardCopiesHashed = uint256(sha256(abi.encodePacked(uint256(0), uint256(0), uint256(0), uint256(0))));
        // this is the pedersen hash for uint256(0)
        // all non base cards counts are 0 when the game starts
        cardCopiesHashed = 0xa65f3fa0002aba81ad5f5805158ca53b4c6786ad9dc9845a0acbd5e718ffe95d;
    }

    function revealArtifact(uint256 tokenId, uint8 num, uint16 copyNum, uint256 longDescriptionHashed, uint256 privateKey) external {
        require(ownerOf(tokenId) == msg.sender);
        // must own artifact being revealed
        // TODO: if using memory and reference it in mapping does it create duplicate
        Artifact memory artifactToReveal = Artifact(num, copyNum, longDescriptionHashed, privateKey);
        uint256 merkleRoot = getArtifactMerkleRoot(artifactToReveal);
        require(tokenId == merkleRoot);

        publicArtifacts[merkleRoot] = artifactToReveal;
    }

    function endGame(uint256[5] memory tokenIds, Artifact[5] memory genesisArtifacts) external whenGameOngoing {
        bool[5] memory hasGenesisCard = [false, false, false, false, false];
        for (uint8 i = 0; i < 5; i++) {
            require(ownerOf(tokenIds[i]) == msg.sender);
            // must own the genesis cards
            require(tokenIds[i] == getArtifactMerkleRoot(genesisArtifacts[i]));
            // ensure artifact is correct
            require(genesisArtifacts[i].num <= 5 && genesisArtifacts[i].num > 0);
            // is a genesis card
            hasGenesisCard[genesisArtifacts[i].num - 1] = true;
        }

        for (uint8 i = 0; i < 5; i++)
            require(hasGenesisCard[i]);

        require(gameOngoing == true);
        assert(address(this).balance >= MAX_MINTABLE * MINT_PRICE);

        // end the game and transfer the money
        gameOngoing = false;
        payable(msg.sender).transfer(MAX_MINTABLE * MINT_PRICE);
    }

    function getArtifactMerkleRoot(Artifact memory artifact) internal pure returns (uint256){
        return uint256(sha256(abi.encodePacked(sha256(abi.encodePacked(sha256(abi.encodePacked(artifact.num)), sha256(abi.encodePacked(artifact.copyNum)))), sha256(abi.encodePacked(abi.encodePacked(artifact.longDescriptionHashed), sha256(abi.encodePacked(artifact.privateKey)))))));
    }

    event cardStolen(address from, address to, uint256 tokenId);

    function stealCard(address from, address to, uint256 tokenId) public isBlackMarketContract {
        emit cardStolen(from, to, tokenId);
        transferFrom(from, to, tokenId);
    }

    event cardBurnt(address owner, uint256 tokenId);

    function duplicateCard(uint256 tokenId) public isBlackMarketContract {
        Artifact memory newCard = Artifact({
            num : publicArtifacts[tokenId].num,
            copyNum : publicArtifacts[tokenId].copyNum, // duplicate doesn't increase the version num (this is power of the card) even when limit is reached more copies can be made
            longDescriptionHashed : publicArtifacts[tokenId].longDescriptionHashed,
            privateKey : random()
            // TODO: copy: true
        });
        uint256 merkleRoot = getArtifactMerkleRoot(newCard);
        publicArtifacts[merkleRoot] = newCard;
        _safeMint(ownerOf(tokenId), merkleRoot);
    }

    function transformCard(uint256 inputTokenId, uint256 targetTokenId) public isBlackMarketContract {
        emit cardBurnt(ownerOf(inputTokenId), inputTokenId);
        _burn(inputTokenId);
        Artifact memory newCard = Artifact({
            num : publicArtifacts[targetTokenId].num,
            copyNum : publicArtifacts[targetTokenId].copyNum,
            longDescriptionHashed : publicArtifacts[targetTokenId].longDescriptionHashed,
            privateKey : random()
            // TODO: copy: true
        });
        uint256 merkleRoot = getArtifactMerkleRoot(newCard);
        publicArtifacts[merkleRoot] = newCard;
        _safeMint(ownerOf(inputTokenId), merkleRoot);
    }

    function setBlackMarketAddress(address _BlackMarketAddress) external onlyOwner {
        require (BlackMarketAddressSet == false, "already set BlackMarket contract address");
        BlackMarketAddress = _BlackMarketAddress;
        BlackMarketAddressSet = true;
//        setApprovalForAll(BlackMarketAddress, true);
    }

    modifier isBlackMarketContract {
        require(BlackMarketAddressSet == true, "BlaCK MARKET CONTRACT NOT SET");
        require(msg.sender == BlackMarketAddress, "ONlY BlaCK MARKET CONTRACT CAN CALL THIS FUNCTION");
        _;
    }

    modifier whenGameOngoing {
        require(gameOngoing, "GAME NOT ONGOING");
        _;
    }

    function random() internal returns (uint){
        _nonce += 1;
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _nonce, _msgSender())));
    }

    //    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    //       require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    //
    //       // https://cloudflare-ipfs.com/ipns/ {TOKEN ID} .dogsunchainednft.com
    //       return string(abi.encodePacked(prefix, tokenId.toString(), suffix));
    //    }


    //    function merge(Proof memory proof, uint[40] memory input) external {
    //        uint256 card1 = convert64bitTo256bit(input[:4]);
    //        uint256 card2 = convert64bitTo256bit(input[4:8]);
    //        require(ownerOf(card1) == _msgSender(),"Must own card1");
    //        require(ownerOf(card2) == _msgSender(),"Must own card2");
    //        // verify merge result
    //        _burn(card1);
    //        _burn(card1);
    //        uint256 card3 = convert64bitTo256bit(input[x:x+4]);
    //        uint256 card4 = convert64bitTo256bit(input[4:8]);
    //        _safeMint(msg.sender,card3);
    //    }

    //    function convert64bitTo256bit(uint[4] memory inputArray) internal {
    //        uint result = 0;
    //        for (uint8 i = 0; i < 4; i++)
    //            result += inputArray[3 - i] << (4 * i);
    //        return result;
    //    }
}
