import os, string, sys

import copy
from collections import deque

# appends padding spaces if the number is smaller than the largest value
# e.g. if the largest val=1245, 1 will be represented as '1   '
def format_num(n, maxSpaces):
    strNum = str(n)
    return strNum + ' ' * (maxSpaces - len(strNum))

# Just a wrapper over python dict to preserve things
# like height, width; also a pretty printing function provided
class Grid:
    def __init__(self, w, h, d):
        self.width = w
        self.height = h
        self.d = d
    
    # pretty print the grid using the number formatter
    def pretty_print_grid(self):
        nSpaces = len(str(max(self.d.values()))) + 1
        strDelim = '|' + ('-' + (nSpaces * ' ')) * self.width + '|'
        print strDelim
        for y in range(self.height):
            print '|' + ' '.join([format_num(self.d[(x, y)], nSpaces) for x in range(self.width)]) + '|'
        print strDelim

# The grid is basically a dictionary. We can treat this as a graph where each node has 4 neighbors.
# Each neighbor contributes an in-edge as well as an out-edge.
# You might want to use this to construct you solution
class Graph:
    def __init__(self, grid):
        self.grid = grid
    
    def vertices(self):
        return self.grid.keys()
    
    def adj(self, (x, y)):
        return [u for u in [(x+1, y), (x-1, y), (x, y+1), (x, y-1)] if u in self.grid.d.keys()]
    
    # put the value val for vertex u
    def putVal(self, u, val):
        self.grid.d[u] = val
    
    def getVal(self, u):
        return self.grid.d[u]

# Takes the grid and the points as arguments and returns a list of paths
# The grid represents the entire chip
# Each path represents the wire used to connect components represented by points
# Each path connects a pair of points in the points array; avoiding obstacles and other paths
# while minimizing the total path length required to connect all points
# If the points cannot be connected the function returns None
def find_paths(grid, points):
    paths = []
    g = Graph(grid)
    grid.pretty_print_grid()
    for p in range(len(points)):
        start_point = points[p][0]
        end_point = points[p][1]
        wire = deque()
        wire.appendleft(start_point)
        visit = set(start_point)
        path = []
        while len(wire) > 0:
            adjacent = g.adj(wire.pop())
            #print adjacent
            best = 1000.0
            count = -1
            i = 0;              
            for x in adjacent:
                if ((g.getVal(x) == 0) and (x not in visit) and (math.sqrt(math.pow(x[0]-end_point[0], 2) + math.pow(x[1]-end_point[1], 2)) < best) or x == end_point):
                    best = math.sqrt(math.pow(x[0]-end_point[0], 2) + math.pow(x[1]-end_point[1], 2))
                    #print best
                    i = count+1
                count = count+1
            if  (best == 0):
                wire.appendleft(adjacent[i])
                path.append(adjacent[i])
                visit.add(adjacent[i])
                break
            if (g.getVal(adjacent[i]) == 0):
                wire.appendleft(adjacent[i])
                path.append(adjacent[i])
                visit.add(adjacent[i])
            else:
                wire.popleft()
           # print path
        paths.append(path)
    return paths

# check that the paths do not cross each other, or the obstacles; returns False if any path does so
def check_correctness(paths, obstacles):
    s = set()
    for path in paths:
        for (x, y) in path:
            if (x, y) in s: return False
            for o in obstacles:
                if (o[0] <= x <= o[2]) and (o[1] <= y <= o[3]):
                    return False
            s.add((x, y))
    return True

def main():
    # read all the chip related info from the input file
    with open(sys.argv[1]) as f:
        # first two lines are grid height and width 
        h = int(f.readline())
        w = int(f.readline())
        
        # third line is the number of obstacles; following numObst lines are the obstacle co-ordinates
        numObst = int(f.readline())
        obstacles = []
        for n in range(numObst):
            line = f.readline()
            obstacles.append([int(x) for x in line.split()])
        
        # read the number of points and their co-ordinates
        numPoints = int(f.readline())
        points = []
        for n in range(numPoints):
            line = f.readline()
            pts = [int(x) for x in line.split()]
            points.append(((pts[0], pts[1]), (pts[2], pts[3])))
    grid = dict(((x, y), 0) for x in range(w) for y in range(h))
    # lay out the obstacles
    for o in obstacles:
        for x in range(o[0], o[2] + 1):
            for y in range(o[1], o[3] + 1):
                grid[(x, y)] = -1
    
    cnt = 1 # route count
    for (s, d) in points:
        grid[s] = cnt
        grid[d] = cnt
        cnt += 1
    
    numPaths = cnt - 1
    g = Grid(w, h, grid)
        
    # g.pretty_print_grid()

    paths = find_paths(g, points)
    if paths is None:
        print "Cannot connect all the points!"
    else:
        # check the correctness
        if not check_correctness(paths, obstacles):
            raise ("Incorrect solution, some path cross each other or the obstacles!")
        print "Paths:"
        totLength = 0
        for p in paths:
            print p
            totLength += len(p)
        print "Total Length: " + str(totLength)
    
if __name__ == "__main__":
    main()
