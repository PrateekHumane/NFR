pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract RareRelics is ERC721 {

    enum SpellTypes{DEFEND, STEAL, BURN, SWAP, DUPLICATE, TRANSFORM}
    enum Ranks{C, B, A, S, SS}

    struct Spell {
        SpellTypes spellType;
        uint256 version;
        uint8 numCardsAffected;
        Ranks ranksAffected;
    }

    mapping(uint256 => Spell) public spells;

    function RareRelics(){

    }
}
