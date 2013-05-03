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

#output codes
invalidmove: .byte 110 # Depreciated
validmove: .byte 111 # Board move
p1wins: .byte 112
p2wins: .byte 113
newline: .asciiz "\n"

.text
#s0 register helps in return
#s1 register used for "from" space
#s2 register used for "to" space
#s3 register used to help returns during jump
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
	addi $t1, $zero, 4095 
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
  
        jal outputboard

	p1:
                
                move $s4, $zero #player turn. 0 for p1, 1 for p2

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
		#!send "invalid move message" to python

                li $v0, 1
		la $t0, invalidmove
		lb $a0, ($t0)
		syscall
		li $v0, 4
		la $a0, newline
		syscall
		
                j p1

		validp1:
		jal updateboard
                jal outputboard
                j p1
	endp1:
	#!!!jal victorychk
	#if there is no victory, go to p2
	la $t0, victory
	lb $t0, ($t0)
	beq $t0, $zero, p2

	#if there is victory, p1 wins! Send back victory code, reset game
	la $t0, p1wins
	lb $a0, ($t0)
	li $v0, 1
	syscall
	la $a0, newline
	li $v0, 4
	syscall
	j newgame

	p2:
                addi $s4, $zero, 1 #player turn. 0 for p1, 1 for p2
		#if AI enabled (not equal to 0), jump to AI
		la $t0, isai
		lb $t0, ($t0)
		bne $zero, $t0, ai

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
		
		#movements come in pairs, so if the message wasn't "end of turn", it must be the space moving to
		li $v0, 5
		syscall
		move $s2, $v0
	
		jal validatep2

		la $t0, valid
		lb $t0, ($t0)
		bne $t0, $zero, validp2
		
                #send "invalid move message" to python
		
                li $v0, 1
		la $t0, invalidmove
		lb $a0, ($t0)
		syscall
		li $v0, 4
		la $a0, newline
		syscall
		j p2

		validp2:
		
		jal updateboard
		jal outputboard
                j p2
		endp2:

	#!!!jal victorychk
	#if there is no victory, go back to p1 turn
	la $t0, victory
	lb $t0, ($t0)
	beq $t0, $zero, p1
   
	#if there is victory, p2 wins! sent message, start new game
	la $t0, p2wins
	lb $a0, ($t0)
	li $v0, 1
	syscall
	la $a0, newline
	li $v0, 4
	syscall
	j newgame

	ai:
		
	endai:
	
        jal updateboard
        jal outputboard
        
	#!!!jal victorychk
	#if there is no victory, go back to p1 turn
	la $t0, victory
	lb $t0, ($t0)
	beq $t0, $zero, p1
   
	#if there is victory, p2 wins! sent message, start new game
	la $t0, p2wins
	lb $a0, ($t0)
	li $v0, 1
	syscall
	la $a0, newline
	li $v0, 4
	syscall
	j newgame

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
	
        #if the "to" space is occupied, don't allow a move to it
	#get occupancy of space from b_haspiece
	la $t0, b_haspiece
	lw $t0, ($t0)
	srlv $t0, $t0, $s2
	andi $t0, $t0, 1
	#if the space isn't 0, its not empty, so we can't move to it
	bne $t0, $zero, endvalidatep1
	
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
	
        #if we haven't been able to move downward, check jump downward
        jal validatedownjump

	#if a pawn move isn't valid, see if a king move is
	kingmovep1:

	#see if the "from" space has a king, store in t0
	la $t0, b_rank
	lw $t0, ($t0)
	#shift the array of pieces to the right, so that the "from" space bit is in the LSB position
	srlv $t0, $t0, $s1
	andi $t0, $t0, 1
	
	#if the piece isn't a king, skip the king validation
	beq $t0, $zero, endvalidatep1
	
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

        #if it isn't a king moving up, see if its a king jumping up
        jal validateupjump

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
  
	#if the "to" space is occupied, don't allow a move to it
	#get occupancy of space from b_haspiece
	la $t0, b_haspiece
	lw $t0, ($t0)
	srlv $t0, $t0, $s2
	andi $t0, $t0, 1
	#if the space isn't 0, its not empty, so we can't move to it
	bne $t0, $zero, endvalidatep2
	
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

        #if it isn't a move up, it may be a jump up
        jal validateupjump

	#if a pawn move isn't valid, see if a king move is
	kingmovep2:

	#see if the piece's square has a king, store in t0
	la $t0, b_rank
	lw $t0, ($t0)
	#shift the array of pieces to the right, so that the "from" space bit is in the LSB position
	srlv $t0, $t0, $s1
	andi $t0, $t0, 1

	#if the piece isn't a king, skip the king validation
	beq $t0, $zero, endvalidatep2
	
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

        #if its a king that can't move down, check a jump down
        jal validatedownjump

	endvalidatep2:
	jr $s0

