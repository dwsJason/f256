;------------------------------------------------------------------------------
;
; mathblock.s - mathblock accelerated math module
;
;------------------------------------------------------------------------------
;
; The idea here is to support general math, but also make it as easy as
; possible using a stack base post operational expressions
;
; The current implementation is experiemental, currently toying with the idea
; of using the actual S register for my stack
;
; using an INDEX register like X might be nicer
;
; or perhaps supporting both mechanims.
;
; I think I will see what the actual code looks like, and refactor until
; it does something that I actually like
;
;------------------------------------------------------------------------------
;To evaluate 3 4 + 5 * in RPN:
;
;    Push 3 onto the stack.
;    Push 4 onto the stack.
;    Encounter +: Pop 4 and 3, calculate 3 + 4 = 7, and push 7 onto the stack.
;    Push 5 onto the stack.
;    Encounter *: Pop 5 and 7, calculate 7 * 5 = 35, and push 35 onto the stack.
;    The result 35 is now on the stack. 
;
;Key advantages:
;
;    No need for parentheses: RPN eliminates the need for parentheses to define
;    operator precedence. 
;
;Left-to-right evaluation: RPN expressions are evaluated strictly from left to
;right, simplifying the evaluation process. 
;Efficient for computers: The stack-based approach is well-suited for computer
; processing, leading to faster calculations. 
;------------------------------------------------------------------------------

PushFixed mac
		pea #{]1/16}
		pea #{]1*4096}
		<<<

;
; Pull a fixed point number from the stack, convert to int, result in A
;
PullInt mac
		tsx
		lda 3,s
		asl 1,x
		rol
		asl 1,x
		rol
		asl 1,x
		rol
		asl 1,x
		rol
		plx
		ply
		<<<

;------------------------------------------------------------------------------
; Take 2 fixed point numbers on the stack
;
;  Input Stack:
;                fixed point 1
;                fixed point 2
;
;  Output Stack:
;                fixed point result
;

FixedMultiplyC mx %00

		rts

FixedMultiply mac
		stz |FP_MATH_CTRL2
		lda #$0003    ; 2 fixed point input, output multiply
		sta |FP_MATH_CTRL0

		pla
		sta FP_MATH_INPUT1_LL
		pla
		sta FP_MATH_INPUT1_HL

		pla
		sta FP_MATH_INPUT0_LL
		pla
		sta FP_MATH_INPUT0_HL

		lda #$A
		sta |FP_MATH_CTRL2

		nop

		lda FP_MATH_OUTPUT_FIXED_LL
		ldx FP_MATH_OUTPUT_FIXED_HL
		phx
		pha
		<<<

;------------------------------------------------------------------------------
; Take 2 fixed point numbers on the stack
;
;  Input Stack:
;                fixed point 1
;                fixed point 2
;
;  Output Stack:
;                fixed point result
;

; 1,3,5,7

FixedAddC mx %00
		plx 	 ; return address off the stack
		clc 	 ; c=0
		pla
		adc 3,s
		sta 3,s
		pla
		adc 3,s
		sta 3,s
		phx
		rts

FixedAdd mac
		clc 	 ; c=0
		pla
		adc 3,s
		sta 3,s
		pla
		adc 3,s
		sta 3,s
		<<<

