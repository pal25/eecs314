.data
newline: .asciiz "\n"
victory: .byte 0
valid: .byte 0
jorm: .byte 0
isai: .byte 0
b_haspeice .word 0
#for color, 0 is p1, 1 is p2
b_color .word 0
b_rank .word 0
eom .byte 100
reset .byte 101

.text
#s0 register helps in return
#s1 register used for "from" space
#s2 register used for "to" space
main:

    #get bit of AI choice
    li $v0, 5
    syscall
    sb $v0, isai

    #initboard procedure
    #!loop through all bits of board registers, set proper bits 

    p1:
        #get message for move
        li $v0, 5
        syscall
        move $s1, $v0

        #check for end of message, end turn if yes
        la $t0, eom
        lb $t0, ($t0)
        beq $s1, $t0, endp1
        
        #check for reset, jump to main if yes 
        la $t0, reset
        lb $t0, ($t0)
        beq $s1, $t0, main
        
        #movements come in pairs, so if the message wasn't "end of turn", it must be the space moving to
        li $v0, 5
        syscall
        move $s2, $v0
    
        jal validateP1

        la $t0, valid
        lb $t0, ($t0)
        bne $to, $zero, validp1
        #!send "invalid move message" to python
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
        
        #check for reset, jump to main if yes 
        la $t0, reset
        lb $t0, ($t0)
        beq $s1, $t0, main
        
        #movements come in pairs, so if the message wasn't "end of turn", it must be the space moving to
        li $v0, 5
        syscall
        move $s2, $v0
    
        jal validateP2

        la $t0, valid
        lb $t0, ($t0)
        bne $to, $zero, validp2
        #!send "invalid move message" to python
        j p2

        validp2:
        
        jal update_board
        
	endp2:
    jal victorychk
    la $t0, victory
    lb $t0, ($t0)
    beq $t0, $zero, p1

    #!send p2 win message to python
    j main

    ai:
	
    endai:
	j p1

validateP1:

    move $s0, $ra

    
    jr $s0

movechkP1:

    
    jr $ra

jumpchkP1:

    
    jr $ra

validateP2:

    move $s0, $ra

    
    jr $s0

movechkP2:


    jr $ra

jumpchkP2:

    
    jr $ra


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

    addi $t0, $zero, 32
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
