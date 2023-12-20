**************************************************
* FLAME.S
* @author Dagen Brock <dagenbrock@gmail.com>
* @date   2010-02-19
* @date   2023-11-23 F256 version -still unoptimized AF... lol
*
* This code is a mess (the lores routines mostly)
* but I've already spent to much time messing
* around with this and it was really just a proof
* of concept on the speed required to do a simple
* transform and to examine the potential of high
* framerate / low resolution video
**************************************************
	
** mapping for copy routines
srcPtr	equ ptr8
dstPtr	equ ptr10
** alternate mapping for averaging routine
srcPtrL	equ ptr10 ; again!
srcPtrR	equ ptr11
srcPtrD	equ ptr12

WIDTH	equ 80
HEIGHT	equ 20
		ds \
FBUF	ds WIDTH*HEIGHT+WIDTH	;extra line gets coals
		ds \
FBUFLEN	equ WIDTH*HEIGHT
LASTLINE	equ WIDTH*HEIGHT-WIDTH+FBUF

breaker dw #250
Start

** set default palette
		jsr SetColorIdxF256A

FIRE
		jsr MakeHeat
		jsr Scroll8
		jsr Average8
		lda #<100
		ldx #>100
		jsr WaitVBLPollAX
		jsr DrawBufFullScreen
		jsr Crackle
		; jsr SpriteToBuf ; draw a "K"
		dec breaker
		bne FIRE
		jsr BleepOff
		rts
		bra FIRE

SetAverage8Height 
		sta :avg8height
		rts
Average8  mx %11
	    lda #FBUF	; pointer to pixel
		sta srcPtr
		lda #>FBUF
		sta srcPtr+1

		lda #FBUF-#1	; pointer to pixel - 1
		sta srcPtrL
		lda #>FBUF-#1
		sta srcPtrL+1

		lda #FBUF+#1	; pointer to pixel + 1
		sta srcPtrR
		lda #>FBUF+#1
		sta srcPtrR+1

		lda #FBUF+WIDTH
		sta srcPtrD
		lda #>FBUF+WIDTH
		sta srcPtrD+1

		ldx #0	; lines

:avgLine	ldy #WIDTH-1
:lineLoop
		clc
		lda (srcPtr),y	;0
		adc (srcPtrL),y	;-1
		adc (srcPtrR),y	;+1
		adc (srcPtrD),y	;1+width
		beq :skipDec	; all zeros then skip everything
		;dec	; makes fire dissipate faster
		lsr
		lsr
:skipDec	sta (srcPtr),y	;0
		dey
		bne :lineLoop
		cpx #HEIGHT
:avg8height = *-1
		beq :doneLines
		inx	;next line

		;shift pointers up a "line"
		lda srcPtrD+1
		sta srcPtr+1
		sta srcPtrL+1	;\_ also copy this for math below.. 
		sta srcPtrR+1	;/  
		lda srcPtrD
		sta srcPtr

		;left pixel
		cmp #0
		bne :noPage	;if A != 0 we aren't crossing pages
		brk
		dec
		sta srcPtrL
		dec srcPtrL+1
		bra :rightPixel
:noPage	dec
		sta srcPtrL


:rightPixel
	lda srcPtr
	inc
	beq :zeroFlip	;0
	sta srcPtrR
	bra :bottomPixel
:zeroFlip	sta srcPtrR
	inc srcPtrR+1

:bottomPixel	;add to bottom line pointer
	lda srcPtrD
	clc
	adc #WIDTH
	sta srcPtrD
	lda srcPtrD+1
	adc #0
	sta srcPtrD+1
	bra :avgLine

:doneLines
	rts





SetColorIdxF256A
	ldx #$0f
:cloop	lda ColorIdxF256A,x
	sta ColorIdx,x
	dex
	bpl :cloop
	rts


SetColorIdxColor
	ldx #$0f
:cloop	lda ColorIdxColor,x
	sta ColorIdx,x
	dex
	bne :cloop
	rts

**************************************************
* Color look up table.
* Fire values 0 through F get translated to these
**************************************************
ColorIdx	ds 16	; we copy the palettes below to here

; character in active chartable
ColorIdxF256A
CharMap
	db $20
	db $B7	; single dot
	db $10  ; beginning of dithers
	db $11
	db $12
	db $13
	db $14
	db $15
	db $16
	db $17
	db $18
	db $19
	db $19
	db $19
	db $19
	* db $08
	db $ff

SetFireBlockFont	        lda $1
        pha
        lda #1
        sta $1 ; font set 0 now at c000 - c7ff

		ldy #0
:lp		lda ColorIdxF256A,y
		jsr CopyGlyph
		iny
		cpy #$10
		bne :lp

  		pla
        sta $1
        rts
	
