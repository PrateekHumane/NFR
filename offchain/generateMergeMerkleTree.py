from PedersenMerkleTreeTools import PedersenMerkleTree
import json
import pickle

with open('merges.json', 'r') as f:
  merges = json.load(f)

mt = PedersenMerkleTree()

for leaf in merges:
    mt.add_leaf(leaf)

mt.make_tree()

with open('merge_tree.pkl', 'wb') as outp:
    pickle.dump(mt, outp, pickle.HIGHEST_PROTOCOL)

print(mt.get_merkle_root())
print(mt.validate_proof(mt.get_proof(1), mt.get_leaf(1), mt.get_merkle_root()))
# with open('merge_tree.pkl', 'rb') as inp:
#     mt = pickle.load(inp)
#     print(mt.get_leaf_count())

# print(mt.get_proof(0))