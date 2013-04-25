import pygame
import sys, subprocess, select

from constants import *
from screen import GameScreen, MenuScreen
from checker_sprites import CheckerPiece

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

        while not self.exiting:
            self.screen = MenuScreen(width, height)
            logging.root.info("State: Menu")
            self.menu()

            self.screen = GameScreen(width, height)
            logging.root.info("State: Game")
            self.run()

    def read_spim(self):
        data = None

        try:
            rdata, __, __ = select.select([spim.stdout.fileno()], [], [], 0.0001)
        except select.error as err:
            logging.root.error("Error: %s" % err.args[0])
            raise

        if rdata:
            data = spim.stdout.readline()
            spim.stdout.flush()
            data = data[:-1] # remove newline
            logging.root.debug("Found Data: %s" % data)
        
        return data

    def parse_data(self, data):
        pass

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
                        spim.stdin.write(str(self.player_num) + "\n") #Determines AI/P2
                        self.running = True
                    elif event.key == pygame.K_ESCAPE:
                        self.exiting = True
                        return
                elif event.type == pygame.QUIT:
                    self.exiting = True
                    return
                   
            p1 = "One Player"
            p2 = "Two Player"
            if self.player_num == 1:
                p1 = "[ " + p1 + " ]"
            elif self.player_num == 2:
                p2 = "[ " + p2 + " ]"

            self.screen.draw_choices(p1, p2)
            pygame.display.flip()
            self.clock.tick(FPS)

    def run(self):
        state = P1_MOVE
        state_changed = True
        logging.root.info("State: P1_MOVE")

        while self.running:
            for event in pygame.event.get([pygame.QUIT, pygame.KEYDOWN]):
                if event.type == pygame.QUIT:
                    self.exiting = True
                    return
                    quit_game()
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        self.exiting = True
                        return
                        quit_game()

            if state_changed:
                self.screen.draw_board()
                self.screen.draw_pieces(self.screen.state)
                pygame.display.flip()
                state_changed = False

            if state == P1_MOVE:
                for event in pygame.event.get():
                    if event.type == pygame.MOUSEBUTTONUP:
                        pos = pygame.mouse.get_pos()
                        for sprite in self.screen.button_group:
                            if sprite.rect.collidepoint(pygame.mouse.get_pos()):
                                logging.root.debug("Button clicked")
                                if sprite.btype == END_OF_TURN:
                                    spim.stdin.write(str(END_OF_TURN) + "\n")
                                    if self.player_num == 2:
                                        state = P2_MOVE
                                        self.screen.draw_window(turn="Blacks Turn")
                                        pygame.display.flip()
                                        logging.root.info("State: P2_MOVE")
                                    else:
                                        state = P2_AI
                
                                elif sprite.btype == RESTART:
                                    spim.stdin.write(str(RESTART) + "\n")
                                    Game() #pop a game on the stack
                                    self.exiting = True
                                    return
                                
                        for sprite in self.screen.p1_group: 
                            if sprite.rect.collidepoint(pos):
                                logging.root.debug("Adding p1 sprite to move group")
                                self.current_piece = sprite
                                state = P1_MOVE_CLICKED
                                logging.root.info("State: P1_MOVE_CLICKED")
                        
            elif state == P1_MOVE_CLICKED:
                for event in pygame.event.get():
                    if event.type == pygame.MOUSEBUTTONUP:
                        self.current_piece.update(pygame.mouse.get_pos())
                        logging.root.debug("P1 piece placed")
                        state = P1_VALIDATE
                        logging.root.info("State: P1_VALIDATE")

                        self.screen.p1_group.clear(self.screen.screen, self.screen.bg)
                        self.screen.p1_group.draw(self.screen.screen)
                        self.screen.p2_group.draw(self.screen.screen)
                        pygame.display.flip()

            elif state == P1_VALIDATE:
                pos = (self.current_piece.old_xpos, self.current_piece.old_ypos)
                spim.stdin.write(self.current_piece.print_boardpos(pos) + "\n")
                pos = (self.current_piece.xpos, self.current_piece.ypos)
                spim.stdin.write(self.current_piece.print_boardpos(pos) + "\n")
                data = self.read_spim()
                if data:
                    state = P1_MOVE
                    state_changed = True
                    logging.root.info("State: P1_MOVE")
                    
            elif state == P2_AI:
                self.screen.draw_window(turn="Waiting for AI...")
                pygame.display.flip()
                
                data = None
                while data is None:
                    data = self.read_spim()
                #self.screen.state = self.parse_data(data)
                
                state = P1_MOVE
                state_changed = True
                self.screen.draw_window(turn="Reds Turn")
                pygame.display.flip()
                
            elif state == P2_MOVE:
                for event in pygame.event.get():
                    if event.type == pygame.MOUSEBUTTONUP:
                        pos = pygame.mouse.get_pos()

                        for sprite in self.screen.button_group:
                            if sprite.rect.collidepoint(pos):
                                logging.root.debug("Button clicked")
                                if sprite.btype == END_OF_TURN:
                                    spim.stdin.write(str(END_OF_TURN) + "\n")
                                    self.screen.draw_window(turn="Reds Turn")
                                    pygame.display.flip()
                                    state = P1_MOVE
                                    logging.root.info("State: P1_MOVE")                                    
                                elif sprite.btype == RESTART:
                                    spim.stdin.write(str(RESTART) + "\n")
                                    Game() #pop a game on the stack
                                    self.exiting = True
                                    return

                        for sprite in self.screen.p2_group: 
                            if sprite.rect.collidepoint(pos):
                                logging.root.debug("Adding p2 sprite to move group")
                                self.current_piece = sprite
                                state = P2_MOVE_CLICKED
                                logging.root.info("State: P2_MOVE_CLICKED")
                        
            elif state == P2_MOVE_CLICKED:
                for event in pygame.event.get():
                    if event.type == pygame.MOUSEBUTTONUP:
                        self.current_piece.update(pygame.mouse.get_pos())
                        logging.root.debug("P2 piece placed")
                        state = P2_VALIDATE
                        logging.root.info("State: P2_VALIDATE")
                        
                        self.screen.p2_group.clear(self.screen.screen, self.screen.bg)
                        self.screen.p2_group.draw(self.screen.screen)
                        self.screen.p1_group.draw(self.screen.screen)
                        pygame.display.flip()
            
            elif state == P2_VALIDATE:
                pos = (self.current_piece.old_xpos, self.current_piece.old_ypos)
                spim.stdin.write(self.current_piece.print_boardpos(pos) + "\n")
                pos = (self.current_piece.xpos, self.current_piece.ypos)
                spim.stdin.write(self.current_piece.print_boardpos(pos) + "\n")

                data = self.read_spim()
                if data:
                    state = P2_MOVE
                    state_changed = True
                    logging.root.info("State: P2_MOVE")

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
    
    try:
        game = Game()
    except SystemExit:
        pass
    except:
        logging.root.error("Checkers encountered an error")
        raise
    finally:
        logging.root.info("Quitting Game")
        spim.kill()
        pygame.display.quit()
        
if __name__ == "__main__":
    main()
    

    
