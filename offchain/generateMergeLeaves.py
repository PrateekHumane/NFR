import json
from itertools import combinations
cards = range(1,50)

mergeLeaves = []
for card_combo in (list(combinations(cards, 2))):
    mergeLeaf = '%0.8X%0.8X' % card_combo
    mergeLeaf += mergeLeaf
    mergeLeaf += '%0.8X' % 51
    mergeLeaf += ('F'*8*3)
    mergeLeaves.append(mergeLeaf)

with open('merges.json', 'w') as outfile:
    json.dump(mergeLeaves, outfile)

# print(mergeLeaves)
# print(len(mergeLeaves))