validateupmove:

	#handles pieces in the center moving up 3/4 or 4/5

        addi $t0, $zero, 4 #holds 4 for loop stop
        add $t1, $zero, $zero #outside iterator
        add $t2, $zero, $zero #inside iterator
        addi $t3, $zero, 5 #static 5 for space comparison
        addi $t4, $zero, 4 #static 4 for space comparison
        add $t5, $zero, $zero #iterator for space
        #$t6 is used for math
        addi $t7, $zero, 3 #static 3 for space comparison

        checkforupmove:
        #check each space to see if a move is valid.
        beq $t0, $t1, checkforupjump
                #check for a "5" move validity from first four spaces
                move $t2, $zero
                checkforupmove5:
                beq $t0, $t2 checkforupmove4intro
                        #check to see if the from space is in this row
                        bne $t5, $s1, cfum4end
                                #if the from space is the space we're on, we can validate
                                sub $t6, $s2, $s1
                                #if the difference between the spaces is 4, validate
                                #covered in sidemove
                                #beq $t6, $t4, setvalid
                                #if the difference between the spaces if 5, validate
                                beq $t6, $t3, setvalid
                                #otherwise, check for a jump
                                j checkforupjump
                        cfum4end:
                        addi $t2, $t2, 1
                        addi $t5, $t5, 1
                j checkforupmove5
                
                #check for a "4" move validity from next four spaces
                checkforupmove4intro:
                move $t2, $zero
                checkforupmove4:
                beq $t0, $t2 checkforupmoveEIL
                        #check to see if the from space is in this row
                        bne $t5, $s1, cfum3end
                                #if the from space is the space we're on, we can validate
                                sub $t6, $s2, $s1
                                #if the difference between the spaces is 4, validate
                                #covered in sidemove
                                #beq $t6, $t4, setvalid
                                #if the difference between the spaces if 3, validate
                                beq $t6, $t7, setvalid
                                #otherwise, check for a jump
                                j checkforupjump
                        cfum3end:
                         
                        addi $t2, $t2, 1
                        addi $t5, $t5, 1
                j checkforupmove4

                checkforupmoveEIL:
                addi $t1, $t1, 1
        j checkforupmove

        checkforupjump:
        #if no moves are valid, check to see if a jump is (depricated. moved to different function)
        

	endvalidateupmove:
	jr $ra
	
validateupsidemove:

        #on the side, a piece must be 4 away
        addi $t1, $zero, 4
        
        #get the difference between the spaces
        sub $t0, $s2, $s1
        #if the difference is 4, validate
        beq $t0, $t1, setvalid

        #otherwise, its invalid, continue on
	jr $ra

validateupjump:

        move $s3, $ra

        #if the piece is in the top two rows, it can't jump up
        move $t0, $zero
        addi $t0, $t0, 24
        beq $s1, $t0, endvalidateupjump
        addi $t0, $t0 1
        beq $s1, $t0, endvalidateupjump
        addi $t0, $t0 1
        beq $s1, $t0, endvalidateupjump
        addi $t0, $t0 1
        beq $s1, $t0, endvalidateupjump
        addi $t0, $t0 1
        beq $s1, $t0, endvalidateupjump
        addi $t0, $t0 1
        beq $s1, $t0, endvalidateupjump
        addi $t0, $t0 1
        beq $s1, $t0, endvalidateupjump
        addi $t0, $t0 1
        beq $s1, $t0, endvalidateupjump

        #if the piece is on the left, only validate left
        move $t0, $zero
        beq $s1, $t0, validateleftuponly #space 0
        addi $t0, $t0, 4
        beq $s1, $t0, validateleftuponly #space 4
        addi $t0, $t0, 4
        beq $s1, $t0, validateleftuponly #space 8
        addi $t0, $t0, 4
        beq $s1, $t0, validateleftuponly #space 12
        addi $t0, $t0, 4
        beq $s1, $t0, validateleftuponly #space 16
        addi $t0, $t0, 4
        beq $s1, $t0, validateleftuponly #space 20

        #if the piece is on the right, only validate right
        addi $t0, $zero, 3 
        beq $s1, $t0, validaterightuponly #space 3
        addi $t0, $zero, 4 
        beq $s1, $t0, validaterightuponly #space 7
        addi $t0, $zero, 4 
        beq $s1, $t0, validaterightuponly #space 11
        addi $t0, $zero, 4 
        beq $s1, $t0, validaterightuponly #space 15
        addi $t0, $zero, 4 
        beq $s1, $t0, validaterightuponly #space 19
        addi $t0, $zero, 4 
        beq $s1, $t0, validaterightuponly #space 23

        #otherwise, validate both
        j validatebothup

        validateleftuponly:
        jal validateupleftsidejump
        j endvalidateupjump

        validaterightuponly:
        jal validateuprightsidejump
        j endvalidateupjump

        validatebothup:
        jal validateuprightsidejump
        jal validateupleftsidejump

        endvalidateupjump:
	jr $s3

