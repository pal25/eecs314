import pygame
import os.path

from constants import *

BLACK = (0, 0, 0)
WHITE = (255, 255, 255)

class GameScreen(object):

    def __init__(self, width=640, height=480, game_board=False):
        self.width = width
        self.height = height
        self.screen = pygame.display.set_mode((width, height))
        self.font = pygame.font.SysFont(None, width*height/5000)
        self.small_font = pygame.font.SysFont(None, width*height/10000)
        self.bg = pygame.Surface(self.screen.get_size())
        self.bg.fill(WHITE)

        if game_board:
            x_size = width/8
            y_size = height/8
            xpos = 0
            ypos = 0
            tile = 0
            for row in range(0,8):
                for column in range(0,8):
                    if tile % 2 == 0:
                        color = BLACK
                    else:
                        color = WHITE
                        
                    pygame.draw.rect(self.bg, color, ((xpos, ypos), (x_size, y_size)))
                    xpos += x_size
                    tile = tile + 1
                    
                tile = tile+1 % 2
                xpos = 0
                ypos += y_size
            
        self.screen.blit(self.bg, (0, 0))            
        pygame.display.flip()

    def draw_pieces(self):
        pass

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
    

        
