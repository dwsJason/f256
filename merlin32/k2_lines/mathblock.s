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

FixedDivide mac
		stz |FP_MATH_CTRL2
		lda #$01C3    ; 2 fixed point input, output divide
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

		nop 	; 4  (14 clock latency on divide)
		nop 	; 8
		nop 	; 10
		nop     ; 12

		lda FP_MATH_OUTPUT_FIXED_HL
		pha
		lda FP_MATH_OUTPUT_FIXED_LL
		pha

		<<<

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

		lda FP_MATH_OUTPUT_FIXED_HL
		pha
		lda FP_MATH_OUTPUT_FIXED_LL
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

FixedSub mac
		sec
		pla
		sbc 3,s
		sta 3,s
		pla
		sbc 3,s
		sta 3,s
		<<<

atan2 mac
		pla
		sta math_abs_x
		pla
		sta math_abs_x+2	; pull x off the stack
		sta math_x+2
		bpl @xok			; value is positive
		lda math_abs_x  	; since negative negate the number
		eor #$FFFF
		inc
		sta math_abs_x  	; low negated
		bne @xok2   		; branch if no wrap on the high
		lda math_abs_x+2
		eor #$ffff
		inc 		   		; add one because low went to zero
		bra @stx2
@xok2
		lda math_abs_x+2
		eor #$ffff
@stx2	sta math_abs_x+2

@xok

		pla
		sta math_abs_y
		pla
		sta math_abs_y+2	; pull y off the stack
		sta math_y+2
		bpl @yok			; value is positive
		lda math_abs_y  	; negative, so need to negate, to make it positive
		eor #$FFFF
		inc
		sta math_abs_y
		bne @yok2
		lda math_abs_y+2
		eor #$ffff
		inc
		bra @sty2
@yok2
		lda math_abs_y+2
		eor #$ffff
@sty2	sta math_abs_y+2

@yok
		stz math_atan2_swap 			; no swap

		cmp math_abs_x+2
		bcc @no_swap			; y < x - no swap
		bne @swap
		; check the low part

		lda math_abs_y
		cmp math_abs_x
		bcc @no_swap
		beq @no_swap
@swap
		; y > x, so swap  - we only deal with slopes that are <= 1, so that
		; we don't have to deal with infinity / large values
		inc math_atan2_swap			; flag to mark swapped, for octant cleanup

		pei math_abs_x+2
		pei math_abs_x
		pei math_abs_y+2
		pei math_abs_y
		pla
		sta math_abs_x
		pla
		sta math_abs_x+2
		pla
		sta math_abs_y
		pla
		sta math_abs_y+2
@no_swap

		pei math_abs_y+2
		pei math_abs_y
		pei math_abs_x+2
		pei math_abs_x

		FixedDivide
		pea 512  		; PI=2048, so this is 1/4 PI, also this is times 16
		pea 0

		FixedMultiply
		pla

		; at this point angle is on the stack, but need to do octant fixup

		lda math_atan2_swap
		beq @no_swap2

		sec
		lda #1024
		sbc 1,s
		sta 1,s

@no_swap2

		lda	math_x+2
		bpl @xispos

		lda #2048
		sec
		sbc 1,s
		sta 1,s

@xispos
		lda math_y+2
		bpl @yispos

		pla
		eor #$FFFF
		inc
		pha

@yispos

		<<<

; Assume fixed-point representation, e.g., Q16.16
; Angle in brads (binary radians), where 0x4000 brads = PI
;int32_t fixed_point_atan2(int32_t y, int32_t x) {
;    int32_t abs_y = abs(y);
;    int32_t abs_x = abs(x);
;    int32_t angle;
;    bool swap_flag = false;
;
;    // Determine if swap is needed for first octant reduction
;    if (abs_y > abs_x) {
;        swap_flag = true;
;        int32_t temp = abs_x;
;        abs_x = abs_y;
;        abs_y = temp;
;    }
;
;    // Calculate ratio (abs_y / abs_x) - careful with fixed-point division
;    // This will be the argument for the atan lookup/calculation
;    int32_t ratio = fixed_point_divide(abs_y, abs_x);
;
;    // Calculate base angle in first octant (e.g., using lookup table with interpolation)
;    angle = fixed_point_atan_first_octant(ratio); 
;
;    // Apply octant corrections
;    if (swap_flag) {
;        angle = FIXED_POINT_PI_HALF - angle; // Equivalent to pi/2 - angle
;    }
;
;    if (x < 0) {
;        angle = FIXED_POINT_PI - angle; // Equivalent to pi - angle
;    }
;    if (y < 0) {
;        angle = -angle; // Equivalent to negating the angle
;    }
;
;    // Normalize angle to [0, 2*PI) or [-PI, PI) range if desired
;    // ...
;
;    return angle;
;}
