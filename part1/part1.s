.text
.global _start

_start:                             
          // initialization code here
		/* r4 = base address of key data register
		   r5 = base address of HEX0 display
		   r6 = current count (0-9)
		   r7 = scratch /temp for key reads */
		
		ldr r4, KEY_BASE
		ldr r5, HEX_BASE
		mov r6, #0  //count at 0

		bl 	display_digit //show initial zero
          	b	loop

loop:

          // loop code here
		ldr r7, [r4] //show initial val, read key register
		
		and r0, r7, #0x1 //check key0(bit 0)
		cmp r0, #0x1 
		beq key0_pressed

		and r0, r7, #0x2 //check key1 (bit1)
		cmp r0, #0x2
		beq key1_pressed
		
		and r0, r7, #0x4 //check key2
		cmp r0, #0x4
		beq key2_pressed

		and r0, r7, #0x8 //check key3
		cmp r0, #0x8
		beq key3_pressed

		b loop //nothing pressed then keep going thru loop

//reset counter for key0
key0_pressed:
		bl wait_release_0 //wait until key released
		mov r6, #0  //reset count
		bl display_digit //update display
		b loop

//increment countand display num)
key1_pressed:
		bl wait_release_1
		cmp r6, #9 
		addlt r6, r6, #1  //add only if count less than 9
		bl display_digit
		b loop

//decrement count
key2_pressed:
		bl wait_release_2
		cmp r6, #0
		subgt r6, r6, #1  //subtract if count > 0
		bl display_digit
		b loop

//blank the display
key3_pressed:
		bl wait_release_3
		mov r0, #0 //0x00 = all segments off
		str r0, [r5]  //write to hex0
		b loop



//convert digit in r0 to 7 seg bit pattern
seg7_code:  ldr     r1, =bit_codes  
            ldrb    r0, [r1, r0]    
            bx      lr
            

//display r6 on HEX0
display_digit: 
			push {lr}
	        mov     r0, r6          //put current count into r0 for seg7_code
                bl      seg7_code       //returns 7-seg bit code in r0
                str     r0, [r5]        //write bit code to HEX0
                pop {lr}
          

// wait_release subroutines: spin until the key is no longer held
wait_release_0:
	        ldr  r0, [r4]
	        and  r0, r0, #0x1
       		cmp  r0, #0x1
		beq  wait_release_0
       		bx   lr

wait_release_1:
        	ldr  r0, [r4]
        	and  r0, r0, #0x2
        	cmp  r0, #0x2
        	beq  wait_release_1
        	bx   lr

wait_release_2:
        	ldr  r0, [r4]
        	and  r0, r0, #0x4
        	cmp  r0, #0x4
        	beq  wait_release_2
        	bx   lr

wait_release_3:
        	ldr  r0, [r4]
        	and  r0, r0, #0x8
        	cmp  r0, #0x8
        	beq  wait_release_3
        	bx   lr
.data
bit_codes:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment
.text
KEY_BASE:      .word 0xFF200050
HEX_BASE:      .word 0xFF200020

.end
