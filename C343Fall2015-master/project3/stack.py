class ArrayStack:
    def __init__(self):
        self.data = []

    def push(self, x):
        self.data.append(x)

    def pop(self):
        return self.data.pop()

    def is_empty(self):
        return len(self.data) == 0
