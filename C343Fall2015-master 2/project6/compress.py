#!/usr/bin/env python

import sys, time, random
from heap import *
from hashtable import *

dna_alph = "ACGT"
e_alph = "ACGTUWSMKRY"


# generate random string drawn from the given alphabet and of a given length
def gen_random_string(alphabet, length):
    a_len = len(alphabet)
    ret = ""
    for n in range(length):
        ret += random.choice(alphabet)
    return ret

# Huffman Tree node
class HTreeNode:
    def __init__(self, key=None, char=None):
        self.key = key
        self.char = char
        self.left = None
        self.right = None
    
    def __repr__(self):
        return repr(self.char) + ': ' + repr(self.key)

def less(x, y): return x.key < y.key

# huffman code execution 
# C is a list containing objects of class HTreeNode with
# characters and their respective frequencies
# returns the root of the Huffman tree
def huff_code(C):
#     Q = PQueue(less)
    Q = PriorityQueue(less)
    n = len(C)
    for c in C:
        Q.push(c)
    
    for i in range(n-1):
        print Q
        z = HTreeNode()
        z.left = Q.pop()
        z.right = Q.pop()
        z.key = z.left.key + z.right.key
        Q.push(z)
    return Q.pop()

def pre(n, l):
    if not n: return
    l.append(n.key)
    pre(n.left, l)
    pre(n.right, l)

def inorder(n, l):
    if not n: return
    inorder(n.left, l)
    l.append(n.key)
    inorder(n.right, l)

def post(n, l):
    if not n: return
    post(n.left, l)
    post(n.right, l)
    l.append(n.key)

# returns the code for c from a tree rooted at n
def get_code(n, c, code):
    if not n: return None
    if n.char == c: return code
    lcode = get_code(n.left, c, code + '0')
    if lcode: return lcode
    return get_code(n.right, c, code + '1')

def get_random_freqs():
#     seq = gen_random_string(dna_alph, 10)
    seq = gen_random_string(e_alph, 1000)
#     print seq
    char_freqs = Hashtable({})
    for c in seq:
        if c in char_freqs:
            char_freqs[c] += 1.0
        else:
            char_freqs[c] = 1.0
    return char_freqs

# divide each value in char_freq with the total number of values
def normalize(char_freq):
    tot = 0.0
    for c in char_freq.keys():
        tot += char_freq[c]
    for c in char_freq.keys():
        char_freq[c] /= tot

# takes a char->freq dict as input and returns 
def exec_huff(char_freqs):
    C = []
    for c in char_freqs.keys():
        o = HTreeNode(char_freqs[c], c)
        C.append(o)
#     print sorted(C, key=lambda x: x.key)
    # huff code
    root = huff_code(C)
#     l = []; pre(root, l); print "pre: " + str(l)
#     l = []; inorder(root, l); print "inorder: " + str(l)
    
    # find the codes
    codes = Hashtable({})
    for c in char_freqs.keys():
        code = get_code(root, c, '')
        codes[c] = code
#     print sorted(codes.items(), key=lambda x: int(x[1]), reverse=True)
    return codes

def gen_tests():
    tests = []
    for n in range(10):
        char_freqs = get_random_freqs()
        normalize(char_freqs)
        codes = exec_huff(char_freqs)
        tests.append((char_freqs, codes))
    f=open('tests.txt', 'w'); f.write(str(tests)); f.close()

# return the total bits required to represent the string, note this might return float value
# since the frequencies are normalized
def calc_total_bits(freq, code):
    sum = 0.0
    for k in freq.keys():
        sum += len(code[k]) * freq[k]
    return sum

def run_batch():
    f=open('tests.txt', 'r'); tests=eval(f.read()); f.close()
    cnt = 0; passed = True
    for (cf, codes) in tests:
        ret_codes = exec_huff(cf)
        # we need to compare the total bits needed to represnt the string
        # instead of the exact code, because the code might differ depending on
        # the priority queue implementation
        tcase_bits = calc_total_bits(cf, codes)
        huff_code_bits = calc_total_bits(cf, ret_codes)
        if tcase_bits != huff_code_bits:
            print "test#" + str(cnt) + ' failed'; passed = False
        cnt += 1
    if passed:
        print "all tests passed!"

if (len(sys.argv) == 2 and sys.argv[1] == 'gentests'):
    gen_tests()
elif (len(sys.argv) == 2 and sys.argv[1] == 'test'):
    run_batch()
else:
    char_freqs = Hashtable({'a': 45, 'b': 13, 'c': 12, 'd': 16, 'e': 9, 'f':5})
#     char_freqs = get_random_freqs()
    normalize(char_freqs)
    code = exec_huff(char_freqs)
    print "total bits with normalized frequencies: " + str(calc_total_bits(char_freqs, code))
