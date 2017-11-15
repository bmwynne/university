import sys, os, time, random
import pygame
from segment_intersection import any_segments_intersect

bgcolor = (255, 255, 255)
line_color = (0, 0, 255)
highlight_color = (255, 0, 0)
movingline_color = (0, 255, 0)

def init((height, width), bgcolor):
    screen = pygame.display.set_mode((width + 200, height))
    screen.fill((0, 0, 0))
    pygame.display.set_caption('Intersecting Lines')
    
    board = pygame.Surface((width, height))
    board.fill(bgcolor)
    screen.blit(board, (0, 0))
    
    pygame.font.init()
    # Go button
    font = pygame.font.Font(None, 36)
    b1 = font.render("Go", 1, (0, 255, 0))
#     textpos = b1.get_rect()
#     textpos.centerx = screen.get_rect().
    screen.blit(b1, (width+10, 40))
    # Reset button
    b2 = font.render("Reset", 1, (255, 0, 0))
#     textpos = b2.get_rect()
#     textpos.centerx = screen.get_rect().centerx
    screen.blit(b2, (width+10, 70))
#     pygame.display.update()
    return screen, board, ((width+10, 40), (width+10+b1.get_width(), 40+b1.get_height())), ((width+10, 70), (width+10+b2.get_width(), 70+b2.get_height()))
    
def reset(screen, bgcolor):
    screen.fill(bgcolor)
    pygame.display.update()

def run_batch(bsizes):
    bmode_graphics = True
    print "batch mode start"
    if bmode_graphics: pygame.init()
    tests_passed = True
    for sz in bsizes:
        (w, h) = (sz, sz)
        screen, board, b1, b2 = None, None, None, None
        if bmode_graphics:
            screen, board, b1, b2 = init((w, h), bgcolor)
        f=open('tests/test_' + str(sz) + '.txt', 'r');tests=eval(f.read());f.close()
        tcnt = 0
        for t in tests:
            segs = t[0]
            isegs = t[1]
            intersect, s1, s2 = any_segments_intersect(segs)
            if intersect:
                if not (s1, s2) in isegs:
                    print str((s1, s2)) + ' should not intersect, test#' + str(tcnt) + 'failed...'
                    tests_passed = False
            else:
                if s1 or s2:
                    print str((s1, s2)) + ' should not intersect, test#' + str(tcnt) + 'failed...'
                    tests_passed = False
            tcnt += 1
            if bmode_graphics:
                for s in segs:
                    pygame.draw.line(board, line_color, s[0], s[1])
                for iseg in isegs:
                    pygame.draw.line(board, highlight_color, iseg[0][0], iseg[0][1])
                    pygame.draw.line(board, highlight_color, iseg[1][0], iseg[1][1])
                screen.blit(board, (0, 0)); pygame.display.flip()
#                 input("Press Enter to continue...")
                time.sleep(2)
                # reset the board
                board.fill(bgcolor); screen.blit(board, (0, 0)); pygame.display.flip()
                
    if bmode_graphics: pygame.quit()
    if tests_passed:
        print("All tests passed!")
    print "batch mode end"
            
def gen_tests(bsizes):
    for sz in bsizes:
        tests = []
        (w, h) = (sz, sz)
        for n in range(5): # number of tests
            segs = []; isegs = []
            # generate random segments
            nsegs = random.randint(2, 25)
            for n in range(nsegs):
                x1 = random.randint(0, w)
                x2 = random.randint(0, w)
                # do not allow vertical segments
                while x1 == x2:
                    x2 = random.randint(0, w)
                segs.append(((x1, random.randint(0, h)), (x2, random.randint(0, h))))
            intersect, s1, s2 = any_segments_intersect(segs)
            if intersect: isegs.append((s1, s2))
            tests.append([segs, isegs])
        f=open('tests/test_' + str(sz) + '.txt', 'w');f.write(str(tests));f.close()
        
bsizes = [sz*100 for sz in range(5, 11)]

def in_bounds(pos, ((x1, y1), (x2, y2))):
    return (x1 <= pos[0] <= x2) and (y1 <= pos[1] <= y2)

def in_screen_bounds(pos, (w, h)):
    return in_bounds(pos, ((0, 0), (w, h)))

def get_button(pos, b1, b2):
    if in_bounds(pos, b1):
        return 1
    elif in_bounds(pos, b2):
        return 2
    return None

if (len(sys.argv) == 2 and sys.argv[1] == 'gentests'):
    gen_tests(bsizes)
elif (len(sys.argv) == 2 and sys.argv[1] == 'test'):
    run_batch(bsizes)
else:
    pygame.init()
    (w, h) = (bsizes[2], bsizes[2])
    screen, board, b1, b2 = init((w, h), bgcolor)
    reset_board = True
    startpos=None; prevpos = None; segs = []
    
    while True:
        if reset_board:
            reset(board, bgcolor)
            reset_board = False
            startpos=None; prevpos = None; segs = [] 
        for e in pygame.event.get():
            if reset_board:
                break
            if e.type == pygame.MOUSEBUTTONDOWN:
                if in_screen_bounds(e.pos, (w, h)):
                    if startpos:
                        pygame.draw.line(board, line_color, startpos, e.pos)
                        segs.append((startpos, e.pos))
                        startpos=None;
                    else:
                         startpos = e.pos
                else:
                    intersect = get_button(e.pos, b1, b2)
                    if intersect == 1:
                        print str(segs)
                        # Run the algo
                        intersect, s1, s2 = any_segments_intersect(segs)
                        print intersect
                        if intersect:
                            pygame.draw.line(board, highlight_color, s1[0], s1[1])
                            pygame.draw.line(board, highlight_color, s2[0], s2[1])
                    elif intersect == 2:
                        # reset
                        reset_board = True
            elif e.type == pygame.MOUSEMOTION:
                if startpos:
                    # erase the prev line
                    if prevpos:
                        pygame.draw.line(board, bgcolor, startpos, prevpos)
                    prevpos = e.pos
                    # draw the new line
                    pygame.draw.line(board, movingline_color, startpos, e.pos)
                    # previous line's erasure might have partially erased non-moving segs too, so draw them again
                    for s in segs:
                        pygame.draw.line(board, line_color, s[0], s[1])
                    
            elif e.type == pygame.QUIT:
                exit(0)
            elif e.type == pygame.KEYUP:
                if e.key == pygame.K_ESCAPE:
                    exit(0)
                elif e.key == pygame.K_RETURN:
                    reset_board = True
            screen.blit(board, (0, 0))
            pygame.display.flip()
    pygame.quit()