validateupleftsidejump:

        #check if the to space is 9 greater than the from
        sub $t0, $s2, $s1
        addi $t1, $zero, 9

        bne $t0, $t1, endvalidateupleftsidejump

        #need to make sure an opposing piece is in the middle
        addi $t0, $zero, 4 #holds 4 for loop stop
        add $t1, $zero, $zero #outside iterator
        add $t2, $zero, $zero #inside iterator
        addi $t3, $zero, 5 #static 5 for space comparison
        addi $t4, $zero, 4 #static 4 for space comparison
        add $t5, $zero, $zero #iterator for space
        #$t6 is used for math
        addi $t7, $zero, 3 #static 3 for space comparison
        la $t8, b_haspiece
        lw $t8, ($t8)
        la $t9, b_color
        lw $t9, ($t9)

        checkforupjumpl:
        #check each space to see if a move is valid.
        beq $t0, $t1, endvalidateupleftsidejump
                #check for a "5" move validity from first four spaces
                move $t2, $zero
                checkforupjumpl5:
                beq $t0, $t2 checkforupjumpl4intro
                        #check to see if the from space is in this row
                        bne $t5, $s1, cfujl4end
                                #if the middle space is the space we're on, we can validate
                                sub $t6, $t5, $s1
                                srlv $t8, $t8, $t6
                                srlv $t9, $t9, $t6
                                andi $t8, $t8, 1
                                andi $t9, $t9, 1
                                beq $t8, $zero, endvalidateupleftsidejump
                                beq $t9, $s4, endvalidateupleftsidejump
                                j setvalid
                                #otherwise, check for a jump
                                j endvalidateupleftsidejump
                        cfujl4end:
                        addi $t2, $t2, 1
                        addi $t5, $t5, 1
                j checkforupjumpl5
                
                #check for a "4" move validity from next four spaces
                checkforupjumpl4intro:
                move $t2, $zero
                checkforupjumpl4:
                beq $t0, $t2 checkforupjumplEIL
                        #check to see if the from space is in this row
                        bne $t5, $s1, cfujl3end
                                #if the from space is the space we're on, we can validate
                                sub $t6, $t4, $s1
                                srlv $t8, $t8, $t6
                                srlv $t9, $t9, $t6
                                andi $t8, $t8, 1
                                andi $t9, $t9, 1
                                beq $t8, $zero, endvalidateupleftsidejump
                                beq $t9, $s4, endvalidateupleftsidejump
                                j setvalid
                                #otherwise, not a valid jump
                                j endvalidateupleftsidejump
                        cfujl3end:
                         
                        addi $t2, $t2, 1
                        addi $t5, $t5, 1
                j checkforupjumpl4

                checkforupjumplEIL:
                addi $t1, $t1, 1
        j checkforupjumpl

        endvalidateupleftsidejump:
        jr $ra

validateuprightsidejump:

        #check if the to space is 7 greater than the from
        sub $t0, $s2, $s1
        addi $t1, $zero, 7

        bne $t0, $t1, endvalidateuprightsidejump

        #need to make sure an opposing piece is in the middle
        addi $t0, $zero, 4 #holds 4 for loop stop
        add $t1, $zero, $zero #outside iterator
        add $t2, $zero, $zero #inside iterator
        addi $t3, $zero, 5 #static 5 for space comparison
        addi $t4, $zero, 4 #static 4 for space comparison
        add $t5, $zero, $zero #iterator for space
        #$t6 is used for math
        addi $t7, $zero, 3 #static 3 for space comparison
        la $t8, b_haspiece
        lw $t8, ($t8)
        la $t9, b_color
        lw $t9, ($t9)

        checkforupjumpr:
        #check each space to see if a move is valid.
        beq $t0, $t1, endvalidateuprightsidejump
                #check for a "5" move validity from first four spaces
                move $t2, $zero
                checkforupjumpr5:
                beq $t0, $t2 checkforupjumpr4intro
                        #check to see if the from space is in this row
                        bne $t5, $s1, cfujr4end
                                #if the middle space is the space we're on, we can validate
                                sub $t6, $t4, $s1
                                #if the difference between the spaces i 4, validate
                                srlv $t8, $t8, $t6
                                srlv $t9, $t9, $t6
                                andi $t8, $t8, 1
                                andi $t9, $t9, 1
                                beq $t8, $zero, endvalidateuprightsidejump
                                beq $t9, $s4, endvalidateuprightsidejump
                                j setvalid
                                j endvalidateupleftsidejump
                        cfujr4end:
                        addi $t2, $t2, 1
                        addi $t5, $t5, 1
                j checkforupjumpr5
                
                #check for a "4" move validity from next four spaces
                checkforupjumpr4intro:
                move $t2, $zero
                checkforupjumpr4:
                beq $t0, $t2 checkforupjumprEIL
                        #check to see if the from space is in this row
                        bne $t5, $s1, cfujr3end
                                #if the from space is the space we're on, we can validate
                                sub $t6, $t7, $s1
                                #if the difference between the spaces is 3, validate
                                srlv $t8, $t8, $t6
                                srlv $t9, $t9, $t6
                                andi $t8, $t8, 1
                                andi $t9, $t9, 1
                                beq $t8, $zero, endvalidateuprightsidejump
                                beq $t9, $s4, endvalidateuprightsidejump
                                j setvalid
                                #otherwise, not a valid jump
                                j endvalidateuprightsidejump
                        cfujr3end:
                         
                        addi $t2, $t2, 1
                        addi $t5, $t5, 1
                j checkforupjumpr4

                checkforupjumprEIL:
                addi $t1, $t1, 1
        j checkforupjumpr

        endvalidateuprightsidejump:
        jr $ra

