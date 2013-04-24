import pygame
import logging
import string

class Button(pygame.sprite.Sprite):
    def __init__(self, screen, btype, pos, text, color1, color2):
        pygame.sprite.Sprite.__init__(self)
        self.btype = btype
        (self.xpos, self.ypos) = pos

        rendering = screen.small_font.render(text, True, color1, color2)
        self.image = pygame.Surface(rendering.get_size())
        self.rect = self.image.get_rect()

        self.image.fill((100, 100, 100))
        self.image.set_colorkey((100, 100, 100))
        self.image.blit(rendering, (0, 0))

    def update(self):
        self.rect.center = (self.xpos, self.ypos)
        
class CheckerPiece(pygame.sprite.Sprite):
    def __init__(self, width, height, xpos, ypos, color):
        pygame.sprite.Sprite.__init__(self)
        self.size = (width, height)
        self.image = pygame.Surface(self.size)
        self.image.fill((100, 100, 100))
        self.image.set_colorkey((100, 100, 100))
        
        self.kinged = False

        self.xpos = xpos
        self.ypos = ypos

        if width < height:
            radius = width/2
        else:
            radius = height/2

        self.shape = pygame.draw.circle(self.image, color, (width/2, height/2), radius, 0)
        self.rect = self.image.get_rect()

    def __repr__(self):
        (width, height) = pygame.display.get_surface().get_size()
        sq_xpos = int(self.xpos // ((width-width/3.05) // 8))
        sq_ypos = 7 - (self.ypos // (height // 8))

        board_space = 8*sq_ypos+sq_xpos
        logging.root.debug("Computer Repr: %d//2" % board_space)
        return str(board_space//2)

    def __str__(self):
        (width, height) = pygame.display.get_surface().get_size()
        sq_xpos = int(self.xpos // ((width-width/3.05) // 8))
        sq_ypos = 7 - (self.ypos // (height // 8))
        board_space = 8*sq_ypos+sq_xpos
        
        xpos = board_space % 8
        ypos = ((board_space) // 8) + 1

        str_pos = string.uppercase[xpos] + str(ypos)
        logging.root.debug("Human Repr: %s" % str_pos)
        return str_pos

    def update(self,pos=None):
        if pos is None:
            self.rect.center = (self.xpos, self.ypos)
        else:
            new_center = self.determine_physical_pos(pos)
            if new_center is not None:
                self.rect.center = new_center
                return True
            else:
                return False

    def get_tile_num(self, pos):
        (xpos, ypos) = pos
        (width, height) = pygame.display.get_surface().get_size()
        sq_xpos = int(xpos // ((width-width/3.05) // 8))
        sq_ypos = 7 - (ypos // (height // 8))
        board_space = 8*sq_ypos+sq_xpos
        return board_space

    def determine_physical_pos(self, pos):
        valid_board = [0, 1, 0, 1, 0, 1, 0, 1,
                       1, 0, 1, 0, 1, 0, 1, 0,
                       0, 1, 0, 1, 0, 1, 0, 1,
                       1, 0, 1, 0, 1, 0, 1, 0,
                       0, 1, 0, 1, 0, 1, 0, 1,
                       1, 0, 1, 0, 1, 0, 1, 0,
                       0, 1, 0, 1, 0, 1, 0, 1,
                       1, 0, 1, 0, 1, 0, 1, 0]

        board_space = self.get_tile_num(pos)

        (width, height) = pygame.display.get_surface().get_size()
        xpos = pos[0]
        ypos = pos[1]
        
        if(xpos >= width-width/3.05 or valid_board[board_space] == 0):
            logging.root.warning("Error with placement position")
            return None

        sq_xpos = (xpos // self.size[0]) * self.size[0]
        sq_ypos = (ypos // self.size[1]) * self.size[1]
        self.xpos = sq_xpos + self.size[0]/2
        self.ypos = sq_ypos + self.size[1]/2
        return (self.xpos, self.ypos)

