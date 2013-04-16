.data
newline: .asciiz "\n"
victory: .byte 0
valid: .byte 0
jorm: .byte 0
isai: .byte 0

.text
main:

    #declare three registers for board data
    #!s0, s1, s2
    
    #get bit of AI choice
    li $v0, 5
    syscall
    sb $v0, isai

    #initboard procedure
    #!loop through all bits of board registers, set proper bits 

    p1:
        #!get message for move (do we need a loop? how exactly is message sent?)

        #!get bit moving from, set to $t8
        #!get bit moving to, set to $t9
    #end p1

    #if AI enabled, jump to AI
    lb $t0, isai
    bne $zero, $t0, ai

    p2:
        
	    j p1
    #end p2

    ai:
	
	    j p1
    #end ai

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