validatedownmove:

	#handles pieces in the center moving up 3/4 or 4/5

        addi $t0, $zero, 4 #holds 4 for loop stop
        add $t1, $zero, $zero #outside iterator
        add $t2, $zero, $zero #inside iterator
        addi $t3, $zero, 5 #static 5 for space comparison
        addi $t4, $zero, 4 #static 4 for space comparison
        add $t5, $zero, $zero #iterator for space
        #$t6 is used for math
        addi $t7, $zero, 3 #static 3 for space comparison

        checkfordownmove:
        #check each space to see if a move is valid.
        beq $t0, $t1, checkfordownjump
                #check for a "3" move validity from first four spaces
                move $t2, $zero
                checkfordownmove5:
                beq $t0, $t2 checkfordownmove4intro
                        #check to see if the from space is in this row
                        bne $t5, $s1, cfdm4end
                                #if the from space is the space we're on, we can validate
                                sub $t6, $s1, $s2
                                #if the difference between the spaces is 4, validate
                                #covered in sidemove
                                #beq $t6, $t4, setvalid
                                #if the difference between the spaces if 3, validate
                                beq $t6, $t7, setvalid
                                #otherwise, check for a jump
                                j checkfordownjump
                        cfdm4end:
                        addi $t2, $t2, 1
                        addi $t5, $t5, 1
                j checkfordownmove5
                
                #check for a "5" move validity from next four spaces
                checkfordownmove4intro:
                move $t2, $zero
                checkfordownmove4:
                beq $t0, $t2 checkfordownmoveEIL
                        #check to see if the from space is in this row
                        bne $t5, $s1, cfdm3end
                                #if the from space is the space we're on, we can validate
                                sub $t6, $s1, $s2
                                #if the difference between the spaces is 4, validate
                                #covered in sidemove
                                #beq $t6, $t4, setvalid
                                #if the difference between the spaces if 5, validate
                                beq $t6, $t3, setvalid
                                #otherwise, check for a jump
                                j checkfordownjump
                        cfdm3end:
                         
                        addi $t2, $t2, 1
                        addi $t5, $t5, 1
                j checkfordownmove4

                checkfordownmoveEIL:
                addi $t1, $t1, 1
        j checkfordownmove

        checkfordownjump:
        #if no moves are valid, check to see if a jump is (depricated. moved to different function)
        

	endvalidatedownmove:
	jr $ra

validatedownsidemove:

        #on the side, a piece must be 4 away
        addi $t1, $zero, 4
        
        #get the difference between the spaces
        sub $t0, $s1, $s2
        #if the difference is 4, validate
        beq $t0, $t1, setvalid

        #otherwise, its invalid, continue on
	jr $ra

