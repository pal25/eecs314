.data
newline: .asciiz "\n"
victory: .byte 0
valid: .byte 0
jorm: .byte 0
isai: .byte 0

.text
#s0 register helps in return
#s1 register used for "from" space
#s2 register used for "to" space
#s3 register used to statically hold "32", the "end of turn" value
main:

    addi $s3, $zero, 32

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

        #if the space moving from is "32", its the skip to end of turn
        beq $s1, $s3, endp1
        
        #get space moving to
        li $v0, 5
        syscall
        move $s2, $v0
    
    endp1:

    #if AI enabled, jump to AI
    lb $t0, isai
    bne $zero, $t0, ai

    p2:
        
	endp2:
    j p1

    ai:
	
    endai
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

    jr $ra
