const artifacts = require('./artifacts.json');
const { MerkleTree } = require('merkletreejs');
const CryptoJS = require('crypto-js')
const SHA256 = require('crypto-js/sha256')
var sha256 = require('js-sha256');

function splitInto8(hex){
    hex = hex.replace('0x','');
    const hexSplit= [hex.slice(0,8),hex.slice(8,16), hex.slice(16,24),hex.slice(24,32), hex.slice(32,40),hex.slice(40,48), hex.slice(48,56),hex.slice(56,64) ];
    return hexSplit;
}

const abi_format = (hex) => splitInto8(hex).map((hexSplit)=>'0x'+hexSplit.replace('0x',''));

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
    const proof = merkleTree.getHexProof(cardNumHashed);
    console.log("proof", proof.map(hex=>abi_format(hex)));
    console.log("root",abi_format(merkleTree.getRoot().toString('hex') ));
});