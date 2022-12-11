const MERGE = artifacts.require("MERGE");
const RareRelics = artifacts.require("RareRelics");
const BlackMarket = artifacts.require("BlackMarket");
const NFR = artifacts.require("NFR");
const Merger = artifacts.require("Merger");
//
// const timeMachine = require('ganache-time-traveler');

const proof = require('./proof.json')

module.exports = async (callback) => {
    try {
        const accounts = await web3.eth.getAccounts()

        const mergeInstance = await MERGE.deployed();
        const rareRelicsInstance = await RareRelics.deployed();
        const NFRInstance = await NFR.deployed();
        const BlackMarketInstance = await BlackMarket.deployed();
        const MergerInstance = await Merger.deployed();

        // add merge controllers
        await mergeInstance.addController(NFRInstance.address);
        await mergeInstance.addController(rareRelicsInstance.address);
        await mergeInstance.addController(BlackMarketInstance.address);
        await mergeInstance.addController(MergerInstance.address);

        await rareRelicsInstance.setNFRAddress(NFRInstance.address);
        await rareRelicsInstance.setBlackMarketAddress(BlackMarketInstance.address);

        await NFRInstance.setBlackMarketAddress(BlackMarketInstance.address);
        await NFRInstance.setMergerAddress(MergerInstance.address);

        for (let account = 0; account < 1; account++) {
            for (let i = 0; i < 1; i++) {
                await NFRInstance.mintPack([47, 49, 44, 45], { from: accounts[account] });
                // console.log((await rareRelicsInstance.balanceOf.call(accounts[0])));
                const spellToken = await rareRelicsInstance.tokenOfOwnerByIndex.call(accounts[account], i);
                const spellReceived = await rareRelicsInstance.spells.call(spellToken);
            }
        }

        let cards = {}
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

        // expect((await MergerInstance.mergeQueueLength.call()).toNumber() === 1);
        // const head = await MergerInstance.head.call();
        // const mergeInfo = (await MergerInstance.mergeQueue.call(head))
        // expect(mergeInfo.tokenId1.eq(cards[47]));
        // expect(mergeInfo.tokenId2.eq(cards[49]));

        // await MergerInstance.processMerge(proof.proof, ["0xbba21a05f4f84324172726d59bb487c7e37bdf6609ea96fbb64c9ea231a2460b", "0xcb3b201542638f328dfbf792fa0e5332a152ab1d45ccce5daaecbc56eb7dcf9a", "0x800f944c671ef1b7cbb12437af4020a4fceb12f1370b1afd6d8356e72ba11f70"], [1,1,1], "0xac7e09d57e2f64aa0164f94b90bdb973edc2a5fe16334c043aba13eeca9e0b27");
        // const accountCards = (await NFRInstance.balanceOf.call(accounts[0])).toNumber();
        // console.log(accountCards);
    }
    catch (e) {
       console.log(e);
    }
    callback();
}