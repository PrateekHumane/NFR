import json
from web3 import Web3, HTTPProvider
import time

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

# Use the application default credentials
# cred = credentials.ApplicationDefault()
# firebase_admin.initialize_app(cred, {
#   'projectId': 'NFRIslands',
# })

# Use a service account (we can remove this depending on where this script runs)
cred = credentials.Certificate('gcp_private_key.json')
firebase_admin.initialize_app(cred)

db = firestore.client()



# truffle development blockchain address
blockchain_address = 'http://127.0.0.1:9545'
# Client instance to interact with the blockchain
web3 = Web3(HTTPProvider(blockchain_address))
# Set the default account (so we don't need to set the "from" for every transaction call)
web3.eth.defaultAccount = web3.eth.accounts[0]

# Path to the compiled contract JSON file
contract_names = ['NFR']
compiled_contracts_paths = [f'../onchain/build/contracts/{contract_name}.json' for contract_name in contract_names]
# Deployed contract address (see `migrate` command output: `contract address`)
deployed_contracts_address = ['0xB11e0a3334c994b60e4dEfCEf944cc3997Cc2ba4']
contracts = {}

for contract_name, compiled_contract_path, deployed_contract_address in zip(contract_names, compiled_contracts_paths, deployed_contracts_address):
    with open(compiled_contract_path) as file:
        contract_json = json.load(file)  # load contract info as JSON
        contract_abi = contract_json['abi']  # fetch contract's abi - necessary to call its functions

    # Fetch deployed contract reference
    contracts[contract_name] = (web3.eth.contract(address=deployed_contract_address, abi=contract_abi))

# Call contract function (this is not persisted to the blockchain)
event_filter = contracts['NFR'].events.PackMinted.createFilter(fromBlock='latest')

def toHexString(num):
    return hex(num)[2:]

while True:
    for event in event_filter.get_new_entries():
        print(event)
        for token in event.args.tokens:
            print(type(token))
            num, copyNum, longDescription, privateKey = contracts['NFR'].functions.publicArtifacts(token).call()
            owner = contracts['NFR'].functions.ownerOf(token).call()
            doc_ref = db.collection('tokens').document(toHexString(token))
            doc_ref.set({
                'num' : int(toHexString(num),16),
                'copyNum' : int(toHexString(copyNum),16),
                'longDescription' : '%0.64X' % longDescription,
                'privateKey' : '%0.64X' % privateKey,
                'owner' : owner[2:]
            })
    time.sleep(1)
