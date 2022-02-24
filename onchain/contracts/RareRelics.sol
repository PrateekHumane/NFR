pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./NFR.sol";
import "./MERGE.sol";

contract RareRelics is ERC721 {

    NFR nfr;
    MERGE merge;

    enum SpellTypes{DEFEND, STEAL, SWAP, DUPLICATE, TRANSFORM}
    enum Ranks{C, B, A, S, SS}

    uint8[5] constant card_rank_indices = [41,26,19,10,5];
    uint16[5] constant card_limits = [1551,1111,555,212,101];

    uint256 public constant MINIMUM_STAKE_TIME = 3 days;
    uint256[5][2] constant DAILY_MERGE_RATE = [[1,2],[3,4],[5,6],[7,8],[9,10]];

    struct Spell {
        SpellTypes spellType;
        uint256 version;
        uint8 numCardsAffected;
        Ranks rankAffected;
    }

    mapping(uint256 => Spell) public spells;

    struct Stake {
        uint80 stakeStart;
        Ranks rank;
        uint arrayIndex;
        bool defended;
    }

    mapping(uint256 => bool) public isStaked;
    mapping(uint256 => Stake) public stakedPool;
    uint256[5][] private stakedPoolIndices;

    uint256 private _nonce;

    constructor(address _nfr, address _merge) {
        nfr = NFR(_nfr);
        merge = MERGE(_merge);
    }

    function useDefendSpell(uint256 spellTokenId, uint256[] relicTokenIds) external {
        require (ownerOf(spellTokenId) == msg.sender, "MUST OWN SPELL TOKEN"); // must own spell card being used
        Spell spell = spells[spellTokenId];
        require (spells[spellTokenId].spellType == SpellTypes.DEFEND, "MUST INPUT DEFEND SPELL");
        require (relicTokenIds.length <= spells[spellTokenId].numCardsAffected, "MORE CARDS DEFENDED THAN SPELL ALLOWS");

        for (uint256 i = 0; i < relicTokenIds.length; i++) {
            require (nfr.ownerOf(relicTokenIds[i]) == _msgSender(), "MUST OWN RELIC");
            require (isStaked[relicTokenIds[i]] == true, "TOKEN NOT STAKED");
            require (stakedPool[relicTokenIds[i]].rank == spell.rankAffected, "RANK DOESNT MATCH SPELL");
        }

        _burn(spellTokenId);

        for (uint256 i = 0; i < relicTokenIds.length; i++) {
            stakedPool[relicTokenIds[i]].defended = true;
        }
    }

    function useStealSpell(uint256 spellTokenId) external returns(uint8){
        require (ownerOf(spellTokenId) == msg.sender, "MUST OWN SPELL TOKEN"); // must own spell card being used
        Spell spell = spells[spellTokenId];
        require (spell.spellType == SpellTypes.STEAL, "MUST INPUT STEAL SPELL");
        require (spell.numCardsAffected <= stakedPoolIndices[spell.rankAffected].length, "NOT ENOUGH CARDS IN STAKE POOL TO SPELL");

        _burn(spellTokenId);

        uint8 cardsSuccessfullyStolen = 0;
        for (uint i = 0; i < spell.numCardsAffected && stakedPoolIndices[spell.rankAffected].length > 0; i++) {
            uint256 cardToSteal = random() % stakedPoolIndices[spell.rankAffected].length;
            if (stakedPool[cardToSteal].defended){
                // if card is defended then defense has been used
                stakedPool[cardToSteal].defended = false;
            }
            else {
                nfr.stealCard(nfr.ownerOf(cardToSteal),_msgSender(),cardToSteal);
                cardsSuccessfullyStolen++;
            }
        }

        return cardsSuccessfullyStolen;
    }

    function useSwapSpell(uint256 spellTokenId, uint256[] relicTokenIds) external returns(uint8){
        require (ownerOf(spellTokenId) == msg.sender, "MUST OWN SPELL TOKEN"); // must own spell card being used
        Spell spell = spells[spellTokenId];
        require (spells[spellTokenId].spellType == SpellTypes.SWAP, "MUST INPUT DEFEND SPELL");
        require (relicTokenIds.length <= spells[spellTokenId].numCardsAffected, "CANT SWAP MORE CARDS THAN SPELL ALLOWS");
        require (relicTokenIds.length <= stakedPoolIndices[spell.rankAffected].length, "NOT ENOUGH CARDS IN STAKE POOL TO SWAP WITH");

        for (uint256 i = 0; i < relicTokenIds.length; i++) {
            require (nfr.ownerOf(relicTokenIds[i]) == _msgSender(), "MUST OWN RELIC");
            require (isStaked[relicTokenIds[i]] == true, "TOKEN NOT STAKED");
            require (stakedPool[relicTokenIds[i]].rank == spell.rankAffected, "RANK DOESNT MATCH SPELL");
        }

        _burn(spellTokenId);

        uint8 cardsSuccessfullySwapped = 0;
        for (uint256 i = 0; i < relicTokenIds.length; i++) {
            uint256 cardToSteal = random() % stakedPoolIndices[spell.rankAffected].length;
            if (stakedPool[cardToSteal].defended) {
                // if card is defended then defense has been used
                stakedPool[cardToSteal].defended = false;
            }
            else {
                // random person steals the relic you put up
                nfr.stealCard(_msgSender(), nfr.ownerOf(cardToSteal), relicTokenIds[i]);
                // you steal the relic they put up
                nfr.stealCard(nfr.ownerOf(cardToSteal),_msgSender(),cardToSteal);

                cardsSuccessfullySwapped++;
            }
        }
        return cardsSuccessfullySwapped;
    }

    function useDuplicateSpell(uint256 spellTokenId, uint256[] relicTokenIds) external {
        require (ownerOf(spellTokenId) == msg.sender, "MUST OWN SPELL TOKEN"); // must own spell card being used
        Spell spell = spells[spellTokenId];
        require (spells[spellTokenId].spellType == SpellTypes.DUPLICATE, "MUST INPUT DUPLICATE SPELL");
        require (relicTokenIds.length <= spells[spellTokenId].numCardsAffected, "MORE CARDS DUPLICATED THAN SPELL ALLOWS");

        for (uint256 i = 0; i < relicTokenIds.length; i++) {
            require (nfr.ownerOf(relicTokenIds[i]) == _msgSender(), "MUST OWN RELIC");
            require (isStaked[relicTokenIds[i]] == true, "TOKEN NOT STAKED");
            require (stakedPool[relicTokenIds[i]].rank == spell.rankAffected, "RANK DOESNT MATCH SPELL");
        }

        _burn(spellTokenId);

        for (uint256 i = 0; i < relicTokenIds.length; i++) {
            nfr.duplicateCard(relicTokenIds[i]);
        }
    }

    function useTransformSpell(uint256 spellTokenId, uint256[] relicTokenIds) external {
        require (ownerOf(spellTokenId) == msg.sender, "MUST OWN SPELL TOKEN"); // must own spell card being used
        Spell spell = spells[spellTokenId];
        require (spells[spellTokenId].spellType == SpellTypes.TRANSFORM, "MUST INPUT TRANSFORM SPELL");
        require (relicTokenIds.length <= spells[spellTokenId].numCardsAffected, "CANT TRANSFORM MORE CARDS THAN SPELL ALLOWS");
        require (relicTokenIds.length <= stakedPoolIndices[spell.rankAffected + 1].length, "NOT ENOUGH CARDS IN TRANSFORM TO");

        for (uint256 i = 0; i < relicTokenIds.length; i++) {
            require (nfr.ownerOf(relicTokenIds[i]) == _msgSender(), "MUST OWN RELIC");
            require (isStaked[relicTokenIds[i]] == true, "TOKEN NOT STAKED");
            require (stakedPool[relicTokenIds[i]].rank == spell.rankAffected, "RANK DOESNT MATCH SPELL");
        }

        _burn(spellTokenId);

        for (uint256 i = 0; i < relicTokenIds.length; i++) {
            uint256 cardToTransformTo = random() % stakedPoolIndices[spell.rankAffected+1].length;
            nfr.transformCard(relicTokenIds[i], cardToTransformTo);
        }
    }

    function stake(uint256 tokenId) external {
        require(nfr.ownerOf(tokenId) == _msgSender(), "MUST OWN TOKEN");
        require(isStaked[tokenId] == false, "TOKEN ALREADY STAKED");
        uint8 relicNum = nfr.publicArtifacts(tokenId).num;
        uint16 relicCopyNum = nfr.publicArtifacts(tokenId).copyNum;
        require(relicNum != 0 && relicCopyNum != 0, "STAKED ITEM MUST BE REVEALED");
        require(relicNum <= card_rank_indices[0], "CARD MUST BE RANK C OR HIGHER TO STAKE");
        Ranks relicRank = getRank(relicNum);
        stakedPoolIndices[relicRank].push(tokenId);

        stakedPool[tokenId] = Stake({
            stakeStart: uint80(block.timestamp),
            rank: relicRank,
            arrayIndex: stakedPoolIndices[relicRank].length - 1
        });
        isStaked[tokenId] = true;
    }

    function redeemMerge(uint256 tokenId, bool unstake) external {
        require(nfr.ownerOf(tokenId) == _msgSender(), "MUST OWN TOKEN");
        require(isStaked[tokenId] == true, "TOKEN NOT STAKED");

        uint80 stakeStart = stakedPool[tokenId].stakeStart;
        require(block.timestamp - stakeStart < MINIMUM_STAKE_TIME, "MUST STAKE FOR AT LEAST 3 DAYS");

        if (unstake) {
            unstake(tokenId);
        }
        // TODO: getMergeRate(rank,copyNum) function
        merge.mint(_msgSender(), (block.timestamp - stakeStart) * DAILY_MERGE_RATE[relicRank] / 1 days);
    }

    function getRank(uint8 cardNum) internal returns (Ranks){
        for (uint i = card_rank_indices.length; i > 0; i--){
            if (cardNum <= card_rank_indices[i])
                return i;
        }
        return 0;
    }

    function unstake(uint256 tokenId) internal {
        require(isStaked[tokenId] == true, "TOKEN NOT STAKED");

        Ranks stakeRank = stakedPool[tokenId].rank;
        uint stakeIndex = stakedPool[tokenId].arrayIndex;

        // get last element to fill in gap
        uint lastElement = stakedPoolIndices[stakeRank].length - 1;
        uint256 lastElementTokenId = stakedPoolIndices[stakeRank][lastElement];
        // set the hole to be the last element
        stakedPoolIndices[stakeRank][stakeIndex] = lastElementTokenId;
        // make sure the stake information reflects the new position (the gap we just filled in)
        stakedPool[lastElementTokenId].arrayIndex = stakeIndex;
        // remove the last element from array now (it has been moved elsewhere)
        stakedPoolIndices[stakeRank].length--;

        // delete the stake instance corresponding to token we're unstaking
        delete stakedPool[tokenId];
        isStaked[tokenId] = false;

    }

    function random() internal returns(uint){
        _nonce += 1;
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _nonce, _msgSender())));
    }
}
