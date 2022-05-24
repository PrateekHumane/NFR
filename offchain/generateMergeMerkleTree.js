const merges = require('./merges.json');
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
const SHA256 = require('crypto-js/sha256');
const CryptoJS = require('crypto-js');
const { ethers } = require("ethers");

function splitInto8(buff){
    const buffHex = buff;
    const buffSplit = [buffHex.slice(0,8),buffHex.slice(8,16), buffHex.slice(16,24),buffHex.slice(24,32), buffHex.slice(32,40),buffHex.slice(40,48), buffHex.slice(48,56),buffHex.slice(56,64) ];
    return buffSplit.map(buffS => '0x'.concat(buffS));
}

const leaves = merges.map(merge => SHA256(CryptoJS.enc.Hex.parse(merge)));
const merkleTree = new MerkleTree(leaves, SHA256, { sortPairs: true, fillDefaultHash:'9a8dcd3f9ff7aa3114e141f03c12989d363ea81fd74c02eea63c5f41489cb17a'});
console.log(merkleTree._toTreeString())
// leaves.forEach((leaf)=>{console.log(leaf.toString())})
console.log(splitInto8(merkleTree.getRoot().toString('hex')));

console.log(merges.length);

const merge1 = Buffer.from('0000002F000000310000002F0000003100000026','hex');
// const merge1 = Buffer.from("0000000100000002000000010000000200000033",'hex');
console.log(merge1.toString('hex'))
const mergeLeaf = SHA256(CryptoJS.enc.Hex.parse(merge1.toString('hex'))).toString();
console.log(mergeLeaf);

const proof = merkleTree.getHexProof(mergeLeaf);
console.log(proof);
console.log(merkleTree.verify(proof, mergeLeaf, merkleTree.getRoot().toString('hex')));

console.log(proof)
console.log(proof.map(p=>splitInto8(p.slice(2))));


let proofHash = Buffer.from(mergeLeaf,'hex');
console.log(proofHash.toString('hex'));
for (const node of proof) {
    const buffers = [];
    if (Buffer.compare(proofHash, Buffer.from(node.slice(2),'hex')) == -1) {
        buffers.push(proofHash, Buffer.from(node.slice(2),'hex'));
    }
    else {
        buffers.push(Buffer.from(node.slice(2),'hex'), proofHash);
    }
    proofHash = merkleTree.hashFn(Buffer.concat(buffers));
    console.log(proofHash.toString('hex'));
}

console.log(proofHash);

// console.log(mergeLeaf.toString('hex'));
// console.log(CryptoJS.enc.Hex.parse(mergeLeaf.toString('hex')).toString())
// console.log(splitInto8(SHA256(CryptoJS.enc.Hex.parse(mergeLeaf.toString('hex'))).toString()));

// console.log(Buffer.from('002').toString('hex'))
// console.log(Buffer.from('999').toString('hex'))
// console.log(CryptoJS.enc.Hex.parse(Buffer.from('card #000').toString('hex')).toString())
// console.log(Buffer.from('card #000').toString('hex'))
// console.log(SHA256(CryptoJS.enc.Hex.parse(Buffer.from('card #003').toString('hex'))).toString())