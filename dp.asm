
.data
# --- Configuration Strings ---
header:         .asciiz "\n=== Digital Pet Simulator (MIPS32) ===\nInitializing system...\n\nPlease set parameters (press Enter for default):\n"
prompt_edr:     .asciiz "Enter Natural Energy Depletion Rate (EDR) [Default: 1]: "
prompt_mel:     .asciiz "Enter Maximum Energy Level (MEL) [Default: 15]: "
prompt_iel:     .asciiz "Enter Initial Energy Level (IEL) [Default: 5]: "
setup_success:  .asciiz "\nParameters set successfully!\n"
msg_edr:        .asciiz "- EDR: "
msg_mel:        .asciiz "- MEL: "
msg_iel:        .asciiz "- IEL: "
units_sec:      .asciiz " units/sec\n"
units:          .asciiz " units\n"

# --- Runtime Strings ---
alive_msg:      .asciiz "\nYour Digital Pet is alive! Current status:\n"
prompt_cmd:     .asciiz "\nEnter a command (F, E, P, I, R, Q) > "
status_end:     .asciiz " Energy: "
slash:          .asciiz "/"
time_msg:       .asciiz "\nTime +1s... Natural energy depletion!\n"

# --- Command Feedback Messages ---
msg_feed:       .asciiz "\nCommand recognized: Feed "
msg_play:       .asciiz "\nCommand recognized: Entertain "
msg_pet:        .asciiz "\nCommand recognized: Pet "
msg_ignore:     .asciiz "\nCommand recognized: Ignore "
msg_reset:      .asciiz "\nCommand recognized: Reset.\nDigital Pet has been reset to its initial state!\n"
msg_quit:       .asciiz "\nCommand recognized: Quit.\nSaving session... goodbye!\n--- simulation terminated ---\n"

# --- Error/Status Messages ---
err_cap:        .asciiz "\nError, maximum energy level reached! Capped to the Max.\n"
err_dead:       .asciiz "\nError, energy level equal or less than 0. DP is dead!\n"
died_banner:    .asciiz "\n*** Your Digital Pet has died! ***\n"
feed_msg_part2: .asciiz ".\nEnergy increased by "
units_text:     .asciiz " units.\n"
dec_msg_part2:  .asciiz ".\nEnergy decreased by "

# --- Input Buffer ---
input_buffer:   .space 20

.text
.globl main


# 1. INITIALIZATION PHASE
main:
    # Print Header
    li $v0, 4
    la $a0, header
    syscall

    # --- Get User Parameters ---
    
    # Get EDR (Default 1)
    la $a0, prompt_edr
    li $a1, 1
    jal get_param_input
    add $s2, $v0, $zero     # Saved EDR

    # Get MEL (Default 15)
    la $a0, prompt_mel
    li $a1, 15
    jal get_param_input
    add $s1, $v0, $zero     # Saved MEL

    # Get IEL (Default 5)
    la $a0, prompt_iel
    li $a1, 5
    jal get_param_input
    add $s0, $v0, $zero     # Saved IEL
    
    # Initialize Current Energy
    add $s3, $s0, $zero     # s3 = Current Energy

    # --- Display Settings Confirmation ---
    li $v0, 4
    la $a0, setup_success
    syscall
    
    # Print EDR
    li $v0, 4
    la $a0, msg_edr
    syscall
    li $v0, 1
    add $a0, $s2, $zero
    syscall
    li $v0, 4
    la $a0, units_sec
    syscall

    # Print MEL
    li $v0, 4
    la $a0, msg_mel
    syscall
    li $v0, 1
    add $a0, $s1, $zero
    syscall
    li $v0, 4
    la $a0, units
    syscall

    # Print IEL
    li $v0, 4
    la $a0, msg_iel
    syscall
    li $v0, 1
    add $a0, $s0, $zero
    syscall
    li $v0, 4
    la $a0, units
    syscall

    # Print "Alive" message
    li $v0, 4
    la $a0, alive_msg
    syscall

    # Show initial status bar
    jal print_status
    
    # Prompt for first command
    li $v0, 4
    la $a0, prompt_cmd
    syscall

    # Initialize Timer
    li $v0, 30
    syscall
    add $s7, $a0, $zero     # s7 stores last timestamp

