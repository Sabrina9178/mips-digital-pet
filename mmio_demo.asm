.data
start_msg:      .asciiz "\nDemo Started! Energy is 20.\nStart typing a number...\n"
tick_msg:       .asciiz "\n[Tick! Energy -1] Current Energy: "
key_msg:        .asciiz " <--- KEY DETECTED: "
reprompt_msg:   .asciiz "\n(Continuing input...) > "
final_msg:      .asciiz "\nSuccess! You entered: "
energy:         .word 20

.text
.globl main

main:
    # 1. Initialize
    addi $v0, $zero, 4
    la $a0, start_msg
    syscall

    addi $s0, $zero, 20     # Energy
    addi $s1, $zero, 0      # Accumulator
    
    # Initialize Timer
    addi $v0, $zero, 30
    syscall
    addu $s7, $a0, $zero    # Last time

loop:
    # --- A. TIMER ---
    addi $v0, $zero, 30
    syscall
    subu $t2, $a0, $s7
    blt $t2, 1000, check_key # If < 1 sec, go check keys

    # --- B. TICK ---
    addu $s7, $a0, $zero    # Reset time
    addi $s0, $s0, -1       # Energy -1
    
    # Print Tick
    addi $v0, $zero, 4
    la $a0, tick_msg
    syscall
    
    addi $v0, $zero, 1
    addu $a0, $s0, $zero
    syscall
    
    # Reprompt
    addi $v0, $zero, 4
    la $a0, reprompt_msg
    syscall
    
    addi $v0, $zero, 1
    addu $a0, $s1, $zero
    syscall

check_key:
    # --- C. CHECK KEYBOARD ---
    lui $t0, 0xffff
    lw $t1, 0($t0)
    andi $t1, $t1, 1
    beqz $t1, loop

    # --- D. KEY DETECTED ---
    lw $a0, 4($t0)          # Read the char
    
    # Check Enter
    addi $t9, $zero, 10
    beq $a0, $t9, process_input # CHANGED: Jump to new label
    
    # Check Digits
    blt $a0, 48, loop
    bgt $a0, 57, loop
    
    # DEBUG: Print "KEY DETECTED" immediately
    addu $t5, $a0, $zero    # Save char
    
    addi $v0, $zero, 4
    la $a0, key_msg         # Print " <--- KEY DETECTED: "
    syscall
    
    addi $v0, $zero, 11     # Print the actual digit
    addu $a0, $t5, $zero
    syscall
    
    # Build Number Logic
    addi $t6, $t5, -48
    addi $t9, $zero, 10
    mult $s1, $t9
    mflo $s1
    addu $s1, $s1, $t6
    
    j loop

process_input:
    # Print Result
    addi $v0, $zero, 4
    la $a0, final_msg
    syscall
    
    addi $v0, $zero, 1
    addu $a0, $s1, $zero
    syscall
    
    # Print Newline
    addi $v0, $zero, 11
    addi $a0, $zero, 10
    syscall

    # RESET Accumulator for the next number
    addi $s1, $zero, 0
    
    # JUMP BACK to loop (Keep ticking!)
    j loop