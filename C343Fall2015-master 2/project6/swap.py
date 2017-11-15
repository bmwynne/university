def swap(A, i, j):
    tmp = A[i]
    A[i] = A[j]
    A[j] = tmp

def swap_range(A, b1, b2, k):
    for i in range(0,k):
        swap(A, b1, b2)
        b1 += 1
        b2 += 1

