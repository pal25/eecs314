import pygame

class CheckerPiece(pygame.sprite.Sprite):
    def __init__(self, width, height, xpos, ypos, color):
        pygame.sprite.Sprite.__init__(self)
        self.image = pygame.Surface((width, height))
        self.image.fill((100, 100, 100))
        self.image.set_colorkey((100, 100, 100))

        self.xpos = xpos
        self.ypos = ypos

        if width < height:
            radius = width/2
        else:
            radius = height/2

        self.shape = pygame.draw.circle(self.image, color, (width/2, height/2), radius, 0)
        self.rect = self.image.get_rect()

    def update(self):
        self.rect.center = (self.xpos, self.ypos)

    def move(self, xpos, ypos):
        self.rect.center = pygame.mouse.get_pos()
