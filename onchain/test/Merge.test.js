const MERGE = artifacts.require("MERGE");
const RareRelics = artifacts.require("RareRelics");
const BlackMarket = artifacts.require("BlackMarket");
const NFR = artifacts.require("NFR");
const Merger = artifacts.require("Merger");

const timeMachine = require('ganache-time-traveler');

contract("testing staking", async accounts => {
    let mergeInstance;
    let rareRelicsInstance;
    let NFRInstance;
    let BlackMarketInstance;
    let MergerInstance;

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
        MergerInstance = await Merger.deployed();

        // rareRelicsInstance = await RareRelics.deployed(mergeInstance.address);
        // NFRInstance = await NFR.deployed(mergeInstance.address, rareRelicsInstance.address);
        // BlackMarketInstance = await BlackMarket.deployed(NFRInstance.address, mergeInstance.address, rareRelicsInstance.address);

        // add merge controllers
        await mergeInstance.addController(NFRInstance.address);
        await mergeInstance.addController(rareRelicsInstance.address);
        await mergeInstance.addController(BlackMarketInstance.address);
        await mergeInstance.addController(MergerInstance.address);

        await rareRelicsInstance.setNFRAddress(NFRInstance.address);
        await rareRelicsInstance.setBlackMarketAddress(BlackMarketInstance.address);

        await NFRInstance.setBlackMarketAddress(BlackMarketInstance.address);
        await NFRInstance.setMergerAddress(MergerInstance.address);
    });

    it("mint spells", async () => {
        // const roots = await NFRInstance.mintPack.call(42, 43, 44);
        // console.log(roots.map(root => root.toString('hex')));
        for (let account = 0; account < 1; account++) {
            for (let i = 0; i < 1; i++) {
                await NFRInstance.mintPack([47, 49, 44, 45], { from: accounts[account] });
                // console.log((await rareRelicsInstance.balanceOf.call(accounts[0])));
                const spellToken = await rareRelicsInstance.tokenOfOwnerByIndex.call(accounts[account], i);
                const spellReceived = await rareRelicsInstance.spells.call(spellToken);
            }
        }
    });


    let cards = {}
    it("request succesful merge", async () => {
        for (let i = 0; i < 3; i++) {
            const card = await NFRInstance.tokenOfOwnerByIndex.call(accounts[0], i);
            const artifact = await NFRInstance.publicArtifacts.call(card);
            console.log(card.toString('hex'));
            console.log(artifact.num.toString());
            console.log(artifact.copyNum.toString());
            console.log(artifact.longDescriptionHashed.toString());
            console.log(artifact.privateKey.toString());
            cards[artifact.num.toNumber()] = card;
        }
        await MergerInstance.requestMerge(cards[47], cards[49]);

        expect((await MergerInstance.mergeQueueLength.call()).toNumber() === 1);
        const head = await MergerInstance.head.call();
        const mergeInfo = (await MergerInstance.mergeQueue.call(head))
        expect(mergeInfo.tokenId1.eq(cards[47]));
        expect(mergeInfo.tokenId2.eq(cards[49]));
    });

});