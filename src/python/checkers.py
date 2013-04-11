import subprocess, select, os.path
import pygame

spim = subprocess.Popen(['spim', '-file', 'test.s'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

class GameBoard():
    def __init__(self, width=640, height=480):
        self.size = (width, height)
        self.screen = pygame.display.set_mode(self.size, pygame.RESIZABLE)
        pygame.display.set_caption("Checkers in MIPS")
        
        colorbg = pygame.Surface(self.size).convert()
        colorbg.fill((255, 255, 255))
        self.screen.blit(colorbg, (0, 0))
        self.background = self.load_image("background.png")

    def load_image(self, filename):
        filename = os.path.join('images', filename)

        try:
            image = pygame.image.load(filename)
        except pygame.error, errmsg:
            print 'Cannot load background image: ', filename
            raise SystemError, errmsg

        return image

    def draw_board(self):
        self.background = pygame.transform.scale(self.background, self.size)

        colorbg = pygame.Surface(self.size).convert()
        colorbg.fill((255, 255, 255))

        self.screen.blit(colorbg, (0, 0))
        self.screen.blit(self.background, self.background.get_rect())
        pygame.display.update()

class CheckerPiece(pygame.sprite.Sprite):
    def __init__(self, player=1):
        pygame.sprint.Sprint.__init__(self)
        screen = pygame.display.get_surface()
        
        if player == 1:
            self.image, self.rect = self.load_image('black_piece.bmp')
        else:
            self.image, self.rect = self.load_image('red_piece.bmp')
        
        self.player = player
        self.piece_type = "pawn"

        self.rect.centerx = centerx
        self.rect.centery = centery
        self.area = pygame.display.get_surface()

    def load_image(self, filename):
        filename = os.path.join('images', filename)

        try:
            image = pygame.image.load(filename)
            image.set_colorkey(brown)
        except pygame.error, errmsg:
            print 'Cannot load background image: ', filename
            raise SystemError, errmsg

    def update(self):
        newpos = move(self.rect)
        pass
        
    def move(self):        
        pass

def update_number(board, newval):
    font = pygame.font.Font(None, 36)
    text = font.render(str(newval), 1, (10, 10, 10))
    textpos = text.get_rect()
    textpos.centerx = board.background.get_rect().centerx
    textpos.centery = board.background.get_rect().centery

    board.background.blit(text, textpos)
    board.screen.blit(board.background, (0, 0)) 
    
    board.draw_board()
    return board

def main(board):
    spim.stdout.readline()
    spim.stdout.readline()
    spim.stdout.readline()
    spim.stdout.readline()
    spim.stdout.readline()

    while True:
        try:
            rdata, __, __ = select.select([spim.stdout.fileno()], [], [], 0.0001)
        except select.error, err:
            print 'Error: %s' % err.args[0]
            return

        if rdata:
            data = spim.stdout.readline()
            print 'Found data: %s' % data
            spim.stdout.flush()
            data = data[:-1]
            board = update_number(board, data)
        else:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    print event
                    return
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_RIGHT:
                        spim.stdin.write('1\n')
                    elif event.key == pygame.K_LEFT:
                        spim.stdin.write('0\n')

if __name__ == '__main__':
    pygame.init()
    init_board = GameBoard(width=132, height=132)
    main(init_board)
