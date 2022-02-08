const artifacts = require('./artifacts.json');
const { MerkleTree } = require('merkletreejs');
const CryptoJS = require('crypto-js')
const SHA256 = require('crypto-js/sha256')
var sha256 = require('js-sha256');

const artifcatTrees = artifacts.map( artifact => {
    console.log(artifact);

    let cardNumBuf = Buffer.alloc(1); // uint8
    cardNumBuf.writeUInt8(artifact.cardNum);
    const cardNumHashed = SHA256(CryptoJS.enc.Hex.parse(cardNumBuf.toString('hex')));

    let copyNumBuf = Buffer.alloc(2); // uint16
    copyNumBuf.writeUInt16BE(1);
    const copyNumHashed = SHA256(CryptoJS.enc.Hex.parse(copyNumBuf.toString('hex')));

    const privateKeyHashed = SHA256(CryptoJS.enc.Hex.parse('0'.repeat(64)));

    leaves = [cardNumHashed, copyNumHashed, SHA256(artifact.description), privateKeyHashed]
    console.log(leaves.map(leaf => leaf.toString()));

    const merkleTree = new MerkleTree(leaves, SHA256);
    console.log("root",merkleTree.getRoot().toString('hex') );
});