CopyGlyph phy
		pha
		ldx #<$c000
		stx ptr0
		stx ptr1
		ldx #>$c000
		stx ptr0+1
		stx ptr1+1

		sta scratch
		stz scratch+1
		asl scratch
		rol scratch+1 ; *2
		asl scratch
		rol scratch+1 ; *4
		asl scratch
		rol scratch+1 ; *8
		lda scratch
		clc 
		adc ptr0
		sta ptr0
		lda scratch+1
		clc 
		adc ptr0+1
		sta ptr0+1

		tya		
		sta scratch
		stz scratch+1
		asl scratch
		rol scratch+1 ; *2
		asl scratch
		rol scratch+1 ; *4
		asl scratch
		rol scratch+1 ; *8
		lda scratch
		clc 
		adc ptr1
		sta ptr1
		lda scratch+1
		clc 
		adc ptr1+1
		sta ptr1+1
		* jsr ShowPtrs

	

		ldy #7
:copy	lda (ptr0),y
		sta (ptr1),y
		dey
		bpl :copy

		pla
		ply
		rts

ShowPtrs
		lda #2
		sta $1

		lda ptr0
		ldx ptr0+1
		ldy #0
		jsr TermPrintAXYH
		_TermCR

		
		lda ptr1
		ldx ptr1+1
		ldy #0
		jsr TermPrintAXYH
		_TermCR
f bra f		
		



ColorIdxColor	dfb #$00	; BLK / BLK
	dfb #$22	; D.BLU / D.BLU
	dfb #$55	; D.GRY / D.GRY
	dfb #$55	; D.GRY / D.GRY
	dfb #$12	; RED / D.BLUE
	dfb #$18	; RED / BROWN
	dfb #$98	; ORNG / BROWN
	dfb #$99	; ORNG / ORNG
	dfb #$b9	; PINK / ORNG
	dfb #$Db	; YELO / PINK
	dfb #$DD	; YELO / YELO
	dfb #$DD	; YELO / YELO
	dfb #$FD	; WHITE / YELO
	dfb #$FF	; WHITE / WHITE
	dfb #$FF	; WHITE / WHITE
	dfb #$FF	; WHITE / WHITE

]FLINE = Lo40
]FLCNT = #HEIGHT+1
]FLCUR = #0
DrawBufFullScreen
		lup ]FLCNT
		ldx #WIDTH
:loop   lda WIDTH*]FLCUR+FBUF,x
		;lda ColorIdx,y
		sta ]FLINE,x
		dex
		bpl :loop
]FLINE = ]FLINE+80
]FLCUR = ]FLCUR+1
		--^
		rts




**************************************************
* Simply copies each pixel in buffer up a line.
**************************************************
Scroll8   mx %11
*set source
		lda #FBUF+WIDTH
		sta srcPtr
		lda #>FBUF+WIDTH
		sta srcPtr+1

*set destination
		lda #FBUF
		sta dstPtr
		lda #>FBUF
		sta dstPtr+1

:movfwd	ldy #0
		ldx #0
		cpx #>FBUFLEN-WIDTH
		beq :frag
:page	lda (srcPtr),y
		sta (dstPtr),y
		iny
		bne :page
		inc srcPtr+1
		inc dstPtr+1
		inx
		cpx #>FBUFLEN-WIDTH
		bne :page
:frag	cpy #FBUFLEN-WIDTH
		beq :doneCopy
		lda (srcPtr),y
		sta (dstPtr),y
		iny
		bne :frag
:doneCopy	rts




**************************************************
* Very simple routine to lay down a line where
* all values are either 0 (cold) or F (hot)
**************************************************
MakeHeat
	* lda #0
	* sta LASTLINE	;FORCE CORNERS BLACK
	* sta LASTLINE+#39
	ldx #WIDTH
:mloop	;*jsr GetRandHot
	* sta LASTLINE,x
	jsr GetRandHot
	sta LASTLINE+WIDTH,x
	* sta LASTLINE,x
	dex
	bne :mloop

	rts

MakeHeatAlt
	ldx #WIDTH-10
:mloop	jsr GetRandHot

	sta LASTLINE+1-WIDTH-WIDTH-WIDTH-WIDTH-WIDTH-WIDTH-WIDTH-WIDTH,x
	sta LASTLINE+2-WIDTH-WIDTH-WIDTH-WIDTH-WIDTH-WIDTH-WIDTH,x
	dex
	bne :mloop

	rts



**************************************************
* Awesome PRNG thx to White Flame (aka David Holz)
**************************************************
GetRand
		lda RND
		beq :doEor
		asl
		bcc :noEor
:doEor	eor #$1d
:noEor	sta RND
		rts

GetRandHot
		jsr galois16o
		bra :foo
		lda RND
		beq :doEor
		asl
		bcc :noEor
:doEor	eor #$1d
:noEor	sta RND
:foo
		cmp #$98	; FIRE RATIO MOD
		bcs :hot
:not	lda #$12	; Note: this is normally #$0F but I'm boosting for more lows
		rts
:hot	lda #$00
		rts
RND		ds 1	; stores our ever changing random number





