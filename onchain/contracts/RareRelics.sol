pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./NFRTypes.sol";
import "./MERGE.sol";

contract RareRelics is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    enum SpellTypes{DEFEND, STEAL, SWAP, DUPLICATE, TRANSFORM}

    struct Spell {
        SpellTypes spellType;
        uint8 numCardsAffected;
        NFRTypes.Ranks rankAffected;
    }

    mapping(uint256 => Spell) public spells;

    MERGE merge;
    address NFRAddress;
    bool NFRAddressSet;

    address BlackMarketAddress;
    bool BlackMarketAddressSet;

    uint16[3][7][5] public SPELL_MINT_PERCENT_CHANCE = [
        //  F        D            C               B            A           S          SS
        //1 2 3    1 2 3     1    2    3     1    2   3     1  2  3     1  2  3    1  2  3
        [[uint16(0),0,0], [uint16(0),0,0], [uint16(250), 100,75], [uint16(150), 75, 50], [uint16(75),50,35], [uint16(50),25,20], [uint16(25),15,5]], // defend
        [[uint16(0),0,0], [uint16(0),0,0], [uint16(250), 100,75], [uint16(150), 75, 50], [uint16(75),50,35], [uint16(50),25,20], [uint16(25),15,5]], // steal
        [[uint16(0),0,0], [uint16(0),0,0], [uint16(350), 100, 50], [uint16(250), 50, 30], [uint16(50),30,10], [uint16(39),20,5], [uint16(10),5,1]],  // swap
        [[uint16(0),0,0], [uint16(0),0,0], [uint16(350), 100, 50], [uint16(250), 50, 30], [uint16(55),30,10], [uint16(40),20,15], [uint16(0),0,0]],  // duplicate
        [[uint16(0),0,0], [uint16(0),0,0], [uint16(450), 150, 100], [uint16(125),65,25], [uint16(50),25,10], [uint16(0),0,0], [uint16(0),0,0]]      // transform
    ];

    uint256 private _nonce;

    constructor(address _merge) ERC721("Rare Relics", "RARERELICS"){
        merge = MERGE(_merge);
        NFRAddressSet = false;
        BlackMarketAddressSet = false;
    }

    function setNFRAddress(address _NFRAddress) external onlyOwner {
        require (NFRAddressSet == false, "already set NFR contract address");
        NFRAddress = _NFRAddress;
        NFRAddressSet = true;
    }

    function setBlackMarketAddress(address _BlackMarketAddress) external onlyOwner {
        require (BlackMarketAddressSet == false, "already set BlackMarket contract address");
        BlackMarketAddress = _BlackMarketAddress;
        BlackMarketAddressSet = true;
    }

    function useSpell(uint tokenID) external {
        require(BlackMarketAddressSet == true, "BlackMarket contract address not set yet");
        require(msg.sender == BlackMarketAddress, "Only BlackMarket contract can call this function");
        _burn(tokenID);
    }

    function mintFromPack(address to) external {
        require(NFRAddressSet == true, "NFR contract address not set yet");
        require(msg.sender == NFRAddress, "Only NFR contract can call this function");
        uint percentageChance = random() % 1000;
        Spell memory newSpell;
        if (percentageChance < 350) {
            newSpell = getRandomSpellAttributes(SpellTypes.DEFEND);
        }
        else if (percentageChance < 700){
            newSpell = getRandomSpellAttributes(SpellTypes.STEAL);
        }
        else if (percentageChance < 950){
            newSpell = getRandomSpellAttributes(SpellTypes.SWAP);
        }
        else if (percentageChance < 995){
            newSpell = getRandomSpellAttributes(SpellTypes.DUPLICATE);
        }
        else {
            newSpell = getRandomSpellAttributes(SpellTypes.TRANSFORM);
        }
        _tokenIds.increment();
        spells[_tokenIds.current()] = newSpell;
        _safeMint(to, _tokenIds.current());
    }

    function mintFromStore(SpellTypes spellType) external payable {
        Spell memory newSpell;
        if (spellType == SpellTypes.DEFEND) {
            newSpell = getRandomSpellAttributes(SpellTypes.DEFEND);
            merge.burn(_msgSender(),10000);
        }
        else if (spellType == SpellTypes.STEAL){
            newSpell = getRandomSpellAttributes(SpellTypes.STEAL);
            merge.burn(_msgSender(),10000);
        }
        else if (spellType == SpellTypes.SWAP){
            newSpell = getRandomSpellAttributes(SpellTypes.SWAP);
            merge.burn(_msgSender(),10000);
        }
        else if (spellType == SpellTypes.DUPLICATE){
            newSpell = getRandomSpellAttributes(SpellTypes.DUPLICATE);
            merge.burn(_msgSender(),10000);
        }
        else {
            newSpell = getRandomSpellAttributes(SpellTypes.TRANSFORM);
            merge.burn(_msgSender(),10000);
        }
        _tokenIds.increment();
        spells[_tokenIds.current()] = newSpell;
        _safeMint(_msgSender(), _tokenIds.current());
    }

    function getRandomSpellAttributes(SpellTypes spellType) internal returns(Spell memory) {
        uint randomPercentage = random() % 1000;
        for (uint8 rankAffected = 0; rankAffected <= uint8(NFRTypes.Ranks.SS); rankAffected++) {
            for (uint8 numCardsAffected = 1; numCardsAffected <= 3; numCardsAffected++ ) { // up to 3 num cards affected
                if (randomPercentage < SPELL_MINT_PERCENT_CHANCE[uint8(spellType)][rankAffected][numCardsAffected-1]) {
                   return Spell({
                        spellType: spellType,
                        numCardsAffected: numCardsAffected,
                        rankAffected: NFRTypes.Ranks(1) // TODO: change back to rankAffected
                   });
                }
                randomPercentage -= SPELL_MINT_PERCENT_CHANCE[uint8(spellType)][rankAffected][numCardsAffected-1];
            }
        }
        revert('Something went wrong getting a random number');
    }

    function random() internal returns(uint){
        _nonce += 1;
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _nonce, _msgSender())));
    }
}
