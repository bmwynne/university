from BST import BinarySearchTree

def left_end(seg):
    if seg[0][0] <= seg[1][0]:
        return seg[0]
    else:
        return seg[1]

def right_end(seg):
    if seg[0][0] <= seg[1][0]:
        return seg[1]
    else:
        return seg[0]

current_x = 0    
def segment_less(s1, s2):
    left1 = left_end(s1)
    right1 = right_end(s1)
    left2 = left_end(s2)
    right2 = right_end(s2)
    # I'm cheating by using division. -Jeremy
    m1 = (right1[1] - left1[1]) / (right1[0] - left1[0])
    m2 = (right2[1] - left2[1]) / (right2[0] - left2[0])
    y1 = left1[1] + m1 * (current_x - left1[0])
    y2 = left2[1] + m2 * (current_x - left2[0])
    return y1 < y2

T = BinarySearchTree(root=None, less=segment_less)

T.insert(((0 * 100, 173), (181, 370)))
T.insert(((7 * 100, 173), (181, 370)))
for n in range(1, 7):
    T.insert(((n * 100, 173), (181, 370)))
# T.insert(((291, 173), (181, 370)))
# T.insert(((432, 457), (391, 167)))
# T.insert(((297, 445), (338, 91)))
# T.insert(((169, 200), (436, 511)))
# T.insert(((168, 200), (436, 511)))
# T.insert(((168, 200), (435, 511)))

# segs = [((80, 156), (174, 427)), ((115, 154), (216, 425)), ((151, 152), (251, 415)), ((185, 149), (296, 409)), ((240, 146), (342, 395)), ((332, 145), (319, 409))]
# for s in segs:
#     T.insert(s)

# T = BinarySearchTree(root=None, parents=True, less=(lambda x, y: x < y))
# for n in range(6):
#     sn = T.insert(n)
    
# def get_height(T):
#     if not T: return 0
#     lh = get_height(T.left)
#     rh = get_height(T.right)
#     print str(T.key) + ", lh: " + str(lh) + ", rh: " + str(rh)
#     return max(lh+1, rh+1)
# print get_height(T.root)

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

l = []; pre(T.root, l); print l
l = []; post(T.root, l); print l

print T.successor(T.search(((1 * 100, 173), (181, 370)))).key
print T.predecessor(T.search(((0 * 100, 173), (181, 370)))).key