# 2. MAIN SIMULATION LOOP
game_loop:
    # Check if pet is dead (Energy <= 0)
    blez $s3, dead_state

    # --- A. Check for User Input (MMIO Polling) ---
    lui $t0, 0xffff
    lw $t1, 0($t0)
    andi $t1, $t1, 1
    bnez $t1, handle_input

    # --- B. Check Timer ---
    li $v0, 30
    syscall
    
    # Calculate Time Diff
    sub $t2, $a0, $s7
    blt $t2, 1000, game_loop

    # --- C. 1 Second Passed: Deplete Energy ---
    add $s7, $a0, $zero     # Update last time
    
    # Print time message
    li $v0, 4
    la $a0, time_msg
    syscall
    
    # Apply Depletion
    sub $s3, $s3, $s2
    
    # Show status
    jal print_status        
    
    # Reprompt
    li $v0, 4
    la $a0, prompt_cmd
    syscall
    
    j game_loop


# 3. INPUT HANDLER
handle_input:
    # Read character
    lw $a0, 4($t0)          
    
    # Ignore newlines
    li $t9, 10 
    beq $a0, $t9, game_loop
    
    # Branch to specific command
    beq $a0, 0x46, cmd_feed
    beq $a0, 0x45, cmd_ent
    beq $a0, 0x50, cmd_pet
    beq $a0, 0x49, cmd_ign
    beq $a0, 0x52, cmd_reset
    beq $a0, 0x51, cmd_quit
    
    j game_loop

# 4. COMMAND LOGIC
# --- Feed (F n) ---
cmd_feed:
    li $v0, 4
    la $a0, msg_feed
    syscall
    jal read_int_arg
    add $t4, $v0, $zero
    
    # Print confirmation
    li $v0, 1
    add $a0, $t4, $zero
    syscall
    li $v0, 4
    la $a0, feed_msg_part2
    syscall
    li $v0, 1
    add $a0, $t4, $zero
    syscall
    li $v0, 4
    la $a0, units_text
    syscall
    
    add $s3, $s3, $t4
    j check_max

# --- Entertain (E n) ---
cmd_ent:
    li $v0, 4
    la $a0, msg_play
    syscall
    jal read_int_arg
    add $t4, $v0, $zero
    
    li $v0, 1
    add $a0, $t4, $zero
    syscall
    li $v0, 4
    la $a0, feed_msg_part2
    syscall
    
    # Multiply by 2
    li $t9, 2
    mult $t4, $t9
    mflo $t4
    
    li $v0, 1
    add $a0, $t4, $zero
    syscall
    li $v0, 4
    la $a0, units_text
    syscall

    add $s3, $s3, $t4
    j check_max

# --- Pet (P n) ---
cmd_pet:
    li $v0, 4
    la $a0, msg_pet
    syscall
    jal read_int_arg
    add $t4, $v0, $zero
    
    li $v0, 1
    add $a0, $t4, $zero
    syscall
    li $v0, 4
    la $a0, feed_msg_part2
    syscall

    # Multiply by 2
    li $t9, 2
    mult $t4, $t9
    mflo $t4
    
    li $v0, 1
    add $a0, $t4, $zero
    syscall
    li $v0, 4
    la $a0, units_text
    syscall
    
    add $s3, $s3, $t4
    j check_max

# --- Ignore (I n) ---
cmd_ign:
    li $v0, 4
    la $a0, msg_ignore
    syscall
    jal read_int_arg
    add $t4, $v0, $zero

    li $v0, 1
    add $a0, $t4, $zero
    syscall
    li $v0, 4
    la $a0, dec_msg_part2
    syscall

    # Multiply by 3
    li $t9, 3
    mult $t4, $t9
    mflo $t4
    
    li $v0, 1
    add $a0, $t4, $zero
    syscall
    li $v0, 4
    la $a0, units_text
    syscall
    
    sub $s3, $s3, $t4
    
    blez $s3, pet_died_action
    
    jal print_status
    li $v0, 4
    la $a0, prompt_cmd
    syscall
    j game_loop

