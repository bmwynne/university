from swap import swap

def less(x, y):
    return x < y

def less_key(x, y):
    return x.key < y.key

def left(i):
    return 2 * i + 1

def right(i):
    return 2 * (i + 1)

def parent(i):
    return (i-1) / 2

class Heap:
    def __init__(self, data, 
                 less = less):
        self.data = data
        self.less = less
        self.build_min_heap()
        
    def __repr__(self):
        return repr(self.data)

    def minimum(self):
        return self.data[0]

    def insert(self, obj):
        self.heap_size += 1
        if len(self.data) < self.heap_size:
            self.data.append(obj)
        else:
            self.data[self.heap_size - 1] = obj
        self.heap_increase_key(self.heap_size - 1)

    def extract_min(self):
        assert self.heap_size != 0
        min = self.data[0]
        self.data[0] = self.data[self.heap_size-1]
        self.heap_size -= 1
        self.min_heapify(0)
        return min
        
    def heap_increase_key(self, i):
        while i > 0 and self.less(self.data[i], self.data[parent(i)]):
            swap(self.data, i, parent(i))
            i = parent(i)
    
    def min_heapify(self, i):
        l = left(i)
        r = right(i)
        if l < self.heap_size and self.less(self.data[l], self.data[i]):
            smallest = l
        else:
            smallest = i
        if r < self.heap_size and self.less(self.data[r], self.data[smallest]):
            smallest = r
        if smallest != i:
            swap(self.data, i, smallest)
            self.min_heapify(smallest)
    
    def build_min_heap(self):
        self.heap_size = len(self.data)
        last_parent = len(self.data) / 2
        for i in range(last_parent, -1, -1):
            self.min_heapify(i)
    
    def heap_sort(self):
        self.build_min_heap()
        for i in range(len(self.data)-1, 0, -1):
            swap(self.data, 0, i)
            self.heap_size -= 1
            self.min_heapify(0)

class PriorityQueue:
    def __init__(self, less=less_key):
        self.heap = Heap([], less)

    def __repr__(self):
        return repr(self.heap)

    def push(self, obj):
        self.heap.insert(obj)

    def pop(self):
        return self.heap.extract_min()

    def increase_key(self, obj):
        self.heap.heap_increase_key(obj.position)

class Obj:
    def __init__(self, k):
        self.key = k
        self.position = -1

    def __repr__(self):
        return str(self.key)

if __name__ == "__main__":
    # test build and extract_min
    L = [4,3,5,1,2]
    h = Heap(L)
    for i in range(1, 6):
        assert h.extract_min() == i

    # test insert
    L = [4,3,5,1,2]
    for k in L:
        h.insert(k)
    for i in range(1, 6):
        assert h.extract_min() == i
    
    # test sort
    L = [4,3,5,1,2]
    Heap(L).heap_sort()
    for i in range(0, 5):
        assert L[i] == 5 - i

    # Test priority queue
    Q = PriorityQueue()
    for i in range(1, 6):
        Q.push(Obj(i))
    for i in range(1, 6):
        assert Q.pop().key == i

    Q = PriorityQueue()
    L = [Obj(4),Obj(3),Obj(5),Obj(1),Obj(2)]
    for i in range(0, 5):
        Q.push(L[i])

    # test increase_key
    for i in range(0, 5):
        L[i].key += 2
        Q.increase_key(L[i])
    for i in range(1, 6):
        assert Q.pop().key == i + 2

    print('passed all tests')
