.data
#internal variables
victory: .byte 0
valid: .byte 0
jorm: .byte 0
isai: .byte 0

#data structure for gameboard
#for color, 0 is p1, 1 is p2
b_haspiece: .word 0
b_color: .word 0
b_rank: .word 0

#input codes
eom: .byte 100
reset: .byte 101
invalidspace: .byte 102

#output codes (errors)
invalidmove: .byte 200
newline: .asciiz "\n"

.text
#s0 register helps in return
#s1 register used for "from" space
#s2 register used for "to" space
#also use t0-t3
main:
newgame:

    #get bit of AI choice
    li $v0, 5
    syscall
    sb $v0, isai

    #initboard procedure
    #init the "haspiece" datastructure
    #we only can use 16-bits in immediate instructions
    la $t0, b_haspiece
    addi $t1, 4095 
    sll $t1, $t1, 20
    ori $t1, $t1, 4095
    sw $t1, ($t0)
    
    #init the "color" datastructure
    la $t0, b_color
    addi $t1, $zero, 4095
    sw $t1, ($t0)
    
    #init the "rank" datastructure
    la $t0, b_rank
    add $t1, $zero, $zero
    sw $t1, ($t0)
  
    p1:
        #get message for move
        li $v0, 5
        syscall
        move $s1, $v0

        #check for end of message, end turn if yes
        la $t0, eom
        lb $t0, ($t0)
        beq $s1, $t0, endp1
        
        #check for reset, jump to newgame if yes 
        la $t0, reset
        lb $t0, ($t0)
        beq $s1, $t0, newgame
        
        #movements come in pairs, so if the message wasn't "end of turn", it must be the space moving to
        li $v0, 5
        syscall
        move $s2, $v0
   
        #validate the move 
        jal validatep1

        la $t0, valid
        lb $t0, ($t0)
        bne $t0, $zero, validp1
        #send "invalid move message" to python
        li $v0, 1
        la $t0, invalidmove
        lb $a0, ($t0)
        syscall
        li $v0, 4
        la $t0, newline
        lw $a0, ($t0)
        j p1

        validp1:
        jal updateboard

    endp1:
    jal victorychk
    la $t0, victory
    lb $t0, ($t0)
    beq $t0, $zero, p1

    #!send p1 win message to python

    #if AI enabled, jump to AI
    la $t0, isai
    lb $t0, ($t0)
    bne $zero, $t0, ai

    p2:
        #get message for move
        li $v0, 5
        syscall
        move $s1, $v0

        #check for end of message, end turn if yes
        la $t0, eom
        lb $t0, ($t0)
        beq $s1, $t0, endp2
        
        #check for reset, jump to newgame if yes 
        la $t0, reset
        lb $t0, ($t0)
        beq $s1, $t0, newgame
        
        #!check for invalid space selection

        #movements come in pairs, so if the message wasn't "end of turn", it must be the space moving to
        li $v0, 5
        syscall
        move $s2, $v0
    
        jal validateP2

        la $t0, valid
        lb $t0, ($t0)
        bne $t0, $zero, validp2
        #send "invalid move message" to python
        li $v0, 1
        la $t0, invalidmove
        lb $a0, ($t0)
        syscall
        li $v0, 4
        la $t0, newline
        lw $a0, ($t0)
        j p2

        validp2:
        
        jal update_board
        
	endp2:
    jal victorychk
    la $t0, victory
    lb $t0, ($t0)
    beq $t0, $zero, p1

    #!send p2 win message to python
    j newgame

    ai:
	
    endai:
	j p1

validatep1:

    #move return address to s0 to allow jal calls in this function
    move $s0, $ra

    #default valid to 0
    la $t0, valid
    sb $zero, ($t0)

    #if the "to" space is coded as invalid, don't allow a move to it
    la $t0, invalidspace
    lb $t0, ($t0)
    beq $s2, $t0, endvalidatep1 
    
    #if the piece is on the botton of the board, it can't move down
    add $t0, $zero, $zero
    beq $s1, $t0, kingmovep1
    addi $t0, $zero, 1
    beq $s1, $t0, kingmovep1
    addi $t0, $zero, 1
    beq $s1, $t0, kingmovep1
    addi $t0, $zero, 1
    beq $s1, $t0, kingmovep1

    jal validatedownsidemove
    
    #if the piece is on the side, jump to kingmove, else, validatedownmove
    add $t0, $zero, $zero
    addi $t0, $zero, 4
    beq $s1, $t0, kingmovep1
    addi $t0, $zero, 7
    beq $s1, $t0, kingmovep1
    addi $t0, $zero, 1
    beq $s1, $t0, kingmovep1
    addi $t0, $zero, 7
    beq $s1, $t0, kingmovep1
    addi $t0, $zero, 1
    beq $s1, $t0, kingmovep1
    addi $t0, $zero, 7
    beq $s1, $t0, kingmovep1
    addi $t0, $zero, 1
    beq $s1, $t0, kingmovep1
    
    jal validatedownmove
    
    #if a pawn move isn't valid, see if a king move is
    kingmovep1:

    #see if the "from" space has a king, store in t0
    la $t0, b_rank
    lw $t0, ($t0)
    #shift the array of pieces to the right, so that the "from" space bit is in the LSB position
    srlv $t0, $t0, $s1
    andi $t0, $t0, 1
    
    #if the piece is on the top of the board, it can't move up
    add $t0, $zero, $zero
    addi $t0, $zero, 28
    beq $s1, $t0, endvalidatep1
    addi $t0, $zero, 1
    beq $s1, $t0, endvalidatep1
    addi $t0, $zero, 1
    beq $s1, $t0, endvalidatep1
    addi $t0, $zero, 1
    beq $s1, $t0, endvalidatep1
    
    jal validateupsidemove
    
    #if the piece is on the side, validateupmove, else, jump to endofvalidate
    add $t0, $zero, $zero
    addi $t0, $zero, 3
    beq $s1, $t0, endvalidatep1
    addi $t0, $zero, 1
    beq $s1, $t0, endvalidatep1
    addi $t0, $zero, 7
    beq $s1, $t0, endvalidatep1
    addi $t0, $zero, 1
    beq $s1, $t0, endvalidatep1
    addi $t0, $zero, 7
    beq $s1, $t0, endvalidatep1
    addi $t0, $zero, 1
    beq $s1, $t0, endvalidatep1
    addi $t0, $zero, 7
    beq $s1, $t0, endvalidatep1
    
    jal validateupmove

    endvalidatep1:
    jr $s0

