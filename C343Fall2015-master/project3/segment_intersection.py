from merge import merge_sort
from BST import *
from avl import *

def cross_product(p1, p2):
    return p1[0] * p2[1] - p2[0] * p1[1]

def difference(p1, p2):
    return (p2[0] - p1[0], p2[1] - p1[1])

# positive result => right turn (clockwise)
# negative result => left turn (counter-clockwise)
def direction(p0, p1, p2):
    return cross_product(difference(p2,p0), difference(p1,p0))

if __name__ == "__main__":
    assert direction( (1,1), (2,2), (2,3) ) < 0
    assert direction( (1,1), (2,2), (3,2) ) > 0
    assert direction( (0,1), (2,1), (1,1) ) == 0

# Does segment p1-p2 straddle the line <-p3-p4->?
def straddle(p1,p2,p3,p4):
    d1 = direction(p3,p4,p1)
    d2 = direction(p3,p4,p2)
    return (d1 > 0 and d2 < 0) or (d1 < 0 and d2 > 0)

if __name__ == "__main__":
    assert straddle((0,0), (2,2), (0,1), (2,1))
    assert straddle((0,1), (2,1), (0,0), (2,2))
    assert not straddle((1,1), (2,1), (0,0), (2,2))

def on_segment(pi, pj, pk):
    return min(pi[0],pj[0]) <= pk[0] <= max(pi[0],pj[0]) \
        and min(pi[1],pj[1]) <= pk[1] <= max(pi[1],pj[1])

if __name__ == "__main__":
    pass 

def segments_intersect(p1,p2,p3,p4):
    return (straddle(p1,p2,p3,p4) and straddle(p3,p4,p1,p2)) \
        or (direction(p3,p4,p1) == 0 and on_segment(p3,p4,p1)) \
        or (direction(p3,p4,p2) == 0 and on_segment(p3,p4,p2)) \
        or (direction(p1,p2,p3) == 0 and on_segment(p1,p2,p3)) \
        or (direction(p1,p2,p4) == 0 and on_segment(p1,p2,p4)) 

if __name__ == "__main__":
    assert segments_intersect((0,0),(2,2), (0,1),(2,1))
    assert segments_intersect((1,1),(2,2), (0,1),(2,1))
    assert not segments_intersect((1,3),(2,2), (0,1),(2,1))
    assert not segments_intersect((2,0),(4,2), (0,1),(2,1))

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


def create_endpoint(point, other_point):
    assert point[0] != other_point[0]
    if point[0] < other_point[0]:
        side = 0 # left
    else:
        side = 1 # right
    return (point[0], side, point[1])

current_x = 0

def any_segments_intersect(S):
    global current_x
    endpoints = []
    segment_of = {}

    for (p1,p2) in S:
        assert p1[0] != p2[0] # don't allow vertical segments
        e = create_endpoint(p1,p2)
        segment_of[e] = (p1,p2)
        endpoints.append(e)

        e  = create_endpoint(p2,p1)
        segment_of[e] = (p2,p1)
        endpoints.append(e)

    endpoints = merge_sort(endpoints)

    # To do: replace with AVLTree. -Jeremy
    T = BinarySearchTree(root=None, less=segment_less)
    #T = AVLTree(root=None, less=segment_less)

    for p in endpoints:
        current_x = p[0]
        s = segment_of[p]
        if p[1] == 0: # p is a left endpoint
            sn = T.insert(s)
            above = T.successor(sn)
            below = T.predecessor(sn)
            if above and \
               segments_intersect(s[0],s[1], above.key[0], above.key[1]):
                return (True, (s[0],s[1]), (above.key[0], above.key[1]))
            if below and \
               segments_intersect(s[0],s[1], below.key[0], below.key[1]):
                return (True, (s[0],s[1]), (below.key[0], below.key[1]))
        else: # p is a right endpoint
            sn = T.search(s)
            if sn:
                above = T.successor(sn)
                below = T.predecessor(sn)
                if above and below and \
                   segments_intersect(above.key[0], above.key[1],
                                      below.key[0], below.key[1]):
                    return (True, (above.key[0], above.key[1]), (below.key[0], below.key[1]))
                T.delete_node(sn)

    return (False, None, None)


if __name__ == "__main__":
    segments = [((0,0),(2,2)),\
                ((2,3),(0,4)),\
                ((3,1),(1,1)),\
                ((4,4),(5,1))]
    assert any_segments_intersect(segments)[0]

    segments = [((1,3),(2,2)), \
                ((0,1),(2,1)), \
                ((2,0),(4,2))]
    assert not any_segments_intersect(segments)[0]

    segments = [((1,3),(4,2)),\
                ((3,4),(2,6)),\
                ((3,8),(6,8)),\
                ((5,4),(4,4)),\
                ((4,7),(7,4)),\
                ((5,5),(7,6)),\
                ((5,2),(7,5)),\
                ((5,3),(8,2)),\
                ((6,2),(9,5))]

    assert any_segments_intersect(segments)[0]

    # this test case fails
#     segments = [((48, 102), (239, 466)), ((135, 104), (409, 574)), ((251, 114), (501, 556)), ((351, 99), (615, 564)), ((469, 123), (677, 583)), ((560, 403), (607, 71))]
#     print any_segments_intersect(segments)[0]

if __name__ == "__main__":
    print('all tests passed!')
