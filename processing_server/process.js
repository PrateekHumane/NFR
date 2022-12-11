var Web3 = require('web3');
var web3 = new Web3('HTTP://127.0.0.1:9545')

const mergerJson = require('../onchain/build/contracts/Merger.json')
const mergerAddress = '0x3c06fE3bE1da0C85Ff290521110151E55A2D5693'

var contract = new web3.eth.Contract(mergerJson.abi, mergerAddress, {from:'0x36142565d207c744a796f9e827ad8977e8988c79', gasPrice: '20000000000'});

const EventEmitter = require('events');
const gotProof = new EventEmitter();

const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp({
  credential: applicationDefault()
});

const db = getFirestore();

const merges_ref = db.collection("merges");
// web3.eth.getBalance('0x36142565d207c744a796f9e827ad8977e8988c79').then(
//     result=> console.log(result)
// )

// const proofLocal = require('./proof.json')

const onProof = async docSnapshot => {
    merge = docSnapshot.data()
    if ('proof' in merge) {
        // console.log(merge);
        const proof = JSON.parse(merge['proof'])
        // console.log('got proof', proof)
        const processingInput = JSON.parse(merge['processingInput'])
        // console.log('processing input', processingInput)
        contract.methods.processMerge(proof.proof, ...processingInput)
            .send({from: '0x36142565d207c744a796f9e827ad8977e8988c79', gas:3000000})
        
        // Get a new write batch
        const batch = db.batch();
        for (let resultCardId in merge['resultCards']){
            let cardRef = db.collection('tokens').doc(resultCardId);
            batch.set(cardRef, merge['resultCards'][resultCardId]);
        }

        const gameStateRef = db.collection('game_states').doc('current')
        batch.update(gameStateRef, { cardCounts: merge.cardCounts, secretKey: merge.secretKey });

        const mergeRef = db.collection('merges').doc(docSnapshot.id)
        // batch.delete(mergeRef)

        await batch.commit()

        // await merges_ref.doc(docSnapshot.id).delete();
        // gotProof.emit('unlocked')
    }
}

// contract.methods.processMerge(proof.proof, ["0xbba21a05f4f84324172726d59bb487c7e37bdf6609ea96fbb64c9ea231a2460b", "0xcb3b201542638f328dfbf792fa0e5332a152ab1d45ccce5daaecbc56eb7dcf9a", "0x800f944c671ef1b7cbb12437af4020a4fceb12f1370b1afd6d8356e72ba11f70"], [1,1,1], "0xac7e09d57e2f64aa0164f94b90bdb973edc2a5fe16334c043aba13eeca9e0b27")
//     .send({from: '0x36142565d207c744a796f9e827ad8977e8988c79', gas:3000000})
//     .then(function(receipt){
//         console.log(receipt);
//         // receipt can also be a new contract instance, when coming from a "contract.deploy({...}).send()"
//     })
//     .catch(function (error) {
//         console.log(error);
//     });


(async () => {
    while (true) {
        let merge_head = await merges_ref.orderBy("date").limit(1).get()
        console.log(merge_head.size)
        if (merge_head.size > 0) {
            console.log(merge_head.docs[0].id)
            const unsubscribe = merges_ref.doc(merge_head.docs[0].id).onSnapshot(onProof)
            await new Promise(resolve => gotProof.once('unlocked', resolve))
            unsubscribe()
        }
    }
})();