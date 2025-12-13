.data
	title: .asciiz "=== Digital Pet Simulator (MIPS32) ===\n"
	initializeMessage: .asciiz "Initializing system...\n\n"
	inputPrompt: .asciiz "Please set parameters (press Enter for default):\n"
	inputMessage_EDR: .asciiz "Enter Natural Energy Depletion Rate (EDR) [Default: 1]:\n"
	inputMessage_MEL: .asciiz "Enter Maximun Energy Level (MEL) [Default: 15]:\n"
	inputMessage_IEL: .asciiz "Enter Initial Energy Level (IEL) [Default: 5]:\n"
	userInput_EDR: .space 20
	userInput_MEL: .space 20
	userInput_IEL: .space 20
	default_EDR: .word 1
	default_MEL: .word 15
	default_IEL: .word 5
	setSuccessfully: .asciiz "Parameters set successfully!\n"
	sign_EDR: .asciiz "- EDR:"
	sign_MEL: .asciiz "- MEL:"
	sign_IEL: .asciiz "- IEL:"
	unit_EDR: .asciiz "units/sec\n"
	unit_MEL: .asciiz "units\n"
	unit_IEL: .asciiz "units\n\n"
	barLeft: .asciiz "["
	barRight: .asciiz "]"
	barFill: .asciiz "#"
	barEmpty: .asciiz "-"
	energyPrompt: .asciiz "Energy:"
	flash: .asciiz"/"
	currentStatusMessage: .asciiz "Your Digital Pet is alive! Current status:\n"
	inputCommandMessage: .asciiz "Enter a command (F, E, P, I, R, Q)>\n"
	inputCommand: .space 30
	inputCommandUnit: .space 20
	newLine: .asciiz "\n"
	
.text
inputParameters:
	li $v0, 4
	la $a0, title
	syscall
	
	li $v0, 4
	la $a0, initializeMessage
	syscall
	
	li $v0, 4
	la $a0, inputPrompt
	syscall
	
askEDR:
	li $v0, 4
	la $a0, inputMessage_EDR
	syscall
	
	li $v0, 8
	la $a0, userInput_EDR
	li $a1, 20
	syscall
	la $t0, userInput_EDR
	lb $t1, 0($t0)
	beq $t1, 10, useDefaultEDR
	subi $t1, $t1, 48
	move $s0, $t1
	j askMEL
	
useDefaultEDR:
	la $t2, default_EDR
	lw $s0, 0($t2)
	j askMEL

askMEL:
	li $v0, 4
	la $a0, inputMessage_MEL
	syscall
	
	li $v0, 8
	la $a0, userInput_MEL
	li $a1, 20
	syscall
	la $t0, userInput_MEL
	lb $t1, 0($t0)
	beq $t1, 10, useDefaultMEL
	subi $t1, $t1, 48
	move $s1, $t1
	j askIEL

useDefaultMEL:
	la $t2, default_MEL
	lw $s1, 0($t2)
	j askIEL
	
askIEL:
	li $v0, 4
	la $a0, inputMessage_IEL
	syscall
	
	li $v0, 8
	la $a0, userInput_IEL
	li $a1, 20
	syscall
	la $t0, userInput_IEL
	lb $t1, 0($t0)
	beq $t1, 10, useDefaultIEL
	subi $t1, $t1, 48
	move $s2, $t1				#set initial energy level to $s2
	move $s3, $s2				#set current energy level to $s3
	j setSuccessfullyPrompt
	
useDefaultIEL:
	la $t2, default_IEL
	lw $s2, 0($t2)
	move $s3, $s2		
	j setSuccessfullyPrompt
	
setSuccessfullyPrompt:
	li $v0, 4
	la $a0, setSuccessfully
	syscall

	li $v0, 4
	la $a0, sign_EDR
	syscall
	
	li $v0, 1
	move $a0, $s0
	syscall
	
	li $v0, 4
	la $a0, unit_EDR
	syscall
	
	li $v0, 4
	la $a0, sign_MEL
	syscall
	
	li $v0, 1
	move $a0, $s1
	syscall
	
	li $v0, 4
	la $a0, unit_MEL
	syscall
	
	li $v0, 4
	la $a0, sign_IEL
	syscall
	
	li $v0, 1
	move $a0, $s2
	syscall
	
	li $v0, 4
	la $a0, unit_IEL
	syscall
	
	li $v0, 4
	la $a0, currentStatusMessage
	syscall
	
calculateStatusBar:
	addi $t0, $zero, 0			#set the initial number of bar count
	beq $t0, $s3, printEmpty
	li $v0, 4
	la $a0, barFill
	syscall
	j 

printBarLeft:



printBarFilll:



printBarEmpty:



printBarRight:


main:
	#timer
	ble $s3, $s0, energyZero		#check if the current ennergy is enough to be substracted and ensure the current energy won't equal to negative value
      	sub $s3, $s3, $s0
      	
      	#access and check command
	li $v0, 4
	la $a0, inputCommandMessage
	syscall
	
	li $v0, 12
	syscall
	move $t0, $v0				#command
	
	li $v0, 5
	syscall
	move $t1, $v0				#command for unit
	
	beq $t0, 'F', feed
	beq $t0, 'E', entertain
	beq $t0, 'P', pet
	beq $t0, 'I', ignore
	beq $t0, 'R', reset
	beq $t0, 'Q', quit
	j main
	

feed:
	addi $t0, $zero, 1		#energy increased unit 
	mul $t2, $t1, $t0		#total energy increased
	add $t3, $s3, $t2		#current energy+total energy increased, used to check whether it will be larger than the maximum level
	bge $t3, $s1, upperLimit	#if current energy+total energy increased<=maximum energy
	add $s3, $s3, $t2		#increase current energy				
	j main
	
entertain:
	addi $t0, $zero, 2
	mul $t2, $t1, $t0
	add $t3, $s3, $t2
	bge $t3, $s1, upperLimit
	add $s3, $s3, $t2
	j main
	
pet:
	addi $t0, $zero, 2
	mul $t2, $t1, $t0
	add $t3, $s3, $t2
	bge $t3, $s1, upperLimit
	add $s3, $s3, $t2
	j main
	
ignore:
	addi $t0, $zero, 3
	mul $t1, $t1, $t0
	ble $s3, $t1, energyZero
	sub $s3, $s3, $t2
	j main

reset:
	move $s3, $s2
	j main

quit:
	

upperLimit:
	move $s3, $s1			#set the current energy to the maximum level

energyZero:
	li $s3, 0
		
	
	

	
	
	
	
	
	
