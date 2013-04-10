import subprocess, select
import pygame
from pygame.locals import QUIT, MOUSEBUTTONUP, MOUSEBUTTONDOWN

spim = subprocess.Popen(['spim', '-file', 'test.s'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

def setup_pygame(width=640, height=480):
    pygame.init()

    size = (width, height)
    screen = pygame.display.set_mode(size)
    pygame.display.set_caption('Checkers in MIPS')

    background = pygame.Surface(screen.get_size())
    background = background.convert()
    background.fill((255, 255, 255))

    return (screen, background)

def update_number(game, newval):
    screen = game[0]
    background = game[1]

    background.fill((255, 255, 255))

    font = pygame.font.Font(None, 36)
    text = font.render(str(newval), 1, (10, 10, 10))
    textpos = text.get_rect()
    textpos.centerx = background.get_rect().centerx
    textpos.centery = background.get_rect().centery

    background.blit(text, textpos)
    screen.blit(background, (0, 0)) 
    pygame.display.update()

    return (screen, background)

def loop(game):
    spim.stdout.readline()
    spim.stdout.readline()
    spim.stdout.readline()
    spim.stdout.readline()
    spim.stdout.readline()

    while True:
        try:
            rdata, __, __ = select.select([spim.stdout.fileno()], [], [], 0.0001)
        except select.error, err:
            print 'Error: %s' % err.args[0]
            return

        if rdata:
            data = spim.stdout.readline()
            print 'Found data: %s' % data
            spim.stdout.flush()
            data = data[:-1]
            game = update_number(game, data)
        else:
            for event in pygame.event.get():
                if event.type == QUIT:
                    print event
                    return
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_RIGHT:
                        spim.stdin.write('1\n')
                    elif event.key == pygame.K_LEFT:
                        spim.stdin.write('0\n')

if __name__ == '__main__':
    game = setup_pygame()
    loop(game)
