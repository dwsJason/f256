;
; Merlin32 Line draw example for Jr
;
; To Assemble "merlin32 -v . link.s"
;
		mx %11

; System Bus Pointer's
;pSource  equ $10
;pDest    equ pSource+4
; Do not use anything below $20, the mmu module owns it

	dum $20
temp0 ds 4
temp1 ds 4
temp2 ds 4
temp3 ds 4
temp4 ds 4
temp5 ds 4
temp6 ds 4
temp7 ds 4

line_color ds 1
line_x0 ds 2
line_y0 ds 1
line_x1 ds 2
line_y1 ds 1

target_x0 ds 2
target_y0 ds 1

target_x1 ds 2
target_y1 ds 1


cursor_x ds 2
cursor_y ds 2

	dend

PIXEL_DATA = $40000
DMA_CLEAR_ADDY = PIXEL_DATA
DMA_CLEAR_LEN  = 320*240

start

; This will copy the color table into memory, then set the video registers
; to display the bitmap

		jsr init320x240

		jsr initColors

		jsr TermInit

		ldx #70
		ldy #1
		jsr TermSetXY

		lda #<txt_title
		ldx #>txt_title
		jsr TermPUTS

		jsr mmu_unlock ; just being lazy here, don't use the mmu functions
					   ; $6000 is both read and write block

;------------------------------------------------------------------------------

		lda #2  	; Fill Color
		jsr DmaClear

;------------------------------------------------------------------------------
;
; Random Seed Init

		stz io_ctrl

		lda #$12
		sta |VKY_SEEDL
		lda #$34
		sta |VKY_SEEDH
		lda #3
		sta |VKY_RND_CTRL
		lda #1
		sta |VKY_RND_CTRL

;------------------------------------------------------------------------------

		do 0 ; random lines
		lda #$B
		sta line_color
]loop
		lda |VKY_RNDL
		sta <line_x0
		lda |VKY_RNDL
		sta <line_y0

		lda |VKY_RNDL
		sta <line_x1
		lda |VKY_RNDL
		sta <line_y1

		lda |VKY_RNDL
		and #$F
		sta line_color

		jsr plot_line

		bra ]loop
		fin



		lda #2
		sta io_ctrl

wow_loop

]x = 0
]y = 0

		lda #150+]x
		sta <line_x0
		sta <line_x1

		lda #150+]y
		sta <line_y0
		sta <line_y1

		;jsr plot_line

		ldx #160+]x
		ldy #150+]y
		jsr text_plot_too

		ldx #170+]x
		ldy #145+]y
		jsr text_plot_too

		ldx #180+]x
		ldy #135+]y
		jsr text_plot_too

		ldx #185+]x
		ldy #125+]y
		jsr text_plot_too

		ldx #185+]x 
		ldy #115+]y
		jsr text_plot_too

		ldx #180+]x 
		ldy #105+]y
		jsr text_plot_too

		ldx #170+]x
		ldy #95+]y
		jsr text_plot_too

		ldx #160+]x
		ldy #90+]y 
		jsr text_plot_too

		ldx #150+]x
		ldy #90+]y 
		jsr text_plot_too

		ldx #140+]x
		ldy #95+]y 
		jsr text_plot_too

		ldx #130+]x
		ldy #105+]y 
		jsr text_plot_too

		ldx #125+]x
		ldy #115+]y 
		jsr text_plot_too

		ldx #125+]x
		ldy #125+]y 
		jsr text_plot_too

		ldx #130+]x
		ldy #135+]y 
		jsr text_plot_too

		ldx #140+]x
		ldy #145+]y 
		jsr text_plot_too

		ldx #150+]x
		ldy #150+]y 
		jsr text_plot_too

		;lda line_color
		;inc
		;and #$F
		;sta line_color

		;jmp wow_loop

; Glyphy Test

		lda #8
		sta <cursor_x
		asl
		sta <cursor_y

;		lda #'A'
;		jsr vectorCOUT

		ldx #0
		phx
]loop
		lda :txt,x
		beq :done
		inx

		phx
		jsr vectorCOUT
		plx

		bra ]loop


:done	bra :done

:txt	asc ' !"#$%&'27'()*+,-./',0D
		asc '0123456789:;<=>?',0D
		asc '@ABCDEFGHIJKLMNO'0D
		db 0

;------------------------------------------------------------------------------