validatep2:

    #move return address to s0 to allow jal calls in this function
    move $s0, $ra

    #default valid to 0
    la $t0, valid
    sb $zero, ($t0)
    
    #if the "to" space is coded as invalid, don't allow a move to it
    la $t0, invalidspace
    lb $t0, ($t0)
    beq $s2, $t0, endvalidatep2 
    
    #if the piece is on the top of the board, it can't move up
    add $t0, $zero, $zero
    addi $t0, $zero, 28
    beq $s1, $t0, kingmovep2
    addi $t0, $zero, 1
    beq $s1, $t0, kingmovep2
    addi $t0, $zero, 1
    beq $s1, $t0, kingmovep2
    addi $t0, $zero, 1
    beq $s1, $t0, kingmovep2

    jal validateupsidemove
    
    #if the piece is on the side, jump to kingmove, else, validateupmove
    add $t0, $zero, $zero
    addi $t0, $zero, 3
    beq $s1, $t0, kingmovep2
    addi $t0, $zero, 1
    beq $s1, $t0, kingmovep2
    addi $t0, $zero, 7
    beq $s1, $t0, kingmovep2
    addi $t0, $zero, 1
    beq $s1, $t0, kingmovep2
    addi $t0, $zero, 7
    beq $s1, $t0, kingmovep2
    addi $t0, $zero, 1
    beq $s1, $t0, kingmovep2
    addi $t0, $zero, 7
    beq $s1, $t0, kingmovep2
    
    jal validateupmove

    #if a pawn move isn't valid, see if a king move is
    kingmovep2:

    #see if the piece's square has a king, store in t0
    la $t0, b_rank
    lw $t0, ($t0)
    #shift the array of pieces to the right, so that the "from" space bit is in the LSB position
    srlv $t0, $t0, $s1
    andi $t0, $t0, 1
    
    #if the piece is on the botton of the board, it can't move down
    add $t0, $zero, $zero
    beq $s1, $t0, endvalidatep2
    addi $t0, $zero, 1
    beq $s1, $t0, endvalidatep2
    addi $t0, $zero, 1
    beq $s1, $t0, endvalidatep2
    addi $t0, $zero, 1
    beq $s1, $t0, endvalidatep2

    jal validatedownsidemove
    
    #if the piece is on the side, end validation check, else, validatedownmove
    add $t0, $zero, $zero
    addi $t0, $zero, 4
    beq $s1, $t0, endvalidatep2
    addi $t0, $zero, 7
    beq $s1, $t0, endvalidatep2
    addi $t0, $zero, 1
    beq $s1, $t0, endvalidatep2
    addi $t0, $zero, 7
    beq $s1, $t0, endvalidatep2
    addi $t0, $zero, 1
    beq $s1, $t0, endvalidatep2
    addi $t0, $zero, 7
    beq $s1, $t0, endvalidatep2
    addi $t0, $zero, 1
    beq $s1, $t0, endvalidatep2

    jal validatedownmove

    endvalidatep2:
    jr $s0

validateupmove:

    move $t0, $ra


    jr $t0
    
validateupsidemove:

    move $t0, $ra


    jr $t0

validateupjump:

    
    jr $ra

validatedownmove:

    move $t0, $ra


    jr $t0

validatedownsidemove:

    move $t0, $ra


    jr $t0

validatedownjump:

    jr $ra

setvalid:

    #set valid to 1
    la $t0, valid
    addi $t1, $zero, 1
    sb $t1, ($t0)
    #if the move is valid, jump all the way back into newgame
    jr $s0

updateboard:

    jr $ra

victorychk:
   
    #t0 is for holding 32
    #t1 is the iterator
    #t2 holds a copy of b_color
    #t3 is the space being considered
    addi $t0, $zero, 32
    add $t1, $zero, $zero

    la $t2, b_color
    lw $t2, ($t2) 

    add $t3, $zero, $zero
    
    #check to see if p1 has any pieces
    loopp1:
    beq $t1, $t0, endp1check

    #!shift a bit from t2 into t3
    bne $zero, $t3, setvictory
    
    addi $t1, $t1, 1
    j loopp1

    endp1check:

    add $t1, $zero, $zero

    la $t2, b_color
    lw $t2, ($t2) 

    add $t3, $zero, $zero
   
    #check to see if p2 has any pieces
    loopp2:
    beq $t1, $t0, endp2check

    #!shift a bit from t2 into t3
    beq $zero, $t3, setvictory
    
    addi $t1, $t1, 1
    j loopp2

    endp2check:
    jr $ra

setvictory:

    addi $a0, $zero, 1
    la $a1, victory
    sb $a0, ($a1)

    jr $ra

#for debugging
endprogram:
        li $a0, 9
        li $v0, 1
        syscall
        li $v0, 10
        syscall