validatedownjump:

        move $s3, $ra

        #if the piece is in the bottom two rows, it can't jump down
        move $t0, $zero
        beq $s1, $t0, endvalidatedownjump
        addi $t0, $t0 1
        beq $s1, $t0, endvalidatedownjump
        addi $t0, $t0 1
        beq $s1, $t0, endvalidatedownjump
        addi $t0, $t0 1
        beq $s1, $t0, endvalidatedownjump
        addi $t0, $t0 1
        beq $s1, $t0, endvalidatedownjump
        addi $t0, $t0 1
        beq $s1, $t0, endvalidatedownjump
        addi $t0, $t0 1
        beq $s1, $t0, endvalidatedownjump
        addi $t0, $t0 1
        beq $s1, $t0, endvalidatedownjump

        #if the piece is on the left, only validate left
        addi $t0, $zero, 8
        beq $s1, $t0, validateleftdownonly #space 8
        addi $t0, $t0, 4
        beq $s1, $t0, validateleftdownonly #space 12
        addi $t0, $t0, 4
        beq $s1, $t0, validateleftdownonly #space 16
        addi $t0, $t0, 4
        beq $s1, $t0, validateleftdownonly #space 20
        addi $t0, $t0, 4
        beq $s1, $t0, validateleftdownonly #space 24
        addi $t0, $t0, 4
        beq $s1, $t0, validateleftdownonly #space 28

        #if the piece is on the right, only validate right
        addi $t0, $zero, 11 
        beq $s1, $t0, validaterightdownonly #space 11
        addi $t0, $zero, 4 
        beq $s1, $t0, validaterightdownonly #space 15
        addi $t0, $zero, 4 
        beq $s1, $t0, validaterightdownonly #space 19
        addi $t0, $zero, 4 
        beq $s1, $t0, validaterightdownonly #space 23
        addi $t0, $zero, 4 
        beq $s1, $t0, validaterightdownonly #space 27
        addi $t0, $zero, 4 
        beq $s1, $t0, validaterightdownonly #space 31

        #otherwise, validate both
        j validatebothdown

        validateleftdownonly:
        jal validatedownleftsidejump
        j endvalidatedownjump

        validaterightdownonly:
        jal validatedownrightsidejump
        j endvalidatedownjump

        validatebothdown:
        jal validatedownrightsidejump
        jal validatedownleftsidejump

        endvalidatedownjump:
	jr $s3

validatedownrightsidejump:

        #check if the to space is 9 greater than the from
        sub $t0, $s1, $s2
        addi $t1, $zero, 9

        bne $t0, $t1, endvalidatedownrightsidejump

        #need to make sure an opposing piece is in the middle
        addi $t0, $zero, 4 #holds 4 for loop stop
        add $t1, $zero, $zero #outside iterator
        add $t2, $zero, $zero #inside iterator
        addi $t3, $zero, 5 #static 5 for space comparison
        addi $t4, $zero, 4 #static 4 for space comparison
        add $t5, $zero, $zero #iterator for space
        #$t6 is used for math
        addi $t7, $zero, 3 #static 3 for space comparison
        la $t8, b_haspiece
        lw $t8, ($t8)
        la $t9, b_color
        lw $t9, ($t9)

        checkfordownjumpr:
        #check each space to see if a move is valid.
        beq $t0, $t1, endvalidatedownrightsidejump
                #check for a "5" move validity from first four spaces
                move $t2, $zero
                checkfordownjumpr5:
                beq $t0, $t2 checkfordownjumpr4intro
                        #check to see if the from space is in this row
                        bne $t5, $s1, cfdjr4end
                                #if the middle space is the space we're on, we can validate
                                sub $t6, $s1, $t4
                                #if the difference between the spaces i 4, validate
                                srlv $t8, $t8, $t6
                                srlv $t9, $t9, $t6
                                andi $t8, $t8, 1
                                andi $t9, $t9, 1
                                beq $t8, $zero, endvalidatedownrightsidejump
                                beq $t9, $s4, endvalidatedownrightsidejump
                                j setvalid
                                #otherwise, check for a jump
                                j endvalidatedownrightsidejump
                        cfdjr4end:
                        addi $t2, $t2, 1
                        addi $t5, $t5, 1
                j checkfordownjumpr5
                
                #check for a "4" move validity from next four spaces
                checkfordownjumpr4intro:
                move $t2, $zero
                checkfordownjumpr4:
                beq $t0, $t2 checkfordownjumprEIL
                        #check to see if the from space is in this row
                        bne $t5, $s1, cfdjr3end
                                #if the from space is the space we're on, we can validate
                                sub $t6, $s1, $t3
                                #if the difference between the spaces if r5, validate
                                srlv $t8, $t8, $t6
                                srlv $t9, $t9, $t6
                                andi $t8, $t8, 1
                                andi $t9, $t9, 1
                                beq $t8, $zero, endvalidatedownrightsidejump
                                beq $t9, $s4, endvalidatedownrightsidejump
                                j setvalid
                                j endvalidatedownrightsidejump
                        cfdjr3end:
                         
                        addi $t2, $t2, 1
                        addi $t5, $t5, 1
                j checkfordownjumpr4

                checkfordownjumprEIL:
                addi $t1, $t1, 1
        j checkfordownjumpr

        endvalidatedownrightsidejump:
        jr $ra

