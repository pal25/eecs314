import pygame

class CheckerPiece(pygame.sprite.Sprite):
    def __init__(self, width, height, color):
        pygame.sprite.Sprite.__init__(self)
        self.imagebg = pygame.Surface((width, height))
        self.imagebg.set_alpha(255)

        if width < height:
            radius = width/2
        else:
            radius = height/2

        self.image = pygame.draw.circle(self.imagebg, color, (width/2, height/2), radius, 0)

    def update(self):
        pass

    def move(self, xpos, ypos):
        
