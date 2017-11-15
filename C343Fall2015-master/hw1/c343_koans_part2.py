from unit_test import *
import math
import inspect
# Instructons:
#   Fill in the blanks with the most simple answer that makes the
#   tests pass and that does not refer directly to any variables.
#   (But don't fill in blanks on the lines that end in a comment that
#    says to ignore the line. Just skip those.)
#
#   I recommend using www.pythontutor.com to visualize the
#   execution of these programs.
#

___ = [] # ignore this line

#===============================================================================
# Functions as parameters
#===============================================================================
def linear_search(A, k, less_or_equal):
    i = 0
    while i != len(A) and not less_or_equal(k, A[i]):
        i = i + 1
    return i
result = linear_search([1,3,6,8,10], 7, lambda a,b: a <= b)
test(result == 3)
result = linear_search([10,8,6,3,1], 7, lambda a,b: a >= b)
test(result == 2)
#-------------------------------------------------------------------------------
def insert_into_sorted(A, j, less_or_equal):
    key = A[j]
    i = j - 1
    while i >= 0 and not less_or_equal(A[i], key):
        A[i+1] = A[i]
        i = i - 1
    A[i + 1] = key
B = [1,3,6,8,10,7]
insert_into_sorted(B, 5, lambda a,b: a <= b)
test(B == [1, 3, 6, 7, 8, 10])
B = [10,8,6,3,1,7]
insert_into_sorted(B, 5, lambda a,b: a >= b)
test( B ==[10, 8, 7, 6, 3, 1])
#===============================================================================
# Exception handling (try/except and raise)
# https://docs.python.org/3.3/reference/compound_stmts.html#try
# https://docs.python.org/3.3/reference/simple_stmts.html#raise
# https://docs.python.org/3.3/reference/executionmodel.html#exceptions
# https://docs.python.org/3.3/library/exceptions.html
#===============================================================================
try:
    x = 1
    raise Exception()
    x = 2
except Exception:
    x = 3
test( x == 3 )
#-----------------------------------------------------------------------------
x = 1
def f():
    global x
    x += 1
    raise Exception
    x += 2
try:
    x += 3
    f()
    x += 4
except Exception:
    x += 5
test( x == 10 )
#-------------------------------------------------------------------------------
try:
    raise Exception(42)
except Exception as e:
    test( e.args[0] == 42 )
#-------------------------------------------------------------------------------
try:
    [1,2][3]
    raise Exception()
except IndexError:
    x = 24
except Exception:
    x = 42
test( x == 24 )
#===============================================================================
# Objects and Classes
#===============================================================================
class Point:
    def __init__(self, px, py):
        self.x = px
        self.y = py
p1 = Point(3,4)
p2 = Point(5,6)
test( p1.x == 3 and p2.x == 5 )
#-------------------------------------------------------------------------------
class Point:
    def __init__(self, px, py):
        self.x = px
        self.y = py
p1 = Point(3,4)
p2 = Point(3,4)
test( ((p1 is p1) == True) and ((p1 is p2) == False) )
#-------------------------------------------------------------------------------
class Point:
    def __init__(self, px, py):
        self.x = px
        self.y = py
    def move(self, dx, dy):
        self.x += dx
        self.y += dy
p1 = Point(3,4)
p2 = Point(5,6)
p1.move(1,2)
p2.move(3,4)
test( p1.x == 4 and p2.x == 8 )
#-------------------------------------------------------------------------------
class ScalablePoint(Point):
    def scale(self, m):
        self.x = self.x * m
        self.y = self.y * m
    def scale_about(self, m, other_point):
        self.move(- other_point.x, - other_point.y)
        self.scale(m)
        self.move(other_point.x, other_point.y)
p1 = ScalablePoint(0,0)
p1.scale(3)
p2 = ScalablePoint(-1, -2)
p1.scale_about(3, p2)
test( p1.x ==2 and p1.y == 4 )
#-------------------------------------------------------------------------------
# -------------------------------------------------------------------------------
class Rectangle:
    def __init__(self, x, y, w, h):
        self.bottom_left = Point(x,y)
        self.top_right = Point(x + w, y + h)
    def move(self, dx, dy):
        self.bottom_left.move(dx, dy)
        self.top_right.move(dx, dy)
