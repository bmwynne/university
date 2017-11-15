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

# Student code -- fill in all the methods that have pass as the only statement
class Heap:
    def __init__(self, data, 
                 less = less):
        self.data = data
        self.less = less
        self.build_min_heap()
        
    def __repr__(self):
        return repr(self.data) 
    
    def minimum(self):
        if len(self.data) == 0:
            raise Exception
        else:
            return self.data[0]
        
          
    def insert(self, obj):
       self.data.append(obj)
       

    def extract_min(self):
       temp = self.data[0]
       del self.data[0]
       return temp
        
        
    def min_heapify(self, i):
        if less(left(i), len(self.data)) and self.data[i] > self.data[left(i)]:
            smallest = left(i)
        else:
            smallest = i
        if less(right(i), len(self.data)) and self.data[smallest] > self.data[right(i)]:
            smallest = right(i)
        if smallest != i:
            swap(self.data, i, smallest)
            min_heapify(self.data, smallest)
    
    def build_min_heap(self):
        last_parent = (len(self.data) / 2) - 1
        i = (len(self.data) / 2)
        while (i > 0):
            min_heapify(self.data, i)
            i = i - 1

            
class PriorityQueue:
    def __init__(self, less=less_key):
        self.heap = Heap([], less)

    def __repr__(self):
        return repr(self.heap)

    def push(self, obj):
        self.heap.insert(obj)

    def pop(self):
        return self.heap.extract_min()

if __name__ == "__main__":
    # unit tests here
    pass


