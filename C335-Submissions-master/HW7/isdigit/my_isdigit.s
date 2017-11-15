/* my_isdigit.s */

	        .text
	        .syntax unified
	        .thumb
	        .global my_isdigit

my_isdigit:
	        movs    r1, r0          @ copy arg
	        movs    r0, #1          @ 'true'
	        cmp     r1, #'0'        @ is the character below '0' in ASCII?
	        it      lo
	        movlo   r0, #0          @ yes, it's not a digit
	        cmp     r1, #'9'        @ no, see if it's above '9' is ASCII
	        it      hi
	        movhi   r0, #0          @ yes, it's not a digit
	        bx      lr              @ return to caller