r = Rectangle(0,0,10,10)
r.move(5,10)
test( r.bottom_left.y == 10 and r.top_right.x == 15)
#-------------------------------------------------------------------------------
def move(dx, dy, point):
    point.x += dx
    point.y += dy
p1 = Point(0,0)
move(3, 4, p1)
test( p1.y == 4 and p1.x == 3)
#-------------------------------------------------------------------------------
a = [Rectangle(0,0,10,20), Point(5,10)]
b = [p.move(1,2) for p in a]
test( a[0].bottom_left.x == 1 and a[1].y == 12)
#-------------------------------------------------------------------------------
class Point:
    def __init__(self, px, py):
        self.x = px
        self.y = py
    def distance(self, other):
        return math.sqrt((other.x - self.x)**2 + (other.y - self.y)**2)
    def closer(self, other1, other2):
        if self.distance(other1) < self.distance(other2):
            return other1
        else:
            return other2
class Point3D(Point):
    def __init__(self, px, py, pz):
        self.x = px; self.y = py; self.z = pz
    def distance(self, other):
        return math.sqrt((other.x - self.x)**2 + (other.y - self.y)**2 \
                         + (other.z - self.z)**2)
p1 = Point3D(0,0,0)
p2 = Point3D(3,4,5)
p3 = Point3D(2,3,4)
test( p1.closer(p2,p3).x == 2)
#-------------------------------------------------------------------------------
class Point:
    def __init__(self, px, py):
        self.x = px
        self.y = py
    def distance(self, other):
        return math.sqrt((other.x - self.x)**2 + (other.y - self.y)**2)
    def __add__(self, other):
        return Point(self.x + other.x, self.y + other.y)
    def __iadd__(self, other):
        self.x += other.x; self.y += other.y
        return self
    def __imul__(self, m):
        self.x *= m; self.y *= m
        return self
    def __eq__(self, other):
        return self.x == other.x and self.y == other.y
p1 = Point(1,2)
p2 = Point(1,1)
p1 += p2
p1 *= 2
test( p1.x == 4   and p1.y == 6   and (p1 == p2) == False )
#-------------------------------------------------------------------------------
jump = [Point(x,y) for x in [-2,2] for y in [-1,1]] \
       + [Point(x,y) for x in [-1,1] for y in [2,-2]]
class KnightsIterator:
    def __init__(self, pos):
        self.n = 0
        self.pos = pos
    def __next__(self):
        if self.n == 8:
            raise StopIteration()
        else:
            p = self.pos + jump[self.n]
            self.n += 1
            return p
class Knight:
    def __init__(self, x, y):
        self.position = Point(x, y)
    def __iter__(self):
        return KnightsIterator(self.position)
k = Knight(4,4)
for p in k:
  #test( k.position.distance(p) == ___ )
	test( k.position.distance(p) == 2.2360679775)
#test( (Point(2,3) in k) == ___ and (Point(5,5) in k) == ___ )
test( (Point(2,3) in k) == True and (Point(5,5) in k) == False)
#-------------------------------------------------------------------------------
class Circle(object):
    pi = 3.14159
    def __init__(self, radius):
        self.radius = radius
    def area(self):
        return self.pi * self.radius * self.radius
c = Circle(2)
test( c.area() == 12.56636)
#-------------------------------------------------------------------------------
class Circle(object):
    pi = 3.14159
    def __init__(self, radius):
        self.radius = radius
    def area(self):
        return self.pi * self.radius * self.radius
c1 = Circle(2)
c2 = Circle(3)
test( c1.pi == 3.14159 and c2.pi == 3.14159)
Circle.pi = math.pi
test( c1.pi == 3.14159265359 and c2.pi == 3.14159265359)
c1.pi = 3.14159
test( c1.pi == 3.14159 and c2.pi == 3.14159265359 and Circle.pi == 3.14159265359)
#-------------------------------------------------------------------------------
classes = [None,None,None]
for i in range(0,3):
    class C:
        number = i
    classes[i] = C

objects = [None,None,None]
for j in range(0,3):
    objects[j] = classes[j]()

test( objects[0].number == 0)
test( objects[1].number == 1)
test( objects[2].number == 2)
#-----------------------------------------------------------------
