const MERGE = artifacts.require("MERGE");
const RareRelics = artifacts.require("RareRelics");
const BlackMarket = artifacts.require("BlackMarket");
const NFR = artifacts.require("NFR");

const timeMachine = require('ganache-time-traveler');

contract("testing staking", async accounts => {
    let mergeInstance;
    let rareRelicsInstance;
    let NFRInstance;
    let BlackMarketInstance;

    // beforeEach(async() => {
    //     let snapshot = await timeMachine.takeSnapshot();
    //     snapshotId = snapshot['result'];
    // });
    //
    // afterEach(async() => {
    //     await timeMachine.revertToSnapshot(snapshotId);
    // });

    before(async () => {
        mergeInstance = await MERGE.deployed();
        rareRelicsInstance = await RareRelics.deployed();
        NFRInstance = await NFR.deployed();
        BlackMarketInstance = await BlackMarket.deployed();

        // rareRelicsInstance = await RareRelics.deployed(mergeInstance.address);
        // NFRInstance = await NFR.deployed(mergeInstance.address, rareRelicsInstance.address);
        // BlackMarketInstance = await BlackMarket.deployed(NFRInstance.address, mergeInstance.address, rareRelicsInstance.address);

        // add merge controllers
        await mergeInstance.addController(NFRInstance.address);
        await mergeInstance.addController(rareRelicsInstance.address);
        await mergeInstance.addController(BlackMarketInstance.address);

        await rareRelicsInstance.setNFRAddress(NFRInstance.address);
        await rareRelicsInstance.setBlackMarketAddress(BlackMarketInstance.address);

        await NFRInstance.setBlackMarketAddress(BlackMarketInstance.address);
    });

    it("mint spells", async () => {
        // const roots = await NFRInstance.mintPack.call(42, 43, 44);
        // console.log(roots.map(root => root.toString('hex')));
        for (let account = 0; account < 2; account++) {
            for (let i = 0; i < 1; i++) {
                await NFRInstance.mintPack(42, 43, 44, { from: accounts[account] });
                // console.log((await rareRelicsInstance.balanceOf.call(accounts[0])));
                const spellToken = await rareRelicsInstance.tokenOfOwnerByIndex.call(accounts[account], i);
                const spellReceived = await rareRelicsInstance.spells.call(spellToken);
                console.log(spellReceived.spellType.toString());
                console.log(spellReceived.numCardsAffected.toString());
                console.log(spellReceived.rankAffected.toString());
            }
        }
    });

    xit("stake card", async() => {
        // stake three of your cards
        for (let i = 0; i < 3; i++) {
            const card = await NFRInstance.tokenOfOwnerByIndex.call(accounts[0], i);
            await BlackMarketInstance.stake(card);
            const stakedCard = await BlackMarketInstance.stakedPool.call(card);
            expect(stakedCard.arrayIndex.toNumber()).to.equal(i);
        }

        // redeem merge from card1
        const card1 = await NFRInstance.tokenOfOwnerByIndex.call(accounts[0], 0);
        await timeMachine.advanceTimeAndBlock(3*60*60*24);
        console.log('merge before redeem',(await mergeInstance.balanceOf.call(accounts[0])).toString());
        // console.log((await BlackMarketInstance.redeemMerge.call(card,false)).toString());
        await BlackMarketInstance.redeemMerge(card1,false);
        console.log('merge after redeem1 (3 days)',(await mergeInstance.balanceOf.call(accounts[0])).toString());
        await BlackMarketInstance.redeemMerge(card1,false);
        console.log('merge after redeem2 (0 days later)',(await mergeInstance.balanceOf.call(accounts[0])).toString());
        await timeMachine.advanceTimeAndBlock(1*60*60*24);
        await BlackMarketInstance.redeemMerge(card1,false);
        console.log('merge after redeem3 (1 days later)',(await mergeInstance.balanceOf.call(accounts[0])).toString());

        // unstake card2
        const card2 = await NFRInstance.tokenOfOwnerByIndex.call(accounts[0], 1);
        const card3 = await NFRInstance.tokenOfOwnerByIndex.call(accounts[0], 2);
        await BlackMarketInstance.redeemMerge(card2,true);
        console.log((await BlackMarketInstance.stakedPool.call(card1)).arrayIndex.toNumber());
        // console.log((await BlackMarketInstance.stakedPool.call(card2)).arrayIndex.toNumber());
        console.log((await BlackMarketInstance.stakedPool.call(card3)).arrayIndex.toNumber());

        // unstake cards 1 and 3 now
        await BlackMarketInstance.redeemMerge(card1,true);
        await BlackMarketInstance.redeemMerge(card3,true);
    });

    xit("test steal", async() => {
        // stake three of your cards
        for (let i = 0; i < 3; i++) {
            const card = await NFRInstance.tokenOfOwnerByIndex.call(accounts[0], i);
            await BlackMarketInstance.stake(card);
            const stakedCard = await BlackMarketInstance.stakedPool.call(card);
            expect(stakedCard.arrayIndex.toNumber()).to.equal(i);
        }

        // account 1 buy and use steal spell
        console.log('merge before spell purchase',(await mergeInstance.balanceOf.call(accounts[1])).toString());
        console.log('num spells before purchase',(await rareRelicsInstance.balanceOf.call(accounts[1])).toString());
        await rareRelicsInstance.mintFromStore(RareRelics.SpellTypes.STEAL, { from: accounts[1] });
        console.log('merge after spell purchase',(await mergeInstance.balanceOf.call(accounts[1])).toString());
        console.log('num spells after purchase',(await rareRelicsInstance.balanceOf.call(accounts[1])).toString());
        const spellToken = await rareRelicsInstance.tokenOfOwnerByIndex.call(accounts[1], 1);
        const spellReceived = await rareRelicsInstance.spells.call(spellToken);
        console.log('num cards to steal',spellReceived.numCardsAffected.toString());
        console.log('rank of cards to steal',spellReceived.rankAffected.toString());

        expect(spellReceived.spellType.toNumber()).to.equal(1);
        console.log('num cards before steal',(await NFRInstance.balanceOf.call(accounts[1])).toString());
        await BlackMarketInstance.useStealSpell(spellToken, { from: accounts[1] });
        console.log('num spells after steal',(await rareRelicsInstance.balanceOf.call(accounts[1])).toString());
        console.log('num cards after steal',(await NFRInstance.balanceOf.call(accounts[1])).toString());
    });

    xit("test defend", async() => {
        // stake all of account 0's cards
        for (let i = 0; i < 4; i++) {
            const card = await NFRInstance.tokenOfOwnerByIndex.call(accounts[0], i);
            console.log("card ",i," id is ", card.toString());
            await BlackMarketInstance.stake(card);
            const stakedCard = await BlackMarketInstance.stakedPool.call(card);
            expect(stakedCard.arrayIndex.toNumber()).to.equal(i);
        }

        for (let test_time = 0; test_time < 4; test_time++) {
            // defend all four of account 0's cards
            for (let i = 0; i < 4; i++) {
                const card = await NFRInstance.tokenOfOwnerByIndex.call(accounts[0], i);
                const stakedCard = await BlackMarketInstance.stakedPool.call(card);
                if (stakedCard.defended == false) {
                    console.log("defending card ", i);
                    // buy a defend card for each i
                    await rareRelicsInstance.mintFromStore(RareRelics.SpellTypes.DEFEND);
                    const spellToken = await rareRelicsInstance.tokenOfOwnerByIndex.call(accounts[0], 1);
                    // call the defend spell on the card i
                    await BlackMarketInstance.useDefendSpell(spellToken, [card]);
                }
            }

            await rareRelicsInstance.mintFromStore(RareRelics.SpellTypes.STEAL, {from: accounts[1]});
            const spellToken = await rareRelicsInstance.tokenOfOwnerByIndex.call(accounts[1], 1);
            // expect((await BlackMarketInstance.useStealSpell.call(spellToken, {from: accounts[1]})).toNumber()).to.equal(0);
            console.log('num cards before steal',(await NFRInstance.balanceOf.call(accounts[1])).toString());
            // steal can steal up to 3 cards. Sometimes it will steal the same card twice burning the defend and actually taking the card
            await BlackMarketInstance.useStealSpell(spellToken, {from: accounts[1]});
            console.log('num cards after steal',(await NFRInstance.balanceOf.call(accounts[1])).toString());
            if ((await NFRInstance.balanceOf.call(accounts[1])).toNumber() == 5){
                console.log("stolen card:", (await NFRInstance.tokenOfOwnerByIndex.call(accounts[1], 4)).toString());
            }
        }
    });

    xit("test swap", async() => {
        // stake all of account 0's cards
        for (let i = 0; i < 4; i++) {
            const card = await NFRInstance.tokenOfOwnerByIndex.call(accounts[0], i);
            console.log("card ",i," id is ", card.toString());
            await BlackMarketInstance.stake(card);
            const stakedCard = await BlackMarketInstance.stakedPool.call(card);
            expect(stakedCard.arrayIndex.toNumber()).to.equal(i);
        }

        // stake 1 of account 1's cards
        const card = await NFRInstance.tokenOfOwnerByIndex.call(accounts[1], 0);
        console.log("card ",0," id is ", card.toString());
        await BlackMarketInstance.stake(card, {from: accounts[1]});
        // buy a swap spell card
        await rareRelicsInstance.mintFromStore(RareRelics.SpellTypes.SWAP, {from: accounts[1]});
        const spellToken = await rareRelicsInstance.tokenOfOwnerByIndex.call(accounts[1], 1);
        // use swap spell
        await BlackMarketInstance.useSwapSpell(spellToken, [card], {from: accounts[1]});

        // still only have 4 cards
        expect((await NFRInstance.balanceOf.call(accounts[1])).toNumber()).to.equal(4);

        // card that got swapped
        for (let i = 0; i < 4; i++) {
            const card = await NFRInstance.tokenOfOwnerByIndex.call(accounts[0], i);
            console.log("account 0 card", i, " id is ", card.toString());
        }

        // card you got from swap
        for (let i = 0; i < 4; i++) {
            const card = await NFRInstance.tokenOfOwnerByIndex.call(accounts[1], i);
            console.log("account 1 card", i, " id is ", card.toString());
        }
    });

    it("test duplicate", async() => {
        // stake account 0's card 0
        const card = await NFRInstance.tokenOfOwnerByIndex.call(accounts[0], 0);
        await BlackMarketInstance.stake(card);
        // const stakedCard = await BlackMarketInstance.stakedPool.call(card);

        // ACCOUNT 1:
        // buy a duplicate spell card
        await rareRelicsInstance.mintFromStore(RareRelics.SpellTypes.DUPLICATE, {from: accounts[0]});
        const spellToken = await rareRelicsInstance.tokenOfOwnerByIndex.call(accounts[0], 1);
        const spellReceived = await rareRelicsInstance.spells.call(spellToken);
        console.log("num cards affected", spellReceived.numCardsAffected.toNumber());
        // use duplicate spell
        await BlackMarketInstance.useDuplicateSpell(spellToken, [card], {from: accounts[0]});


        // still only have 4 cards
        const accountCards = (await NFRInstance.balanceOf.call(accounts[0])).toNumber();

        // card that got swapped
        for (let i = 0; i < accountCards; i++) {
            const card = await NFRInstance.tokenOfOwnerByIndex.call(accounts[0], i);
            console.log("account 0 card", i, " id is ", card.toString());
        }
    });
});