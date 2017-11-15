import pygame
# import pygame._view
from pygame import *
import random

from flood import flood
# from flood_array import flood
from utilities import *
from drought import create_drought
import sys
import time
import copy
import math
import csv

#declare global variables
btncol = None
screen = None

keycolors = { K_a: "pink", K_s: "violet", K_d: "yellow",
              K_z: "red", K_x: "olive", K_c: "blue" }

def mean(l):
    return float(sum(l))/len(l) if len(l) > 0 else float('nan')

def button_rect(btn):
    coord = btn['position']
    return pygame.Rect(coord[0], coord[1], 32, 32)

def game_over(png_file, screen_size):
    shade = pygame.Surface(screen_size)
    shade.fill([0, 0, 0])
    shade.set_alpha(200)
    screen.blit(shade, [0, 0])
    imggameover = pygame.image.load(png_file)
    picture_size = (320,240)
    picture_tiles = [pygame.Rect((0,0), picture_size),
                     pygame.Rect((320,0), picture_size),
                     pygame.Rect((0,240), picture_size),
                     pygame.Rect((320,240), picture_size)]
    rectangle = picture_tiles[random.randint(0, 3)]
    screen.blit(imggameover, [64, 104], rectangle)
    pygame.display.update()

def populate_with_random_colors(color_of_tile):
#     print str(board_size)
    for i in range(board_size):
        for j in range(board_size):
            color_of_tile[(STEP_SIZE*i,STEP_SIZE*j)] = colors[random.randint(0, 5)]

def populate_with_wave_pattern(color_of_tile):
#     print str(board_size)
    clrs = []
    for i in range(board_size):
        color = colors[i%6]
        clrs.append(color)
        for j in range(i):
            color_of_tile[(STEP_SIZE*i,STEP_SIZE*j)] = color; color_of_tile[(STEP_SIZE*j,STEP_SIZE*i)] = color
        color_of_tile[(STEP_SIZE*i,STEP_SIZE*i)] = color
    return clrs

def initialize(board_size, color_of_tile, flooded_list, screen_size):
    global btncol
    global screen
    
    screen.fill(0) #color screen black

    #fills the grid with randomly colored tiles
    for i in range(board_size):
        for j in range(board_size):
            X = STEP_SIZE*i
            Y = STEP_SIZE*j
            tile = pygame.Surface(TILE_SIZE)
            tile.fill(rgb[color_of_tile[(X,Y)]])
            screen.blit(tile, [X, Y])

    # This is the function the students will write. -Jeremy
    flood(color_of_tile, flooded_list, screen_size)

    tile = pygame.Surface(TILE_SIZE)
    tile.fill(rgb[color_of_tile[(0,0)]])
    for i in range(len(flooded_list)):
        screen.blit(tile, flooded_list[i])
    pygame.display.update()

    # render controls
    # button initialization
    btncol = [dict(), dict(), dict(), dict(), dict(), dict()]

    # button initialization, color and position
    btncol[0] = { 'color': rgb["pink"], 'position': (screen_size[1] + 64, 21) }
    btncol[1] = { 'color': rgb["violet"], 'position': (screen_size[1] + 64, 95) }
    btncol[2] = { 'color': rgb["yellow"], 'position': (screen_size[1] + 64, 169) }
    btncol[3] = { 'color': rgb["red"], 'position': (screen_size[1] + 64, 243) }
    btncol[4] = { 'color': rgb["olive"], 'position': (screen_size[1] + 64, 317) }
    btncol[5] = { 'color': rgb["blue"], 'position': (screen_size[1] + 64, 391) }

    for i in range(len(btncol)):
        pygame.draw.circle(screen, btncol[i]['color'],
                           (btncol[i]['position'][0]+16,
                            btncol[i]['position'][1]+16),
                           16)
    pygame.display.update()

# this list holds the test cases to be used in batch mode
# each test is a list of board,color pairs
tests = []
test = []
# currently these sizes are fixed, hoping to change them later
board_size = 14
max_moves = 25
test_file = "tests_" + str(board_size) + ".txt"

