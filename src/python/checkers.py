import subprocess, select, os.path
import pygame

START_MENU = 0
IN_PROGRESS = 1
VICTORY = 0

spim = subprocess.Popen(['spim', '-file', 'test.s'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

class GameBoard():
    def __init__(self, size=None, width=640, height=480, image='background.png'):
        if size:
            self.size = size
        else:
            self.size = (width, height)
        
        self.screen = pygame.display.set_mode(self.size, pygame.RESIZABLE)
        self.background = self.load_image(image)
        pygame.display.set_caption('Checkers in MIPS')
        self.draw_board()
        
    def load_image(self, filename):
        filename = os.path.join('images', filename)

        try:
            image = pygame.image.load(filename)
        except pygame.error, errmsg:
            print 'Cannot load background image: ', filename
            raise SystemError, errmsg

        return image

    def draw_board(self):
        self.screen = pygame.display.set_mode(self.size, pygame.RESIZABLE)
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

def main(board):
    STATE = START_MENU

    while True:
        try:
            rdata, __, __ = select.select([spim.stdout.fileno()], [], [], 0.0001)
        except select.error, err:
            print 'Error: %s' % err.args[0]
            return

        if rdata:
            data = spim.stdout.readline()
            spim.stdout.flush()
            data = data[:-1]
            print 'Found data: ', data
        
        elif STATE is IN_PROGRESS:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    print event
                    return
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_RIGHT:
                        spim.stdin.write('1\n')
                    elif event.key == pygame.K_LEFT:
                        spim.stdin.write('0\n')
                elif event.type == pygame.VIDEORESIZE:
                    board.size = event.size
                    board.draw_board()
        
        elif STATE is START_MENU:
            LEFT = 0
            RIGHT = 1
            NO_CHOICE = 3

            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    print event
                    return
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_LEFT:
                        print 'Selecting One Player'
                        board = GameBoard(board.size, image='basic_intro_p1.bmp')
                    elif event.key == pygame.K_RIGHT:
                        print 'Selecting Two Player'
                        board = GameBoard(board.size, image='basic_intro_p2.bmp')
                    elif event.key == pygame.K_RETURN:
                        STATE = IN_PROGRESS
                        board = GameBoard(board.size, image='background.png')
                        print 'Made a selection'
                elif event.type == pygame.VIDEORESIZE:
                    board.size = event.size
                    board.draw_board()
        
        else:
            pass
        

if __name__ == '__main__':
    spim.stdout.readline()
    spim.stdout.readline()
    spim.stdout.readline()
    spim.stdout.readline()
    spim.stdout.readline()
    spim.stdout.flush()

    pygame.init()
    init_board = GameBoard(width=264, height=264, image='basic_intro_none.bmp')
    main(init_board)
