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

; 16 bit load
ldxy mac
	if #=]1

	ldx #<]1
	ldy #>]1

	else

	ldx ]1
	ldy ]1+1

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

; 16 bit push / pop
phax mac
	pha
	phx
	<<<

plax mac
	plx
	pla
	<<<


; 16 bit dec
dexy mac
	dex
	bne skip
	dey
	cpy #$FF
skip
	<<<

; Long Conditional Branches

beql mac
    bne skip@
    jmp ]1
skip@
    <<<

bnel mac
    beq skip@
    jmp ]1
skip@
    <<<

bccl mac
    bcs skip@
    jmp ]1
skip@
    <<<

bcsl mac
    bcc skip@
    jmp ]1
skip@
    <<<

bpll mac
	bmi skip@
	jmp ]1
skip@
    <<<

bmil mac
	bpl skip@
	jmp ]1
skip@
    <<<

cstr mac
	asc ]1
	db 0
	<<<
;-------------------------------------------------------------------------------
; print X;Y;'CSTRING'
print mac
	ldx #]1
	ldy #]2
	jsr TermSetXY
	ldax #datastr
	jsr TermPUTS
	bra skip
datastr cstr ]3
skip
	eom


