const cards = require('./sampleCards.json');
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
const SHA256 = require('crypto-js/sha256')
const CryptoJS = require('crypto-js')
const { ethers } = require("ethers");

function hashCard(key, value) {
    return SHA256(key.concat(value));
}

function splitInto4(buff){
   const buffHex = buff.toString('hex');
   const buffSplit = [buffHex.slice(0,16), buffHex.slice(16,32), buffHex.slice(32,48), buffHex.slice(48,64)];
   return buffSplit;
}

function splitInto8(buff){
    // console.log(buff.toString('hex'));
    const buffHex = buff.toString('hex');
    // console.log(buffHex);
    const buffSplit = [buffHex.slice(0,8),buffHex.slice(8,16), buffHex.slice(16,24),buffHex.slice(24,32), buffHex.slice(32,40),buffHex.slice(40,48), buffHex.slice(48,56),buffHex.slice(56,64) ];
    return buffSplit;
}

const cardTrees = cards.map( card => {
    console.log(card);
    const leaves = Object.entries(card).map(attribute => hashCard(...attribute));

    const merkleTree = new MerkleTree(leaves, SHA256, { sortPairs: true });

    const leaf = hashCard("card #", card["card #"]);

    const proof = merkleTree.getHexProof(leaf);
    console.log(proof.map(p=>splitInto8(Buffer.from(p.slice(2),'hex'))));

    let proofHash = Buffer.from(leaf.toString(),'hex');
    // console.log('leaf', leaf.toString());
    // console.log('leaf', proofHash);

    merkleTree.verify(proof,leaf,merkleTree.getRoot());
    for (const node of proof) {
        const buffers = [];
        if (Buffer.compare(proofHash, Buffer.from(node.slice(2),'hex')) == -1) {
            // console.log('== -1');
            buffers.push(proofHash, Buffer.from(node.slice(2),'hex'));
        }
        else {
            // console.log('not == -1');
            buffers.push(Buffer.from(node.slice(2),'hex'), proofHash);
        }
        // console.log(buffers);
        proofHash = merkleTree.hashFn(Buffer.concat(buffers));
        // console.log(proofHash);
    }
    // merkleTree.verify(proof,leaf,merkleTree.getRoot());
    // console.log('root',splitInto8( merkleTree.getRoot()));
    console.log("root",merkleTree.getRoot().toString('hex') );
    console.log("[");
    splitInto8( merkleTree.getRoot()).forEach(u32 => console.log(`"0x${u32}",`))
    console.log("],");

    console.log("leaf");
    console.log("[");
    splitInto8(Buffer.from(leaf.toString(),'hex')).forEach(u32 => console.log(`"0x${u32}",`));
    console.log("]");

    return merkleTree;
});

// console.log(cardTrees);

//leaf: ["0x5dece88b9d09e10b","0xa9855456b1b9c9b4","0x6f6b39b7a297a71c","0x33860d00729c1ab0"]
// root: ["0x7883d8f7c47f48e3","0x3b794370e46f51c9","0xa786e844c0e294c8","0xc5cc418d4f07a8b5"]
//
// proof1:["0x19df6d308f0cad41","0x5ab56a0052d3a173","0x24163660a88eb830","0xca0cc39ff10eb804"]
// proof2:["0xd618a119e08664dd","0x01fc35cd1541a186","0x6f500a837f11e0f3","0x40a55ad851402972"]
// proof3:["0x8e4642871e5ccb51","0x6aaf15516379acf2","0x0043c6ed34342428","0x0bc5d4205bd41eb5"]