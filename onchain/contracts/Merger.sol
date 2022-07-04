// contracts/MyNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFR.sol";
import "./MERGE.sol";
import "./MergeZKP.sol";

contract Merger {

    struct MergeInfo {
        uint256 nextMerge;
        uint256 tokenId1;
        uint256 tokenId2;
    }

    mapping (uint256 => MergeInfo) public mergeQueue;
    uint public mergeQueueLength = 0;
    uint256 public head;
    uint256 public rear;

   uint256 public cardCopiesHashed; // TODO: make private

    NFR nfr;
    MERGE merge;
    MergeZKP mergeZKP;

    constructor(address _nfr, address _merge, address _mergeZKP) {
        nfr = NFR(_nfr);
        mergeZKP = MergeZKP(_mergeZKP);
        merge = MERGE(_merge);

        // 1024 bit preimage representing the hidden card amounts for cards other than baseCardCopyCounts
        // this is the pedersen hash for pedersen(pedersen(uint256(0),uint256(0)),pedersen(uint256(0),uint256(0)))
        // all non base cards counts are 0 when the game starts
        cardCopiesHashed = 0xa693657d6c91fb3d012c9c0e44c2a411a0c65b00a77a54980938f73c06e82487;
        }

    event AddMerge(uint256 mergeId, uint256 tokenId1, uint256 tokenId2);
    function requestMerge(uint256 tokenId1, uint256 tokenId2) external {
        // require(nfr.gameOngoing());
        require(nfr.ownerOf(tokenId1) == msg.sender && nfr.ownerOf(tokenId2) == msg.sender, "You must own the tokens");
        require(tokenId1 != tokenId2, "Enter two different tokens");
        // require(msg.value >= 0.002);
        // require(msg.sender merge >= 1 ether)
        merge.burn(msg.sender, 1 ether);

        uint256 mergeId = uint256(keccak256(abi.encodePacked(tokenId1, tokenId2)));
        mergeQueue[mergeId] = MergeInfo(0,tokenId1,tokenId2);
        if (mergeQueueLength > 0)
            mergeQueue[rear].nextMerge = mergeId;
        else
            head = mergeId;

        rear = mergeId;

        mergeQueueLength++;

        emit AddMerge(mergeId, tokenId1, tokenId2);
    }

    event ConstructInput(uint[31] zkpInput);
    function processMerge(MergeZKP.Proof calldata proof, uint[3] calldata resultCardRoots, bool[3] calldata resultCardsMint, uint newCardCopiesHashed) external {
        // owner only? function
        require (mergeQueueLength > 0, "No merges in queue");
        uint256 nextMerge = head;

        uint256 tokenId1 = mergeQueue[nextMerge].tokenId1;
        uint256 tokenId2 = mergeQueue[nextMerge].tokenId2;
        require(nfr.ownerOf(tokenId1) == nfr.ownerOf(tokenId2), "must own both tokens still");

        // check the merge zero knowledge proof
        uint[31] memory zkpInput;

        // convert copy counts hashed into 4 u64 ints
        for (uint i = 0; i < 4; i++) {
            zkpInput[i] = (cardCopiesHashed >> ((3-i)*64)) & 0xFFFFFFFFFFFFFFFF;
        }
        // convert tokenId1 into 4  64 bit uints
        for (uint i = 0; i < 4; i++) {
            zkpInput[4+i] = (tokenId1 >> (3-i)*64) & 0xFFFFFFFFFFFFFFFF;
        }
        // convert tokenId2 into 4  64 bit uints
        for (uint i = 0; i < 4; i++) {
            zkpInput[8+i] = (tokenId2 >> ((3-i)*64)) & 0xFFFFFFFFFFFFFFFF;
        }
        // fill the rest in with input
        for (uint c = 0; c < 3; c++) {
            for (uint i = 0; i < 4; i++) {
                zkpInput[12+c*4+i] = (resultCardRoots[c] >> ((3-i)*64)) & 0xFFFFFFFFFFFFFFFF;
            }
        }
        // convert bool of whether or not to mint to uint
        for (uint i = 0; i < 3; i++) {
            zkpInput[24+i] = resultCardsMint[i] ? 1: 0;
        }
        // add in the new card copy counts to zkp input
        for (uint i = 0; i < 4; i++) {
            zkpInput[27+i] = (newCardCopiesHashed >> (3-i)*64) & 0xFFFFFFFFFFFFFFFF;
        }

        emit ConstructInput(zkpInput);

        // verifying zero knowledge proof showing this is a fair merge
        require(mergeZKP.verifyTx(proof,zkpInput), "Zero Knowledge Proof Failed");

        uint256[2] memory inputTokens;

        inputTokens[0] = tokenId1;
        inputTokens[1] = tokenId2;

        // do the token exchange for the merge
        nfr.doMerge(inputTokens, resultCardRoots, resultCardsMint);

        cardCopiesHashed = newCardCopiesHashed;

        // pop merge from queue
        head = mergeQueue[nextMerge].nextMerge;
        delete mergeQueue[nextMerge];
        mergeQueueLength--;
    }

//    function convert256bitTo64bit(uint input) internal pure returns(uint[4] memory){
//        uint[4] memory inputArray;
//        for (uint8 i = 0; i < 4; i++)
//            inputArray[i] = (input >> (i*64)) & 0x11111111;
//        return inputArray;
//    }
//
//    function convert64bitTo256bit(uint[4] memory inputArray) internal pure returns(uint256){
//        uint256 result = 0;
//        for (uint8 i = 0; i < 4; i++)
//            result += inputArray[3 - i] << (64 * i);
//        return result;
//    }
//
//    function convert32bitTo256bit(uint[8] memory inputArray) internal pure returns(uint256){
//        uint256 result = 0;
//        for (uint8 i = 0; i < 8; i++)
//            result += inputArray[7 - i] << (32 * i);
//        return result;
//    }
}