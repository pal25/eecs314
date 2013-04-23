import pygame
import logging
import string

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

    def update(self, pos=None):
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
        (width, height) = pygame.display.get_surface().get_size()
        board_space = self.get_tile_num((self.xpos, self.ypos))

        even = None
        if int(board_space) % 2 == 0:
            even = True
            logging.root.debug("Even previous position: %d" % board_space)
        else:
            even = False
            logging.root.debug("Odd previous position: %d" % board_space)

        xpos = pos[0]
        ypos = pos[1]
        
        if(xpos >= width-width/3.05):
            logging.root.warning("Error with placement position")
            return None

        sq_xpos = (xpos // self.size[0]) * self.size[0]
        sq_ypos = (ypos // self.size[1]) * self.size[1]
        xpos = sq_xpos + self.size[0]/2
        ypos = sq_ypos + self.size[1]/2
        
        board_space = self.get_tile_num((xpos, ypos))
        if (int(board_space) % 2 == 0) and not even:
            self.xpos = xpos
            self.ypos = ypos
            logging.root.debug("Even current position: %d" % board_space)
            return (self.xpos, self.ypos)
        elif (int(board_space) % 2 != 0) and even:
            self.xpos = xpos
            self.ypos = ypos
            logging.root.debug("Odd current position: %d" % board_space)
            return (self.xpos, self.ypos)
        else:
            logging.root.debug("Invalid placement")
            return None
