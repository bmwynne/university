import random
from utilities import *

# Instead of using random access to remove,
# could instead do a one-pass algorithm to do the
# removal, such as an STL-style copy_if. -Jeremy

def create_drought(flooded_list, color_of_tile):
    drought_tiles = []
    for i in range(0, len(flooded_list), 3):
        drought_tiles.append(flooded_list[i])

    for coord in drought_tiles:
        flooded_list.remove(coord)
        color = color_of_tile[coord]
        c = colors.index(color)
        c = (c + 1) % len(colors)
        new_color = colors[c]
        color_of_tile[coord] = new_color    
    return drought_tiles
