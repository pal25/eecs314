import pygame
import os.path

def load_image(filename):
    filename = os.path.join('images', filename)
    try:
        image = pygame.image.load(filename)
    except pygame.error, errmsg:
        print 'Cannot load background image: ', filename
        raise SystemError, errmsg
    return image.convert()
