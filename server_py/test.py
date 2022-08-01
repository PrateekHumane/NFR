import json
from web3 import Web3, HTTPProvider
import time

# truffle development blockchain address
blockchain_address = 'http://127.0.0.1:9545'
# Client instance to interact with the blockchain
web3 = Web3(HTTPProvider(blockchain_address))
# Set the default account (so we don't need to set the "from" for every transaction call)
web3.eth.defaultAccount = web3.eth.accounts[0]

# Path to the compiled contract JSON file
compiled_contract_path = '../onchain/build/contracts/Merger.json'
# Deployed contract address (see `migrate` command output: `contract address`)
deployed_contract_address = '0x3c06fE3bE1da0C85Ff290521110151E55A2D5693'

with open(compiled_contract_path) as file:
    contract_json = json.load(file)  # load contract info as JSON
    contract_abi = contract_json['abi']  # fetch contract's abi - necessary to call its functions

# Fetch deployed contract reference
contract = web3.eth.contract(address=deployed_contract_address, abi=contract_abi)

# Call contract function (this is not persisted to the blockchain)
event_filter = contract.events.AddMerge.createFilter(fromBlock='latest')

while True:
    for event in event_filter.get_new_entries():
        print(event)
        print(contract.functions.mergeQueueLength().call())
        time.sleep(2)
