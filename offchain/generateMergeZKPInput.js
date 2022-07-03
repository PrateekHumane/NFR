const { ethers } = require("ethers");

const keccak256 = ethers.utils.solidityKeccak256;

const token1 = {num: 47, copyNum: 1, longDescriptionHashed: 0, privateKey: 0};
const token2 = {num: 49, copyNum: 1, longDescriptionHashed: 0, privateKey: 0};
const input_cards = [token1, token2];

const pre_image = new Array(64).fill(0);
const secret_key = 0;

function hashArtifact(artifact){
    // let numBuf = Buffer.alloc(1); // uint8
    // numBuf.writeUInt8(artifact.num);
    // console.log(numBuf.toString('hex'));
    const numHash = keccak256([ "uint8"], [ artifact.num ]);
    const copyNumHash = keccak256([ "uint16"], [ artifact.copyNum ]);
    const longDescriptionHashedHash = keccak256([ "uint256"], [ artifact.longDescriptionHashed ]);
    const privateKeyHash = keccak256([ "uint256"], [ artifact.privateKey ]);
    const hash1 = (keccak256([ "uint256", "uint256"], [ numHash, copyNumHash ]));
    const hash2 = (keccak256([ "uint256", "uint256"], [ longDescriptionHashedHash, privateKeyHash ]));
    return keccak256([ "uint256", "uint256"], [hash1,hash2]);
}

function getArtifactPath(artifact){
    const copyNumHash = keccak256([ "uint16"], [ artifact.copyNum ]);
    const longDescriptionHashedHash = keccak256([ "uint256"], [ artifact.longDescriptionHashed ]);
    const privateKeyHash = keccak256([ "uint256"], [ artifact.privateKey ]);
    const hash2 = (keccak256([ "uint256", "uint256"], [ longDescriptionHashedHash, privateKeyHash ]));
    return [copyNumHash, hash2];
}

const toU32 = (num) => ethers.utils.solidityPack(["uint32"],[num]);

const U256toU64 = (hex) => {
    hex = hex.slice(2);
    const buffSplit = [hex.slice(0,16), hex.slice(16,32), hex.slice(32,48), hex.slice(48,64)];
    return buffSplit.map(slice=>'0x'+slice);
};

const input_cards_IDs = input_cards.map(artifact => toU32(artifact.num));
const input_cards_path = input_cards.map(artifact => getArtifactPath(artifact).map(hash => U256toU64(hash)));
const input_cards_roots = input_cards.map(artifact => U256toU64(hashArtifact(artifact)));

console.log(input_cards_IDs);
console.log(input_cards_path);
console.log(input_cards_roots);
