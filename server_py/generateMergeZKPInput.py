import eth_utils
from generateMergeMerkleProof import get_merge_merkle_proof
import codecs
import os
import random
from zokrates_pycrypto.gadgets.pedersenHasher import PedersenHasher
import json
import numpy as np

def getMergeInput(token1, token2, card_counts, current_secret_key):
    # ---- CONSTANTS ---- #
    # cards_counts_secret_key = '1acbbaaf2cb480c9359249eade3644ca1f6225a9cf1beb85710e497abf65e3a8'
    long_descriptions_hashed = ['0x0000000000000000000000000000000000000000000000000000000000000000'] * 50
    card_limit_indexes = np.array([41, 26, 19, 10, 5, 0])
    card_limits = [2**32,1551,1111,555,212,101]
    # ------------------- #

    # ---- grab this from the database ---#
    # card_counts = [0] * 41

    # ------------------------------------#

    new_card_counts = card_counts.copy()

    # token1 = {'num': 47, 'copyNum': 1,
    #         'longDescription': '29a6711440fe7a63e9478a2f99eae57b5ba4ec5af8cdca67a922232c71ada9e3',
    #         'privateKey': '0000000000000000000000000000000000000000000000000000000000000000'}
    # token2 = {'num': 49, 'copyNum': 1,
    #         'longDescription': 'f413a42af6f20a53dd943a6835aec02dff9c876f7d7f253670aa07dbaa32b05c',
    #         'privateKey': '0000000000000000000000000000000000000000000000000000000000000000'}
    input_cards = [token1, token2]


    def get_card_root(artifact):
        # num_hash = eth_utils.keccak(hexstr='0x%0.2X' % artifact['num']).hex()
        # copy_num_hash = eth_utils.keccak(hexstr='0x%0.4X' % artifact['copyNum']).hex()
        # long_description_hashed =  eth_utils.keccak(text=artifact['longDescription'])
        hash_1 = eth_utils.keccak(hexstr='0x%0.8X' % artifact['num'] + '%0.8X' % artifact['copyNum']).hex()
        hash_2 = eth_utils.keccak(hexstr=artifact['longDescription'] + artifact['privateKey']).hex()
        return eth_utils.keccak(hexstr=hash_1 + hash_2).hex()


    def get_card_path(artifact):
        # copy_num_hash = eth_utils.keccak(hexstr='0x%0.4X' % artifact['copyNum']).hex()
        # long_description_hashed =  eth_utils.keccak(text=artifact['longDescription'])
        hash_2 = eth_utils.keccak(hexstr=artifact['longDescription'] + artifact['privateKey']).hex()
        return hash_2


    def split_into_bits(hex_str, bits=32):
        chunks = int(bits / 4)
        return ['0x' + hex_str[i:i + chunks] for i in range(0, len(hex_str), chunks)]


    input_cards_IDs = []
    input_cards_copy_counts = []
    input_cards_paths = []
    input_cards_roots = []
    for token in input_cards:
        input_cards_IDs.append('0x%0.8X' % token['num'])
        input_cards_copy_counts.append('0x%0.8X' % token['copyNum'])
        input_cards_roots.append(split_into_bits(get_card_root(token), 64))
        input_cards_paths.append(split_into_bits(get_card_path(token), 64))

    print('input card IDs',input_cards_IDs)
    print('input_cards_copy_counts',input_cards_copy_counts)
    print('input_cards_paths',input_cards_paths)
    print('input_cards_roots',input_cards_roots)

    # TODO: remove input cards from DB and add the new cards back in

    merge_proof, result_cards_IDs_ordered = get_merge_merkle_proof(token1['num'], token2['num'])
    print(merge_proof)

    merge_proof_order = list(range(3))
    random.shuffle(merge_proof_order)
    result_cards_IDs = [0, 0, 0]
    for i, order in enumerate(merge_proof_order):
        result_cards_IDs[order] = result_cards_IDs_ordered[i]
    merge_proof_order = list(map(lambda x:'0x%0.8X'%x,merge_proof_order))

    print(result_cards_IDs)

    # construct result cards (structs)
    result_cards_roots = []
    result_cards_paths = []
    result_cards = {}
    result_cards_mint = []
    result_cards_root_raw = []

    for result_card in result_cards_IDs:
        card_num = int(result_card, 16)
        mint_card = 0
        if card_num == 51:
            root_raw = '0x0000000000000000000000000000000000000000000000000000000000000000'
            root = ['0x0000000000000000', '0x0000000000000000', '0x0000000000000000', '0x0000000000000000']
            path = ['0x0000000000000000', '0x0000000000000000', '0x0000000000000000', '0x0000000000000000']
        else:
            card_count = None
            if card_num == token1['num']:
                card_count = token1['copyNum']
            elif card_num == token2['num']:
                card_count = token2['copyNum']
            else:
                card_count = card_counts[card_num - 1] + 1
                new_card_counts[card_num - 1] += 1
            if card_count > card_limits[np.argmax(card_count > card_limit_indexes)]:
                new_card_counts[card_num - 1] -= 1 # because the input card will never reach card limit anyways
                root_raw = '0x0000000000000000000000000000000000000000000000000000000000000000'
                root = ['0x0000000000000000', '0x0000000000000000', '0x0000000000000000', '0x0000000000000000']
                path = ['0x0000000000000000', '0x0000000000000000', '0x0000000000000000', '0x0000000000000000']
            else:
                mint_card = 1
                card = {
                    # get the result cards ids as raw numbers
                    'num': card_num,
                    'copyNum': card_count,
                    'longDescription': long_descriptions_hashed[card_num - 1],
                    'privateKey': codecs.encode(os.urandom(32), 'hex').decode(),
                    'owner':token1['owner']
                }
                print('result card root', get_card_root(card))
                root_raw = '0x'+get_card_root(card)
                root = split_into_bits(get_card_root(card), 64)
                path = split_into_bits(get_card_path(card), 64)
                result_cards[root_raw] = card

        result_cards_roots.append(root)
        result_cards_paths.append(path)
        result_cards_root_raw.append(root_raw)
        result_cards_mint.append(mint_card)

    print(result_cards_paths)
    print(result_cards_roots)
    print(merge_proof_order)

    cards_minted_preimage_string = ''.join(['%0.4X' % card_counts[i] for i in range(len(card_counts))]) + '0' * (
    (51 - len(card_counts))) * 4
    cards_minted_preimage = split_into_bits(cards_minted_preimage_string,16)

    # cards_minted_secret_key = split_into_bits(cards_counts_secret_key)
    cards_minted_secret_key_int = int(current_secret_key,16)
    cards_minted_secret_key_bin = str(bin(cards_minted_secret_key_int))[2:]
    cards_minted_secret_key = [bool(int(bit)) for bit in '0'*(1024-41*16-len(cards_minted_secret_key_bin))+cards_minted_secret_key_bin]
    print(cards_minted_secret_key)
    new_cards_minted_secret_key_int = random.getrandbits(1024-41*16)
    new_cards_minted_secret_key_bin = str(bin(new_cards_minted_secret_key_int))[2:]
    new_cards_minted_secret_key = [bool(int(bit)) for bit in '0'*(1024-41*16-len(new_cards_minted_secret_key_bin))+new_cards_minted_secret_key_bin]
    print(new_cards_minted_secret_key)

    cards_minted_preimage_full = cards_minted_preimage_string[:(41*4)] + '%0.92X' % cards_minted_secret_key_int

    preimage1 = bytes.fromhex(cards_minted_preimage_full[:len(cards_minted_preimage_full) // 2])
    preimage2 = bytes.fromhex(cards_minted_preimage_full[len(cards_minted_preimage_full) // 2:])
    # create an instance with personalisation string
    hasher = PedersenHasher(b"test")
    # hash payload
    hash1 = hasher.hash_bytes(preimage1)
    hash2 = hasher.hash_bytes(preimage2)
    final_hash = bytes.fromhex(hash1.compress().hex() + hash2.compress().hex())
    cards_minted_hashed = hasher.hash_bytes(final_hash).compress().hex()
    print(split_into_bits(cards_minted_hashed))

    new_cards_minted_preimage_string = ''.join(['%0.4X' % new_card_counts[i] for i in range(len(card_counts))]) + '0' * (
    (51 - len(card_counts))) * 4
    cards_minted_preimage_full = new_cards_minted_preimage_string[:(41*4)] + '%0.92X' % new_cards_minted_secret_key_int

    preimage1 = bytes.fromhex(cards_minted_preimage_full[:len(cards_minted_preimage_full) // 2])
    preimage2 = bytes.fromhex(cards_minted_preimage_full[len(cards_minted_preimage_full) // 2:])
    # hash payload
    hash1 = hasher.hash_bytes(preimage1)
    hash2 = hasher.hash_bytes(preimage2)
    final_hash = bytes.fromhex(hash1.compress().hex() + hash2.compress().hex())
    new_cards_minted_hashed = '0x'+ hasher.hash_bytes(final_hash).compress().hex()
    print('new cards minted hashed',new_cards_minted_hashed)

    # with open('generated_merge_input.json', 'w') as f:
    #     json.dump([input_cards_IDs, input_cards_copy_counts, input_cards_paths, merge_proof, result_cards_IDs, result_cards_paths,
    #             merge_proof_order, cards_minted_preimage, cards_minted_secret_key, new_cards_minted_secret_key], f)
    return {
        'mergeInput' : json.dumps([input_cards_IDs, input_cards_copy_counts, input_cards_paths, merge_proof, result_cards_IDs, result_cards_paths,
                merge_proof_order, cards_minted_preimage, cards_minted_secret_key, new_cards_minted_secret_key]),
        'resultCards' : result_cards,
        'cardCounts' : new_card_counts,
        'secretKey': hex(new_cards_minted_secret_key_int),
        'processingInput' : json.dumps([result_cards_root_raw, result_cards_mint, new_cards_minted_hashed])
    }