vectorCOUT
:pGlyph = temp6   ; seems like line doesn't use this
		cmp #13
		beq vlinef

		sec
		sbc #32
		asl
		tax
		lda vector_font,x
		sta :pGlyph
		lda vector_font+1,x
		sta :pGlyph+1

		ldy #0
]lp 	lda (:pGlyph),y
		beq :done

		phy
		pha

		and #$F
		tax

		clc
		lda vfont_points_x,x
		adc cursor_x
		sta line_x0
		clc
		lda vfont_points_y,x
		adc cursor_y
		sta line_y0

		pla
		and #$F0
		lsr
		lsr
		lsr
		lsr
		tax

		clc
		lda vfont_points_x,x
		adc cursor_x
		sta line_x1
		clc
		lda vfont_points_y,x
		adc cursor_y
		sta line_y1

		jsr plot_line

		ply
		iny
		bra ]lp

:done
		; fall through to cursor step
vcursor_step
		clc
		lda <cursor_x
		adc #14			; width, although these could kern
		sta <cursor_x
		cmp #240
		bcc :ok
vlinef	clc
		lda #8
		sta <cursor_x
		lda <cursor_y
		adc #16
		sta <cursor_y
		cmp #240-16
		bcc :ok
		lda #16
		sta <cursor_y
:ok
		rts

vfont_points_x
		db 0
		db -5,0,5
		db -5,0,5
		db -5,0,5
		db -5,0,5
		db -5,0,5

vfont_points_y
		db 0
		db -7,-7,-7
		db -5,-5,-5
		db 0,0,0
		db 5,5,5
		db 7,7,7
		

;------------------------------------------------------------------------------

init320x240
		php
		sei

		; Access to vicky generate registers
		stz io_ctrl

		; enable the graphics mode
;;		lda #%00001111	; gamma + bitmap + graphics + overlay + text
;		lda #%00000001	; text
		lda #%01111111  ; all the things
		sta VKY_MSTR_CTRL_0

		;lda #%110       ; text in 40 column when it's enabled
		;sta $D001
		;lda #6
		;lda #1 ; clock_70
		lda #0
		sta VKY_MSTR_CTRL_1

		; layer stuff - take from Jr manual
;		lda #$54
		lda #$10
		sta VKY_LAYER_CTRL_0  ; tile map layers
;		lda #$06
		lda #$02
		sta VKY_LAYER_CTRL_1  ; tile map layers

		; Tile Map 0
		lda #$11
		sta $D200 ; tile size 8x8 + enable

		; Tile Map Disable
		stz VKY_TM0_CTRL
		stz VKY_TM1_CTRL
		stz VKY_TM2_CTRL

		; bitmap disables
		lda #1
		stz VKY_BM0_CTRL  ; enable
		sta VKY_BM1_CTRL  ; disable
		stz $D110  ; disable

		; set address of image, since image uncompressed, we just display it
		; where we loaded it.
		lda #<PIXEL_DATA
		sta VKY_BM0_ADDR_L
		lda #>PIXEL_DATA
		sta VKY_BM0_ADDR_M
		lda #^PIXEL_DATA
		sta VKY_BM0_ADDR_H

		lda #<PIXEL_DATA
		sta VKY_BM1_ADDR_L
		lda #>PIXEL_DATA
		sta VKY_BM1_ADDR_M
		lda #^PIXEL_DATA
		sta VKY_BM1_ADDR_H

		lda #2
		sta io_ctrl
		plp

		rts
;------------------------------------------------------------------------------

txt_title asc 'Vectors'
		db 13,0

txt_plot asc 'Plot ('
		db 0
txt_too asc ') to ('
		db 0


;------------------------------------------------------------------------------
;
; A = Fill Color
;
; Clear 320x240 buffer PIXEL_DATA with A
;
DmaClear
		php
		sei

;]size = {320*240}
]size = DMA_CLEAR_LEN
;]addr = PIXEL_DATA
]addr = DMA_CLEAR_ADDY


		ldy io_ctrl
		phy

		stz io_ctrl

		ldx #DMA_CTRL_ENABLE+DMA_CTRL_FILL
		stx |DMA_CTRL

		sta |DMA_FILL_VAL

		lda #<]addr
		sta |DMA_DST_ADDR
		lda #>]addr
		sta |DMA_DST_ADDR+1
		lda #^]addr
		sta |DMA_DST_ADDR+2


		lda #<]size
		sta |DMA_COUNT
		lda #>]size
		sta |DMA_COUNT+1
		lda #^]size
		sta |DMA_COUNT+2

		lda #DMA_CTRL_START
		tsb |DMA_CTRL

]busy
		lda |DMA_STATUS
		bmi ]busy

		stz |DMA_CTRL

		pla
		sta io_ctrl

		plp

		rts

