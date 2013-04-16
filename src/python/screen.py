import pygame
import os.path

from constants import *

class GameScreen(object):

    def __init__(self, width=640, height=480, game_board=False):
        self.width = width
        self.height = height
        self.screen = pygame.display.set_mode((width, height))
        self.font = pygame.font.SysFont(None, width*height/5000)
        self.small_font = pygame.font.SysFont(None, width*height/10000)
        self.bg = pygame.Surface(self.screen.get_size())
        self.bg.fill(WHITE)

        self.state = [1, 0, 1, 0, 1, 0, 1, 0,
                              0, 1, 0, 1, 0, 1, 0, 1,
                              1, 0, 1, 0, 1, 0, 1, 0,
                              0, 0, 0, 0, 0, 0, 0, 0,
                              0, 0, 0, 0, 0, 0, 0, 0,
                              0, 2, 0, 2, 0, 2, 0, 2,
                              2, 0, 2, 0, 2, 0, 2, 0,
                              0, 2, 0, 2, 0, 2, 0, 2]

        if game_board:
            self.draw_pieces(self.state)
        
        
    def draw_pieces(self, state):
        self.bg.fill(WHITE)
        x_size = self.width/8
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

                if state[row*8+column] == 1:
                    pygame.draw.circle(self.bg, RED, (xpos+x_size/2, ypos+y_size/2), y_size/2, 0)
                elif state[row*8+column] == 2:
                    pygame.draw.circle(self.bg, BLACK, (xpos+x_size/2, ypos+y_size/2), y_size/2, 0)

                xpos += x_size
                tile = tile + 1
                    
            tile = tile+1 % 2
            xpos = 0
            ypos += y_size

        self.screen.blit(self.bg, (0, 0))            
        pygame.display.flip()


    def draw_text(self, text, color1, color2, xpos, ypos):
        rendering = self.font.render(text, True, color1, color2)
        
        self.screen.blit(rendering, (xpos-rendering.get_width()/2, ypos))

    def draw_text_small(self, text, color1, color2, xpos, ypos):
        rendering = self.small_font.render(text, True, color1, color2)
        self.screen.blit(rendering, (xpos-rendering.get_width()/2, ypos))

    def draw_menu(self, choice1, choice2):
        self.screen.blit(self.bg, (0, 0))

        title = "Checkers in MIPS!"
        self.draw_text(title, BLACK, WHITE, self.width/2, self.height*1/5)
        self.draw_text_small(choice1, BLACK, WHITE, self.width/2, self.height*3/5)
        self.draw_text_small(choice2, BLACK, WHITE, self.width/2, self.height*4/5)

        pygame.display.flip()
    

        
