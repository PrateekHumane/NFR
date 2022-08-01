import json
from web3 import Web3, HTTPProvider
import time
import datetime

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

# Use a service account
cred = credentials.Certificate('gcp_private_key.json')
firebase_admin.initialize_app(cred)

db = firestore.client()

from generateMergeZKPInput import *


# truffle development blockchain address
blockchain_address = 'http://127.0.0.1:9545'
# Client instance to interact with the blockchain
web3 = Web3(HTTPProvider(blockchain_address))
# Set the default account (so we don't need to set the "from" for every transaction call)
web3.eth.defaultAccount = web3.eth.accounts[0]

# Path to the compiled contract JSON file
contract_names = ['Merger']
compiled_contracts_paths = [f'../onchain/build/contracts/{contract_name}.json' for contract_name in contract_names]
# Deployed contract address (see `migrate` command output: `contract address`)
deployed_contracts_address = ['0x3c06fE3bE1da0C85Ff290521110151E55A2D5693']
contracts = {}

for contract_name, compiled_contract_path, deployed_contract_address in zip(contract_names, compiled_contracts_paths, deployed_contracts_address):
    with open(compiled_contract_path) as file:
        contract_json = json.load(file)  # load contract info as JSON
        contract_abi = contract_json['abi']  # fetch contract's abi - necessary to call its functions

    # Fetch deployed contract reference
    contracts[contract_name] = (web3.eth.contract(address=deployed_contract_address, abi=contract_abi))

# Call contract function (this is not persisted to the blockchain)
event_filter = contracts['Merger'].events.AddMerge.createFilter(fromBlock='latest')

def toHexString(num):
    return hex(num)[2:]

while True:
    for event in event_filter.get_new_entries():
        print(event)
        tokenId1 = event.args.tokenId1
        tokenId2 = event.args.tokenId2
        mergeId = event.args.mergeId
        token1 = db.collection('tokens').document(toHexString(tokenId1)).get().to_dict()
        token2 = db.collection('tokens').document(toHexString(tokenId2)).get().to_dict()
        print(token1,token2)
        merges_ref = db.collection("merges")
        merge_rear = merges_ref.order_by("date").limit_to_last(1).get()
        if len(merge_rear) > 0:
            current_card_count = merge_rear[0].to_dict()['card_count']
        else:
           current_game_state = db.collection('game_states').document('current').get().to_dict()
           current_card_count = current_game_state['cardCounts']

        mergeData = getMergeInput(token1,token2,current_card_count)
        mergeData['date'] = datetime.datetime.now(tz=datetime.timezone.utc)
        new_merge = merges_ref.document(toHexString(mergeId))
        print(mergeData)
        new_merge.set(mergeData)

    time.sleep(1)
