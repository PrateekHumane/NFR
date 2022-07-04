pragma solidity ^0.8.0;

library NFRTypes {
    enum Ranks{F, D, C, B, A, S, SS}

    function getRank(uint32 cardNum) public pure returns (Ranks){
        uint8[7] memory card_rank_indices = [51,50,41,26,19,10,5];
        for (uint i = card_rank_indices.length-1; i > 0; i--){
            if (cardNum <= card_rank_indices[i])
                return Ranks(i);
        }
        revert('Card number should be less than 51');
    }

}
