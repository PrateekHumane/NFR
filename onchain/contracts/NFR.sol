// contracts/MyNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NFR is ERC721 {

    // some are hiddenCards and some are regular cards. Some ERC721 or ERC20

    uint8 public constant MAX_MINTABLE = 5000;
    uint16 public packsMinted;

    // if we need more info than merkleRoot per card, then create a struct that the ID maps to
    // map from hiddenCardId -> merkleRoot
    uint16[9] public baseCardCopyCounts = [0, 0, 0, 0, 0, 0, 0, 0, 0];
    uint256[9] public baseCardHashedDescription = [0, 0, 0, 0, 0, 0, 0, 0, 0];

    struct Artifact {
        uint8 num;
        uint16 copyNum;
        // HIDDEN VALUES:
        uint256 longDescriptionHashed;
        uint256 privateKey;
    }

    mapping(uint256 => Artifact) private publicArtifacts;

    MERGE merge;

    constructor(address _merge) ERC721("NFR island", "NFR") public {
        packsMinted = 0;
//        merge = MERGE(_merge);
    }

    function mintPack (uint8[3] cards) public external payable {
        require(packsMinted < MAX_MINTABLE);
        // three cards decided must be base cards
        for (let i = 0; i < 3; i++)
            require(cards[i] <= 50 && cards[i] >= 42);

        // additional card based on when you mint the pack
        cards.push(packsMinted % 9 + 42);
        for (let i = 0; i < 3; i++)
            Artifact memory artifactToMint;
            artifactToMint.num = cards[i];
            baseCardCopyCounts[cards[i]-42] += 1;
            artifactToMint.copyNum = baseCardCopyCounts[cards[i]-42];
            artifactToMint.longDescriptionHashed = baseCardHashedDescription[cards[i]-42];
            artifactToMint.privateKey = 0;

            // create a merkle tree out of each card
            uint256 merkleRoot = sha256(sha256(sha256(artifactsMinted[i].num),sha256(artifactsMinted[i].copyNum)),sha256(artifactsMinted[i].longDescriptionHashed, artifactsMinted[i].privateKey));
            publicArtifacts[merkleRoot] = artifactToMint;
            _safeMint(msg.sender, merkleRoot); // TODO: do I need to ensure the root is unique beforehand?

        // TODO: mint 5 merge tokens and a random spell card according to distribution

        packsMinted +=1;
    }

//    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
//       require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
//
//       // https://cloudflare-ipfs.com/ipns/ {TOKEN ID} .dogsunchainednft.com
//       return string(abi.encodePacked(prefix, tokenId.toString(), suffix));
//    }


    function merge(Proof memory proof, uint[40] memory input) external {
        uint256 card1 = convert64bitTo256bit(input[:4]);
        uint256 card2 = convert64bitTo256bit(input[4:8]);
        require(ownerOf(card1) == _msgSender(),"Must own card1");
        require(ownerOf(card2) == _msgSender(),"Must own card2");
        // get merge result offchain using chainlink
    }

    function convert64bitTo256bit(uint[4] memory inputArray) internal {
        uint result = 0;
        for (uint8 i =0; i < 4; i++)
            result += inputArray[3-i]<<(4*i);
        return result;
    }
}
