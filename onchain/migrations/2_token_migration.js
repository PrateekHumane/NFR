const NFRToken = artifacts.require("NFR")
const MERGEToken = artifacts.require("MERGE")
const RareRelics = artifacts.require("RareRelics")
const BlackMarket = artifacts.require("BlackMarket")
const NFRTypes = artifacts.require("NFRTypes")
const MergeZKP = artifacts.require("MergeZKP")
const Merger = artifacts.require("Merger")

module.exports = function (deployer){
    deployer.then(async () => {
        await deployer.deploy(NFRTypes)
        await deployer.link(NFRTypes, [RareRelics, BlackMarket])
        await deployer.deploy(MERGEToken)
        await deployer.deploy(MergeZKP)
        await deployer.deploy(RareRelics, MERGEToken.address)
        await deployer.deploy(NFRToken, MERGEToken.address, RareRelics.address)
        await deployer.deploy(Merger, NFRToken.address, MERGEToken.address, MergeZKP.address)
        await deployer.deploy(BlackMarket, NFRToken.address, MERGEToken.address, RareRelics.address)
    });

};