def threeway_compare(x,y):
    if x < y:
        return -1
    elif x == y:
        return 0
    else:
        return 1

def merge(left, right, compare = threeway_compare):
    result = []
    i, j = 0, 0
    while i < len(left) and j < len(right):
        if compare(left[i], right[j]) <= 0:
            result.append(left[i])
            i += 1
        else:
            result.append(right[j])
            j += 1
    result += left[i:]
    result += right[j:]
    return result

def merge_sort(lst, compare = threeway_compare):
    if len(lst) <= 1:
        return lst
    else:
        middle = int(len(lst) / 2)
        left = merge_sort(lst[:middle], compare)
        right = merge_sort(lst[middle:], compare)
        return merge(left, right, compare)

if __name__ == "__main__":
    cmp = lambda x,y: -1 if x < y else (0 if x == y else 1)
    assert merge_sort([], cmp) == []
    assert merge_sort([1], cmp) == [1]
    assert merge_sort([1,2], cmp) == [1,2]
    assert merge_sort([2,1], cmp) == [1,2]
    assert merge_sort([1,2,3]) == [1,2,3]
    assert merge_sort([2,1,3], cmp) == [1,2,3]
    assert merge_sort([3,2,1], cmp) == [1,2,3]
    assert merge_sort([3,4,8,0,6,7,4,2,1,9,4,5]) == [0,1,2,3,4,4,4,5,6,7,8,9]
    print('all tests passed!')
