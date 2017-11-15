from stack import ArrayStack

class BSTNode:
    def __init__(self, key, left=None, right=None):
        self.key = key
        self.left = left
        self.right = right

def less_than(x,y):
    return x < y

class BinarySearchTree:
    def __init__(self, root = None, less=less_than):
        self.root = root
        self.parents = True
        self.less = less

    # takes value, returns node with key value
    def insert(self, k):
        if self.root is None:
            self.root = BSTNode(k)
            return self.root
        else:
            node = self.root
            while node is not None:
                if node.key == k:
                    return node
                elif self.less(k, node.key):
                    if node.left is None:
                        newNode = BSTNode(k)
                        node.left = newNode
                        return newNode
                    else:
                        node = node.left
                else:
                    if node.right is None:
                        newNode = BSTNode(k)
                        node.right = newNode
                        return newNode
                    else:
                        node = node.right

    # takes node, returns node
    # return the node with the smallest key greater than n.key
    def successor(self, n):
        if search(n.key) is None:
            return None
        node = self.root
        smallest = None
        while node is not None:
            if self.less(n.key, node.key):
                if smallest is None or self.less(node.key, smallest.key):
                    smallest = node
                if node.left is None:
                    return smallest
                else:
                    node = node.left
            else:
                if node.right is None:
                    return smallest
                else:
                    node = node.right

    # return the node with the largest key smaller than n.key
    def predecessor(self, n):
        if search(n.key) is None:
            return None
        node = self.root
        largest = None
        while node is not None:
            if self.less(node.key, n.key):
                if largest is None or self.less(largest.key, node.key):
                    largest = node
                if node.right is None:
                    return largest
                else:
                    node = node.right
            else:
                if node.left is None:
                    return largest
                else:
                    node = node.left

    # takes key returns node
    # can return None
    def search(self, k):
        if self.root is None:
            return None
        else:
            node = self.root
            while node is not None:
                if node.key == k:
                    return node
                elif self.less(k, node.key):
                    node = node.left
                else:
                    node = node.right
            return None

    # takes node returns Parent node (if found)
    # otherwise returns None
    def get_parent(self, n):
        if n is self.root or search(n.key) is None:
            return None
        node = self.root
        while node is not None:
            if node.right is n or node.left is n:
                return node
            else:
                if self.less(n.key, node.key):
                    node = node.left
                else:
                    node = node.right
            
    # takes node, returns node
    def delete_node(self, n):
        p = self.search(n.key)
        if p is None:
            return None
        else:
            if p.left == None or p.right == None:
                twoChildren = False
            else:
                twoChildren = True
            if not twoChildren:
                child = p.left
                if child is None:
                    child = p.right
                parent = self.get_parent(p)
                if parent.left is p:
                    parent.left = child
                else:
                    parent.right = child
                return child
            else:
                r = self.predecessor(p)
                parent = self.get_parent(r)
                temp = r.left
                if parent.left is r:
                    parent.left = temp
                else:
                    parent.right = temp
                p.key = r.key
                return p
