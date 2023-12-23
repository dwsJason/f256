;------------------------------------------------------------------------------
;
;  Machine ID, and hardware version check
;
		mx %11

MIN_JR_VERSION = $00170100
MIN_K_VERSION  = $00130000

HasGoodHardware

;------------------------------------------------------------------------------
		do 0  ; peek at the registers, debug
		jsr TermInit

		stz io_ctrl
		lda VKY_CHV0
		ldx VKY_CHV1

		ldy #2
		sty io_ctrl
		jsr TermPrintAXH
		lda #' '
		jsr TermCOUT

		stz io_ctrl
		lda VKY_CHSV0
		ldx VKY_CHSV1

		ldy #2
		sty io_ctrl
		jsr TermPrintAXH

]done
		bra ]done
		fin
;------------------------------------------------------------------------------

		jsr TermInit

		stz io_ctrl

		lda VKY_MID
		and #$1F		; only lower 5 bits valid?

		cmp #MID_F256_K
		beq :HasF256K
		cmp #MID_F256
		beq :HasF256Jr

		ldax #txt_unknown_machine
:msg
		ldy #2
		sty io_ctrl			; page in text memory
		jsr TermPUTS
:die
		bra :die 


; in mine, 9599 0017 0100
:HasF256Jr

		lda VKY_CHV1
		cmp #^{MIN_JR_VERSION/256}
		beq :cc0   		    ; equal, keep checking
		bcc :jr_fail		; less than, bad
		bcs :rts   			; it's good, because >

:cc0	lda VKY_CHV0
		cmp #^MIN_JR_VERSION
		beq :cc1             ; equal, keep checking
		bcs :rts            ; >, it's good
		bcc :jr_fail        ; < fail
:cc1
		lda VKY_CHSV1
		cmp #>MIN_JR_VERSION
		beq :cc2 			; equal, keep checking
		bcs :rts            ; >, it's good
		bcc :jr_fail		; < fail
:cc2
		lda VKY_CHSV0
		cmp #<MIN_JR_VERSION  
		bcs :rts            ; >= good

:jr_fail
		ldax #txt_requiredJ
		bra :msg

:rts	rts


; 9601 0013 0000
:HasF256K

		lda VKY_CHV1
		cmp #^{MIN_K_VERSION/256}
		beq :c0    		    ; equal, keep checking
		bcc :k_fail		; less than, bad
		bcs :rts   			; it's good, because >

:c0		lda VKY_CHV0
		cmp #^MIN_K_VERSION
		beq :c1             ; equal, keep checking
		bcs :rts            ; >, it's good
		bcc :k_fail        ; < fail
:c1
		lda VKY_CHSV1
		cmp #>MIN_K_VERSION
		beq :c2 			; equal, keep checking
		bcs :rts            ; >, it's good
		bcc :k_fail		; < fail
:c2
		lda VKY_CHSV0
		cmp #<MIN_K_VERSION  
		bcs :rts            ; >= good

:k_fail
		ldax #txt_requiredK
		bra :msg

txt_unknown_machine asc 'Unknown Machine',0D
			asc 'This demo requires an F256K/Jr to run.',0D,00

txt_requiredJ asc 'F256M_Wbh_Nov18th_2023_RC17_0100.jic,'
			  asc ' or higher required',0D,00

txt_requiredK asc 'F256K_WBh_Dec9th_RevB0x_RC13_0000.jic,'
			  asc ' or higher required',0D,00


		
