import json
from itertools import combinations
cards = range(1,49)

mergeLeaves = []
for card_combo in (list(combinations(cards, 2))):
    mergeLeaf = '%08d%08d' % card_combo
    mergeLeaf += mergeLeaf
    mergeLeaf += ('F'*8*4)
    mergeLeaves.append(mergeLeaf)

with open('merges.json', 'w') as outfile:
    json.dump(mergeLeaves, outfile)

# print(mergeLeaves)
# print(len(mergeLeaves))
