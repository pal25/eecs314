import pygame

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

    def update(self, pos=None):
        if pos is None:
            self.rect.center = (self.xpos, self.ypos)
        else:
            self.rect.center = self.determine_pos(pos)

    def determine_pos(self, pos):
        xpos = pos[0]
        ypos = pos[1]
        
        sq_xpos = (xpos // self.size[0]) * self.size[0]
        sq_ypos = (ypos // self.size[1]) * self.size[1]

        self.xpos = sq_xpos + self.size[0]/2
        self.ypos = sq_ypos + self.size[1]/2
        
        return (self.xpos, self.ypos)