;------------------------------------------------------------------------------
plot_line
;		jmp plot_line_16x8y
		jmp plot_line_8x8y


		rts

;------------------------------------------------------------------------------
;
; no real regard given to performance, just make it work
;
plot_line_16x8y
		rts



;------------------------------------------------------------------------------
;
; no real regard given to performance, just make it work
;
plot_line_8x8y

:x0 = temp0
:y0 = temp0+2
:x1 = temp1
:y1 = temp1+2
:dx = temp2
:dy = temp2+1
:sx = temp3
:sy = temp3+1

:err  = temp4
:err2 = temp4+2

:temp0 = temp5

;----- copy inputs
		ldx <line_x0
		ldy <line_y0
		stx <:x0
		sty <:y0

		ldx <line_x1
		ldy <line_y1
		stx <:x1
		sty <:y1

;----- calulate dx + sx (delta x, and step x)
; dx = abs(x1 - x0)
; sx = x0 < x1 ? 1: -1  ; I'm doing 1 or 0
		cpx <:x0
		bcs :x_good

		sec
		lda <:x0
		sbc <:x1

		stz <:sx  ; indicate negative step
		bra :st_dx
:x_good
		lda #1
		sta <:sx  ; positive step
		txa
		sbc <:x0
:st_dx	sta <:dx

;----- calculate dy + sy (delta y, and step y)
; dy = -abs(y1 - y0)      ; I'm keeping this positive
; sy = y0 < y1 ? 1 : -1   ; I'm doing 1 or 0
:now_y
		cpy <:y0
		bcs :y_good

		sec
		lda <:y0
		sbc <:y1

		stz <:sy ; indicate negative step
		bra :st_dy
:y_good
		lda #1
		sta <:sy ; positive step
		tya
		sbc <:y0
:st_dy  sta <:dy

;----- calculate initial error
; error = dx + dy
		sec
		lda <:dx
		sbc <:dy
		sta <:err
		lda #0		; both dx and dy are only 8 bit, for now
		sbc #0
		sta <:err+1
]loop
		jsr PlotXY

; if x0==x1 && y0==y1 - done
		lda <:x0
		eor <:x1
		bne :go_go

		lda <:y0
		eor <:y1
		beq :done_done
:go_go
;----- calc e2
		lda <:err
		asl
		sta <:err2
		lda <:err+1
		rol
		sta <:err2+1
; if e2 >= (-dy)   (in original code dy is always negative)
;               (in our code dy is always positive)
		bpl :e2_ge_dy ; when error is positive, it's always greater=

		; if e2 is negative - 
		eor #$FF
		sta <:temp0+1

		lda <:err2
		eor #$FF
		inc
		sta <:temp0
		bne :kk
		inc <:temp0+1
:kk
		; temp0 is now a positive version of e2
		; now check to see if e2 <= dy

		lda <:temp0+1
		bne :next_thing

		lda <:temp0
		cmp <:dy
		bcc :e2_ge_dy
		beq :e2_ge_dy
		bcs :next_thing
:e2_ge_dy
		; if x0 == x1 break, break the if?
		lda <:x0
		eor <:x1
		beq :next_thing
		; error = error + dy
		sec
		lda <:err
		sbc <:dy
		sta <:err
		lda <:err+1
		sbc #0
		sta <:err+1
		; x0 = x0 + sx
		lda <:sx
		beq :dec_x
		inc <:x0
		bra :next_thing
:dec_x
		dec <:x0

:next_thing
; if e2 <= dx
		lda <:err2+1
		bmi :kk2	  ; if e2 negative, it's automatically smaller
		bne ]loop     ; dx can be 255 at the biggest, so err2+1 has to be 0
					  ; for e2 to be <= dx
		lda <:dx
		cmp <:err2
		bcc ]loop

