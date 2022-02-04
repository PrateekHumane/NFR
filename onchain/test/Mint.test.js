const {accounts, contract} = require('@openzeppelin/test-environment');

const cards = require('./sampleCards.json');
const { MerkleTree } = require('merkletreejs');
const {expect} = require('chai');
const { ethers } = require("ethers");

const NFRContract = contract.fromArtifact('NFR'); // Loads a compiled contract

function hashCard(key, value) {
    return Buffer.from(ethers.utils.solidityKeccak256(
        ['string', 'string'],
        [key, value],
    ).slice(2), 'hex');
}

describe('NFR', function () {
    const [owner] = accounts;

    beforeEach(async function(){
        this.contract = await NFRContract.new({ from: owner });
    });

    before(async function() {
        this.merkleTree = new MerkleTree(Object.entries(cards).map(attribute => hashCard(...attribute)), sha256, { sortPairs: true });
    });

    it('minting', async function () {
        expect((await this.contract.cardsRedeemed()).toString()).to.equal('0');
        await this.contract.mint();
        expect((await this.contract.cardsRedeemed()).toString()).to.equal('1');
    });

    // it('verify attributes', async function () {
    //     await this.contract.mint();
    //     const cardId = 0;
    //
    //     const leaf = hashCard("card #", "001");
    //     const proof = this.merkleTree.getHexProof(leaf);
    //     expect((await this.contract.verify(cardId,leaf,proof))).to.equal(true);
    //
    //     const leafFake = hashCard("card #", "002");
    //     const proofFake = this.merkleTree.getHexProof(leaf);
    //     expect((await this.contract.verify(cardId,leafFake,proofFake))).to.equal(false);
    // });
});