drought_enabled = True

def get_screen_size(bsize):
    return (max(bsize * STEP_SIZE + 160, 608), max(bsize * STEP_SIZE, 448))

screen_size = get_screen_size(board_size)

# This function runs the game for one step, returns true if the game has finished 
def step(screen_size, color_of_tile, flooded_list, color, show_graphics=False, gen_tests=False, times=[]):
    global tests
    global test
    global board_size
    global max_moves
    global screen
    
    if color != None and step.movecount < max_moves:
        step.movecount += 1
        
        if show_graphics:
            tile = pygame.Surface(TILE_SIZE)
            tile.fill(rgb[color])
        
        if gen_tests: test.append(copy.deepcopy(color_of_tile)); test.append(color)
        
        for coord in flooded_list:
            color_of_tile[coord] = color

        # This is the function the students will write. -Jeremy
        t1 = time.time()
        flood(color_of_tile, flooded_list, screen_size)
        t2 = time.time()
        times.append(t2-t1)

        if show_graphics:
            for i in range(len(flooded_list)):
                screen.blit(tile, flooded_list[i])

        # drought every seven years
        if drought_enabled and len(flooded_list) > 0 and step.movecount % 7 == 0:
            td1 = time.time()
            drought_tiles = create_drought(flooded_list, color_of_tile)
#             td2 = time.clock()
            diff = time.time() - td1
            print "%0.8lf" % diff
#             times.append(diff)
            
            if show_graphics:
                display.set_caption('Flood-it! Drought in progress!')
                for coord in drought_tiles:
                    tile.fill(rgb[color_of_tile[coord]])
                    screen.blit(tile, coord)
        else:
            if show_graphics:
                display.set_caption('Flood-it! '+str(step.movecount)+'/' + str(max_moves))

        if show_graphics:
            pygame.display.update()

    if len(flooded_list) == (board_size * board_size):
        if show_graphics:
            game_over('win.png', screen_size)
            display.set_caption('Flood-it! Congratulations. You won!')
        if gen_tests: test.append(copy.deepcopy(color_of_tile)); tests.append(test); test = []
        step.movecount = 0
        return True

    if step.movecount == max_moves and len(flooded_list) != (board_size * board_size):
        if show_graphics:
            game_over('gameover.png', screen_size)
            display.set_caption('Flood-it! GAME OVER!')
        if gen_tests: test.append(copy.deepcopy(color_of_tile)); tests.append(test); test = []
        step.movecount = 0
        return True
    
    return False

step.movecount = 0

import numpy

# reads tests from the test file(s), runs the step function on board,color configurations, tells you if the test failed
# generates the timing graph if all tests successful
def run_batch(mode):
    global board_size
    global max_moves
    global screen

    print('batch mode start')
    
    batch_mode_graphics = False
    
    if batch_mode_graphics:
        pygame.init()
    
    xvals = []; yvals = []
    
    successful = True
    for (bsize, moves) in sorted(bsizes_moves_hash.items()):
        board_size = bsize
        max_moves = moves
        screen_size = get_screen_size(board_size)
        
        # read the [[board->color->updated_board...]...] list from a file
        f = open('tests_' + str(board_size)+'.txt', 'r'); ts = eval(f.read()); f.close()
        
        if batch_mode_graphics:
            screen = pygame.display.set_mode(screen_size)
            display.set_caption('Flood-it!')
        
        times = []
        
        testnum = 0
        # for each test
        for t in ts:
            
            flooded_list = [(0, 0)]
            
            if batch_mode_graphics:
                initialize(board_size, t[0], flooded_list, screen_size)
                time.sleep(1)
            
            for i in range(0, len(t) - 1, 2):
                color_of_tile = t[i]
#                 t1 = time.time()
                step(screen_size, color_of_tile, flooded_list, t[i+1], batch_mode_graphics, False, times)
