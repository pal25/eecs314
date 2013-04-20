import pygame
import sys, subprocess, select

from constants import *
from screen import GameScreen
from checkerpiece import CheckerPiece

import logging
import logging.config

spim = subprocess.Popen(['spim', '-file', 'test.s'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

class Game(object):
    
    def __init__(self, width=640, height=480):
        self.width = width
        self.height = height

        self.victory = False
        self.running = False
        self.exiting = False
        self.player_num = 1
        self.current_piece = pygame.sprite.GroupSingle()
        self.clock = pygame.time.Clock()

        self.read_spim()
        self.read_spim()
        self.read_spim()
        self.read_spim()
        self.read_spim()
        self.read_spim()

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
                        logging.root.debug("Choosing One Player")
                        self.player_num = 1
                    elif event.key == pygame.K_DOWN:
                        logging.root.debug("Choosing Two Player")
                        self.player_num = 2
                    elif event.key == pygame.K_RETURN:
                        logging.root.debug("Chosing Return Value")
                        self.running = True
                    elif event.key == pygame.K_ESCAPE:
                        quit_game()
                elif event.type == pygame.QUIT:
                    quit_game()
                   
            p1 = "One Player"
            p2 = "Two Player"
            if self.player_num == 1:
                p1 = "[ " + p1 + " ]"
            elif self.player_num == 2:
                p2 = "[ " + p2 + " ]"

            self.screen.draw_menu(p1, p2)
            self.clock.tick(FPS)

    def read_spim(self):
        data = None

        try:
            rdata, __, __ = select.select([spim.stdout.fileno()], [], [], 0.0001)
        except select.error, err:
            logging.root.error("Error: %s" % err.args[0])
            quit_game()

        if rdata:
            data = spim.stdout.readline()
            spim.stdout.flush()
            data = data[:-1] # remove newline
            logging.root.debug("Found Data: %s" % data)
        
        return data

    def parse_data(self, data):
        pass

    def run(self):
        state = P1_MOVE

        while self.running:
            for event in pygame.event.get([pygame.QUIT, pygame.KEYDOWN]):
                if event.type == pygame.QUIT:
                    quit_game()
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        quit_game()

            if state == P1_MOVE:
                for event in pygame.event.get():
                    if event.type == pygame.MOUSEBUTTONUP:
                        pos = pygame.mouse.get_pos()
                        for sprite in self.screen.p1_group: 
                            if sprite.rect.collidepoint(pos):
                                logging.root.debug("Adding p1 sprite to move group")
                                self.current_piece = sprite
                                state = P1_MOVE_CLICKED

            elif state == P1_MOVE_CLICKED:
                for event in pygame.event.get():
                    if event.type == pygame.MOUSEBUTTONUP:
                        logging.root.debug("P1 piece placed")
                        state = P1_VALIDATE
                        self.current_piece.update(pygame.mouse.get_pos())
                        self.screen.p1_group.clear(self.screen.screen, self.screen.bg)
                        self.screen.p1_group.draw(self.screen.screen)
                        self.screen.p2_group.draw(self.screen.screen)
                        pygame.display.flip()
                        
            elif state == P1_VALIDATE:
                logging.root.debug("Validating p1 move")
                state = P2_MOVE
                data = self.read_spim()
                if data:
                    print "Data"

            elif state == P2_MOVE:
                for event in pygame.event.get():
                    if event.type == pygame.MOUSEBUTTONUP:
                        pos = pygame.mouse.get_pos()
                        for sprite in self.screen.p2_group: 
                            if sprite.rect.collidepoint(pos):
                                logging.root.debug("Adding p2 sprite to move group")
                                self.current_piece = sprite
                                state = P2_MOVE_CLICKED

            elif state == P2_MOVE_CLICKED:
                for event in pygame.event.get():
                    if event.type == pygame.MOUSEBUTTONUP:
                        logging.root.debug("P2 piece placed")
                        state = P2_VALIDATE
                        self.current_piece.update(pygame.mouse.get_pos())
                        self.screen.p2_group.clear(self.screen.screen, self.screen.bg)
                        self.screen.p2_group.draw(self.screen.screen)
                        self.screen.p1_group.draw(self.screen.screen)
                        pygame.display.flip()

            elif state == P2_VALIDATE:
                logging.root.debug("Validating p2 move")
                state = P1_MOVE
                data = self.read_spim()
                if data:
                    print "Data"

            self.clock.tick(FPS)


def main():
    logging.config.fileConfig("logging.conf")
    logging.root.setLevel("DEBUG")

    pygame.init()
    pygame.display.set_caption('Checkers in MIPS')
    pygame.event.set_allowed([pygame.QUIT, 
                              pygame.KEYDOWN, 
                              pygame.MOUSEBUTTONUP, 
                              pygame.MOUSEBUTTONDOWN, 
                              pygame.MOUSEMOTION])
    
    game = Game()

def quit_game():
    logging.root.warning("Quitting Game")
    sys.exit()

if __name__ == "__main__":
    main()
    

    
