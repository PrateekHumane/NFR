const num_cards = 48
console.log(Math.floor(Math.random()*2^((64-num_cards)*16)-1).toString(16))
console.log((64-num_cards)*16/4)
let hash = ''

for(let i = 0; i < (num_cards)*16/4; i++)
    hash += '0'

for(let i = 0; i < (64-num_cards)*16/4; i++)
    hash += Math.floor(Math.random()*16).toString(16)

console.log(hash)

console.log(hash)
console.log(hash.length)

for (let i = 0; i < 256; i+=8){
   console.log(`"0x${hash.substr(i,8)}",`);
}