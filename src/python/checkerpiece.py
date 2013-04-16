import pygame

class CheckerPiece(pygame.sprite.Sprite):
    def __init__(self):
        pygame.sprite.Sprite.__init__(self)
        self.image = load_image('button.jpg')

    def update(self):
        pass
