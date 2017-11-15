/* my_iswhite.s */

	        .text
	        .syntax unified
	        .thumb
	        .global myiswhite

myiswhite:	
	        movs    r1, r0          @ Copy Arg
	        movs    r0, #1          @ 'True'
	        cmp     r1, #32         @ ASCII Space
		beq	equal
		cmp	r1, #09		@ ASCII Horizontal Tab
		beq 	equal
		cmp	r1, #13		@ ASCII Carriage Return
		beq	equal
		cmp	r1, #10		@ ASCII Line Feed
		beq 	equal
		cmp 	r1, #12		@ ASCII Form Feed
		beq	equal		
		cmp	r1, #11		@ ASCII Vertical Tab


equal:
		bx	lr
		