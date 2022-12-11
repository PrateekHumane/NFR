from web3 import Web3, HTTPProvider
import time
import threading
import json

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

# Use a service account (we can remove this depending on where this script runs)
# cred = credentials.Certificate('gcp_private_key.json')
firebase_admin.initialize_app()

db = firestore.client()

# truffle development blockchain address
blockchain_address = 'http://127.0.0.1:9545'
# Client instance to interact with the blockchain
web3 = Web3(HTTPProvider(blockchain_address))
# Set the default account (so we don't need to set the "from" for every transaction call)
web3.eth.defaultAccount = web3.eth.accounts[0]

# Deployed contract address (see `migrate` command output: `contract address`)
merger_address = '0x3c06fE3bE1da0C85Ff290521110151E55A2D5693'
with open('../onchain/build/contracts/Merger.json') as file:
    contract_json = json.load(file)  # load contract info as JSON
    contract_abi = contract_json['abi']  # fetch contract's abi - necessary to call its functions

merger_contract = web3.eth.contract(address=merger_address, abi=contract_abi)

# Create a callback on_snapshot function to capture changes
def on_proof(doc_snapshot, changes, read_time):
    for doc in doc_snapshot:
        print(f'Received proof: {doc.to_dict()}')
        merge = doc.to_dict()
        if "proof" in merge:
            print(merge)
            proof = json.loads(merge['proof'])
            print('got proof',proof)
            processingInput = json.loads(merge['processingInput'])
            print('processing input', processingInput)
            merger_contract.functions.processMerge(proof['proof'], *processingInput).send()
            got_proof.set()

while True:
    merges_ref = db.collection("merges")
    merge_head_ref = merges_ref.order_by("date").limit(1)
    merge_head = merge_head_ref.get()
    if len(merge_head) > 0:
        print(merge_head[0].id)
        got_proof = threading.Event()
        doc_watch = db.collection("merges").document(merge_head[0].id).on_snapshot(on_proof)
        got_proof.wait()
        doc_watch.unsubscribe()

    time.sleep(0.1)