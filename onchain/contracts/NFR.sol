// contracts/MyNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NFR is ERC721 {

    // some are hiddenCards and some are regular cards. Some ERC721 or ERC20

    uint8 public constant MAX_MINTABLE = 3;
    uint16 public cardsRedeemed;

    // if we need more info than merkleRoot per card, then create a struct that the ID maps to
    // map from hiddenCardId -> merkleRoot
    uint256[3] public baseCardTokenIDs; //tokenIDs of baseCards are also merkle roots

    // mapping (uint256 => bytes32) cardIdToMerkleRoot;
    // map from mintNum to hiddenCardId
    // mapping (uint16 => uint256) mintOrder;
    // mapping (uint16 => bytes32) hiddenCardIdToMerkleRoot;

     mapping (uint256 => uint) mergeTime;

    MERGE merge;

    constructor(address _merge) ERC721("NFR island", "NFR") {
        cardsRedeemed = 0;
        baseCardTokenIDs[0]=0x3622270ee2d86a424ec39b290b301909faa80691a96f1db92509a8a1ba6bac21;
        baseCardTokenIDs[1]=0x325337c6f247e8915fb53a3edbf19a210d283edc26e02f14b5d0d54e8ee9ce11;
        baseCardTokenIDs[2]=0x8f5dcb386d0518b8615b08d9589ee65883faf02d5da0e3d62950d328b4d94040;
        merge = MERGE(_merge);
    }

    function mint() external payable {
        require(cardsRedeemed < MAX_MINTABLE);
        _safeMint(msg.sender, baseCardTokenIDs[cardsRedeemed]);
        cardsRedeemed+=1;
    }

    function useMergeToken(uint256 card1, uint256 card2) external {
        require(ownerOf(card1) == _msgSender(),"Must own card1");
        require(ownerOf(card2) == _msgSender(),"Must own card2");
        merge.burn(_msgSender(), 1);
        mergeTime[card1]=block.timestamp;
        mergeTime[card2]=block.timestamp;
    }

    function merge(Proof memory proof, uint[40] memory input) external {
        uint256 card1 = convert64bitTo256bit(input[:4]);
        uint256 card2 = convert64bitTo256bit(input[4:8]);
        require(ownerOf(card1) == _msgSender(),"Must own card1");
        require(ownerOf(card2) == _msgSender(),"Must own card2");
        // get merge result offchain using chainlink
    }

    // function: check if the proof is valid for ZKP indicating whether a leaf and proof is valid
    // this to show the information you are presenting to the user is fair
    // don't use this function - if people use this, then others can see if the card# is a part of cardID
    // they can check every card# -> leaf and see which leaf they tried that was a successful verification
    // we can't make the card#'s random ids because we need a list of them to prove the game is winable
    // instead do the verification offchain, no reason to do it onchain anyways
//    function verify(uint16 cardId, bytes32 leaf, bytes32[] memory proof)
//    public view returns (bool)
//    {
//        require(msg.sender == ownerOf(cardId));
//        return MerkleProof.verify(proof, merkleRoots[cardId], leaf);
//    }
    function convert64bitTo256bit(uint[4] memory inputArray) internal {
        uint result = 0;
        for (uint8 i =0; i < 4; i++)
            result += inputArray[3-i]<<(4*i);
        return result;
    }
}