#                 t2 = time.time()
#                 times.append(t2-t1)
                if batch_mode_graphics: time.sleep(1)
                
                if mode == 'test' and color_of_tile != t[i+2]:
                    print str(testnum) + " failed"
                    successful = False
                    break
            testnum += 1
        val = numpy.mean(times) * (10 ** 3)
        print str(bsize) + ': ' + str(val)
        xvals.append(bsize * bsize); yvals.append(val)
        
    if successful and mode == 'time':
        with open('times.csv', 'wb') as f:
            writer = csv.writer(f)
            writer.writerows(zip(xvals, yvals))
    
    print('batch mode end')
    
# this hash gives us the board size-to-moves mapping, this will be used to run tests in batch mode
bsizes_moves_hash = {14:25}
for sz in range(20, 51, 2):
    bsizes_moves_hash[sz] = int(math.ceil(float(sz*25)/14))
# # print str(sorted(bsizes_moves_hash))

# bsizes_moves_hash = {20:36, 30:54, 50:90}

"""
There are three functionalities(modes) provided here:

1. interactive gaming mode:
invoked by the command 'python floodit.py'
In this mode, the user acts as a gamer, trying to flood the board within the alloted moves

2. test mode:
invoked by the command 'python floodit.py test'
In this mode, the user is trying to test their code on the tests provided in various .txt files
e.g. for a board of size 14, the test file is tests_14.txt
This file contains board,color configurations that the tested code must match against

3. time mode:
invoked by the command 'python floodit.py time'
This mode runs the game on the test file but instead of checking for correctness,
it measures the execution time.

4. Test generation mode:
invoked by the command 'python floodit.py gentests'
This mode is used to generate tests to be used as test cases to check student codes in batch mode
"""
if len(sys.argv) > 1 and (sys.argv[1] == 'test' or sys.argv[1] == 'time'):
    run_batch(sys.argv[1])
elif len(sys.argv) > 1 and sys.argv[1] == 'gentests':
    # generate tests
    # randomly choose colors and step through the board to generate log data
    for (bsize, moves) in sorted(bsizes_moves_hash.items()):
        tests = []
        board_size = bsize
        max_moves = moves
        screen_size = get_screen_size(board_size)
        for n in range(5): #number of tests
            color_of_tile = {}
            populate_with_random_colors(color_of_tile)
#             clrs = populate_with_wave_pattern(color_of_tile)
            flooded_list = [(0, 0)]
            for i in range(moves):
                color = colors[random.randint(0, 5)]
#                 color = clrs[i+1]
                gameover = step(screen_size, color_of_tile, flooded_list, color, False, True)
                if gameover: break
        f=open('tests_' + str(bsize) + '.txt', 'w'); f.write(str(tests)); f.close()
else:
    # incteractive mode
    pygame.init()
    screen = pygame.display.set_mode(screen_size)
    display.set_caption('Flood-it!')
    init_game = True
    
    while True:
        if init_game:
            color_of_tile = {}
            populate_with_random_colors(color_of_tile)
            flooded_list = [(0, 0)]
            initialize(board_size, color_of_tile, flooded_list, screen_size)
            
            init_game = False
            #print "init"
        
        # the events tell us thr gamer choices e.g. choice of color, quit etc.
        for e in event.get():
            color = None
        
            if e.type == MOUSEBUTTONDOWN:
                for i in range(len(btncol)):
                    if button_rect(btncol[i]).collidepoint(e.pos):
                        color = colors[i]
            elif e.type == QUIT:
                f=open(test_file, 'w');f.write(str(tests));f.close()
                exit(0)
            elif e.type == KEYUP:
                if e.key == K_ESCAPE:
                    f=open(test_file, 'w');f.write(str(tests));f.close()
                    exit(0)
                elif e.key == K_r:
                    init_game = True
                    break
                elif e.key in keycolors:
                    color = keycolors[e.key]
            
            gameover = step(screen_size, color_of_tile, flooded_list, color, True, True)
            
            # if gameover: 
            #     time.sleep(1)
            #     init_game=True
            #     print "game over"
            #     break
