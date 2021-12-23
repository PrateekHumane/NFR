const {accounts, contract} = require('@openzeppelin/test-environment');

const {expect} = require('chai');

const proofJSON = require('./proof.json');

const VerifierContract = contract.fromArtifact('Verifier'); // Loads a compiled contract

describe('Verifier', function () {
    const [owner] = accounts;

    beforeEach(async function(){
        this.contract = await VerifierContract.new({ from: owner });
    });

    it('verify proof', async function () {
        expect((await this.contract.verifyTx(proofJSON.proof,proofJSON.inputs))).to.equal(true);
    });
});