validatedownleftsidejump:

        #check if the from space is 7 greater than the to
        sub $t0, $s1, $s2
        addi $t1, $zero, 7

        bne $t0, $t1, endvalidatedownleftsidejump

        #need to make sure an opposing piece is in the middle
        addi $t0, $zero, 4 #holds 4 for loop stop
        add $t1, $zero, $zero #outside iterator
        add $t2, $zero, $zero #inside iterator
        addi $t3, $zero, 5 #static 5 for space comparison
        addi $t4, $zero, 4 #static 4 for space comparison
        add $t5, $zero, $zero #iterator for space
        #$t6 is used for math
        addi $t7, $zero, 3 #static 3 for space comparison
        la $t8, b_haspiece
        lw $t8, ($t8)
        la $t9, b_color
        lw $t9, ($t9)
        checkfordownjumpl:
        #check each space to see if a move is valid.
        beq $t0, $t1, endvalidatedownleftsidejump
                #check for a "5" move validity from first four spaces
                move $t2, $zero
                checkfordownjumpl5:
                beq $t0, $t2 checkfordownjumpl4intro
                        #check to see if the from space is in this row
                        bne $t5, $s1, cfdjl4end
                                #if the middle space is the space we're on, we can validate
                                sub $t6, $s1, $t3
                                #if the difference between the spaces if 3, validate
                                srlv $t8, $t8, $t6
                                srlv $t9, $t9, $t6
                                andi $t8, $t8, 1
                                andi $t9, $t9, 1
                                beq $t8, $zero, endvalidatedownleftsidejump
                                beq $t9, $s4, endvalidatedownleftsidejump
                                j setvalid
                                #otherwise, check for a jump
                                j endvalidatedownleftsidejump
                        cfdjl4end:
                        addi $t2, $t2, 1
                        addi $t5, $t5, 1
                j checkfordownjumpl5
                
                #check for a "4" move validity from next four spaces
                checkfordownjumpl4intro:
                move $t2, $zero
                checkfordownjumpl4:
                beq $t0, $t2 checkfordownjumplEIL
                        #check to see if the from space is in this row
                        bne $t5, $s1, cfdjl3end
                                #if the middle space is the space we're on, we can validate
                                sub $t6, $s1, $t4
                                #if the difference between the spaces is 4, validate
                                srlv $t8, $t8, $t6
                                srlv $t9, $t9, $t6
                                andi $t8, $t8, 1
                                andi $t9, $t9, 1
                                beq $t8, $zero, endvalidatedownleftsidejump
                                beq $t9, $s4, endvalidatedownleftsidejump
                                j setvalid
                                #otherwise, check for a jump
                                j endvalidatedownleftsidejump
                        cfdjl3end:
                         
                        addi $t2, $t2, 1
                        addi $t5, $t5, 1
                j checkfordownjumpl4

                checkfordownjumplEIL:
                addi $t1, $t1, 1
        j checkfordownjumpl

        endvalidatedownleftsidejump:
        jr $ra

setvalid:

	#set valid to 1
	la $t0, valid
	addi $t1, $zero, 1
	sb $t1, ($t0)
	#if the move is valid, jump all the way back into newgame
	jr $s0

