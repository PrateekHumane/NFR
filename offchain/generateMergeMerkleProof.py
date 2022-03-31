import pickle

def get_index(x,y):
    return 51*(x-1)-(x-1)/2*(x-1+1)+y-1-x

card1 = 2
card2 = 3

merge_index = int(get_index(card1,card2))

curr = merge_index + 1
baseline = 2048
direction = []
while baseline > 1:
    if curr <= baseline /2:
        direction.append('l')
    else:
        curr -= baseline / 2
        direction.append('r')

    baseline /= 2


with open('merge_tree.pkl', 'rb') as inp:
    mt = pickle.load(inp)
    print(mt.get_leaf_count())
    print(mt.get_leaf(merge_index))
    print(mt.get_proof(merge_index))
    print(mt.get_merkle_root())
    test = mt.validate_proof(mt.get_proof(1), mt.get_leaf(1), mt.get_merkle_root())
    print(test)
