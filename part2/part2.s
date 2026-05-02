.text
.global _start

_start:                             
          // initialization code here
	/* r4 = edge-capture register address (0xFF20005C)
           r5 = HEX0-1 base address (0xFF200020)
           r6 = current count (0 to 99)
       	   r7 = scratch / delay counter
           r8 = timer state (0=stopped, 1=running) */

	ldr  r4, EDGE_BASE      // load edge-capture address
        ldr  r5, HEX_BASE       // load hex base address
        mov  r6, #0             // count timer at 0
        mov  r8, #0             // timer starts stopped

        // clear edge-capture register on startup
        mov  r7, #0xF
        str  r7, [r4]

        bl   display_count      // show 00 on startup

loop:

          // loop code here
	ldr r7, [r4]  //read edge-capture reg
	cmp r7, #0   
	beq check_running //break if key not pressed

	//id pressed: clear edge-capture and toggle state
	mov r7, #0xF
	str r7, [r4] //clearing edge capture
	cmp r8, #0
	moveq r8, #1   //was stopped, now running
	movne r8, #0  //was running, now stopped

check_running:
	cmp r8, #0 //check timer
	beq loop //if stopped, keep polling

	//if running, do delay, then add and display
	ldr r7, =200000000 

sub_loop:
	subs r7, r7, #1
	bne sub_loop
	
	//increment count
	add r6, r6, #1
	cmp r6, #100
	moveq r6, #0  //reset when reaching 100
	
	bl display_count //update display
	b loop

//split r6 into tens and ones, looks up both, and combines into one word
display_count:
	push {lr}
	mov r0, r6
	bl ones_digit //returns one digit in r0
	bl seg7_code //return 7 seg encode
	mov r9, r0   //save the ones spot

	//get 10s
	mov r0, r6
	bl tens_digit 
	bl seg7_code

	//combine ones and tens hex1 bits 15-8 hex0 bits 7-0
	lsl r0, r0, #8 // hex1 is in bits 15-8, so put bit in position before ORing
	orr r0, r0, r9  // or in ones encoding LOOKED UP OPERATOR preforms bitwiser or operation
	str r0, [r5] //write both digits to hex1-hex0

	pop {lr}
	bx lr

//returns r6 % 10 in r0
ones_digit:
	push {lr}
	mov r1, #10
	bl divide //r2 = quotient, r0 = remainder
	//r0 already holds remainder
	pop {lr}
	bx lr

//returns r6 /10 in r0
tens_digit:
	push {lr}
	mov r1, #10
	bl divide
	mov r0, r2
	pop {lr}
	bx lr

divide:
	mov r2, #0
div_loop:
	cmp r0,r1
	blt div_done
	sub r0, r0, r1 
	add r2,r2, #1
	b div_loop
div_done:
	//r0 now holds remainde, r2 holds quotient
	bx lr

seg7_code:  ldr     r1, =bit_codes  
            ldrb    r0, [r1, r0]    
            bx      lr              
.data
bit_codes:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment 
.text
EDGE_BASE: .word 0xFF20005C
HEX_BASE:   .word 0xFF200020
         
.end
