const merges = require('./sampleMerges.json');
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
const SHA256 = require('crypto-js/sha256')
const CryptoJS = require('crypto-js')
const { ethers } = require("ethers");

function splitInto8(buff){
    const buffHex = buff;
    const buffSplit = [buffHex.slice(0,8),buffHex.slice(8,16), buffHex.slice(16,24),buffHex.slice(24,32), buffHex.slice(32,40),buffHex.slice(40,48), buffHex.slice(48,56),buffHex.slice(56,64) ];
    return buffSplit.map(buffS => '0x'.concat(buffS));
}

function hashCard(mergeCombo) {

    const hashes = mergeCombo.map(cardID => SHA256(cardID).toString());

    console.log(hashes);
    // console.log(hashes.map(hash=>splitInto8(hash).join(',')));

    const hashesParsed = CryptoJS.enc.Hex.parse(hashes.join(''));
    return SHA256(hashesParsed);
}

// const leaves = merges.map(merge => hashCard(merge));
// console.log(leaves);

// const merkleTree = new MerkleTree(leaves, SHA256, { sortPairs: true });

// console.log(merkleTree.getRoot());

const mergeLeaf = Buffer.from('0000000100000002000000010000000200000003FFFFFFFFFFFFFFFFFFFFFFFF','hex');
console.log(mergeLeaf.toString('hex'));
console.log(CryptoJS.enc.Hex.parse(mergeLeaf.toString('hex')).toString())
console.log(SHA256(CryptoJS.enc.Hex.parse(mergeLeaf.toString('hex'))).toString());
console.log(splitInto8(SHA256(CryptoJS.enc.Hex.parse(mergeLeaf.toString('hex'))).toString()));

// console.log(Buffer.from('002').toString('hex'))
// console.log(Buffer.from('999').toString('hex'))
// console.log(CryptoJS.enc.Hex.parse(Buffer.from('card #000').toString('hex')).toString())
// console.log(Buffer.from('card #000').toString('hex'))
// console.log(SHA256(CryptoJS.enc.Hex.parse(Buffer.from('card #003').toString('hex'))).toString())