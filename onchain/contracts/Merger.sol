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
        cardCopiesHashed = 0xa65f3fa0002aba81ad5f5805158ca53b4c6786ad9dc9845a0acbd5e718ffe95d;
    }

    event AddMerge(uint256 mergeId, uint256 tokenId1, uint256 tokenId2);
    function requestMerge(uint256 tokenId1, uint256 tokenId2) external {
        require(nfr.gameOngoing());
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

    function processMerge(MergeZKP.Proof calldata proof, uint[12] calldata resultCardRoots, bool[3] calldata resultCardsMint, uint[4] calldata newCardCopiesHashed) external {
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
            zkpInput[i] = (cardCopiesHashed >> (i*64)) & 0x11111111;
        }
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

        uint256[2] memory inputTokens;
        uint256[3] memory resultTokens;

        inputTokens[0] = tokenId1;
        inputTokens[1] = tokenId2;

        for (uint i = 0; i < 3; i++) {
            // if we are supposed to mint the relic
            if (resultCardsMint[i]) {
                // mint the corresponding token
                resultTokens[i] = convert64bitTo256bit([resultCardRoots[i*4], resultCardRoots[i*4+1], resultCardRoots[i*4+2], resultCardRoots[i*4+3]]);
            }
        }

        // do the token exchange for the merge
        nfr.doMerge(inputTokens, resultTokens, resultCardsMint);

        cardCopiesHashed = convert32bitTo256bit(newCardCopiesHashed);

        // pop merge from queue
        head = mergeQueue[nextMerge].nextMerge;
        delete mergeQueue[nextMerge];
        mergeQueueLength--;
    }

    function convert256bitTo64bit(uint memory input) internal pure returns(uint[4] memory){
        uint[4] inputArray;
        for (uint8 i = 0; i < 4; i++)
            inputArray = (input >> (i*64)) & 0x11111111;
        return inputArray;
    }

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