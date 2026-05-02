.text
.global _start

_start:                             
          // initialization code here
	/* r4 = key edge capture adress
	   r5 = hex base adress
	   r6 = hundreths counter 
	   r7 = seconds counter
	   r8 = timer state
	   r9 = timer base adress */

	ldr r4, edge_base 
	ldr r5, hex_base
	ldr r9, timer_base
	mov r6, #0 //hundreths starts at 0
	mov r7, #0 //seconds at 0 too
	mov r8, #0  //timer starts stopped

	mov r0, #0xF //clear edge capture register on start
	str r0, [r4]

	ldr r0, =2000000 //2 million ticks is 0.01 seconds at 200MHz
	str r0, [r9] //write to load register

	mov r0, #1 //clear f bit on startup (just in case)
	str r0, [r9, #12] //write to interrupt status reg

	bl display_time //show time 0:00


loop:

          // loop code here
	// first check keypress
	ldr r0, [r4] 
	cmp r0, #0 //any key pressed?
	beq check_timer //if not skip to timer check

	//else, clear edgeg capture and toggle timer
	mov r0, #0xF
	str r0, [r4] //clear edge capture
	
	cmp r8, #0 
	beq start_timer //if stopped (0) then start running
	b stop_timer //else stop timer
start_timer:
	mov r8, #1  //mark running (to be sure)
	
	//reset timer too
	ldr r0, =2000000
	str r0, [r9]

	mov r0, #0b11
	str r0, [r9, #8] 
	b loop

stop_timer:
	mov r8, #0 //mark stopped
	
	//write 0
	mov r0, #0
	str r0, [r9, #8] //write to control register
	b loop

check_timer:
	cmp r8, #0 //if timer stopped, keep polling
	beq loop
	//has .01 second passed as well?
	ldr r0, [r9, #12] //read interrupt status register
	and r0, r0, #1 //isolate f bit
	cmp r0, #1
	bne loop //if f not set go to loop
	
	//if set, clear f bit
	mov r0, #1
	str r0, [r9, #12]

	//update time counters
	
	//hundreths
	add r6, r6, #1
	cmp r6, #100 
	bne display_and_loop//if hundreths hasnt hit 100, just update display

	//dd hit 100
	mov r6, #0 
	add r7, r7, #1 //increment seconds once hundreths hit 100
	cmp r7, #60  //if seconds hit 60, reset it 
	moveq r7, #0

display_and_loop:
	bl display_time  //update dipslay
	b loop

//r7 = seconds r6 = hundreths
//one 32 bit word (hex3|hex2|hex1|hex0)
display_time:
	push {lr}

	mov r0, r6
	bl ones_digit
	bl seg7_code 
	mov r10, r0 //all above is getting ones digit

	//get 10s digit 
	mov r0, r6
	bl tens_digit
	bl seg7_code 
	lsl r0, r0, #8 //shift to bit 15-8 for hex1
	orr r10, r10, r0 //combine with hex0

	//het hex2 ones digit of ss
	mov r0, r7 
	bl ones_digit
	bl seg7_code
	lsl r0, r0, #16
	orr r10, r10, r0 //combine with prev

	 //get hex3 tens digit of seconds
        mov r0, r7
        bl tens_digit
        bl seg7_code
        lsl r0, r0, #24 // shift to bits 31-24 for hex3
        orr r10, r10, r0 // combine with rest

	str r10, [r5] //write all 4 digits to hex3-hex0

	pop {lr}
	bx lr //now return allat

tens_digit:
	push {lr}
	mov r1, #10
	bl divide
	mov r0, r2
	pop {lr}
	bx lr

ones_digit:
	push {lr}
	mov r1, #10
	bl divide
	pop {lr}
	bx lr
divide:
	mov r2, #0
div_loop:
	cmp r0, r1
	blt div_done
	sub r0, r0, r1
	add r2, r2, #1
	b div_loop
div_done:
	bx lr

seg7_code:  ldr     r1, =bit_codes  
            ldrb    r0, [r1, r0]    
            bx      lr              
.data
bit_codes:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment
          
.text
edge_base:   .word 0xFF200050
hex_base:    .word 0xFF200020
timer_base:  .word 0xFFFEC600
.end
