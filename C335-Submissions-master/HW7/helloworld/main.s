 .syntax unified
	        .thumb
	        .text
	        .global main
main:
	        push {lr}             @ save return address on stack
	        ldr  r0, =message     @ load &message into r0
	        bl   printf           @ call printf
	        movs r0, #0           @ prepare to return 0
	        pop  {pc}             @ return (pc = saved lr)

	       .data
message:
	       .ascii "Hello, World\n"
	       .byte 0