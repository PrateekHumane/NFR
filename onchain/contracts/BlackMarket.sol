pragma solidity ^0.8.0;
import "./NFR.sol";
import "./MERGE.sol";
import "./RareRelics.sol";
import "./NFRTypes.sol";

contract BlackMarket {

    NFR nfr;
    MERGE merge;
    RareRelics rareRelics;

    uint16[5] public card_limits = [1551,1111,555,212,101];

    uint256 public constant MINIMUM_STAKE_TIME = 3 days;
    uint256[5] public DAILY_MERGE_RATE = [(1 ether)/10,(1 ether)/5,(1 ether)/4,(1 ether)/2,(1 ether)];

    struct Stake {
        uint stakeStart;
        uint redeemLast;
        NFRTypes.Ranks rank;
        uint arrayIndex;
        bool defended;
    }

    mapping(uint256 => bool) public isStaked;
    mapping(uint256 => Stake) public stakedPool;
    uint256[][5] private stakedPoolIndices;

    uint256 private _nonce;

    constructor(address _nfr, address _merge, address _rareRelics) {
        nfr = NFR(_nfr);
        merge = MERGE(_merge);
        rareRelics = RareRelics(_rareRelics);
    }

    function useDefendSpell(uint256 spellTokenId, uint256[] memory relicTokenIds) external {
        require (rareRelics.ownerOf(spellTokenId) == msg.sender, "MUST OWN SPELL TOKEN"); // must own spell card being used
        (RareRelics.SpellTypes spellType,uint8 numCardsAffected,NFRTypes.Ranks rankAffected) = rareRelics.spells(spellTokenId);
        require (spellType == RareRelics.SpellTypes.DEFEND, "MUST INPUT DEFEND SPELL");
        require (relicTokenIds.length <= numCardsAffected, "MORE CARDS DEFENDED THAN SPELL ALLOWS");

        for (uint256 i = 0; i < relicTokenIds.length; i++) {
            require (nfr.ownerOf(relicTokenIds[i]) == msg.sender, "MUST OWN RELIC");
            require (isStaked[relicTokenIds[i]] == true, "TOKEN NOT STAKED");
            require (stakedPool[relicTokenIds[i]].rank == rankAffected, "RANK DOESNT MATCH SPELL");
        }

        rareRelics.useSpell(spellTokenId);

        for (uint256 i = 0; i < relicTokenIds.length; i++) {
            stakedPool[relicTokenIds[i]].defended = true;
        }
    }

    function useStealSpell(uint256 spellTokenId) external returns(uint8){
        require (rareRelics.ownerOf(spellTokenId) == msg.sender, "MUST OWN SPELL TOKEN"); // must own spell card being used
        (RareRelics.SpellTypes spellType,uint8 numCardsAffected,NFRTypes.Ranks rankAffected) = rareRelics.spells(spellTokenId);
        require (spellType == RareRelics.SpellTypes.STEAL, "MUST INPUT STEAL SPELL");
        require (numCardsAffected <= stakedPoolIndices[uint8(rankAffected)].length, "NOT ENOUGH CARDS IN STAKE POOL TO STEAL");

        rareRelics.useSpell(spellTokenId);

        uint8 cardsSuccessfullyStolen = 0;
        for (uint i = 0; i < numCardsAffected && stakedPoolIndices[uint8(rankAffected)].length > 0; i++) {
            uint256 cardToStealIndex = random() % stakedPoolIndices[uint8(rankAffected)].length;
            uint256 cardToSteal = stakedPoolIndices[uint8(rankAffected)][cardToStealIndex];
            if (stakedPool[cardToSteal].defended){
                // if card is defended then defense has been used
                stakedPool[cardToSteal].defended = false;
            }
            else {
                nfr.stealCard(nfr.ownerOf(cardToSteal),msg.sender,cardToSteal);
//                nfr.transferFrom(nfr.ownerOf(cardToSteal),msg.sender,cardToSteal);
                cardsSuccessfullyStolen++;
            }
        }

        return cardsSuccessfullyStolen;
    }

    function useSwapSpell(uint256 spellTokenId, uint256[] memory relicTokenIds) external returns(uint8){
        require (rareRelics.ownerOf(spellTokenId) == msg.sender, "MUST OWN SPELL TOKEN"); // must own spell card being used
        (RareRelics.SpellTypes spellType,uint8 numCardsAffected,NFRTypes.Ranks rankAffected) = rareRelics.spells(spellTokenId);
        require (spellType == RareRelics.SpellTypes.SWAP, "MUST INPUT DEFEND SPELL");
        require (relicTokenIds.length <= numCardsAffected, "CANT SWAP MORE CARDS THAN SPELL ALLOWS");
        require (relicTokenIds.length <= stakedPoolIndices[uint8(rankAffected)].length, "NOT ENOUGH CARDS IN STAKE POOL TO SWAP WITH");

        for (uint256 i = 0; i < relicTokenIds.length; i++) {
            require (nfr.ownerOf(relicTokenIds[i]) == msg.sender, "MUST OWN RELIC");
            require (isStaked[relicTokenIds[i]] == true, "TOKEN NOT STAKED");
            require (stakedPool[relicTokenIds[i]].rank == rankAffected, "RANK DOESNT MATCH SPELL");
        }

        rareRelics.useSpell(spellTokenId);

        uint8 cardsSuccessfullySwapped = 0;
        for (uint256 i = 0; i < relicTokenIds.length; i++) {
            uint256 cardToStealIndex = random() % stakedPoolIndices[uint8(rankAffected)].length;
            uint256 cardToSteal = stakedPoolIndices[uint8(rankAffected)][cardToStealIndex];
            if (stakedPool[cardToSteal].defended) {
                // if card is defended then defense has been used
                stakedPool[cardToSteal].defended = false;
            }
            else {
                // random person steals the relic you put up
                nfr.stealCard(msg.sender, nfr.ownerOf(cardToSteal), relicTokenIds[i]);
                // you steal the relic they put up
                nfr.stealCard(nfr.ownerOf(cardToSteal),msg.sender,cardToSteal);

                cardsSuccessfullySwapped++;
            }
        }
        return cardsSuccessfullySwapped;
    }

    function useDuplicateSpell(uint256 spellTokenId, uint256[] memory relicTokenIds) external {
        require (rareRelics.ownerOf(spellTokenId) == msg.sender, "MUST OWN SPELL TOKEN"); // must own spell card being used
        (RareRelics.SpellTypes spellType,uint8 numCardsAffected,NFRTypes.Ranks rankAffected) = rareRelics.spells(spellTokenId);
        require (spellType == RareRelics.SpellTypes.DUPLICATE, "MUST INPUT DUPLICATE SPELL");
        require (relicTokenIds.length <= numCardsAffected, "MORE CARDS DUPLICATED THAN SPELL ALLOWS");

        for (uint256 i = 0; i < relicTokenIds.length; i++) {
            require (nfr.ownerOf(relicTokenIds[i]) == msg.sender, "MUST OWN RELIC");
            require (isStaked[relicTokenIds[i]] == true, "TOKEN NOT STAKED");
            require (stakedPool[relicTokenIds[i]].rank == rankAffected, "RANK DOESNT MATCH SPELL");
        }

        rareRelics.useSpell(spellTokenId);

        for (uint256 i = 0; i < relicTokenIds.length; i++) {
            nfr.duplicateCard(relicTokenIds[i]);
        }
    }

    function useTransformSpell(uint256 spellTokenId, uint256[] memory relicTokenIds) external {
        require (rareRelics.ownerOf(spellTokenId) == msg.sender, "MUST OWN SPELL TOKEN"); // must own spell card being used
        (RareRelics.SpellTypes spellType,uint8 numCardsAffected,NFRTypes.Ranks rankAffected) = rareRelics.spells(spellTokenId);
        require (spellType == RareRelics.SpellTypes.TRANSFORM, "MUST INPUT TRANSFORM SPELL");
        require (relicTokenIds.length <= numCardsAffected, "CANT TRANSFORM MORE CARDS THAN SPELL ALLOWS");
        require (relicTokenIds.length <= stakedPoolIndices[uint8(rankAffected) + 1].length, "NOT ENOUGH CARDS IN TRANSFORM TO");

        for (uint256 i = 0; i < relicTokenIds.length; i++) {
            require (nfr.ownerOf(relicTokenIds[i]) == msg.sender, "MUST OWN RELIC");
            require (isStaked[relicTokenIds[i]] == true, "TOKEN NOT STAKED");
            require (stakedPool[relicTokenIds[i]].rank == rankAffected, "RANK DOESNT MATCH SPELL");
        }

        rareRelics.useSpell(spellTokenId);

        for (uint256 i = 0; i < relicTokenIds.length; i++) {
            uint256 cardToTransformToIndex = random() % stakedPoolIndices[uint8(rankAffected)+1].length;
            uint256 cardToTransformTo = stakedPoolIndices[uint8(rankAffected)][cardToTransformToIndex];
            nfr.transformCard(relicTokenIds[i], cardToTransformTo);
        }
    }

    function stake(uint256 tokenId) external {
        require(nfr.ownerOf(tokenId) == msg.sender, "MUST OWN TOKEN");
        require(isStaked[tokenId] == false, "TOKEN ALREADY STAKED");
        (uint32 relicNum,uint32 relicCopyNum, , )  = nfr.publicArtifacts(tokenId);
        require(relicNum != 0 && relicCopyNum != 0, "STAKED ITEM MUST BE REVEALED");
        NFRTypes.Ranks relicRank = NFRTypes.getRank(relicNum);
//        require(relicRank >= NFRTypes.Ranks.C, "CARD MUST BE RANK C OR HIGHER TO STAKE");
        stakedPoolIndices[uint8(relicRank)].push(tokenId);

        stakedPool[tokenId] = Stake({
            stakeStart: block.timestamp,
            redeemLast: block.timestamp,
            rank: relicRank,
            arrayIndex: stakedPoolIndices[uint8(relicRank)].length - 1,
            defended: false
        });
        isStaked[tokenId] = true;
    }

    function redeemMerge(uint256 tokenId, bool unstakeToken) external returns(uint) {
        require(nfr.ownerOf(tokenId) == msg.sender, "MUST OWN TOKEN");
        require(isStaked[tokenId] == true, "TOKEN NOT STAKED");

        require(block.timestamp - stakedPool[tokenId].stakeStart >= MINIMUM_STAKE_TIME, "MUST STAKE FOR AT LEAST 3 DAYS");

        if (unstakeToken) {
            unstake(tokenId);
        }
        // TODO: getMergeRate(rank,copyNum) function
        uint amount = (block.timestamp - stakedPool[tokenId].redeemLast) * DAILY_MERGE_RATE[uint8(stakedPool[tokenId].rank)] / 1 days;
        stakedPool[tokenId].redeemLast = block.timestamp;
        merge.mint(msg.sender, amount);
        return amount;
    }


    function unstake(uint256 tokenId) internal {
        require(isStaked[tokenId] == true, "TOKEN NOT STAKED");

        uint8 stakeRank = uint8(stakedPool[tokenId].rank);
        uint stakeIndex = stakedPool[tokenId].arrayIndex;

        // get last element to fill in gap
        uint lastElement = stakedPoolIndices[stakeRank].length - 1;
        uint256 lastElementTokenId = stakedPoolIndices[stakeRank][lastElement];
        // set the hole to be the last element
        stakedPoolIndices[stakeRank][stakeIndex] = lastElementTokenId;
        // make sure the stake information reflects the new position (the gap we just filled in)
        stakedPool[lastElementTokenId].arrayIndex = stakeIndex;
        // remove the last element from array now (it has been moved elsewhere)
        stakedPoolIndices[stakeRank].pop();

        // delete the stake instance corresponding to token we're unstaking
        delete stakedPool[tokenId];
        isStaked[tokenId] = false;

    }

    function random() internal returns(uint){
        _nonce += 1;
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _nonce, msg.sender)));
    }

}
