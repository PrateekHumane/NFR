// contracts/MyNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NFR is ERC721 {

    // some are hiddenCards and some are regular cards. Some ERC721 or ERC20

    uint256 public constant MINT_PRICE = .05 ether;
    uint16 public constant MAX_MINTABLE = 10;
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

    //    MERGE merge;

    constructor(/**address _merge**/) ERC721("NFR island", "NFR") {
        packsMinted = 0;
        gameOngoing = false;
        //        merge = MERGE(_merge);
    }

    function mintPack(uint8 artifact1, uint8 artifact2,uint8 artifact3) external payable returns (uint256[4] memory){
        // TODO: comment back in after testing
//        require(msg.value >= MINT_PRICE);
        require(packsMinted < MAX_MINTABLE);
        // three cards decided must be base cards
        require(artifact1 <= 50 && artifact1 >= 42);
        require(artifact2 <= 50 && artifact2 >= 42);
        require(artifact3 <= 50 && artifact3 >= 42);

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
            // TODO: do I need to ensure the root is unique beforehand?
            results[i] = merkleRoot;
        }

        // TODO: mint 5 merge tokens and a random spell card according to distribution

        packsMinted += 1;

        // Once someone buys the last pack, begin the game!
        if (packsMinted == MAX_MINTABLE)
            startGame();

        return results;
    }

    function startGame() internal {
       gameOngoing = true;
       // 1024 bit preimage representing the hidden card amounts for cards other than baseCardCopyCounts
       cardCopiesHashed = uint256(sha256(abi.encodePacked(uint256(0), uint256(0), uint256(0), uint256(0))));
    }

    function revealArtifact(uint256 tokenId, uint8 num, uint16 copyNum, uint256 longDescriptionHashed, uint256 privateKey) external {
        require (ownerOf(tokenId) == msg.sender); // must own artifact being revealed
        // TODO: if using memory and reference it in mapping does it create duplicate
        Artifact memory artifactToReveal = Artifact(num,copyNum,longDescriptionHashed,privateKey);
        uint256 merkleRoot = getArtifactMerkleRoot(artifactToReveal);
        require (tokenId == merkleRoot);

        publicArtifacts[merkleRoot] = artifactToReveal;
    }

    function endGame() external {
        require(gameOngoing == true);
        assert(address(this).balance >= MAX_MINTABLE * MINT_PRICE);

        // end the game and transfer the money
        gameOngoing = false;
        payable(msg.sender).transfer(MAX_MINTABLE * MINT_PRICE);
    }

    function getArtifactMerkleRoot(Artifact memory artifact) internal returns(uint256){
        return uint256(sha256(abi.encodePacked(sha256(abi.encodePacked(sha256(abi.encodePacked(artifact.num)), sha256(abi.encodePacked(artifact.copyNum)))), sha256(abi.encodePacked(abi.encodePacked(artifact.longDescriptionHashed), sha256(abi.encodePacked(artifact.privateKey)))))));
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
    //        // get merge result offchain using chainlink
    //    }

//    function convert64bitTo256bit(uint[4] memory inputArray) internal {
//        uint result = 0;
//        for (uint8 i = 0; i < 4; i++)
//            result += inputArray[3 - i] << (4 * i);
//        return result;
//    }
}