:kk2
		; if y0 == y1 break
		lda <:y0
		eor <:y1
		beq ]loop
		; error = error + dx
		clc
		lda <:err
		adc <:dx
		sta <:err
		lda <:err+1
		adc #0
		sta <:err+1
		; y0 = y0 + sy
		lda <:sy
		beq :dec_y
		inc <:y0
		bra ]loop
:dec_y
		dec <:y0
		bra ]loop

:done_done
		rts

;------------------------------------------------------------------------------
;
; Version requires $6000 WRITE_BLOCK, so quicker detection of wrap
;
PlotXY
		ldx <:y0
		clc
		lda |:block_low_320,x   ; low byte of address in our mapped block
		adc <:x0
		sta |:p+1				; modify the store code, with abs address

		ldy |:block_num,x

		lda |:block_hi_320,x
		adc #0  				; Or adc x0+1 for 16-bit
		bpl :good_to_go 		; this check depends on block ending at 7FFF

		iny

		lda #>WRITE_BLOCK

:good_to_go
		sty <mmu3
		sta |:p+2
		lda line_color
:p		sta |WRITE_BLOCK

		rts


; I'm going to change this out to be an mmu+block + offset address
; simulating what the bitmap coordinate math block does



:block_low_320
]var = PIXEL_DATA
		lup 256
		db <]var
]var = ]var + 320
		--^

:block_hi_320
]var = PIXEL_DATA
		lup 256
		db >{{]var&$1FFF}+WRITE_BLOCK}
]var = ]var + 320
		--^

:block_num
]var = PIXEL_DATA
		lup 256
		db {]var/$2000}
]var = ]var + 320
		--^

;------------------------------------------------------------------------------

text_plot_too
		lda <line_x1
		sta <line_x0

		lda <line_y1
		sta <line_y0

		stx <line_x1
		sty <line_y1

		; comment this line out, to get the text
		jmp plot_line


		lda #<txt_plot
		ldx #>txt_plot
		jsr TermPUTS

		lda <line_x0
		jsr TermPrintAI  ; AI only goes to 99

		lda #$2C ; ','
		jsr TermCOUT

		lda <line_y0
		jsr TermPrintAI

		lda #<txt_too
		ldx #>txt_too
		jsr TermPUTS

		lda <line_x1
		jsr TermPrintAI

		lda #$2C ; ','
		jsr TermCOUT

		lda <line_y1
		jsr TermPrintAI

		lda #$29 ;')'
		jsr TermCOUT
		jsr TermCR

		;stz <io_ctrl

		jsr plot_line

		;lda #2
		;sta <io_ctrl
		rts



;------------------------------------------------------------------------------

WaitVBLPoll
		lda $1
		pha
		stz $1
LINE_NO = 241*2
        lda #<LINE_NO
        ldx #>LINE_NO
:waitforlineAX		
]wait
        cpx $D01B
        beq ]wait
]wait
        cmp $D01A
        beq ]wait

]wait
        cpx $D01B
        bne ]wait
]wait
        cmp $D01A
        bne ]wait
		pla 
		sta $1
        rts

;------------------------------------------------------------------------------
;
;   1   2   3
;   4   5   6
;
;
;   7   8   9
;
;
;   A   B   C
;   D   E   F
;
;------------------------------------------------------------------------------
;
;   0  1  2  3
;
;   4  5  6  7 
;
;   8  9  A  B
;
;   C  D  E  F
;
;------------------------------------------------------------------------------
;   *---*---*    *-0-*-1-*
;   |\  |  /|    |\  |  /|
;   | \ | / |    2 3 4 5 6
;   |  \|/  |    |  \|/  |
;   *---*---*    *-7-*-8-*
;   |  /|\  |    |  /|\  |
;   | / | \ |    9 A B C D
;   |/  |  \|    |/  |  \|
;   *---*---*    *-E-*-F-*
;------------------------------------------------------------------------------
;
; line segment font
;
;LED_SEG0 = %0000_0000_0000_0001
;LED_SEG1 = %0000_0000_0000_0010
;LED_SEG2 = %0000_0000_0000_0100
;LED_SEG3 = %0000_0000_0000_1000
;LED_SEG4 = %0000_0000_0001_0000
;LED_SEG5 = %0000_0000_0010_0000
;LED_SEG6 = %0000_0000_0100_0000
;LED_SEG7 = %0000_0000_1000_0000
;LED_SEG8 = %0000_0001_0000_0000
;LED_SEG9 = %0000_0010_0000_0000
;LED_SEGA = %0000_0100_0000_0000
;LED_SEGB = %0000_1000_0000_0000
;LED_SEGC = %0001_0000_0000_0000
;LED_SEGD = %0010_0000_0000_0000
;LED_SEGE = %0100_0000_0000_0000
;LED_SEGF = %1000_0000_0000_0000
;
;LED_SPACE  = $00
;LED_PERIOD = $FF
;
;line_segment_font
;	dw LED_SPACE
;	dw LED_SEG2.LED_SEG9
;	dw LED_SEG4.LED_SEG6