updateboard: 		# Update the board positions given and old and new pos
	move $s0, $ra
	move $t0, $s1 	# Position from
	move $t1, $s2 	# Position to

	# Determine which number is larger
	slt $t2, $t0, $t1 # if t0 < t1, set t2
	bne $t2, $zero, updatesub1 #if t2 set, then branch

	# Subtract larger number from smaller number
        updatesub2:
	sub $t2, $t0, $t1
	j updatejumpcheck

	# Subtract larger number from smaller number
        updatesub1:
	sub $t2, $t1, $t0

	# Check if a jump was made
	updatejumpcheck:	
	slti $t3, $t2, 6 #if the difference is less than 6, set t3
	bne $t3, $zero, updatepiece #if t3 set, then its just a move, and we can branch over the jump checking

        #matt commented out for testing
	# Push the $ra to the stack
	# addi $sp, $sp, -4
	# sw $ra, 0($sp)

	# Call update jump
	jal updatejump

        # matt commented out for testing
	# Pop the $ra from the stack
	# lw $ra, 0($sp)
	# addi $sp, $sp, 4
	
        updatepiece:	
	la $t2, b_haspiece
	lw $t2, ($t2)
	la $t3, b_color
	lw $t3, ($t3)
	la $t4, b_rank
	lw $t4, ($t4)

	# Convert the old pos to 0
	addi $t5, $zero, 1 	# Put a 1 in $t5
	sllv $t5, $t5, $t0 	# Shift the 1 $t0 units
	not $t5, $t5 		# Invert to all 1's and 1 zero
	and $t2, $t2, $t5 	# And the bit mask to has_piece
	
	# Convert the new pos to 1
	addi $t5, $zero, 1	# Put a 1 in $t5
	sllv $t5, $t5, $t1	# Shift the 1 $t0 units
	or $t2, $t2, $t5	# Or the bit mask to has_piece

	# Copy the old color to the new color
	srlv $t5, $t3, $t0	# Shift old bit into the 0th position
	andi $t5, $t5, 1	# Clear the rest of the bits
	beq $t5, $zero, updatetored #if the old color is red, jump to the "make red" code

        #BUG: if the space moving "to" was ever set to black, taking the or will keep it black.
        #sllv $t5, $t5, $t1	# Shift old bit to new bit pos
        #or $t3, $t3, $t5	# Or the bit mask to color
	
        updatetoblack:
        #make the "to" space black, keep all others the same. t5 currently holds 1
	sllv $t5, $t5, $t1      #shift the old bit into the new position
        or $t3, $t3, $t5        #or the bit mask to switch the "to" color and keep the rest the same
        j updaterank
        
        updatetored:
        #make the "to" space red, keep all others the same. t5 currently holds 0
        addi $t5, $zero, 1      #make the LSB 1
        sllv $t5, $t5, $t1      #shift the bit into the "to"  position
        not $t5, $t5            #invert the bits
        and $t3, $t3, $t5       #and the bit mask to switch the "to" color and keep the rest the same
        
        updaterank:
        # Copy the old rank to the new rank
	srlv $t5, $t4, $t0	# Shift old bit into the 0th position
	andi $t5, $t5, 1	# Clear the rest of the bits
        beq $t5, $zero, updatetopawn #if the old rank is pawn, jump to the "make pawn" code

        #BUG: always keeps the rank what is was
	#sllv $t5, $t5, $t1	# Shift old bit to new bit pos
	#or $t4, $t4, $t5	# Or the bit mask to rank

        updatetoking:
        #make the "to" space a king, keep all others the same. t5 currently holds 1
	sllv $t5, $t5, $t1      #shift the old bit into the new position
        or $t4, $t4, $t5        #or the bit mask to switch the "to" color and keep the rest the same
        j updatesaveboard
        
        updatetopawn:
        #make the "to" space a pawn, keep all others the same. t5 currently holds 0
        addi $t5, $zero, 1      #make the LSB 1
        sllv $t5, $t5, $t1      #shift the bit into the "to" position
        not $t5, $t5            #invert the bits
        and $t4, $t4, $t5       #and the bit mask to switch the "to" color and keep the rest the same


        updatesaveboard:
	# Save the new bit arrays
	la $t5, b_haspiece
	sw $t2, 0($t5)
	la $t5, b_color
	sw $t3, 0($t5)
	la $t5, b_rank
	sw $t4, 0($t5)
	
	jr $s0

