const NFRToken = artifacts.require("NFR")

module.exports = function (deployer){
    deployer.deploy(NFRToken)
};