vector_font

		da :space,:bang,:quote,:hash,:dolla,:prcnt,:and,:squot
		da :lpren,:rpren,:star,:plus,:comma,:minus,:peri,:slash
		da :0,:1,:2,:3,:4,:5,:6,:7
		da :8,:9,:colon,:semi,:lt,:equ,:gt,:quest
		da :at,:A,:B,:C,:D,:E,:F,:G,:H,:I,:J,:K,:L,:M,:N,:O

;------------------------------------------------------------------------------
;
;   1   2   3
;   4   5   6
;
;
;   7   8   9
;
;
;   A   B   C
;   D   E   F
;
;------------------------------------------------------------------------------


:space hex 00                   ;
:bang  hex 477ADD00             ; !
:quote hex 253600               ; "
:hash  hex 5b4679ac00           ; #
:dolla hex 2E4647799cac00       ; $
:prcnt hex 4578475889bc8b9cd300 ; %
:and   hex 00                   ; &
:squot hex 2500                 ; '
:lpren hex 535bbf00             ; (
:rpren hex 155BBD00             ; )
:star  hex 4C79A600             ; *
:plus  hex 795B00               ; +
:comma hex AD00 				; ,
:minus hex 7900					;
:peri  hex DD00                 ; .
:slash hex A600                 ; /
:0     hex 42266cceeaa4A600     ; 0
:1     hex 755B00               ; 1
:2     hex 4679AC697A00         ; 2
:3     hex 466CAC8900           ; 3
:4     hex 47796C00             ; 4
:5     hex 4679AC479C00         ; 5
:6     hex 4679AC4A9C00         ; 6
:7     hex 466C00               ; 7
:8     hex 4679AC4A6C00         ; 8
:9     hex 4679AC476C00         ; 9
:colon hex 55BB00               ; :
:semi  hex 55BE00               ; ;
:lt    hex 767C00               ; <
:equ   hex 79AC00               ; =
:gt    hex 49A900               ; >
:quest hex 4669898BEE00         ; ?
:at    hex 4AAC4689586900       ; @
:A     hex 7A57599C7900         ; A
:B     hex 46AC5B6C8900  		; B
:C     hex 464AAC00             ; C
:D     hex 46AC5B6C00           ; D
:E     hex 46AC784A00           ; E
:F     hex 46784A00             ; F
:G     hex 46AC4A9C8900         ; G
:H     hex 4A796C00             ; H
:I     hex 465bac00             ; I
:J     hex 7AAEEC6C00           ; J
:K     hex 4A78868C00           ; K
:L     hex 4AAC00               ; L
:M     hex 4A48866C00           ; M
:N     hex 4A6C4C00             ; N
:O     hex 46AC4A6C00           ; O



;
;
;  2PI = 256
;
sintable_lo
	hex 00488fd5175690c4f1173347504d3e22f7bd7419ad2e9cf539687f7f6736eb85
	hex 0468aed8e4d19f4ddb4894bec5aa6b0983d80914faba53c7143b3a13c44eb1ec

sintable_hi
	hex 00060c12191f252b31383e444a50565c61676d73787e83888e93989da2a7abb0
	hex b5b9bdc1c5c9cdd1d4d8dbdee1e4e7eaeceef1f3f4f6f8f9fbfcfdfefeffffff

costable_lo
	hex 00fffffffefefdfcfbf9f8f6f4f3f1eeeceae7e4e1dedbd8d4d1cdc9c5c1bdb9
	hex b5b0aba7a29d98938e88837e78736d67615c56504a443e38312b251f19120c06

costable_hi
	hex 00ecb14ec4133a3b14c753bafa1409d883096baac5be9448db4d9fd1e4d8ae68
	hex 0485eb36677f7f6839f59c2ead1974bdf7223e4d50473317f1c4905617d58f48

