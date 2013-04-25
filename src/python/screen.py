import pygame
import os.path
import logging

from constants import *
from checker_sprites import CheckerPiece, Button

class GenericScreen(object):
    def __init__(self, width=800, height=640):
        self.width = width
        self.height = height
        self.screen = pygame.display.set_mode((width, height))
        self.font = pygame.font.SysFont(None, width*height/5000)
        self.small_font = pygame.font.SysFont(None, width*height/10000)
        self.bg = pygame.Surface((self.width, self.height))
        self.bg.fill(WHITE)

    def draw_text(self, text, color1, color2, xpos, ypos):
        rendering = self.font.render(text, True, color1, color2)
        self.screen.blit(rendering, (xpos-rendering.get_width()/2, ypos))

    def draw_text_small(self, text, color1, color2, xpos, ypos):
        rendering = self.small_font.render(text, True, color1, color2)
        self.screen.blit(rendering, (xpos-rendering.get_width()/2, ypos))


class MenuScreen(GenericScreen):
    def __init__(self, width=800, height=640):
        GenericScreen.__init__(self, width, height)
        self.bg = pygame.Surface(pygame.display.get_surface().get_size())
        self.bg.fill(WHITE)
        self.screen.blit(self.bg, (0, 0))

        title = "Checkers in MIPS!"
        self.draw_text(title, BLACK, WHITE, self.width/2, self.height*1/5)
        self.draw_choices("One Player", "Two Player")
        pygame.display.flip()

    def draw_choices(self, choice1, choice2):
        erase_bg = pygame.Surface((self.width, self.height-self.height*3/5))
        erase_bg.fill(WHITE)
        self.screen.blit(erase_bg, (0, self.height*3/5))
        
        self.draw_text_small(choice1, BLACK, WHITE, self.width/2, self.height*3/5)
        self.draw_text_small(choice2, BLACK, WHITE, self.width/2, self.height*4/5)
        

class GameScreen(GenericScreen):
    def __init__(self, width=800, height=640):
        GenericScreen.__init__(self, width, height)

        self.xwin = self.width/3.05
        self.ywin = self.height
        self.bg = pygame.Surface((self.width-(self.width/3), self.height))
        self.bg.fill(WHITE)

        self.state = [1, 0, 1, 0, 1, 0, 1, 0,
                      0, 1, 0, 1, 0, 1, 0, 1,
                      1, 0, 1, 0, 1, 0, 1, 0,
                      0, 0, 0, 0, 0, 0, 0, 0,
                      0, 0, 0, 0, 0, 0, 0, 0,
                      0, 2, 0, 2, 0, 2, 0, 2,
                      2, 0, 2, 0, 2, 0, 2, 0,
                      0, 2, 0, 2, 0, 2, 0, 2]

        self.p1_group = pygame.sprite.Group()
        self.p2_group = pygame.sprite.Group()
        self.button_group = pygame.sprite.Group()

        self.draw_board()
        self.draw_pieces(self.state)
        self.draw_window()
        pygame.display.flip()
        
    def draw_window(self, turn="Reds Turn"):
        self.win_size = (self.width/3.05, self.height)
        self.win_pos = (self.width-self.width/3.05, 0)
        self.win_center_width = self.width-(self.width/3.05)/2

        winbg = pygame.Surface((self.width/3.05, self.height))
        winbg.fill(WHITE)
        self.screen.blit(winbg, (self.width-self.width/3.05, 0))

        self.draw_text_small(turn, BLACK, WHITE, self.width-(self.width/3.05)/2, self.height*1/20)

        self.button_group = pygame.sprite.Group()

        pos = (self.win_center_width, self.height*15/20)
        self.button_group.add(Button(self, RESTART, pos, "Restart", WHITE, BLACK))
        pos = (self.win_center_width, self.height*18/20)
        self.button_group.add(Button(self, END_OF_TURN, pos, "End Turn", WHITE, BLACK))

        self.button_group.update()
        self.button_group.draw(self.screen)

    def draw_board(self):
        self.bg.fill(BLACK)
        x_size = (self.width-(self.width/3))/8
        y_size = self.height/8
        xpos = 0
        ypos = 0
        tile = 0
        
        for row in range(0,8):
            for column in range(0,8):
                if tile % 2 == 0:
                    color = DIRTY_RED
                else:
                    color = WHITE
                    
                pygame.draw.rect(self.bg, color, ((xpos, ypos), (x_size, y_size)))

                xpos += x_size
                tile = tile + 1
                    
            tile = tile+1 % 2
            xpos = 0
            ypos += y_size

        self.screen.blit(self.bg, (0, 0))  

    def draw_pieces(self, state):
        x_size = (self.width-(self.width/3))/8
        y_size = self.height/8
        xpos = 0
        ypos = 0
        tile = 0

        self.p1_group = pygame.sprite.Group()
        self.p2_group = pygame.sprite.Group()
        
        for row in range(0,8):
            for column in range(0,8):
                if tile % 2 == 0:
                    color = DIRTY_RED
                else:
                    color = WHITE
                    
                if state[row*8+column] == 1:
                    self.p1_group.add(CheckerPiece(x_size, y_size, xpos+x_size/2, ypos+y_size/2, RED))
                elif state[row*8+column] == 2:
                    self.p2_group.add(CheckerPiece(x_size, y_size, xpos+x_size/2, ypos+y_size/2, BLACK))
                    
                xpos += x_size
                tile = tile + 1
                    
            tile = tile+1 % 2
            xpos = 0
            ypos += y_size

        self.p1_group.update()
        self.p1_group.clear(self.screen, self.bg)
        self.p1_group.draw(self.screen)

        self.p2_group.update()
        self.p2_group.clear(self.screen, self.bg)
        self.p2_group.draw(self.screen)


    
        
