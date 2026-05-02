.text
.global _start

_start:                             
          // initialization code here
	/* r4 = key edge capture address
	   r5 = hex base adress
	   r6 = current count
	   r8 = timer state 1= running 0=stopped
	   r9 = timer base adress  */

	ldr r4, edge_base  //load key adres
	ldr r5, hex_base // load hex base adress
	ldr r9, timer_base // load timer base adress
	mov r6, #0 //count 
	mov r8, #0 //timer starts stopped

	//set edge-capture register to start
	mov r0, #0xF
	str r0, [r4]

	//clear the F bit in interrupt status register on startup
	mov r0, #1
	str r0,  [r9, #12] //write 1 to clear interrupt status
	
	bl display_count  //show 00 on startup

loop:

          // loop code here
	
	ldr r0, [r4] //read edge-capture register
	cmp r0, #0
	beq check_timer //no key pressed, skip toggle

	mov r0, #0xF
	str r0, [r4] //clear edge-capture bits

	cmp r8, #0
	beq start_timer //was stopped, start it
	b stop_timer //was running stop it

        b loop

start_timer:
	mov r8, #1 //start timer 
	
	ldr r0, =50000000
	str r0, [r9] //write load lregister
	
	mov r0, #0b11
	str r0, [r9, #8] //write to control register at 0xFFFEC608
	b loop

stop_timer:

	mov r8, #0 //mark timer stopped
	mov r0, #0b00
	str r0, [r9, #8]
	b loop

check_timer:

	//else, check if f bit is set
	ldr r0, [r9, #12]
	and r0, r0, #1
	cmp r0, #1
	bne loop//f bit not set then timer isnt done

	mov r0, #1 
	str r0, [r9, #12] //write 1 to clear f bit
	add r6, r6, #1 //add to count
	cmp r6, #100 
	moveq r6, #0 //reset to 0 when reaching 100
	bl display_count
	b loop

display_count:
	push {lr}
	mov r0, r6 
	bl ones_digit //get ones in r0 
	bl seg7_code //convert to 7 seg encoding
	mov r10,r0 //save the ones place in r10

	mov r0, r6 
	bl tens_digit //get tens digit in r
	bl seg7_code

	lsl r0,r0, #8 //shit tens into bits 15-8
	orr r0, r0, r10 //or in ones encoding
	str r0, [r5]
	
	pop {lr}
	bx lr

ones_digit: //copied
	push {lr}
	mov r1, #10
	bl divide //r0 = remainder r2 = quotient

	pop {lr}
	bx lr

tens_digit:
	push {lr}
	mov r1, #10
	bl divide 
	mov r0, r2
	pop {lr}
	bx lr



divide:
        mov  r2, #0
div_loop:
        cmp  r0, r1
        blt  div_done
        sub  r0, r0, r1
        add  r2, r2, #1
        b    div_loop
div_done:
        bx   lr             // r0 = remainder, r2 = quotient



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
