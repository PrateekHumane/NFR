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
        for (let account = 0; account < 1; account++) {
            for (let i = 0; i < 1; i++) {
                await NFRInstance.mintPack(47, 49, 44, 45, { from: accounts[account] });
                // console.log((await rareRelicsInstance.balanceOf.call(accounts[0])));
                const spellToken = await rareRelicsInstance.tokenOfOwnerByIndex.call(accounts[account], i);
                const spellReceived = await rareRelicsInstance.spells.call(spellToken);
                console.log(spellReceived.spellType.toString());
                console.log(spellReceived.numCardsAffected.toString());
                console.log(spellReceived.rankAffected.toString());
            }
        }

        for (let i = 0; i < 3; i++) {
            const card = await NFRInstance.tokenOfOwnerByIndex.call(accounts[0], i);
            const artifact = await NFRInstance.publicArtifacts.call(card);
            console.log(artifact.toString());
        }
    });


    xit("succesful merge", async () => {
        await NFRInstance.requestMerge()
    });

});