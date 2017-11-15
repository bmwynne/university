import subprocess

# SCREEN_SIZE = (608, 448)
TILE_SIZE = (32, 32)
STEP_SIZE = 32
colors = ["pink", "violet", "yellow", "red", "olive", "blue"]
rgb = { "pink": (255, 105, 180),
        "violet": (138, 43, 226),
        "yellow": (255, 255, 0),
        "red": (255, 69, 0),
        "olive": (110, 139, 61),
        "blue": (0, 191, 255) }

def up(coord):
    return (coord[0], coord[1] - STEP_SIZE)

def right(coord):
    return (coord[0] + STEP_SIZE, coord[1])

def down(coord):
    return (coord[0], coord[1] + STEP_SIZE)

def left(coord):
    return (coord[0] - STEP_SIZE, coord[1])

def in_bounds(coord, screen_size):
    return 0 <= coord[0] and coord[0] < screen_size[1] \
        and 0 <= coord[1] and coord[1] < screen_size[1]
        
# simple macro-like function to run a command
# BEWARE that the input string is split using space as a delimiter
def exec_command(str_command):
#     print(str_command)
    return subprocess.Popen(str_command.split(' '), stdout=subprocess.PIPE).communicate()[0]

# returns the keys not present in either d1/d2 + keys that differ in values 
def dict_diff(d1, d2):
    key_diff = set(d1.keys()) - set(d2.keys())
    key_diff.union(set(d2.keys()) - set(d1.keys()))
#     if (len(key_diff) > 0): return key_diff
    # key_diff empty
    for key in d1.keys():
        if d1[key] != d2[key]:
            key_diff.add(key)
    return key_diff