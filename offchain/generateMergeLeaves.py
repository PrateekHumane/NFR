import json
import ast
import codecs
import os
from itertools import combinations

cards = range(1,51)

with open('merges_raw.txt', 'r') as f:
    dict_text = f.read()
    merges_raw = ast.literal_eval(dict_text)

mergeLeaves = []
for card_combo in (list(combinations(cards, 2))):
    mergeLeaf = '%0.8X%0.8X' % card_combo
    # mergeLeaf += mergeLeaf
    # mergeLeaf += '%0.8X' % 51
    mergeLeaf += '%0.8X%0.8X%0.8X' % merges_raw.get(card_combo, (*card_combo,51))
    mergeLeaf += ('0'*8*3)
    # mergeLeaf += ('0'*8*8)
    mergeLeaves.append(mergeLeaf)

while len(mergeLeaves) != 2048:
    mergeLeaves.append(codecs.encode(os.urandom(32), 'hex').decode())

with open('merges.json', 'w') as outfile:
    json.dump(mergeLeaves, outfile)

# print(mergeLeaves)
print(len(mergeLeaves))