updatejump:
	# $t2 holds num of spaces
                # that is, the difference between the old space and the new space
	# $t1 holds new pos
	# $t0 holds old pos

	# Determine which number is larger
	slt $t3, $t0, $t1                       # Set $t3 if $t0 < $t1, means old < new, (new > old)
	bne $t3, $zero, updatejnewgtold 	# Take if $t3 is not set, means t0

        updatejoldgtnew: 		# Figure out piece to remove old > new
	        sub $t3, $t0, $t1 	# The difference old - new

	        # Check the line 
                slti $t4 $t0, 12 	# If $t0 < 12 ? 1 : 0
		bne $t4, $zero, ogtncount54
	        slti $t4, $t0, 16	# IF $t0 < 16 ? 1 : 0
	        bne $t4, $zero, ogtncount34
	        slti $t4 $t0, 20 	# If $t0 < 20 ? 1 : 0
		bne $t4, $zero, ogtncount54
	        slti $t4, $t0, 24	# IF $t0 < 24 ? 1 : 0
	        bne $t4, $zero, ogtncount34
                slti $t4, $t0, 28
                bne $t4, $zero, ogtncount54
	        j ogtncount34 		# ELSE $t0 >= 24

        ogtncount54:	
	        slti $t4, $t3, 8
	        bne $t4, $zero, ogtncount254 	# Take if $t3 == 7
        ogtncount154:			# $t3 == 9
	        addi $t3, $t1, 5	# Count 5 from new
	        j updatejremove		# Jump to remove code
        ogtncount254:			# $t3 == 7
	        addi $t3, $t1, 4	# Count 4 from new
	        j updatejremove		# Jump to remove code

        ogtncount34:	
	        slti $t4, $t3, 8
	        bne $t4, $zero, ogtncount234 	# Take if $t3 == 7
        ogtncount134:			# $t3 == 9
	        addi $t3, $t1, 4	# Count 5 from new
	        j updatejremove		# Jump to remove code
        ogtncount234:			# $t3 == 7
	        addi $t3, $t1, 3	# Count 4 from new
	        j updatejremove		# Jump to remove code
        
        
        
        updatejnewgtold: 		# Figure out piece to remove new > old 	
	        sub $t3, $t1, $t0 	# The difference new - old

	        # Check the line 
	        slti $t4 $t1, 12 	# If $t1 < 12 ? 1 : 0
		bne $t4, $zero, ngtocount54
	        slti $t4, $t1, 16	# IF $t1 < 16 ? 1 : 0
	        bne $t4, $zero, ngtocount34
	        slti $t4 $t1, 20 	# If $t1 < 20 ? 1 : 0
		bne $t4, $zero, ngtocount54
	        slti $t4, $t1, 24	# IF $t1 < 24 ? 1 : 0
	        bne $t4, $zero, ngtocount34
                slti $t4, $t0, 28
                bne $t4, $zero, ngtocount54
	        j ngtocount34		# ELSE $t1 > 24

        ngtocount34:	
	        slti $t4, $t3, 8
	        bne $t4, $zero, ngtocount234 	# Take if $t3 == 7
        ngtocount134:			# $t3 == 9
	        addi $t3, $t0, 4	# Count 4 from old
	        j updatejremove		# Jump to remove code
        ngtocount234:			# $t3 == 7
	        addi $t3, $t0, 3	# Count 3 from old
	        j updatejremove		# Jump to remove code

        ngtocount54:	
	        slti $t4, $t3, 8
	        bne $t4, $zero, ngtocount254 	# Take if $t3 == 7
        ngtocount154:			# $t3 == 9
	        addi $t3, $t0, 5	# Count 4 from old
	        j updatejremove		# Jump to remove code
        ngtocount254:			# $t3 == 7
	        addi $t3, $t0, 4	# Count 3 from old
	        j updatejremove		# Jump to remove code


        updatejremove:			# Remove the position, which is stored in t3
	        la $t4, b_haspiece 	# Get the addr for the piece array
	        lw $t4, ($t4)		# Load the array into $t4
	
	        addi $t5, $zero, 1 	# Put a 1 in $t5
	        sllv $t5, $t5, $t3 	# Shift the 1 $t3 units
	        not $t5, $t5 		# Invert to all 1's and 1 zero
	        and $t4, $t4, $t5 	# And the bit mask to has_piece

	        la $t5, b_haspiece 	# Get the addr for the piece array 
	        sw $t4, ($t5) 		# Store the new array from $t4
                jr $ra 			# Return to updateboard
	
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
	
	#check to see if p2 has any pieces
	loopp1:
	beq $t1, $t0, endp1check

	andi $t3, $t2, 1
	bne $zero, $t3, endp1check
	
	addi $t1, $t1, 1
	j loopp1

	endp1check:

	add $t1, $zero, $zero

	la $t2, b_color
	lw $t2, ($t2) 

	add $t3, $zero, $zero
   
	#check to see if p1 has any pieces
	loopp2:
	beq $t1, $t0, endp2check

	andi $t3, $t2, 1
	beq $zero, $t3, endp2check
	
	addi $t1, $t1, 1
	j loopp2

	endp2check:
	jr $ra

setvictory:

	addi $a0, $zero, 1
	la $a1, victory
	sb $a0, ($a1)

	jr $ra

outputboard: 			# Responsible for printing out the board to Python
	add $t0, $zero, $zero 	# Bit position and counter
	addi $t1, $zero, 32 	# End value
	
	la $t2, b_haspiece 	#has piece
	lw $t2, 0($t2)
	la $t3, b_color 	#color
	lw $t3, 0($t3)
	la $t4, b_rank 		#rank
	lw $t4, 0($t4)
	
	# Print the valid move header
	la $a0, validmove
	lb $a0 0($a0)
        addi $v0, $zero, 1
	syscall

        outputloop: 		# Loop for outputboard
	add $t5, $zero, $zero 	# Initialize t5 to 0
	add $t6, $zero, $zero
	
	# Shift t0-th value from t2 into t6
	srav $t5, $t2, $t0
	andi $t5, $t5, 1
        add $t6, $t6, $t5
	sll $t6, $t6, 1

        andi $t6, $t6, 7 #getting lowest three bits of t6
	
        # Shift t0-th value from t3 into t6
	srav $t5, $t3, $t0
	andi $t5, $t5, 1
        add $t6, $t6, $t5
	sll $t6, $t6, 1

        andi $t6, $t6, 7 #getting lowest three bits of t6
	
        # Shift t0-th value from t4 into t6
	srav $t5, $t4, $t0
        andi $t5, $t5, 1
	add $t6, $t6, $t5

        andi $t6, $t6, 7 #getting lowest three bits of t6

	# Print the three-tuple on range [000...111]
	move $a0, $t6
	addi $v0, $zero, 1
	syscall

	# Increment counter and loop
	addi $t0, $t0, 1
	bne $t0, $t1, outputloop

	# After loop print newline
	la $a0, newline
	addi $v0, $zero, 4
	syscall

	# Return to code
        jr $ra

#for debugging
endprogram:
		li $a0, 9
		li $v0, 1
		syscall
		li $v0, 10
		syscall
