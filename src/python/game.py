import pygame
from screen import GameScreen
import sys, subprocess, select

FPS = 30

spim = subprocess.Popen(['spim', '-file', 'test.s'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

class Game(object):
    
    def __init__(self, width=640, height=480):
        self.width = width
        self.height = height

        self.victory = False
        self.running = False
        self.exiting = False
        self.player_num = 1
        self.clock = pygame.time.Clock()

        while True:
            self.screen = GameScreen(width, height, False)
            self.menu()
            self.screen = GameScreen(width, height, True)
            self.run()

    def menu(self):
        while not self.running:
            for event in pygame.event.get():
                if event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_UP:
                        print "Choosing One Player"
                        self.player_num = 1
                    elif event.key == pygame.K_DOWN:
                        print "Choosing Two Player"
                        self.player_num = 2
                    elif event.key == pygame.K_RETURN:
                        print "Chosing Return Value"
                        self.running = True
                    elif event.key == pygame.K_ESCAPE:
                        print"Quitting Game"
                        quit_game()
                elif event.type == pygame.QUIT:
                    print "Quitting Game"
                    quit_game()
                   
            p1 = "One Player"
            p2 = "Two Player"
            if self.player_num == 1:
                p1 = "[ " + p1 + " ]"
            elif self.player_num == 2:
                p2 = "[ " + p2 + " ]"

            self.screen.draw_menu(p1, p2)
            self.clock.tick(FPS)

    def run(self):
        while self.running:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    print "Quitting Game"
                    quit_game()
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        print"Quitting Game"
                        quit_game()
            
            self.clock.tick(FPS)
def main():
    pygame.init()
    pygame.display.set_caption('Checkers in MIPS')
    pygame.event.set_allowed([pygame.QUIT, pygame.KEYDOWN])
    
    game = Game()

def quit_game():
    sys.exit()

if __name__ == "__main__":
    main()
    

    
