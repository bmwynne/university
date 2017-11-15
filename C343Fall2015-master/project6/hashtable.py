class Hashtable:
    def __init__(self, dict):
        self.size    = max(1, len(dict))
        self.buckets = [ [] for i in range(self.size)]
        self.data = [ [] for i in range(self.size)]
        #self.value   = [None] * self.size
        for key,value in dict.iteritems():
            self.__setitem__(key,value)

    def __getitem__(self, key):
        index = hash(key)% self.size
        bucket_size = len(self.buckets[index])
        for x in range(bucket_size):
            if self.buckets[index][x] == key:            
                return self.data[index][x]

    def __setitem__(self, key, value):
        index = hash(key) % self.size
        bucket_size = len(self.buckets[index])
        if bucket_size == 0:
            self.buckets[index] = [key]
            self.data[index] = [value]
        else:
            for x in range(bucket_size):
                if self.buckets[index][x] == key:
                    self.data[index][x] = value
                    return
            self.buckets[index].append(key)
            self.data[index].append(value)
           

    def __delitem__(self, key):
        index = hash(key) % self.size
        bucket_size = len(self.buckets[index])
        value = self.__getitem__(key)
        for i in range(bucket_size):
            if self.buckets[index][k] == key:
                self.buckets[index].remove(key)
                self.data[index].remove(value)
                return

    def keys(self):
        keys = []
        for bucket in range(self.size):
            for i in self.buckets[bucket]:
                keys.append(i)

        return keys
