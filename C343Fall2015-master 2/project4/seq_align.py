#! /usr/bin/env python

import sys, time, random
import pygame

e_aplh = "abcdefghijklmnopqrstuvwxyz"
dna_alph = "ACGT"

# generate random string drawn from the given alphabet and of a given length
def gen_random_string(alphabet, length):
    a_len = len(alphabet)
    ret = ""
    for n in range(length):
        ret += alphabet[random.randint(0, a_len-1)]
    return ret

# print gen_random_string(e_aplh, 5)

SPACE_CHAR = '_'
SPACE_PENALTY = -1

# the scoring function
def s(x, y):
    if x == SPACE_CHAR or y == SPACE_CHAR:
        return SPACE_PENALTY
    elif x == y:
        return 2
    else:
        return -2

TILE_SIZE = 40
tile_color = (255, 255, 255)
highlight_color = (120, 129, 250)


def init_board(m, n):
    screen = pygame.display.set_mode(((m+2)*TILE_SIZE, (n+2)*TILE_SIZE))
    screen.fill((0, 0, 0))
    pygame.display.set_caption('Dot Board')
    pygame.font.init()
    font = pygame.font.Font(None, 15)
    return screen, font

def create_tile(font, text, color):
    tile = pygame.Surface((TILE_SIZE, TILE_SIZE))
    tile.fill(color)
    b1 = font.render(text, 1, (0, 0, 0))
    tile.blit(b1, (TILE_SIZE/2, TILE_SIZE/2))
    return tile

def render_board(board, font, s1, s2, F):
    for i in range(len(s1)):
        tile = create_tile(font, s1[i], tile_color)
        board.blit(tile, ((i+2)*TILE_SIZE, 0))
    tile = create_tile(font, '', tile_color); board.blit(tile, (0, 0))
    tile = create_tile(font, '', tile_color); board.blit(tile, (TILE_SIZE, 0))
    for j in range(len(s2)):
        tile = create_tile(font, s2[j], tile_color)
        board.blit(tile, (0, (j+2)*TILE_SIZE))
    tile = create_tile(font, '', tile_color); board.blit(tile, (0, TILE_SIZE))
    for (x,y) in sorted(F.keys()):
        tile = create_tile(font, str(F[(x,y)]), tile_color)
        board.blit(tile, ((x+1)*TILE_SIZE, (y+1)*TILE_SIZE))

def format_tb(table, length):
    for x in range(length):
        for y in range(length):
            if y == length - 1:
                print table[x][y]
            else:
                print table[x][y],
                print "\t",

def seq_align(s1, s2, enable_graphics=True):
 #  table[x-1][y-1] --> diagonal of table
 #  table[x-1][y]   --> left     of table
 #  table[x][y-1]   --> up       of table
 #
 #  commented out code is utilized for visualitation of sequence alignment table in terminal format  

 #  print "Initializing Table......"
    table = [[0 for x in range(len(s1) + 1)] for y in range(len(s2) + 1)]
   
    for x in range(len(s2) + 1):
        table[x][0] -= x
    for y in range(len(s1) + 1):
        table[0][y] -= y

  #  format_tb(table, len(table))
  #  print "Populating Table......."              
    for x in range(1, len(s2) + 1):      # utilizing 2d table method from lecture notes
        for y in range(1, len(s1) + 1):
                       table[x][y]   = max(
                       table[x-1][y-1] + s(s1[y-1], s2[x-1]), 
                       table[x-1][y]   + SPACE_PENALTY,         
                       table[x][y-1]   + SPACE_PENALTY)          
  #  format_tb(table, len(table))
    
    
    curr_index = (len(s2), len(s1))
    s1_index = len(s1)
    s2_index = len(s2)
    
    while curr_index[0] >= 0 and curr_index[1] >= 0:
        x = curr_index[0]
        y = curr_index[1]
        best_score = max(table[x][y-1], table[x-1][y],table[x-1][y-1])

        if best_score == table[x-1][y-1]:
            curr_index = (x-1, y-1)
            s1_index -= 1
            s2_index -= 1

        elif best_score == table[x][y-1]:
            curr_index = (x, y-1)
            s1_index -= 1
            s2 = s2[ : s2_index] + '_' + s2[s2_index : ]

        elif best_score == table[x-1][y]:
            curr_index = (x-1, y)
            s2_index -= 1
            s1 = s1[ : s1_index] + '_' + s1[s1_index : ]

    return s1, s2
    
def bestSoln(orig_a1, orig_a2, ret_a1, ret_a2, a1, a2):
    if len(ret_a1) != len(ret_a2):
        return False

    ansScore = 0
    for ctr in range(len(a1)):
        ansScore += s(a1[ctr], a2[ctr])

    retScore = 0
    for ctr in range(len(ret_a1)):
        retScore += s(ret_a1[ctr], ret_a2[ctr])

    if retScore > ansScore:
        return False

    orig_ctr = 0
    for ctr in range(len(ret_a1)):
        if ret_a1[ctr] != "_":
            if ret_a1[ctr] != orig_a1[orig_ctr]:
                return False
            orig_ctr += 1

    orig_ctr = 0
    for ctr in range(len(ret_a2)):
        if ret_a2[ctr] != "_":
            if ret_a2[ctr] != orig_a2[orig_ctr]:
                return False
            orig_ctr += 1
        
    return True

if len(sys.argv) == 2 and sys.argv[1] == 'test':
    f=open('tests.txt', 'r');tests= eval(f.read());f.close()
    cnt = 0; passed = True
    for ((s1, s2), (a1, a2)) in tests:
        (ret_a1, ret_a2) = seq_align(s1, s2, False)
        #if (ret_a1 != a1) or (ret_a2 != a2):
        if( not bestSoln(s1, s2, ret_a1, ret_a2, a1, a2) ):
            print s1, s2 
            print a1, a2
            print ret_a1, ret_a2
            print("test#" + str(cnt) + " failed...")
            passed = False
        cnt += 1
    if passed: print("All tests passed!")
elif len(sys.argv) == 2 and sys.argv[1] == 'gentests':
    tests = []
    for n in range(25):
        m = random.randint(8, 70); n = random.randint(8, 70)
        (s1, s2) = (gen_random_string(dna_alph, m), gen_random_string(dna_alph, n))
        (a1, a2) = seq_align(s1, s2, False)
        tests.append(((s1, s2), (a1, a2)))
    f=open('tests.txt', 'w');f.write(str(tests));f.close()
else:
    l = [('ACACACTA', 'AGCACACA'), ('IMISSMISSISSIPI', 'MYMISSISAHIPPIE')]
    enable_graphics = True
    if enable_graphics: pygame.init()
    for (s1, s2) in l:
        print 'sequences:'
        print (s1, s2)
        
        m = len(s1)
        n = len(s2)
        
        print 'alignment: '
        print seq_align(s1, s2, enable_graphics)
    
    if enable_graphics: pygame.quit()
             
