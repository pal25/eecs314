.data
newline:	.asciiz "\n"

.text
main:
	addi $t0, $zero, 100
	j print
	
input:
	li $v0, 5
	syscall
	bne $zero, $v0, inc

dec:	
	addi $t0, $t0, -1
	j print

inc:
	addi $t0, $t0, 1
	j print

print:	
	li $v0, 1
	move $a0, $t0
	syscall
	li $v0, 4
	la $a0, newline
	syscall
	j input

exit:	
	li $v0, 10
	syscall