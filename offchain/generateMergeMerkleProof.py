import pickle



def get_merge_merkle_proof(card1, card2):
    def get_index(x, y):
        # return 50 * (x - 1) - (x - 1) / 2 * (x - 1 + 1) + y - 1 - x
        return -51 - (x-99)*x/2 + y

    merge_index = int(get_index(card1, card2))

    curr = merge_index + 1
    baseline = 2048
    direction = []
    while baseline > 1:
        if curr <= baseline / 2:
            direction.append('l')
        else:
            curr -= baseline / 2
            direction.append('r')

        baseline /= 2

    with open('merge_tree.pkl', 'rb') as inp:
        mt = pickle.load(inp)


    # print(mt.get_leaf_count())
    # print(mt.get_leaf(merge_index))
    # print(mt.get_proof(merge_index))
    # print(mt.get_merkle_root())
    # test = mt.validate_proof(mt.get_proof(1), mt.get_leaf(1), mt.get_merkle_root())
    # print(mt.get_leaf(merge_index))

    def split_into_bits(hex_str, bits=32):
        chunks = int(bits / 4)
        return ['0x' + hex_str[i:i + chunks] for i in range(0, len(hex_str), chunks)]


    # remove the dictionary in proof:
    proof = mt.get_proof(merge_index)
    merge_proof = []
    for hash_dict in proof:
        hash = list(hash_dict.values())[0]
        merge_proof.append(split_into_bits(hash))

    # print(merge_proof)

    result_cards_IDs = split_into_bits(mt.get_leaf(merge_index))[2:5]
    # print(result_cards_IDs)
    return merge_proof, result_cards_IDs

# print(get_merge_merkle_proof(47,49))