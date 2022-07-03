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
    uint256[9] public baseCardHashedDescription = [0x01649792131254809c4b0f4287aaeb9a5229812249af54b3a86c8dcfecda625a, 4, 5, 6, 7, 0, 1, 2, 3];

    struct Artifact {
        uint8 num;
        uint16 copyNum;
        // HIDDEN VALUES:
        uint256 longDescriptionHashed;
        uint256 privateKey;
    }

    struct MergeInfo {
       uint256 nextMerge;
       uint256 tokenId1;
       uint256 tokenId2;
    }
    mapping (uint256 => MergeInfo) public mergeQueue;
    uint public mergeQueueLength = 0;
    uint256 public head;
    uint256 public rear;

    mapping(uint256 => Artifact) public publicArtifacts; // private or public?

    uint256 public cardCopiesHashed; // TODO: make private

    MERGE merge;
    RareRelics rareRelics;

    address BlackMarketAddress;
    bool BlackMarketAddressSet;

    address MergerAddress;
    bool MergerAddressSet;

    uint256 private _nonce;

    constructor(address _merge, address _rareRelics) ERC721("NFR island", "NFR") {
        packsMinted = 0;
        gameOngoing = false;
        merge = MERGE(_merge);
        rareRelics = RareRelics(_rareRelics);
        BlackMarketAddressSet = false;
        MergerAddressSet = false;
    }

    function mintPack(uint8[4] memory artifactNums) external payable returns (uint256[4] memory){
        // TODO: comment back in after testing
        //        require(msg.value >= MINT_PRICE);
        require(packsMinted < MAX_MINTABLE, "MAX PACKS MINTED");
        // cards decided must be base cards
        for (uint8 a = 0; a < 4; a++)
            require(artifactNums[a] <= 50 && artifactNums[a] >= 42, "CAN ONLY REQUEST BASE CARD");

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
        setApprovalForAll(BlackMarketAddress, true); // TODO: why call this every time?
        rareRelics.mintFromPack(msg.sender);
        merge.mint(msg.sender, 5 ether);

        packsMinted += 1;

        // Once someone buys the last pack, begin the game!
        if (packsMinted == MAX_MINTABLE)
            startGame();

        return results;
    }

    function startGame() internal {
        gameOngoing = true;

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
        uint256 hash1 = uint256(keccak256(abi.encodePacked(keccak256(abi.encodePacked(artifact.num)), keccak256(abi.encodePacked(artifact.copyNum)))));
        uint256 hash2 = uint256(keccak256(abi.encodePacked(keccak256(abi.encodePacked(artifact.longDescriptionHashed)), keccak256(abi.encodePacked(artifact.privateKey)))));
        return uint256(keccak256(abi.encodePacked(hash1,hash2)));
//        return uint256(keccak256(abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked(artifact.num)), keccak256(abi.encodePacked(artifact.copyNum)))), keccak256(abi.encodePacked(abi.encodePacked(artifact.longDescriptionHashed), keccak256(abi.encodePacked(artifact.privateKey)))))));
    }

    event cardStolen(address from, address to, uint256 tokenId);

    function stealCard(address from, address to, uint256 tokenId) public isBlackMarketContract {
        emit cardStolen(from, to, tokenId);
        transferFrom(from, to, tokenId);
    }

    event cardBurnt(address owner, uint256 tokenId);

    function duplicateCard(uint256 tokenId) public isBlackMarketContract {
//        Artifact memory newCard = Artifact({
//            num : publicArtifacts[tokenId].num,
//            copyNum : publicArtifacts[tokenId].copyNum, // duplicate doesn't increase the version num (this is power of the card) even when limit is reached more copies can be made
//            longDescriptionHashed : publicArtifacts[tokenId].longDescriptionHashed,
//            privateKey : random()
//            // TODO: copy: true
//        });
//        uint256 merkleRoot = getArtifactMerkleRoot(newCard);
//        publicArtifacts[merkleRoot] = newCard;
//        _safeMint(ownerOf(tokenId), merkleRoot);
    }

    function transformCard(uint256 inputTokenId, uint256 targetTokenId) public isBlackMarketContract {
        emit cardBurnt(ownerOf(inputTokenId), inputTokenId);
//        _burn(inputTokenId);
//        Artifact memory newCard = Artifact({
//            num : publicArtifacts[targetTokenId].num,
//            copyNum : publicArtifacts[targetTokenId].copyNum,
//            longDescriptionHashed : publicArtifacts[targetTokenId].longDescriptionHashed,
//            privateKey : random()
//            // TODO: copy: true
//        });
//        uint256 merkleRoot = getArtifactMerkleRoot(newCard);
//        publicArtifacts[merkleRoot] = newCard;
//        _safeMint(ownerOf(inputTokenId), merkleRoot);
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

    function setMergerAddress(address _MergerAddress) external onlyOwner {
        require (MergerAddressSet == false, "already set Merger contract address");
        MergerAddress = _MergerAddress;
        MergerAddressSet = true;
    }

    function doMerge(uint256[2] memory inputTokens,uint256[3] memory resultTokens, bool[3] memory resultTokensMint) public isMergerContract {
        emit cardBurnt(ownerOf(inputTokens[0]), inputTokens[0]);
        emit cardBurnt(ownerOf(inputTokens[1]), inputTokens[1]);
        _burn(inputTokens[0]);
        _burn(inputTokens[1]);

        for (uint i = 0; i < 3; i++) {
            // if we are supposed to mint the relic
            if (resultTokensMint[i]) {
                // mint the corresponding token
                _safeMint(ownerOf(inputTokens[0]), resultTokens[i]);
            }
        }
    }

    modifier isMergerContract {
        require(MergerAddressSet == true, "MERGER CONTRACT NOT SET");
        require(msg.sender == MergerAddress, "ONlY MERGER CONTRACT CAN CALL THIS FUNCTION");
        _;
    }

    modifier whenGameOngoing {
        require(gameOngoing, "GAME NOT ONGOING");
        _;
    }

    // TODO: add to library?
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

}
