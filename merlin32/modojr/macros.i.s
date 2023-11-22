;
; Jason's Macros for dealing to make 8 bit cpu stuff easier?
;

; 24 bit load
ldaxy mac
	if #=]1

	lda #<]1
	ldx #>]1
	ldy #^]1

	else

	lda ]1
	ldx ]1+1
	ldy ]1+2

	fin

	<<<

; 24 bit store
staxy mac

	sta ]1
	stx ]1+1
	sty ]1+2

	<<<

; 16 bit load
ldax mac
	if #=]1

	lda #<]1
	ldx #>]1

	else

	lda ]1
	ldx ]1+1

	fin

	<<<

; 16 bit store
stax mac

	sta ]1
	stx ]1+1

	<<<

; 16 bit compare
cmpax mac
	if #=]1

	cpx #>]1
	bne @done
	cmp #<]1
@done
	else

	cpx ]1+1
	bne @done
	cmp ]1
@done
	fin

	<<<