**************************************************
* Lores lines
**************************************************
Lo01      equ $c000
Lo02      equ $c000+#80
Lo03      equ $c000+#80*2
Lo04      equ $c000+#80*3
Lo05      equ $c000+#80*4
Lo06      equ $c000+#80*5
Lo07      equ $c000+#80*6
Lo08      equ $c000+#80*7
Lo09      equ $c000+#80*8
Lo10      equ $c000+#80*9
Lo11      equ $c000+#80*10
Lo12      equ $c000+#80*11
Lo13      equ $c000+#80*12
Lo14      equ $c000+#80*13
Lo15      equ $c000+#80*14
Lo16      equ $c000+#80*15
Lo17      equ $c000+#80*16
Lo18      equ $c000+#80*17
Lo19      equ $c000+#80*18
Lo20      equ $c000+#80*19
Lo21      equ $c000+#80*20
Lo22      equ $c000+#80*21
Lo23      equ $c000+#80*22
Lo24      equ $c000+#80*23
Lo25      equ $c000+#80*24
Lo26      equ $c000+#80*25
Lo27      equ $c000+#80*26
Lo28      equ $c000+#80*27
Lo29      equ $c000+#80*28
Lo30      equ $c000+#80*29
Lo31      equ $c000+#80*30
Lo32      equ $c000+#80*31
Lo33      equ $c000+#80*32
Lo34      equ $c000+#80*33
Lo35      equ $c000+#80*34
Lo36      equ $c000+#80*35
Lo37      equ $c000+#80*36
Lo38      equ $c000+#80*37
Lo39      equ $c000+#80*38
Lo40      equ $c000+#80*39
Lo41      equ $c000+#80*40
Lo42      equ $c000+#80*41
Lo43      equ $c000+#80*42
Lo44      equ $c000+#80*43
Lo45      equ $c000+#80*44
Lo46      equ $c000+#80*45
Lo47      equ $c000+#80*46
Lo48      equ $c000+#80*47

* * x=10,y=10
* SpriteToBuf
* 	lda #$0f
* 	sta WIDTH*14+FBUF+10
* 	sta WIDTH*14+FBUF+11
* 	sta WIDTH*14+FBUF+12

* 	lda #$0f
* 	sta WIDTH*15+FBUF+10
* 	sta WIDTH*15+FBUF+11
* 	sta WIDTH*15+FBUF+12

* 	lda #$0f
* 	sta WIDTH*16+FBUF+10
* 	sta WIDTH*16+FBUF+11
* 	sta WIDTH*16+FBUF+12
* 	sta WIDTH*16+FBUF+13
* 	sta WIDTH*16+FBUF+14

* 	lda #$0f
* 	sta WIDTH*17+FBUF+10
* 	sta WIDTH*17+FBUF+11
* 	sta WIDTH*17+FBUF+12


* 	rts
* SpriteXY	db $06,$05
* Sprite
* 	db $00,$01,$01,$01,$01,$00
* 	db $01,$0f,$0f,$0f,$0f,$10
* 	db $01,$0f,$0f,$0f,$0f,$10
* 	db $01,$0f,$0f,$0f,$0f,$10
* 	db $00,$01,$01,$01,$01,$00


* SPR_K_XY	db $14,$0c
* SPR_K	db $00,$fe,$fe,$fe,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$fe,$fe,$00,$00,$00,$00
* 	db $ff,$ff,$ff,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$fe,$ff,$ff,$ff,$ff,$00,$00,$00
* 	db $ff,$ff,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$fe,$ff,$ff,$ff,$ff,$ef,$ef,$00,$00,$00
* 	db $ff,$ff,$ff,$ff,$00,$00,$00,$00,$00,$fe,$ff,$ff,$ff,$ff,$00,$00,$00,$00,$00,$00,$00
* 	db $ff,$ff,$ff,$ff,$00,$00,$00,$00,$fe,$ff,$ff,$ff,$ef,$00,$00,$00,$00,$00,$00,$00,$00
* 	db $ff,$ff,$ff,$ff,$00,$00,$fe,$ff,$ff,$ff,$ef,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
* 	db $ff,$ff,$ff,$ff,$00,$fe,$ff,$ff,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
* 	db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fe,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
* 	db $ff,$ff,$ff,$ff,$ff,$ff,$ef,$ff,$ff,$ff,$ff,$fe,$00,$00,$00,$00,$00,$00,$00,$00,$00
* 	db $ff,$ff,$ff,$ff,$ef,$00,$00,$00,$ef,$ff,$ff,$ff,$fe,$00,$00,$00,$00,$00,$00,$00,$00
* 	db $ff,$ff,$ff,$ff,$00,$00,$00,$00,$00,$ef,$ff,$ff,$ff,$ff,$00,$00,$00,$00,$00,$00,$00
* 	db $ff,$ff,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$ef,$ff,$ff,$ff,$ff,$fe,$fe,$fe,$fe,$00
* 	db $ef,$ff,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$ef,$ef,$ff,$ff,$ff,$ff,$ff,$ef