;sin cos table
;0   0.000000 1.000000 00 100  0000 10000
;1   0.024541 0.999699 06 ff   0648  ffec
;2   0.049068 0.998795 0c ff   0c8f  ffb1
;3   0.073565 0.997290 12 ff   12d5  ff4e
;4   0.098017 0.995185 19 fe   1917  fec4
;5   0.122411 0.992480 1f fe   1f56  fe13
;6   0.146730 0.989177 25 fd   2590  fd3a
;7   0.170962 0.985278 2b fc   2bc4  fc3b
;8   0.195090 0.980785 31 fb   31f1  fb14
;9   0.219101 0.975702 38 f9   3817  f9c7
;10  0.242980 0.970031 3e f8   3e33  f853
;11  0.266713 0.963776 44 f6   4447  f6ba
;12  0.290285 0.956940 4a f4   4a50  f4fa
;13  0.313682 0.949528 50 f3   504d  f314
;14  0.336890 0.941544 56 f1   563e  f109
;15  0.359895 0.932993 5c ee   5c22  eed8
;16  0.382683 0.923880 61 ec   61f7  ec83
;17  0.405241 0.914210 67 ea   67bd  ea09
;18  0.427555 0.903989 6d e7   6d74  e76b
;19  0.449611 0.893224 73 e4   7319  e4aa
;20  0.471397 0.881921 78 e1   78ad  e1c5
;21  0.492898 0.870087 7e de   7e2e  debe
;22  0.514103 0.857729 83 db   839c  db94
;23  0.534998 0.844854 88 d8   88f5  d848
;24  0.555570 0.831470 8e d4   8e39  d4db
;25  0.575808 0.817585 93 d1   9368  d14d
;26  0.595699 0.803208 98 cd   987f  cd9f
;27  0.615232 0.788346 9d c9   9d7f  c9d1
;28  0.634393 0.773010 a2 c5   a267  c5e4
;29   0.653173 0.757209 a7 c1 a736 c1d8
;30   0.671559 0.740951 ab bd abeb bdae
;31  0.689541 0.724247 b0 b9   b085  b968
;32  0.707107 0.707107 b5 b5   b504  b504
;33  0.724247 0.689541 b9 b0   b968  b085
;34  0.740951 0.671559 bd ab   bdae  abeb
;35  0.757209 0.653173 c1 a7   c1d8  a736
;36  0.773010 0.634393 c5 a2   c5e4  a267
;37  0.788346 0.615232 c9 9d   c9d1  9d7f
;38  0.803208 0.595699 cd 98   cd9f  987f
;39  0.817585 0.575808 d1 93   d14d  9368
;40  0.831470 0.555570 d4 8e   d4db  8e39
;41  0.844854 0.534998 d8 88   d848  88f5
;42  0.857729 0.514103 db 83   db94  839c
;43  0.870087 0.492898 de 7e   debe  7e2e
;44  0.881921 0.471397 e1 78   e1c5  78ad
;45  0.893224 0.449611 e4 73   e4aa  7319
;46  0.903989 0.427555 e7 6d   e76b  6d74
;47  0.914210 0.405241 ea 67   ea09  67bd
;48  0.923880 0.382683 ec 61   ec83  61f7
;49  0.932993 0.359895 ee 5c   eed8  5c22
;50  0.941544 0.336890 f1 56   f109  563e
;51  0.949528 0.313682 f3 50   f314  504d
;52  0.956940 0.290285 f4 4a   f4fa  4a50
;53  0.963776 0.266713 f6 44   f6ba  4447
;54  0.970031 0.242980 f8 3e   f853  3e33
;55  0.975702 0.219101 f9 38   f9c7  3817
;56  0.980785 0.195090 fb 31   fb14  31f1
;57  0.985278 0.170962 fc 2b   fc3b  2bc4
;58  0.989177 0.146730 fd 25   fd3a  2590
;59  0.992480 0.122411 fe 1f   fe13  1f56
;60  0.995185 0.098017 fe 19   fec4  1917
;61  0.997290 0.073565 ff 12   ff4e  12d5
;62  0.998795 0.049068 ff 0c   ffb1  0c8f
;63  0.999699 0.024541 ff 06   ffec  0648
;64 1.00000 -0.000000 100 00  10000  0000