# --- Reset (R) ---
cmd_reset:
    li $v0, 4
    la $a0, msg_reset
    syscall
    add $s3, $s0, $zero
    
    jal print_status
    li $v0, 4
    la $a0, prompt_cmd
    syscall
    j game_loop

# --- Quit (Q) ---
cmd_quit:
    li $v0, 4
    la $a0, msg_quit
    syscall
    li $v0, 10
    syscall

# 5. HELPER ROUTINES
check_max:
    ble $s3, $s1, action_done
    add $s3, $s1, $zero
    li $v0, 4
    la $a0, err_cap
    syscall
    
action_done:
    jal print_status
    li $v0, 4
    la $a0, prompt_cmd
    syscall
    j game_loop

pet_died_action:
    li $v0, 4
    la $a0, err_dead
    syscall
    
dead_state:
    jal print_status
    li $v0, 4
    la $a0, died_banner
    syscall
    li $v0, 4
    la $a0, prompt_cmd
    syscall
    
dead_loop:
    lui $t0, 0xffff
    lw $t1, 0($t0)
    andi $t1, $t1, 1
    beqz $t1, dead_loop
    
    lw $a0, 4($t0)
    beq $a0, 0x52, cmd_reset
    beq $a0, 0x51, cmd_quit
    j dead_loop

read_int_arg:
    li $v0, 5
    syscall
    jr $ra

print_status:
    # Calculate Hashes
    li $t0, 10
    
    beqz $s1, skip_math
    
    # t1 = Current * 10
    li $t9, 10
    mult $s3, $t9
    mflo $t1
    
    # t2 = t1 / Max
    div $t1, $s1
    mflo $t2
    
    # Cap hashes at 10
    ble $t2, 10, math_ok
    li $t2, 10
math_ok:
    bge $t2, 0, start_draw
    li $t2, 0

start_draw:
    # Print "["
    li $v0, 11
    li $a0, 91
    syscall

    # Print Hashes
    add $t3, $t2, $zero
print_hashes:
    beqz $t3, start_dashes
    li $a0, 35
    syscall
    addi $t3, $t3, -1
    j print_hashes

    # Print Dashes
start_dashes:
    li $t4, 10
    sub $t4, $t4, $t2
print_dashes_loop:
    beqz $t4, end_bracket
    li $a0, 45
    syscall
    addi $t4, $t4, -1
    j print_dashes_loop

end_bracket:
    li $a0, 93
    syscall

skip_math:
    # Print " Energy: X/Y"
    li $v0, 4
    la $a0, status_end
    syscall
    li $v0, 1
    add $a0, $s3, $zero
    syscall
    li $v0, 4
    la $a0, slash
    syscall
    li $v0, 1
    add $a0, $s1, $zero
    syscall
    li $v0, 11
    li $a0, 10
    syscall
    
    jr $ra

get_param_input:
    # 1. Print Prompt
    add $t0, $a0, $zero
    li $v0, 4
    syscall
    
    # 2. Read String
    li $v0, 8
    la $a0, input_buffer
    li $a1, 10
    syscall
    
    # 3. Check for Empty
    lb $t1, input_buffer
    li $t2, 10
    beq $t1, $t2, use_default
    
    # 4. Parse String to Int
    la $t3, input_buffer
    li $v0, 0
parse_loop:
    lb $t4, 0($t3)
    li $t5, 10
    beq $t4, $t5, parse_done
    blt $t4, 48, parse_done
    bgt $t4, 57, parse_done
    
    addi $t4, $t4, -48
    
    # v0 = v0 * 10
    li $t9, 10
    mult $v0, $t9
    mflo $v0
    
    add $v0, $v0, $t4
    
    addi $t3, $t3, 1
    j parse_loop
    
parse_done:
    jr $ra

use_default:
    add $v0, $a1, $zero
    jr $ra