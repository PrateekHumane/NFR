// contracts/MyNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./MERGE.sol";
import "./RareRelics.sol";
import "./MergeZKP.sol";

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
    MergeZKP mergeZKP;

    address BlackMarketAddress;
    bool BlackMarketAddressSet;

    uint256 private _nonce;

    constructor(address _merge, address _rareRelics, address _mergeZKP) ERC721("NFR island", "NFR") {
        packsMinted = 0;
        gameOngoing = false;
        merge = MERGE(_merge);
        rareRelics = RareRelics(_rareRelics);
        mergeZKP = MergeZKP(_mergeZKP);
        BlackMarketAddressSet = false;
    }

    function mintPack(uint8 artifact1, uint8 artifact2, uint8 artifact3, uint8 artifact4) external payable returns (uint256[4] memory){
        // TODO: comment back in after testing
        //        require(msg.value >= MINT_PRICE);
        require(packsMinted < MAX_MINTABLE, "MAX PACKS MINTED");
        // three cards decided must be base cards
        require(artifact1 <= 50 && artifact1 >= 42, "CAN ONLY REQUEST BASE CARD");
        require(artifact2 <= 50 && artifact2 >= 42, "CAN ONLY REQUEST BASE CARD");
        require(artifact3 <= 50 && artifact3 >= 42, "CAN ONLY REQUEST BASE CARD");
        require(artifact4 <= 50 && artifact4 >= 42, "CAN ONLY REQUEST BASE CARD");

        // additional card based on when you mint the pack
        uint8[4] memory artifactNums = [artifact1, artifact2, artifact3, artifact4];
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

    event AddMerge(uint256 mergeId, uint256 tokenId1, uint256 tokenId2);
    function requestMerge(uint256 tokenId1, uint256 tokenId2) external {
        require(ownerOf(tokenId1) == msg.sender && ownerOf(tokenId2) == msg.sender, "You must own the tokens");
        require(tokenId1 != tokenId2, "Enter two different tokens");
        // require(msg.value >= 0.002);
        merge.burn(msg.sender, 1 ether);

        uint256 mergeId = uint256(keccak256(abi.encodePacked(tokenId1, tokenId2)));
        mergeQueue[mergeId] = MergeInfo(0,tokenId1,tokenId2);
        if (mergeQueueLength > 0)
            mergeQueue[rear].nextMerge = mergeId;
        rear = mergeId;

        mergeQueueLength++;

        emit AddMerge(mergeId, tokenId1, tokenId2);
    }

    function processMerge(MergeZKP.Proof memory proof, uint[12] memory resultCardRoots, bool[3] memory resultCardsMint, uint[8] memory newCardCopiesHashed) external onlyOwner {
        require (mergeQueueLength > 0, "No merges in queue");
        uint256 nextMerge = head;

        uint256 tokenId1 = mergeQueue[nextMerge].tokenId1;
        uint256 tokenId2 = mergeQueue[nextMerge].tokenId2;
        require(ownerOf(tokenId1) == ownerOf(tokenId2), "must own both tokens still");

        // check the merge zero knowledge proof
        uint[39] memory zkpInput;

        // convert tokenId1 into 4  64 bit uints
        for (uint i = 0; i < 4; i++) {
            zkpInput[i] = tokenId1 & (0x11111111 << (3-i)*64);
        }
        // convert tokenId2 into 4  64 bit uints
        for (uint i = 0; i < 4; i++) {
            zkpInput[4+i] = tokenId2 & (0x11111111 << (3-i)*64);
        }
        // fill the rest in with input
        for (uint i = 0; i < 12; i++) {
            zkpInput[8+i] = resultCardRoots[i];
        }
        // convert copy counts hashed into 8 u32 ints
        for (uint i = 0; i < 8; i++) {
            zkpInput[20+i] = cardCopiesHashed & (0x1111 << (7-i)*32);
        }
        // convert bool of whether or not to mint to uint
        for (uint i = 0; i < 3; i++) {
            zkpInput[28+i] = resultCardsMint[i] ? 1: 0;
        }
        // add in the new card copy counts to zkp input
        for (uint i = 0; i < 8; i++) {
            zkpInput[31+i] = newCardCopiesHashed[i];
        }

        // verifying zero knowledge proof showing this is a fair merge
        require(mergeZKP.verifyTx(proof,zkpInput), "Zero Knowledge Proof Failed");

        _burn(tokenId1);
        _burn(tokenId2);

        for (uint i = 0; i < 3; i++) {
          // if we are supposed to mint the relic
          if (resultCardsMint[i]) {
              // mint the corresponding token
              _safeMint(ownerOf(tokenId1), convert64bitTo256bit([resultCardRoots[i*4], resultCardRoots[i*4+1], resultCardRoots[i*4+2], resultCardRoots[i*4+3]]));
          }
        }

        cardCopiesHashed = convert32bitTo256bit(newCardCopiesHashed);

        // pop merge from queue
        head = mergeQueue[nextMerge].nextMerge;
        delete mergeQueue[nextMerge];
        mergeQueueLength--;
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
        return uint256(keccak256(abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked(artifact.num)), keccak256(abi.encodePacked(artifact.copyNum)))), keccak256(abi.encodePacked(abi.encodePacked(artifact.longDescriptionHashed), keccak256(abi.encodePacked(artifact.privateKey)))))));
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

    function convert64bitTo256bit(uint[4] memory inputArray) internal pure returns(uint256){
        uint256 result = 0;
        for (uint8 i = 0; i < 4; i++)
            result += inputArray[3 - i] << (64 * i);
        return result;
    }

    function convert32bitTo256bit(uint[8] memory inputArray) internal pure returns(uint256){
        uint256 result = 0;
        for (uint8 i = 0; i < 8; i++)
            result += inputArray[7 - i] << (32 * i);
        return result;
    }
}
