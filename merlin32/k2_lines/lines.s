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
line_x1 ds 2

line_y0 ds 1
line_y1 ds 1

target_x0 ds 2
target_y0 ds 1

target_x1 ds 2
target_y1 ds 1


cursor_x ds 2
cursor_y ds 2

line_x ds 2
line_y ds 2

display_buffer ds 2

	dend

;K
;PIXEL_DATA = $40000
;K2 with 2MB of RAM (NOTE My SOFTWARE LINE DRAW WONT WORK WITH THIS)
; 2 pixel buffers from $5A800 -> $7FFFF
;PIXEL_DATA  = $6D400  ; Top of 512k
;PIXEL_DATA2 = $5A800  ; 

PIXEL_DATA  = $1ED400  ; Top of 2MB
PIXEL_DATA2 = $1DA800  ; 


DMA_CLEAR_ADDY = PIXEL_DATA
DMA_CLEAR_LEN  = 320*240

start  	mx %11
		sei
		clc
		xce

; This will copy the color table into memory, then set the video registers
; to display the bitmap

		jsr init320x240

		jsr initColors

		jsr TermInit

		ldx #69
		ldy #1
		jsr TermSetXY

		lda #<txt_title
		ldx #>txt_title
		jsr TermPUTS

		jsr mmu_unlock ; just being lazy here, don't use the mmu functions
					   ; $6000 is both read and write block

;------------------------------------------------------------------------------

		jsr WaitVBLPoll
		lda #2  	; Fill Color
		jsr DmaClearPixelData

		jsr WaitVBLPoll
		lda #2
		jsr DmaClearPixelData2

; Pump Swap Chain

		stz display_buffer
		jsr SwapChain

;------------------------------------------------------------------------------
;
; Random Seed Init

		stz io_ctrl

		lda #$34
		sta |VKY_SEEDL
		lda #$FF
		sta |VKY_SEEDH
		lda #3
		sta |VKY_RND_CTRL
		nop
		nop
		lda #1
		sta |VKY_RND_CTRL

;------------------------------------------------------------------------------

		stz line_x1+1
		stz line_x0+1

		lda #15
		sta line_color

;------------------------------------------------------------------------------

		do 0 ; random lines
		lda #$B
		sta line_color

]loop
		lda |VKY_RNDL
		sta <line_x0
		lda |VKY_RNDH
		sta <line_x1


		lda |VKY_RNDL
		and #$7f
		sta <line_y0
		lda |VKY_RNDH
		and #$3f
		adc <line_y0
		sta <line_y0
		lda |VKY_RNDL
		and #$1f
		adc <line_y0
		sta <line_y0

		lda |VKY_RNDH
		and #$7f
		sta <line_y1

		lda line_color
		inc
		and #$F
		sta line_color

		jsr plot_line

		stz io_ctrl

		bra ]loop
		fin

		lda #2
		sta io_ctrl

		stz line_y
		stz line_y+1
		stz line_x
		stz line_x+1

wow_loop mx %11
		sep #$30

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

:done
		plx

		jsr SwapChain
		brl wow_loop

		bra :done

:txt	asc ' !"#$%&'27'()*+,-./',0D
		asc '0123456789:;<=>?',0D
		asc '@ABCDEFGHIJKLMNO'0D
		asc 'PQRSTUVWXYZ[\]^_'0D
		asc '`abcdefghijklmno'0D
		asc 'pqrstuvwxyz{|}~'0D
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

		lda #1  		   	; enable line drawing
		sta VKY_MSTR_CTRL_2

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
		sta VKY_BM1_CTRL  ; enable
		stz VKY_BM2_CTRL  ; disable

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

SwapChain mx %11
		php
		sep #$30
		lda io_ctrl
		pha
		stz io_ctrl
		rep #$30

		; Step 1, wait for line draw hardware to finish
]wait_fifo
		lda |LINE_FIFO_LO
		and #$FFF
		bne ]wait_fifo

		lda #LINE_CTRL_FIFO_RESET
		tsb LINE_CTRL
		trb LINE_CTRL

		jsr WaitVBLPoll

		lda <display_buffer
		inc
		and #1
		sta <display_buffer
		
		beq :show0_draw1
		;show1_draw0

		lda #<PIXEL_DATA2
		sta VKY_BM1_ADDR_L
		lda #>PIXEL_DATA2
		sta VKY_BM1_ADDR_L+1

		lda #<PIXEL_DATA
		sta VKY_BM0_ADDR_L
		lda #>PIXEL_DATA
		sta VKY_BM0_ADDR_L+1

		sep #$30
		lda #2
		jsr DmaClearPixelData
		bra :done

:show0_draw1 mx %00

		lda #<PIXEL_DATA
		sta VKY_BM1_ADDR_L
		lda #>PIXEL_DATA
		sta VKY_BM1_ADDR_L+1

		lda #<PIXEL_DATA2
		sta VKY_BM0_ADDR_L
		lda #>PIXEL_DATA2
		sta VKY_BM0_ADDR_L+1

		sep #$30
		lda #2
		jsr DmaClearPixelData2

:done
		sep #$30
		pla
		sta io_ctrl

		plp
		mx %11
		rts


;------------------------------------------------------------------------------

txt_title asc 'K2 Vectors'
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
DmaClearPixelData
		php
		sei

;]size = {320*240}
]size = DMA_CLEAR_LEN
;]addr = PIXEL_DATA
]addr = DMA_CLEAR_ADDY


		ldy io_ctrl
		phy

		stz io_ctrl

		ldx #DMA_CTRL_ENABLE.DMA_CTRL_FILL.DMA_CTRL_16BITS
		stx |DMA_CTRL

		sta |DMA_FILL_VAL
		sta |DMA_FILL_VAL+1
		sta |DMA_FILL_VAL+2
		sta |DMA_FILL_VAL+3

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


DmaClearPixelData2
		php
		sei

;]size = {320*240}
]size = DMA_CLEAR_LEN
;]addr = PIXEL_DATA
]addr = PIXEL_DATA2


		ldy io_ctrl
		phy

		stz io_ctrl

		ldx #DMA_CTRL_ENABLE.DMA_CTRL_FILL.DMA_CTRL_16BITS
		stx |DMA_CTRL

		sta |DMA_FILL_VAL
		sta |DMA_FILL_VAL+1
		sta |DMA_FILL_VAL+2
		sta |DMA_FILL_VAL+3

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
;		jmp plot_line_8x8y

		jmp plot_line_hw


		rts

;------------------------------------------------------------------------------
plot_line_hw
		stz io_ctrl

		; Hardware Accelerated Line
		lda <line_color
		sta LINE_COLOR

		rep #$10

		ldx <line_x0
		ldy <line_x1

		;ldx #10
		stx |LINE_X0
		;ldx #300
		sty |LINE_X1

		ldx <line_y0  ; grabs both y0 and y1

		;ldx #$8080
		stx |LINE_Y0  ; sets both

		lda #3    ; 2 works for loading
		sta |LINE_CTRL

]wait	lda |LINE_CTRL	; wait for line to be queued into FIFO
		bpl ]wait

		lda #1  	   	
		sta |LINE_CTRL  ; keep FIFO running

		sep #$30

		lda #2
		sta io_ctrl
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
		php
		sei
		sep #$30
		pha
		lda io_ctrl
		stz io_ctrl

		pha
		rep #$30

LINE_NO = 261*2
        lda #LINE_NO
]wait
		cmp $D01A
		bne ]wait

		sep #$30
		pla
		sta io_ctrl
		pla

		plp
		mx %11
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
		da :P,:Q,:R,:S,:T,:U,:V,:W,:X,:Y,:Z,:lb,:back,:rb,:carot,:under
		da :btick,:a,:b,:c,:d,:e,:f,:g,:h,:i,:j,:k,:l,:m,:n,:o
		da :p,:q,:r,:s,:t,:u,:v,:w,:x,:y,:z,:lcurl,:vbar,:rcurl,:tilda

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
:P     hex 4A46796900			; P
:Q     hex 46ac4a6c8F00         ; Q
:R     hex 4A46798C6900         ; R
:S     hex 4679ac479c00         ; S
:T     hex 465b00               ; T
:U     hex 4aac6c00             ; U
:V     hex 4bb600               ; V
:W     hex 4aa88c6c00           ; W
:X     hex 4ca600               ; X
:Y     hex 48868b00             ; Y
:Z     hex 466aac00             ; Z
:lb    hex 232eef00             ; [
:back  hex 4C00                 ; \
:rb    hex 122ede00             ; ]
:carot hex 755900               ; ^
:under hex DF00                 ; _
:btick hex 1500                 ; `
:a     hex 7a78AB8E00           ; a
:b     hex 4a788bab00           ; b
:c     hex 78ab7a00             ; c
:d     hex 89bc8b6c00           ; d
:e     hex 7a78aba800           ; e
:f     hex 5b795600             ; f
:g     hex 4578475bab00         ; g
:h     hex 4a788b00             ; h
:i     hex 8b5500               ; i
:j     hex 225b7aab00           ; j
:k     hex 5b868c00             ; k
:l     hex 4a00                 ; l
:m     hex 797a8b9c00           ; m
:n     hex 7a788b00             ; n
:o     hex 78ab7a8b00           ; o
:p     hex 4a45785800           ; p
:q     hex 4578475b00           ; q
:r     hex 7a7800               ; r
:s     hex 478b4578ab00         ; s
:t     hex 4a78ab00             ; t
:u     hex 7A8BAB00             ; u
:v     hex 7AA800               ; v
:w     hex 7AA88C9C00           ; w
:x     hex 7BA800               ; x
:y     hex 586cbc8900           ; y
:z     hex 788AAB00             ; z
:lcurl hex 785B53BF00 			; {
:vbar  hex 2E00                 ; |
:rcurl hex 895B15DB00           ; }
:tilda hex 42532500             ; ~

;------------------------------------------------------------------------------
;
;  2PI = 4096
;  4.12 format
;

sin_table
	dw $0000,$0006,$000c,$0012,$0019,$001f,$0025,$002b
	dw $0032,$0038,$003e,$0045,$004b,$0051,$0057,$005e
	dw $0064,$006a,$0071,$0077,$007d,$0083,$008a,$0090
	dw $0096,$009d,$00a3,$00a9,$00af,$00b6,$00bc,$00c2
	dw $00c8,$00cf,$00d5,$00db,$00e2,$00e8,$00ee,$00f4
	dw $00fb,$0101,$0107,$010d,$0114,$011a,$0120,$0127
	dw $012d,$0133,$0139,$0140,$0146,$014c,$0152,$0159
	dw $015f,$0165,$016b,$0172,$0178,$017e,$0184,$018b
	dw $0191,$0197,$019d,$01a4,$01aa,$01b0,$01b6,$01bd
	dw $01c3,$01c9,$01cf,$01d6,$01dc,$01e2,$01e8,$01ef
	dw $01f5,$01fb,$0201,$0208,$020e,$0214,$021a,$0221
	dw $0227,$022d,$0233,$0239,$0240,$0246,$024c,$0252
	dw $0259,$025f,$0265,$026b,$0271,$0278,$027e,$0284
	dw $028a,$0290,$0297,$029d,$02a3,$02a9,$02af,$02b6
	dw $02bc,$02c2,$02c8,$02ce,$02d5,$02db,$02e1,$02e7
	dw $02ed,$02f3,$02fa,$0300,$0306,$030c,$0312,$0318
	dw $031f,$0325,$032b,$0331,$0337,$033d,$0344,$034a
	dw $0350,$0356,$035c,$0362,$0368,$036f,$0375,$037b
	dw $0381,$0387,$038d,$0393,$0399,$03a0,$03a6,$03ac
	dw $03b2,$03b8,$03be,$03c4,$03ca,$03d0,$03d7,$03dd
	dw $03e3,$03e9,$03ef,$03f5,$03fb,$0401,$0407,$040d
	dw $0413,$041a,$0420,$0426,$042c,$0432,$0438,$043e
	dw $0444,$044a,$0450,$0456,$045c,$0462,$0468,$046e
	dw $0474,$047a,$0480,$0486,$048c,$0492,$0498,$049e
	dw $04a5,$04ab,$04b1,$04b7,$04bd,$04c3,$04c9,$04cf
	dw $04d5,$04db,$04e0,$04e6,$04ec,$04f2,$04f8,$04fe
	dw $0504,$050a,$0510,$0516,$051c,$0522,$0528,$052e
	dw $0534,$053a,$0540,$0546,$054c,$0552,$0558,$055d
	dw $0563,$0569,$056f,$0575,$057b,$0581,$0587,$058d
	dw $0593,$0599,$059e,$05a4,$05aa,$05b0,$05b6,$05bc
	dw $05c2,$05c7,$05cd,$05d3,$05d9,$05df,$05e5,$05eb
	dw $05f0,$05f6,$05fc,$0602,$0608,$060e,$0613,$0619
	dw $061f,$0625,$062b,$0630,$0636,$063c,$0642,$0648
	dw $064d,$0653,$0659,$065f,$0664,$066a,$0670,$0676
	dw $067b,$0681,$0687,$068d,$0692,$0698,$069e,$06a3
	dw $06a9,$06af,$06b5,$06ba,$06c0,$06c6,$06cb,$06d1
	dw $06d7,$06dc,$06e2,$06e8,$06ed,$06f3,$06f9,$06fe
	dw $0704,$070a,$070f,$0715,$071b,$0720,$0726,$072b
	dw $0731,$0737,$073c,$0742,$0748,$074d,$0753,$0758
	dw $075e,$0763,$0769,$076f,$0774,$077a,$077f,$0785
	dw $078a,$0790,$0795,$079b,$07a0,$07a6,$07ac,$07b1
	dw $07b7,$07bc,$07c2,$07c7,$07cd,$07d2,$07d7,$07dd
	dw $07e2,$07e8,$07ed,$07f3,$07f8,$07fe,$0803,$0809
	dw $080e,$0813,$0819,$081e,$0824,$0829,$082e,$0834
	dw $0839,$083f,$0844,$0849,$084f,$0854,$085a,$085f
	dw $0864,$086a,$086f,$0874,$087a,$087f,$0884,$088a
	dw $088f,$0894,$0899,$089f,$08a4,$08a9,$08af,$08b4
	dw $08b9,$08be,$08c4,$08c9,$08ce,$08d3,$08d9,$08de
	dw $08e3,$08e8,$08ee,$08f3,$08f8,$08fd,$0902,$0908
	dw $090d,$0912,$0917,$091c,$0921,$0927,$092c,$0931
	dw $0936,$093b,$0940,$0945,$094b,$0950,$0955,$095a
	dw $095f,$0964,$0969,$096e,$0973,$0978,$097d,$0982
	dw $0987,$098d,$0992,$0997,$099c,$09a1,$09a6,$09ab
	dw $09b0,$09b5,$09ba,$09bf,$09c4,$09c9,$09ce,$09d3
	dw $09d7,$09dc,$09e1,$09e6,$09eb,$09f0,$09f5,$09fa
	dw $09ff,$0a04,$0a09,$0a0e,$0a12,$0a17,$0a1c,$0a21
	dw $0a26,$0a2b,$0a30,$0a35,$0a39,$0a3e,$0a43,$0a48
	dw $0a4d,$0a51,$0a56,$0a5b,$0a60,$0a65,$0a69,$0a6e
	dw $0a73,$0a78,$0a7c,$0a81,$0a86,$0a8b,$0a8f,$0a94
	dw $0a99,$0a9d,$0aa2,$0aa7,$0aac,$0ab0,$0ab5,$0aba
	dw $0abe,$0ac3,$0ac8,$0acc,$0ad1,$0ad5,$0ada,$0adf
	dw $0ae3,$0ae8,$0aec,$0af1,$0af6,$0afa,$0aff,$0b03
	dw $0b08,$0b0c,$0b11,$0b15,$0b1a,$0b1f,$0b23,$0b28
	dw $0b2c,$0b31,$0b35,$0b3a,$0b3e,$0b42,$0b47,$0b4b
	dw $0b50,$0b54,$0b59,$0b5d,$0b62,$0b66,$0b6a,$0b6f
	dw $0b73,$0b78,$0b7c,$0b80,$0b85,$0b89,$0b8d,$0b92
	dw $0b96,$0b9a,$0b9f,$0ba3,$0ba7,$0bac,$0bb0,$0bb4
	dw $0bb8,$0bbd,$0bc1,$0bc5,$0bca,$0bce,$0bd2,$0bd6
	dw $0bda,$0bdf,$0be3,$0be7,$0beb,$0bef,$0bf4,$0bf8
	dw $0bfc,$0c00,$0c04,$0c08,$0c0d,$0c11,$0c15,$0c19
	dw $0c1d,$0c21,$0c25,$0c29,$0c2d,$0c31,$0c36,$0c3a
	dw $0c3e,$0c42,$0c46,$0c4a,$0c4e,$0c52,$0c56,$0c5a
	dw $0c5e,$0c62,$0c66,$0c6a,$0c6e,$0c72,$0c76,$0c79
	dw $0c7d,$0c81,$0c85,$0c89,$0c8d,$0c91,$0c95,$0c99
	dw $0c9d,$0ca0,$0ca4,$0ca8,$0cac,$0cb0,$0cb4,$0cb7
	dw $0cbb,$0cbf,$0cc3,$0cc7,$0cca,$0cce,$0cd2,$0cd6
	dw $0cd9,$0cdd,$0ce1,$0ce5,$0ce8,$0cec,$0cf0,$0cf3
	dw $0cf7,$0cfb,$0cfe,$0d02,$0d06,$0d09,$0d0d,$0d11
	dw $0d14,$0d18,$0d1c,$0d1f,$0d23,$0d26,$0d2a,$0d2d
	dw $0d31,$0d35,$0d38,$0d3c,$0d3f,$0d43,$0d46,$0d4a
	dw $0d4d,$0d51,$0d54,$0d58,$0d5b,$0d5f,$0d62,$0d65
	dw $0d69,$0d6c,$0d70,$0d73,$0d77,$0d7a,$0d7d,$0d81
	dw $0d84,$0d87,$0d8b,$0d8e,$0d91,$0d95,$0d98,$0d9b
	dw $0d9f,$0da2,$0da5,$0da9,$0dac,$0daf,$0db2,$0db6
	dw $0db9,$0dbc,$0dbf,$0dc2,$0dc6,$0dc9,$0dcc,$0dcf
	dw $0dd2,$0dd5,$0dd9,$0ddc,$0ddf,$0de2,$0de5,$0de8
	dw $0deb,$0dee,$0df2,$0df5,$0df8,$0dfb,$0dfe,$0e01
	dw $0e04,$0e07,$0e0a,$0e0d,$0e10,$0e13,$0e16,$0e19
	dw $0e1c,$0e1f,$0e22,$0e25,$0e28,$0e2b,$0e2d,$0e30
	dw $0e33,$0e36,$0e39,$0e3c,$0e3f,$0e42,$0e44,$0e47
	dw $0e4a,$0e4d,$0e50,$0e53,$0e55,$0e58,$0e5b,$0e5e
	dw $0e60,$0e63,$0e66,$0e69,$0e6b,$0e6e,$0e71,$0e74
	dw $0e76,$0e79,$0e7c,$0e7e,$0e81,$0e84,$0e86,$0e89
	dw $0e8b,$0e8e,$0e91,$0e93,$0e96,$0e98,$0e9b,$0e9e
	dw $0ea0,$0ea3,$0ea5,$0ea8,$0eaa,$0ead,$0eaf,$0eb2
	dw $0eb4,$0eb7,$0eb9,$0ebc,$0ebe,$0ec0,$0ec3,$0ec5
	dw $0ec8,$0eca,$0ecd,$0ecf,$0ed1,$0ed4,$0ed6,$0ed8
	dw $0edb,$0edd,$0edf,$0ee2,$0ee4,$0ee6,$0ee8,$0eeb
	dw $0eed,$0eef,$0ef2,$0ef4,$0ef6,$0ef8,$0efa,$0efd
	dw $0eff,$0f01,$0f03,$0f05,$0f08,$0f0a,$0f0c,$0f0e
	dw $0f10,$0f12,$0f14,$0f16,$0f18,$0f1b,$0f1d,$0f1f
	dw $0f21,$0f23,$0f25,$0f27,$0f29,$0f2b,$0f2d,$0f2f
	dw $0f31,$0f33,$0f35,$0f37,$0f39,$0f3b,$0f3c,$0f3e
	dw $0f40,$0f42,$0f44,$0f46,$0f48,$0f4a,$0f4b,$0f4d
	dw $0f4f,$0f51,$0f53,$0f55,$0f56,$0f58,$0f5a,$0f5c
	dw $0f5d,$0f5f,$0f61,$0f63,$0f64,$0f66,$0f68,$0f69
	dw $0f6b,$0f6d,$0f6e,$0f70,$0f72,$0f73,$0f75,$0f77
	dw $0f78,$0f7a,$0f7b,$0f7d,$0f7f,$0f80,$0f82,$0f83
	dw $0f85,$0f86,$0f88,$0f89,$0f8b,$0f8c,$0f8e,$0f8f
	dw $0f91,$0f92,$0f94,$0f95,$0f96,$0f98,$0f99,$0f9b
	dw $0f9c,$0f9d,$0f9f,$0fa0,$0fa1,$0fa3,$0fa4,$0fa5
	dw $0fa7,$0fa8,$0fa9,$0fab,$0fac,$0fad,$0fae,$0fb0
	dw $0fb1,$0fb2,$0fb3,$0fb4,$0fb6,$0fb7,$0fb8,$0fb9
	dw $0fba,$0fbb,$0fbd,$0fbe,$0fbf,$0fc0,$0fc1,$0fc2
	dw $0fc3,$0fc4,$0fc5,$0fc6,$0fc7,$0fc8,$0fc9,$0fca
	dw $0fcb,$0fcc,$0fcd,$0fce,$0fcf,$0fd0,$0fd1,$0fd2
	dw $0fd3,$0fd4,$0fd5,$0fd6,$0fd7,$0fd8,$0fd9,$0fd9
	dw $0fda,$0fdb,$0fdc,$0fdd,$0fde,$0fde,$0fdf,$0fe0
	dw $0fe1,$0fe1,$0fe2,$0fe3,$0fe4,$0fe4,$0fe5,$0fe6
	dw $0fe7,$0fe7,$0fe8,$0fe9,$0fe9,$0fea,$0feb,$0feb
	dw $0fec,$0fec,$0fed,$0fee,$0fee,$0fef,$0fef,$0ff0
	dw $0ff0,$0ff1,$0ff1,$0ff2,$0ff2,$0ff3,$0ff3,$0ff4
	dw $0ff4,$0ff5,$0ff5,$0ff6,$0ff6,$0ff7,$0ff7,$0ff7
	dw $0ff8,$0ff8,$0ff9,$0ff9,$0ff9,$0ffa,$0ffa,$0ffa
	dw $0ffb,$0ffb,$0ffb,$0ffb,$0ffc,$0ffc,$0ffc,$0ffc
	dw $0ffd,$0ffd,$0ffd,$0ffd,$0ffe,$0ffe,$0ffe,$0ffe
	dw $0ffe,$0ffe,$0fff,$0fff,$0fff,$0fff,$0fff,$0fff
	dw $0fff,$0fff,$0fff,$0fff,$0fff,$0fff,$0fff,$0fff
	dw $1000,$0fff,$0fff,$0fff,$0fff,$0fff,$0fff,$0fff
	dw $0fff,$0fff,$0fff,$0fff,$0fff,$0fff,$0fff,$0ffe
	dw $0ffe,$0ffe,$0ffe,$0ffe,$0ffe,$0ffd,$0ffd,$0ffd
	dw $0ffd,$0ffc,$0ffc,$0ffc,$0ffc,$0ffb,$0ffb,$0ffb
	dw $0ffb,$0ffa,$0ffa,$0ffa,$0ff9,$0ff9,$0ff9,$0ff8
	dw $0ff8,$0ff7,$0ff7,$0ff7,$0ff6,$0ff6,$0ff5,$0ff5
	dw $0ff4,$0ff4,$0ff3,$0ff3,$0ff2,$0ff2,$0ff1,$0ff1
	dw $0ff0,$0ff0,$0fef,$0fef,$0fee,$0fee,$0fed,$0fec
	dw $0fec,$0feb,$0feb,$0fea,$0fe9,$0fe9,$0fe8,$0fe7
	dw $0fe7,$0fe6,$0fe5,$0fe4,$0fe4,$0fe3,$0fe2,$0fe1
	dw $0fe1,$0fe0,$0fdf,$0fde,$0fde,$0fdd,$0fdc,$0fdb
	dw $0fda,$0fd9,$0fd9,$0fd8,$0fd7,$0fd6,$0fd5,$0fd4
	dw $0fd3,$0fd2,$0fd1,$0fd0,$0fcf,$0fce,$0fcd,$0fcc
	dw $0fcb,$0fca,$0fc9,$0fc8,$0fc7,$0fc6,$0fc5,$0fc4
	dw $0fc3,$0fc2,$0fc1,$0fc0,$0fbf,$0fbe,$0fbd,$0fbb
	dw $0fba,$0fb9,$0fb8,$0fb7,$0fb6,$0fb4,$0fb3,$0fb2
	dw $0fb1,$0fb0,$0fae,$0fad,$0fac,$0fab,$0fa9,$0fa8
	dw $0fa7,$0fa5,$0fa4,$0fa3,$0fa1,$0fa0,$0f9f,$0f9d
	dw $0f9c,$0f9b,$0f99,$0f98,$0f96,$0f95,$0f94,$0f92
	dw $0f91,$0f8f,$0f8e,$0f8c,$0f8b,$0f89,$0f88,$0f86
	dw $0f85,$0f83,$0f82,$0f80,$0f7f,$0f7d,$0f7b,$0f7a
	dw $0f78,$0f77,$0f75,$0f73,$0f72,$0f70,$0f6e,$0f6d
	dw $0f6b,$0f69,$0f68,$0f66,$0f64,$0f63,$0f61,$0f5f
	dw $0f5d,$0f5c,$0f5a,$0f58,$0f56,$0f55,$0f53,$0f51
	dw $0f4f,$0f4d,$0f4b,$0f4a,$0f48,$0f46,$0f44,$0f42
	dw $0f40,$0f3e,$0f3c,$0f3b,$0f39,$0f37,$0f35,$0f33
	dw $0f31,$0f2f,$0f2d,$0f2b,$0f29,$0f27,$0f25,$0f23
	dw $0f21,$0f1f,$0f1d,$0f1b,$0f18,$0f16,$0f14,$0f12
	dw $0f10,$0f0e,$0f0c,$0f0a,$0f08,$0f05,$0f03,$0f01
	dw $0eff,$0efd,$0efa,$0ef8,$0ef6,$0ef4,$0ef2,$0eef
	dw $0eed,$0eeb,$0ee8,$0ee6,$0ee4,$0ee2,$0edf,$0edd
	dw $0edb,$0ed8,$0ed6,$0ed4,$0ed1,$0ecf,$0ecd,$0eca
	dw $0ec8,$0ec5,$0ec3,$0ec0,$0ebe,$0ebc,$0eb9,$0eb7
	dw $0eb4,$0eb2,$0eaf,$0ead,$0eaa,$0ea8,$0ea5,$0ea3
	dw $0ea0,$0e9e,$0e9b,$0e98,$0e96,$0e93,$0e91,$0e8e
	dw $0e8b,$0e89,$0e86,$0e84,$0e81,$0e7e,$0e7c,$0e79
	dw $0e76,$0e74,$0e71,$0e6e,$0e6b,$0e69,$0e66,$0e63
	dw $0e60,$0e5e,$0e5b,$0e58,$0e55,$0e53,$0e50,$0e4d
	dw $0e4a,$0e47,$0e44,$0e42,$0e3f,$0e3c,$0e39,$0e36
	dw $0e33,$0e30,$0e2d,$0e2b,$0e28,$0e25,$0e22,$0e1f
	dw $0e1c,$0e19,$0e16,$0e13,$0e10,$0e0d,$0e0a,$0e07
	dw $0e04,$0e01,$0dfe,$0dfb,$0df8,$0df5,$0df2,$0dee
	dw $0deb,$0de8,$0de5,$0de2,$0ddf,$0ddc,$0dd9,$0dd5
	dw $0dd2,$0dcf,$0dcc,$0dc9,$0dc6,$0dc2,$0dbf,$0dbc
	dw $0db9,$0db6,$0db2,$0daf,$0dac,$0da9,$0da5,$0da2
	dw $0d9f,$0d9b,$0d98,$0d95,$0d91,$0d8e,$0d8b,$0d87
	dw $0d84,$0d81,$0d7d,$0d7a,$0d77,$0d73,$0d70,$0d6c
	dw $0d69,$0d65,$0d62,$0d5f,$0d5b,$0d58,$0d54,$0d51
	dw $0d4d,$0d4a,$0d46,$0d43,$0d3f,$0d3c,$0d38,$0d35
	dw $0d31,$0d2d,$0d2a,$0d26,$0d23,$0d1f,$0d1c,$0d18
	dw $0d14,$0d11,$0d0d,$0d09,$0d06,$0d02,$0cfe,$0cfb
	dw $0cf7,$0cf3,$0cf0,$0cec,$0ce8,$0ce5,$0ce1,$0cdd
	dw $0cd9,$0cd6,$0cd2,$0cce,$0cca,$0cc7,$0cc3,$0cbf
	dw $0cbb,$0cb7,$0cb4,$0cb0,$0cac,$0ca8,$0ca4,$0ca0
	dw $0c9d,$0c99,$0c95,$0c91,$0c8d,$0c89,$0c85,$0c81
	dw $0c7d,$0c79,$0c76,$0c72,$0c6e,$0c6a,$0c66,$0c62
	dw $0c5e,$0c5a,$0c56,$0c52,$0c4e,$0c4a,$0c46,$0c42
	dw $0c3e,$0c3a,$0c36,$0c31,$0c2d,$0c29,$0c25,$0c21
	dw $0c1d,$0c19,$0c15,$0c11,$0c0d,$0c08,$0c04,$0c00
	dw $0bfc,$0bf8,$0bf4,$0bef,$0beb,$0be7,$0be3,$0bdf
	dw $0bda,$0bd6,$0bd2,$0bce,$0bca,$0bc5,$0bc1,$0bbd
	dw $0bb8,$0bb4,$0bb0,$0bac,$0ba7,$0ba3,$0b9f,$0b9a
	dw $0b96,$0b92,$0b8d,$0b89,$0b85,$0b80,$0b7c,$0b78
	dw $0b73,$0b6f,$0b6a,$0b66,$0b62,$0b5d,$0b59,$0b54
	dw $0b50,$0b4b,$0b47,$0b42,$0b3e,$0b3a,$0b35,$0b31
	dw $0b2c,$0b28,$0b23,$0b1f,$0b1a,$0b15,$0b11,$0b0c
	dw $0b08,$0b03,$0aff,$0afa,$0af6,$0af1,$0aec,$0ae8
	dw $0ae3,$0adf,$0ada,$0ad5,$0ad1,$0acc,$0ac8,$0ac3
	dw $0abe,$0aba,$0ab5,$0ab0,$0aac,$0aa7,$0aa2,$0a9d
	dw $0a99,$0a94,$0a8f,$0a8b,$0a86,$0a81,$0a7c,$0a78
	dw $0a73,$0a6e,$0a69,$0a65,$0a60,$0a5b,$0a56,$0a51
	dw $0a4d,$0a48,$0a43,$0a3e,$0a39,$0a35,$0a30,$0a2b
	dw $0a26,$0a21,$0a1c,$0a17,$0a12,$0a0e,$0a09,$0a04
	dw $09ff,$09fa,$09f5,$09f0,$09eb,$09e6,$09e1,$09dc
	dw $09d7,$09d3,$09ce,$09c9,$09c4,$09bf,$09ba,$09b5
	dw $09b0,$09ab,$09a6,$09a1,$099c,$0997,$0992,$098d
	dw $0987,$0982,$097d,$0978,$0973,$096e,$0969,$0964
	dw $095f,$095a,$0955,$0950,$094b,$0945,$0940,$093b
	dw $0936,$0931,$092c,$0927,$0921,$091c,$0917,$0912
	dw $090d,$0908,$0902,$08fd,$08f8,$08f3,$08ee,$08e8
	dw $08e3,$08de,$08d9,$08d3,$08ce,$08c9,$08c4,$08be
	dw $08b9,$08b4,$08af,$08a9,$08a4,$089f,$0899,$0894
	dw $088f,$088a,$0884,$087f,$087a,$0874,$086f,$086a
	dw $0864,$085f,$085a,$0854,$084f,$0849,$0844,$083f
	dw $0839,$0834,$082e,$0829,$0824,$081e,$0819,$0813
	dw $080e,$0809,$0803,$07fe,$07f8,$07f3,$07ed,$07e8
	dw $07e2,$07dd,$07d7,$07d2,$07cd,$07c7,$07c2,$07bc
	dw $07b7,$07b1,$07ac,$07a6,$07a0,$079b,$0795,$0790
	dw $078a,$0785,$077f,$077a,$0774,$076f,$0769,$0763
	dw $075e,$0758,$0753,$074d,$0748,$0742,$073c,$0737
	dw $0731,$072b,$0726,$0720,$071b,$0715,$070f,$070a
	dw $0704,$06fe,$06f9,$06f3,$06ed,$06e8,$06e2,$06dc
	dw $06d7,$06d1,$06cb,$06c6,$06c0,$06ba,$06b5,$06af
	dw $06a9,$06a3,$069e,$0698,$0692,$068d,$0687,$0681
	dw $067b,$0676,$0670,$066a,$0664,$065f,$0659,$0653
	dw $064d,$0648,$0642,$063c,$0636,$0630,$062b,$0625
	dw $061f,$0619,$0613,$060e,$0608,$0602,$05fc,$05f6
	dw $05f0,$05eb,$05e5,$05df,$05d9,$05d3,$05cd,$05c7
	dw $05c2,$05bc,$05b6,$05b0,$05aa,$05a4,$059e,$0599
	dw $0593,$058d,$0587,$0581,$057b,$0575,$056f,$0569
	dw $0563,$055d,$0558,$0552,$054c,$0546,$0540,$053a
	dw $0534,$052e,$0528,$0522,$051c,$0516,$0510,$050a
	dw $0504,$04fe,$04f8,$04f2,$04ec,$04e6,$04e0,$04db
	dw $04d5,$04cf,$04c9,$04c3,$04bd,$04b7,$04b1,$04ab
	dw $04a5,$049e,$0498,$0492,$048c,$0486,$0480,$047a
	dw $0474,$046e,$0468,$0462,$045c,$0456,$0450,$044a
	dw $0444,$043e,$0438,$0432,$042c,$0426,$0420,$041a
	dw $0413,$040d,$0407,$0401,$03fb,$03f5,$03ef,$03e9
	dw $03e3,$03dd,$03d7,$03d0,$03ca,$03c4,$03be,$03b8
	dw $03b2,$03ac,$03a6,$03a0,$0399,$0393,$038d,$0387
	dw $0381,$037b,$0375,$036f,$0368,$0362,$035c,$0356
	dw $0350,$034a,$0344,$033d,$0337,$0331,$032b,$0325
	dw $031f,$0318,$0312,$030c,$0306,$0300,$02fa,$02f3
	dw $02ed,$02e7,$02e1,$02db,$02d5,$02ce,$02c8,$02c2
	dw $02bc,$02b6,$02af,$02a9,$02a3,$029d,$0297,$0290
	dw $028a,$0284,$027e,$0278,$0271,$026b,$0265,$025f
	dw $0259,$0252,$024c,$0246,$0240,$0239,$0233,$022d
	dw $0227,$0221,$021a,$0214,$020e,$0208,$0201,$01fb
	dw $01f5,$01ef,$01e8,$01e2,$01dc,$01d6,$01cf,$01c9
	dw $01c3,$01bd,$01b6,$01b0,$01aa,$01a4,$019d,$0197
	dw $0191,$018b,$0184,$017e,$0178,$0172,$016b,$0165
	dw $015f,$0159,$0152,$014c,$0146,$0140,$0139,$0133
	dw $012d,$0127,$0120,$011a,$0114,$010d,$0107,$0101
	dw $00fb,$00f4,$00ee,$00e8,$00e2,$00db,$00d5,$00cf
	dw $00c8,$00c2,$00bc,$00b6,$00af,$00a9,$00a3,$009d
	dw $0096,$0090,$008a,$0083,$007d,$0077,$0071,$006a
	dw $0064,$005e,$0057,$0051,$004b,$0045,$003e,$0038
	dw $0032,$002b,$0025,$001f,$0019,$0012,$000c,$0006
	dw $0000,$fffa,$fff4,$ffee,$ffe7,$ffe1,$ffdb,$ffd5
	dw $ffce,$ffc8,$ffc2,$ffbb,$ffb5,$ffaf,$ffa9,$ffa2
	dw $ff9c,$ff96,$ff8f,$ff89,$ff83,$ff7d,$ff76,$ff70
	dw $ff6a,$ff63,$ff5d,$ff57,$ff51,$ff4a,$ff44,$ff3e
	dw $ff38,$ff31,$ff2b,$ff25,$ff1e,$ff18,$ff12,$ff0c
	dw $ff05,$feff,$fef9,$fef3,$feec,$fee6,$fee0,$fed9
	dw $fed3,$fecd,$fec7,$fec0,$feba,$feb4,$feae,$fea7
	dw $fea1,$fe9b,$fe95,$fe8e,$fe88,$fe82,$fe7c,$fe75
	dw $fe6f,$fe69,$fe63,$fe5c,$fe56,$fe50,$fe4a,$fe43
	dw $fe3d,$fe37,$fe31,$fe2a,$fe24,$fe1e,$fe18,$fe11
	dw $fe0b,$fe05,$fdff,$fdf8,$fdf2,$fdec,$fde6,$fddf
	dw $fdd9,$fdd3,$fdcd,$fdc7,$fdc0,$fdba,$fdb4,$fdae
	dw $fda7,$fda1,$fd9b,$fd95,$fd8f,$fd88,$fd82,$fd7c
	dw $fd76,$fd70,$fd69,$fd63,$fd5d,$fd57,$fd51,$fd4a
	dw $fd44,$fd3e,$fd38,$fd32,$fd2b,$fd25,$fd1f,$fd19
	dw $fd13,$fd0d,$fd06,$fd00,$fcfa,$fcf4,$fcee,$fce8
	dw $fce1,$fcdb,$fcd5,$fccf,$fcc9,$fcc3,$fcbc,$fcb6
	dw $fcb0,$fcaa,$fca4,$fc9e,$fc98,$fc91,$fc8b,$fc85
	dw $fc7f,$fc79,$fc73,$fc6d,$fc67,$fc60,$fc5a,$fc54
	dw $fc4e,$fc48,$fc42,$fc3c,$fc36,$fc30,$fc29,$fc23
	dw $fc1d,$fc17,$fc11,$fc0b,$fc05,$fbff,$fbf9,$fbf3
	dw $fbed,$fbe6,$fbe0,$fbda,$fbd4,$fbce,$fbc8,$fbc2
	dw $fbbc,$fbb6,$fbb0,$fbaa,$fba4,$fb9e,$fb98,$fb92
	dw $fb8c,$fb86,$fb80,$fb7a,$fb74,$fb6e,$fb68,$fb62
	dw $fb5b,$fb55,$fb4f,$fb49,$fb43,$fb3d,$fb37,$fb31
	dw $fb2b,$fb25,$fb20,$fb1a,$fb14,$fb0e,$fb08,$fb02
	dw $fafc,$faf6,$faf0,$faea,$fae4,$fade,$fad8,$fad2
	dw $facc,$fac6,$fac0,$faba,$fab4,$faae,$faa8,$faa3
	dw $fa9d,$fa97,$fa91,$fa8b,$fa85,$fa7f,$fa79,$fa73
	dw $fa6d,$fa67,$fa62,$fa5c,$fa56,$fa50,$fa4a,$fa44
	dw $fa3e,$fa39,$fa33,$fa2d,$fa27,$fa21,$fa1b,$fa15
	dw $fa10,$fa0a,$fa04,$f9fe,$f9f8,$f9f2,$f9ed,$f9e7
	dw $f9e1,$f9db,$f9d5,$f9d0,$f9ca,$f9c4,$f9be,$f9b8
	dw $f9b3,$f9ad,$f9a7,$f9a1,$f99c,$f996,$f990,$f98a
	dw $f985,$f97f,$f979,$f973,$f96e,$f968,$f962,$f95d
	dw $f957,$f951,$f94b,$f946,$f940,$f93a,$f935,$f92f
	dw $f929,$f924,$f91e,$f918,$f913,$f90d,$f907,$f902
	dw $f8fc,$f8f6,$f8f1,$f8eb,$f8e5,$f8e0,$f8da,$f8d5
	dw $f8cf,$f8c9,$f8c4,$f8be,$f8b8,$f8b3,$f8ad,$f8a8
	dw $f8a2,$f89d,$f897,$f891,$f88c,$f886,$f881,$f87b
	dw $f876,$f870,$f86b,$f865,$f860,$f85a,$f854,$f84f
	dw $f849,$f844,$f83e,$f839,$f833,$f82e,$f829,$f823
	dw $f81e,$f818,$f813,$f80d,$f808,$f802,$f7fd,$f7f7
	dw $f7f2,$f7ed,$f7e7,$f7e2,$f7dc,$f7d7,$f7d2,$f7cc
	dw $f7c7,$f7c1,$f7bc,$f7b7,$f7b1,$f7ac,$f7a6,$f7a1
	dw $f79c,$f796,$f791,$f78c,$f786,$f781,$f77c,$f776
	dw $f771,$f76c,$f767,$f761,$f75c,$f757,$f751,$f74c
	dw $f747,$f742,$f73c,$f737,$f732,$f72d,$f727,$f722
	dw $f71d,$f718,$f712,$f70d,$f708,$f703,$f6fe,$f6f8
	dw $f6f3,$f6ee,$f6e9,$f6e4,$f6df,$f6d9,$f6d4,$f6cf
	dw $f6ca,$f6c5,$f6c0,$f6bb,$f6b5,$f6b0,$f6ab,$f6a6
	dw $f6a1,$f69c,$f697,$f692,$f68d,$f688,$f683,$f67e
	dw $f679,$f673,$f66e,$f669,$f664,$f65f,$f65a,$f655
	dw $f650,$f64b,$f646,$f641,$f63c,$f637,$f632,$f62d
	dw $f629,$f624,$f61f,$f61a,$f615,$f610,$f60b,$f606
	dw $f601,$f5fc,$f5f7,$f5f2,$f5ee,$f5e9,$f5e4,$f5df
	dw $f5da,$f5d5,$f5d0,$f5cb,$f5c7,$f5c2,$f5bd,$f5b8
	dw $f5b3,$f5af,$f5aa,$f5a5,$f5a0,$f59b,$f597,$f592
	dw $f58d,$f588,$f584,$f57f,$f57a,$f575,$f571,$f56c
	dw $f567,$f563,$f55e,$f559,$f554,$f550,$f54b,$f546
	dw $f542,$f53d,$f538,$f534,$f52f,$f52b,$f526,$f521
	dw $f51d,$f518,$f514,$f50f,$f50a,$f506,$f501,$f4fd
	dw $f4f8,$f4f4,$f4ef,$f4eb,$f4e6,$f4e1,$f4dd,$f4d8
	dw $f4d4,$f4cf,$f4cb,$f4c6,$f4c2,$f4be,$f4b9,$f4b5
	dw $f4b0,$f4ac,$f4a7,$f4a3,$f49e,$f49a,$f496,$f491
	dw $f48d,$f488,$f484,$f480,$f47b,$f477,$f473,$f46e
	dw $f46a,$f466,$f461,$f45d,$f459,$f454,$f450,$f44c
	dw $f448,$f443,$f43f,$f43b,$f436,$f432,$f42e,$f42a
	dw $f426,$f421,$f41d,$f419,$f415,$f411,$f40c,$f408
	dw $f404,$f400,$f3fc,$f3f8,$f3f3,$f3ef,$f3eb,$f3e7
	dw $f3e3,$f3df,$f3db,$f3d7,$f3d3,$f3cf,$f3ca,$f3c6
	dw $f3c2,$f3be,$f3ba,$f3b6,$f3b2,$f3ae,$f3aa,$f3a6
	dw $f3a2,$f39e,$f39a,$f396,$f392,$f38e,$f38a,$f387
	dw $f383,$f37f,$f37b,$f377,$f373,$f36f,$f36b,$f367
	dw $f363,$f360,$f35c,$f358,$f354,$f350,$f34c,$f349
	dw $f345,$f341,$f33d,$f339,$f336,$f332,$f32e,$f32a
	dw $f327,$f323,$f31f,$f31b,$f318,$f314,$f310,$f30d
	dw $f309,$f305,$f302,$f2fe,$f2fa,$f2f7,$f2f3,$f2ef
	dw $f2ec,$f2e8,$f2e4,$f2e1,$f2dd,$f2da,$f2d6,$f2d3
	dw $f2cf,$f2cb,$f2c8,$f2c4,$f2c1,$f2bd,$f2ba,$f2b6
	dw $f2b3,$f2af,$f2ac,$f2a8,$f2a5,$f2a1,$f29e,$f29b
	dw $f297,$f294,$f290,$f28d,$f289,$f286,$f283,$f27f
	dw $f27c,$f279,$f275,$f272,$f26f,$f26b,$f268,$f265
	dw $f261,$f25e,$f25b,$f257,$f254,$f251,$f24e,$f24a
	dw $f247,$f244,$f241,$f23e,$f23a,$f237,$f234,$f231
	dw $f22e,$f22b,$f227,$f224,$f221,$f21e,$f21b,$f218
	dw $f215,$f212,$f20e,$f20b,$f208,$f205,$f202,$f1ff
	dw $f1fc,$f1f9,$f1f6,$f1f3,$f1f0,$f1ed,$f1ea,$f1e7
	dw $f1e4,$f1e1,$f1de,$f1db,$f1d8,$f1d5,$f1d3,$f1d0
	dw $f1cd,$f1ca,$f1c7,$f1c4,$f1c1,$f1be,$f1bc,$f1b9
	dw $f1b6,$f1b3,$f1b0,$f1ad,$f1ab,$f1a8,$f1a5,$f1a2
	dw $f1a0,$f19d,$f19a,$f197,$f195,$f192,$f18f,$f18c
	dw $f18a,$f187,$f184,$f182,$f17f,$f17c,$f17a,$f177
	dw $f175,$f172,$f16f,$f16d,$f16a,$f168,$f165,$f162
	dw $f160,$f15d,$f15b,$f158,$f156,$f153,$f151,$f14e
	dw $f14c,$f149,$f147,$f144,$f142,$f140,$f13d,$f13b
	dw $f138,$f136,$f133,$f131,$f12f,$f12c,$f12a,$f128
	dw $f125,$f123,$f121,$f11e,$f11c,$f11a,$f118,$f115
	dw $f113,$f111,$f10e,$f10c,$f10a,$f108,$f106,$f103
	dw $f101,$f0ff,$f0fd,$f0fb,$f0f8,$f0f6,$f0f4,$f0f2
	dw $f0f0,$f0ee,$f0ec,$f0ea,$f0e8,$f0e5,$f0e3,$f0e1
	dw $f0df,$f0dd,$f0db,$f0d9,$f0d7,$f0d5,$f0d3,$f0d1
	dw $f0cf,$f0cd,$f0cb,$f0c9,$f0c7,$f0c5,$f0c4,$f0c2
	dw $f0c0,$f0be,$f0bc,$f0ba,$f0b8,$f0b6,$f0b5,$f0b3
	dw $f0b1,$f0af,$f0ad,$f0ab,$f0aa,$f0a8,$f0a6,$f0a4
	dw $f0a3,$f0a1,$f09f,$f09d,$f09c,$f09a,$f098,$f097
	dw $f095,$f093,$f092,$f090,$f08e,$f08d,$f08b,$f089
	dw $f088,$f086,$f085,$f083,$f081,$f080,$f07e,$f07d
	dw $f07b,$f07a,$f078,$f077,$f075,$f074,$f072,$f071
	dw $f06f,$f06e,$f06c,$f06b,$f06a,$f068,$f067,$f065
	dw $f064,$f063,$f061,$f060,$f05f,$f05d,$f05c,$f05b
	dw $f059,$f058,$f057,$f055,$f054,$f053,$f052,$f050
	dw $f04f,$f04e,$f04d,$f04c,$f04a,$f049,$f048,$f047
	dw $f046,$f045,$f043,$f042,$f041,$f040,$f03f,$f03e
	dw $f03d,$f03c,$f03b,$f03a,$f039,$f038,$f037,$f036
	dw $f035,$f034,$f033,$f032,$f031,$f030,$f02f,$f02e
	dw $f02d,$f02c,$f02b,$f02a,$f029,$f028,$f027,$f027
	dw $f026,$f025,$f024,$f023,$f022,$f022,$f021,$f020
	dw $f01f,$f01f,$f01e,$f01d,$f01c,$f01c,$f01b,$f01a
	dw $f019,$f019,$f018,$f017,$f017,$f016,$f015,$f015
	dw $f014,$f014,$f013,$f012,$f012,$f011,$f011,$f010
	dw $f010,$f00f,$f00f,$f00e,$f00e,$f00d,$f00d,$f00c
	dw $f00c,$f00b,$f00b,$f00a,$f00a,$f009,$f009,$f009
	dw $f008,$f008,$f007,$f007,$f007,$f006,$f006,$f006
	dw $f005,$f005,$f005,$f005,$f004,$f004,$f004,$f004
	dw $f003,$f003,$f003,$f003,$f002,$f002,$f002,$f002
	dw $f002,$f002,$f001,$f001,$f001,$f001,$f001,$f001
	dw $f001,$f001,$f001,$f001,$f001,$f001,$f001,$f001
	dw $f000,$f001,$f001,$f001,$f001,$f001,$f001,$f001
	dw $f001,$f001,$f001,$f001,$f001,$f001,$f001,$f002
	dw $f002,$f002,$f002,$f002,$f002,$f003,$f003,$f003
	dw $f003,$f004,$f004,$f004,$f004,$f005,$f005,$f005
	dw $f005,$f006,$f006,$f006,$f007,$f007,$f007,$f008
	dw $f008,$f009,$f009,$f009,$f00a,$f00a,$f00b,$f00b
	dw $f00c,$f00c,$f00d,$f00d,$f00e,$f00e,$f00f,$f00f
	dw $f010,$f010,$f011,$f011,$f012,$f012,$f013,$f014
	dw $f014,$f015,$f015,$f016,$f017,$f017,$f018,$f019
	dw $f019,$f01a,$f01b,$f01c,$f01c,$f01d,$f01e,$f01f
	dw $f01f,$f020,$f021,$f022,$f022,$f023,$f024,$f025
	dw $f026,$f027,$f027,$f028,$f029,$f02a,$f02b,$f02c
	dw $f02d,$f02e,$f02f,$f030,$f031,$f032,$f033,$f034
	dw $f035,$f036,$f037,$f038,$f039,$f03a,$f03b,$f03c
	dw $f03d,$f03e,$f03f,$f040,$f041,$f042,$f043,$f045
	dw $f046,$f047,$f048,$f049,$f04a,$f04c,$f04d,$f04e
	dw $f04f,$f050,$f052,$f053,$f054,$f055,$f057,$f058
	dw $f059,$f05b,$f05c,$f05d,$f05f,$f060,$f061,$f063
	dw $f064,$f065,$f067,$f068,$f06a,$f06b,$f06c,$f06e
	dw $f06f,$f071,$f072,$f074,$f075,$f077,$f078,$f07a
	dw $f07b,$f07d,$f07e,$f080,$f081,$f083,$f085,$f086
	dw $f088,$f089,$f08b,$f08d,$f08e,$f090,$f092,$f093
	dw $f095,$f097,$f098,$f09a,$f09c,$f09d,$f09f,$f0a1
	dw $f0a3,$f0a4,$f0a6,$f0a8,$f0aa,$f0ab,$f0ad,$f0af
	dw $f0b1,$f0b3,$f0b5,$f0b6,$f0b8,$f0ba,$f0bc,$f0be
	dw $f0c0,$f0c2,$f0c4,$f0c5,$f0c7,$f0c9,$f0cb,$f0cd
	dw $f0cf,$f0d1,$f0d3,$f0d5,$f0d7,$f0d9,$f0db,$f0dd
	dw $f0df,$f0e1,$f0e3,$f0e5,$f0e8,$f0ea,$f0ec,$f0ee
	dw $f0f0,$f0f2,$f0f4,$f0f6,$f0f8,$f0fb,$f0fd,$f0ff
	dw $f101,$f103,$f106,$f108,$f10a,$f10c,$f10e,$f111
	dw $f113,$f115,$f118,$f11a,$f11c,$f11e,$f121,$f123
	dw $f125,$f128,$f12a,$f12c,$f12f,$f131,$f133,$f136
	dw $f138,$f13b,$f13d,$f140,$f142,$f144,$f147,$f149
	dw $f14c,$f14e,$f151,$f153,$f156,$f158,$f15b,$f15d
	dw $f160,$f162,$f165,$f168,$f16a,$f16d,$f16f,$f172
	dw $f175,$f177,$f17a,$f17c,$f17f,$f182,$f184,$f187
	dw $f18a,$f18c,$f18f,$f192,$f195,$f197,$f19a,$f19d
	dw $f1a0,$f1a2,$f1a5,$f1a8,$f1ab,$f1ad,$f1b0,$f1b3
	dw $f1b6,$f1b9,$f1bc,$f1be,$f1c1,$f1c4,$f1c7,$f1ca
	dw $f1cd,$f1d0,$f1d3,$f1d5,$f1d8,$f1db,$f1de,$f1e1
	dw $f1e4,$f1e7,$f1ea,$f1ed,$f1f0,$f1f3,$f1f6,$f1f9
	dw $f1fc,$f1ff,$f202,$f205,$f208,$f20b,$f20e,$f212
	dw $f215,$f218,$f21b,$f21e,$f221,$f224,$f227,$f22b
	dw $f22e,$f231,$f234,$f237,$f23a,$f23e,$f241,$f244
	dw $f247,$f24a,$f24e,$f251,$f254,$f257,$f25b,$f25e
	dw $f261,$f265,$f268,$f26b,$f26f,$f272,$f275,$f279
	dw $f27c,$f27f,$f283,$f286,$f289,$f28d,$f290,$f294
	dw $f297,$f29b,$f29e,$f2a1,$f2a5,$f2a8,$f2ac,$f2af
	dw $f2b3,$f2b6,$f2ba,$f2bd,$f2c1,$f2c4,$f2c8,$f2cb
	dw $f2cf,$f2d3,$f2d6,$f2da,$f2dd,$f2e1,$f2e4,$f2e8
	dw $f2ec,$f2ef,$f2f3,$f2f7,$f2fa,$f2fe,$f302,$f305
	dw $f309,$f30d,$f310,$f314,$f318,$f31b,$f31f,$f323
	dw $f327,$f32a,$f32e,$f332,$f336,$f339,$f33d,$f341
	dw $f345,$f349,$f34c,$f350,$f354,$f358,$f35c,$f360
	dw $f363,$f367,$f36b,$f36f,$f373,$f377,$f37b,$f37f
	dw $f383,$f387,$f38a,$f38e,$f392,$f396,$f39a,$f39e
	dw $f3a2,$f3a6,$f3aa,$f3ae,$f3b2,$f3b6,$f3ba,$f3be
	dw $f3c2,$f3c6,$f3ca,$f3cf,$f3d3,$f3d7,$f3db,$f3df
	dw $f3e3,$f3e7,$f3eb,$f3ef,$f3f3,$f3f8,$f3fc,$f400
	dw $f404,$f408,$f40c,$f411,$f415,$f419,$f41d,$f421
	dw $f426,$f42a,$f42e,$f432,$f436,$f43b,$f43f,$f443
	dw $f448,$f44c,$f450,$f454,$f459,$f45d,$f461,$f466
	dw $f46a,$f46e,$f473,$f477,$f47b,$f480,$f484,$f488
	dw $f48d,$f491,$f496,$f49a,$f49e,$f4a3,$f4a7,$f4ac
	dw $f4b0,$f4b5,$f4b9,$f4be,$f4c2,$f4c6,$f4cb,$f4cf
	dw $f4d4,$f4d8,$f4dd,$f4e1,$f4e6,$f4eb,$f4ef,$f4f4
	dw $f4f8,$f4fd,$f501,$f506,$f50a,$f50f,$f514,$f518
	dw $f51d,$f521,$f526,$f52b,$f52f,$f534,$f538,$f53d
	dw $f542,$f546,$f54b,$f550,$f554,$f559,$f55e,$f563
	dw $f567,$f56c,$f571,$f575,$f57a,$f57f,$f584,$f588
	dw $f58d,$f592,$f597,$f59b,$f5a0,$f5a5,$f5aa,$f5af
	dw $f5b3,$f5b8,$f5bd,$f5c2,$f5c7,$f5cb,$f5d0,$f5d5
	dw $f5da,$f5df,$f5e4,$f5e9,$f5ee,$f5f2,$f5f7,$f5fc
	dw $f601,$f606,$f60b,$f610,$f615,$f61a,$f61f,$f624
	dw $f629,$f62d,$f632,$f637,$f63c,$f641,$f646,$f64b
	dw $f650,$f655,$f65a,$f65f,$f664,$f669,$f66e,$f673
	dw $f679,$f67e,$f683,$f688,$f68d,$f692,$f697,$f69c
	dw $f6a1,$f6a6,$f6ab,$f6b0,$f6b5,$f6bb,$f6c0,$f6c5
	dw $f6ca,$f6cf,$f6d4,$f6d9,$f6df,$f6e4,$f6e9,$f6ee
	dw $f6f3,$f6f8,$f6fe,$f703,$f708,$f70d,$f712,$f718
	dw $f71d,$f722,$f727,$f72d,$f732,$f737,$f73c,$f742
	dw $f747,$f74c,$f751,$f757,$f75c,$f761,$f767,$f76c
	dw $f771,$f776,$f77c,$f781,$f786,$f78c,$f791,$f796
	dw $f79c,$f7a1,$f7a6,$f7ac,$f7b1,$f7b7,$f7bc,$f7c1
	dw $f7c7,$f7cc,$f7d2,$f7d7,$f7dc,$f7e2,$f7e7,$f7ed
	dw $f7f2,$f7f7,$f7fd,$f802,$f808,$f80d,$f813,$f818
	dw $f81e,$f823,$f829,$f82e,$f833,$f839,$f83e,$f844
	dw $f849,$f84f,$f854,$f85a,$f860,$f865,$f86b,$f870
	dw $f876,$f87b,$f881,$f886,$f88c,$f891,$f897,$f89d
	dw $f8a2,$f8a8,$f8ad,$f8b3,$f8b8,$f8be,$f8c4,$f8c9
	dw $f8cf,$f8d5,$f8da,$f8e0,$f8e5,$f8eb,$f8f1,$f8f6
	dw $f8fc,$f902,$f907,$f90d,$f913,$f918,$f91e,$f924
	dw $f929,$f92f,$f935,$f93a,$f940,$f946,$f94b,$f951
	dw $f957,$f95d,$f962,$f968,$f96e,$f973,$f979,$f97f
	dw $f985,$f98a,$f990,$f996,$f99c,$f9a1,$f9a7,$f9ad
	dw $f9b3,$f9b8,$f9be,$f9c4,$f9ca,$f9d0,$f9d5,$f9db
	dw $f9e1,$f9e7,$f9ed,$f9f2,$f9f8,$f9fe,$fa04,$fa0a
	dw $fa10,$fa15,$fa1b,$fa21,$fa27,$fa2d,$fa33,$fa39
	dw $fa3e,$fa44,$fa4a,$fa50,$fa56,$fa5c,$fa62,$fa67
	dw $fa6d,$fa73,$fa79,$fa7f,$fa85,$fa8b,$fa91,$fa97
	dw $fa9d,$faa3,$faa8,$faae,$fab4,$faba,$fac0,$fac6
	dw $facc,$fad2,$fad8,$fade,$fae4,$faea,$faf0,$faf6
	dw $fafc,$fb02,$fb08,$fb0e,$fb14,$fb1a,$fb20,$fb25
	dw $fb2b,$fb31,$fb37,$fb3d,$fb43,$fb49,$fb4f,$fb55
	dw $fb5b,$fb62,$fb68,$fb6e,$fb74,$fb7a,$fb80,$fb86
	dw $fb8c,$fb92,$fb98,$fb9e,$fba4,$fbaa,$fbb0,$fbb6
	dw $fbbc,$fbc2,$fbc8,$fbce,$fbd4,$fbda,$fbe0,$fbe6
	dw $fbed,$fbf3,$fbf9,$fbff,$fc05,$fc0b,$fc11,$fc17
	dw $fc1d,$fc23,$fc29,$fc30,$fc36,$fc3c,$fc42,$fc48
	dw $fc4e,$fc54,$fc5a,$fc60,$fc67,$fc6d,$fc73,$fc79
	dw $fc7f,$fc85,$fc8b,$fc91,$fc98,$fc9e,$fca4,$fcaa
	dw $fcb0,$fcb6,$fcbc,$fcc3,$fcc9,$fccf,$fcd5,$fcdb
	dw $fce1,$fce8,$fcee,$fcf4,$fcfa,$fd00,$fd06,$fd0d
	dw $fd13,$fd19,$fd1f,$fd25,$fd2b,$fd32,$fd38,$fd3e
	dw $fd44,$fd4a,$fd51,$fd57,$fd5d,$fd63,$fd69,$fd70
	dw $fd76,$fd7c,$fd82,$fd88,$fd8f,$fd95,$fd9b,$fda1
	dw $fda7,$fdae,$fdb4,$fdba,$fdc0,$fdc7,$fdcd,$fdd3
	dw $fdd9,$fddf,$fde6,$fdec,$fdf2,$fdf8,$fdff,$fe05
	dw $fe0b,$fe11,$fe18,$fe1e,$fe24,$fe2a,$fe31,$fe37
	dw $fe3d,$fe43,$fe4a,$fe50,$fe56,$fe5c,$fe63,$fe69
	dw $fe6f,$fe75,$fe7c,$fe82,$fe88,$fe8e,$fe95,$fe9b
	dw $fea1,$fea7,$feae,$feb4,$feba,$fec0,$fec7,$fecd
	dw $fed3,$fed9,$fee0,$fee6,$feec,$fef3,$fef9,$feff
	dw $ff05,$ff0c,$ff12,$ff18,$ff1e,$ff25,$ff2b,$ff31
	dw $ff38,$ff3e,$ff44,$ff4a,$ff51,$ff57,$ff5d,$ff63
	dw $ff6a,$ff70,$ff76,$ff7d,$ff83,$ff89,$ff8f,$ff96
	dw $ff9c,$ffa2,$ffa9,$ffaf,$ffb5,$ffbb,$ffc2,$ffc8
	dw $ffce,$ffd5,$ffdb,$ffe1,$ffe7,$ffee,$fff4,$fffa

cos_table
	dw $1000,$0fff,$0fff,$0fff,$0fff,$0fff,$0fff,$0fff
	dw $0fff,$0fff,$0fff,$0fff,$0fff,$0fff,$0fff,$0ffe
	dw $0ffe,$0ffe,$0ffe,$0ffe,$0ffe,$0ffd,$0ffd,$0ffd
	dw $0ffd,$0ffc,$0ffc,$0ffc,$0ffc,$0ffb,$0ffb,$0ffb
	dw $0ffb,$0ffa,$0ffa,$0ffa,$0ff9,$0ff9,$0ff9,$0ff8
	dw $0ff8,$0ff7,$0ff7,$0ff7,$0ff6,$0ff6,$0ff5,$0ff5
	dw $0ff4,$0ff4,$0ff3,$0ff3,$0ff2,$0ff2,$0ff1,$0ff1
	dw $0ff0,$0ff0,$0fef,$0fef,$0fee,$0fee,$0fed,$0fec
	dw $0fec,$0feb,$0feb,$0fea,$0fe9,$0fe9,$0fe8,$0fe7
	dw $0fe7,$0fe6,$0fe5,$0fe4,$0fe4,$0fe3,$0fe2,$0fe1
	dw $0fe1,$0fe0,$0fdf,$0fde,$0fde,$0fdd,$0fdc,$0fdb
	dw $0fda,$0fd9,$0fd9,$0fd8,$0fd7,$0fd6,$0fd5,$0fd4
	dw $0fd3,$0fd2,$0fd1,$0fd0,$0fcf,$0fce,$0fcd,$0fcc
	dw $0fcb,$0fca,$0fc9,$0fc8,$0fc7,$0fc6,$0fc5,$0fc4
	dw $0fc3,$0fc2,$0fc1,$0fc0,$0fbf,$0fbe,$0fbd,$0fbb
	dw $0fba,$0fb9,$0fb8,$0fb7,$0fb6,$0fb4,$0fb3,$0fb2
	dw $0fb1,$0fb0,$0fae,$0fad,$0fac,$0fab,$0fa9,$0fa8
	dw $0fa7,$0fa5,$0fa4,$0fa3,$0fa1,$0fa0,$0f9f,$0f9d
	dw $0f9c,$0f9b,$0f99,$0f98,$0f96,$0f95,$0f94,$0f92
	dw $0f91,$0f8f,$0f8e,$0f8c,$0f8b,$0f89,$0f88,$0f86
	dw $0f85,$0f83,$0f82,$0f80,$0f7f,$0f7d,$0f7b,$0f7a
	dw $0f78,$0f77,$0f75,$0f73,$0f72,$0f70,$0f6e,$0f6d
	dw $0f6b,$0f69,$0f68,$0f66,$0f64,$0f63,$0f61,$0f5f
	dw $0f5d,$0f5c,$0f5a,$0f58,$0f56,$0f55,$0f53,$0f51
	dw $0f4f,$0f4d,$0f4b,$0f4a,$0f48,$0f46,$0f44,$0f42
	dw $0f40,$0f3e,$0f3c,$0f3b,$0f39,$0f37,$0f35,$0f33
	dw $0f31,$0f2f,$0f2d,$0f2b,$0f29,$0f27,$0f25,$0f23
	dw $0f21,$0f1f,$0f1d,$0f1b,$0f18,$0f16,$0f14,$0f12
	dw $0f10,$0f0e,$0f0c,$0f0a,$0f08,$0f05,$0f03,$0f01
	dw $0eff,$0efd,$0efa,$0ef8,$0ef6,$0ef4,$0ef2,$0eef
	dw $0eed,$0eeb,$0ee8,$0ee6,$0ee4,$0ee2,$0edf,$0edd
	dw $0edb,$0ed8,$0ed6,$0ed4,$0ed1,$0ecf,$0ecd,$0eca
	dw $0ec8,$0ec5,$0ec3,$0ec0,$0ebe,$0ebc,$0eb9,$0eb7
	dw $0eb4,$0eb2,$0eaf,$0ead,$0eaa,$0ea8,$0ea5,$0ea3
	dw $0ea0,$0e9e,$0e9b,$0e98,$0e96,$0e93,$0e91,$0e8e
	dw $0e8b,$0e89,$0e86,$0e84,$0e81,$0e7e,$0e7c,$0e79
	dw $0e76,$0e74,$0e71,$0e6e,$0e6b,$0e69,$0e66,$0e63
	dw $0e60,$0e5e,$0e5b,$0e58,$0e55,$0e53,$0e50,$0e4d
	dw $0e4a,$0e47,$0e44,$0e42,$0e3f,$0e3c,$0e39,$0e36
	dw $0e33,$0e30,$0e2d,$0e2b,$0e28,$0e25,$0e22,$0e1f
	dw $0e1c,$0e19,$0e16,$0e13,$0e10,$0e0d,$0e0a,$0e07
	dw $0e04,$0e01,$0dfe,$0dfb,$0df8,$0df5,$0df2,$0dee
	dw $0deb,$0de8,$0de5,$0de2,$0ddf,$0ddc,$0dd9,$0dd5
	dw $0dd2,$0dcf,$0dcc,$0dc9,$0dc6,$0dc2,$0dbf,$0dbc
	dw $0db9,$0db6,$0db2,$0daf,$0dac,$0da9,$0da5,$0da2
	dw $0d9f,$0d9b,$0d98,$0d95,$0d91,$0d8e,$0d8b,$0d87
	dw $0d84,$0d81,$0d7d,$0d7a,$0d77,$0d73,$0d70,$0d6c
	dw $0d69,$0d65,$0d62,$0d5f,$0d5b,$0d58,$0d54,$0d51
	dw $0d4d,$0d4a,$0d46,$0d43,$0d3f,$0d3c,$0d38,$0d35
	dw $0d31,$0d2d,$0d2a,$0d26,$0d23,$0d1f,$0d1c,$0d18
	dw $0d14,$0d11,$0d0d,$0d09,$0d06,$0d02,$0cfe,$0cfb
	dw $0cf7,$0cf3,$0cf0,$0cec,$0ce8,$0ce5,$0ce1,$0cdd
	dw $0cd9,$0cd6,$0cd2,$0cce,$0cca,$0cc7,$0cc3,$0cbf
	dw $0cbb,$0cb7,$0cb4,$0cb0,$0cac,$0ca8,$0ca4,$0ca0
	dw $0c9d,$0c99,$0c95,$0c91,$0c8d,$0c89,$0c85,$0c81
	dw $0c7d,$0c79,$0c76,$0c72,$0c6e,$0c6a,$0c66,$0c62
	dw $0c5e,$0c5a,$0c56,$0c52,$0c4e,$0c4a,$0c46,$0c42
	dw $0c3e,$0c3a,$0c36,$0c31,$0c2d,$0c29,$0c25,$0c21
	dw $0c1d,$0c19,$0c15,$0c11,$0c0d,$0c08,$0c04,$0c00
	dw $0bfc,$0bf8,$0bf4,$0bef,$0beb,$0be7,$0be3,$0bdf
	dw $0bda,$0bd6,$0bd2,$0bce,$0bca,$0bc5,$0bc1,$0bbd
	dw $0bb8,$0bb4,$0bb0,$0bac,$0ba7,$0ba3,$0b9f,$0b9a
	dw $0b96,$0b92,$0b8d,$0b89,$0b85,$0b80,$0b7c,$0b78
	dw $0b73,$0b6f,$0b6a,$0b66,$0b62,$0b5d,$0b59,$0b54
	dw $0b50,$0b4b,$0b47,$0b42,$0b3e,$0b3a,$0b35,$0b31
	dw $0b2c,$0b28,$0b23,$0b1f,$0b1a,$0b15,$0b11,$0b0c
	dw $0b08,$0b03,$0aff,$0afa,$0af6,$0af1,$0aec,$0ae8
	dw $0ae3,$0adf,$0ada,$0ad5,$0ad1,$0acc,$0ac8,$0ac3
	dw $0abe,$0aba,$0ab5,$0ab0,$0aac,$0aa7,$0aa2,$0a9d
	dw $0a99,$0a94,$0a8f,$0a8b,$0a86,$0a81,$0a7c,$0a78
	dw $0a73,$0a6e,$0a69,$0a65,$0a60,$0a5b,$0a56,$0a51
	dw $0a4d,$0a48,$0a43,$0a3e,$0a39,$0a35,$0a30,$0a2b
	dw $0a26,$0a21,$0a1c,$0a17,$0a12,$0a0e,$0a09,$0a04
	dw $09ff,$09fa,$09f5,$09f0,$09eb,$09e6,$09e1,$09dc
	dw $09d7,$09d3,$09ce,$09c9,$09c4,$09bf,$09ba,$09b5
	dw $09b0,$09ab,$09a6,$09a1,$099c,$0997,$0992,$098d
	dw $0987,$0982,$097d,$0978,$0973,$096e,$0969,$0964
	dw $095f,$095a,$0955,$0950,$094b,$0945,$0940,$093b
	dw $0936,$0931,$092c,$0927,$0921,$091c,$0917,$0912
	dw $090d,$0908,$0902,$08fd,$08f8,$08f3,$08ee,$08e8
	dw $08e3,$08de,$08d9,$08d3,$08ce,$08c9,$08c4,$08be
	dw $08b9,$08b4,$08af,$08a9,$08a4,$089f,$0899,$0894
	dw $088f,$088a,$0884,$087f,$087a,$0874,$086f,$086a
	dw $0864,$085f,$085a,$0854,$084f,$0849,$0844,$083f
	dw $0839,$0834,$082e,$0829,$0824,$081e,$0819,$0813
	dw $080e,$0809,$0803,$07fe,$07f8,$07f3,$07ed,$07e8
	dw $07e2,$07dd,$07d7,$07d2,$07cd,$07c7,$07c2,$07bc
	dw $07b7,$07b1,$07ac,$07a6,$07a0,$079b,$0795,$0790
	dw $078a,$0785,$077f,$077a,$0774,$076f,$0769,$0763
	dw $075e,$0758,$0753,$074d,$0748,$0742,$073c,$0737
	dw $0731,$072b,$0726,$0720,$071b,$0715,$070f,$070a
	dw $0704,$06fe,$06f9,$06f3,$06ed,$06e8,$06e2,$06dc
	dw $06d7,$06d1,$06cb,$06c6,$06c0,$06ba,$06b5,$06af
	dw $06a9,$06a3,$069e,$0698,$0692,$068d,$0687,$0681
	dw $067b,$0676,$0670,$066a,$0664,$065f,$0659,$0653
	dw $064d,$0648,$0642,$063c,$0636,$0630,$062b,$0625
	dw $061f,$0619,$0613,$060e,$0608,$0602,$05fc,$05f6
	dw $05f0,$05eb,$05e5,$05df,$05d9,$05d3,$05cd,$05c7
	dw $05c2,$05bc,$05b6,$05b0,$05aa,$05a4,$059e,$0599
	dw $0593,$058d,$0587,$0581,$057b,$0575,$056f,$0569
	dw $0563,$055d,$0558,$0552,$054c,$0546,$0540,$053a
	dw $0534,$052e,$0528,$0522,$051c,$0516,$0510,$050a
	dw $0504,$04fe,$04f8,$04f2,$04ec,$04e6,$04e0,$04db
	dw $04d5,$04cf,$04c9,$04c3,$04bd,$04b7,$04b1,$04ab
	dw $04a5,$049e,$0498,$0492,$048c,$0486,$0480,$047a
	dw $0474,$046e,$0468,$0462,$045c,$0456,$0450,$044a
	dw $0444,$043e,$0438,$0432,$042c,$0426,$0420,$041a
	dw $0413,$040d,$0407,$0401,$03fb,$03f5,$03ef,$03e9
	dw $03e3,$03dd,$03d7,$03d0,$03ca,$03c4,$03be,$03b8
	dw $03b2,$03ac,$03a6,$03a0,$0399,$0393,$038d,$0387
	dw $0381,$037b,$0375,$036f,$0368,$0362,$035c,$0356
	dw $0350,$034a,$0344,$033d,$0337,$0331,$032b,$0325
	dw $031f,$0318,$0312,$030c,$0306,$0300,$02fa,$02f3
	dw $02ed,$02e7,$02e1,$02db,$02d5,$02ce,$02c8,$02c2
	dw $02bc,$02b6,$02af,$02a9,$02a3,$029d,$0297,$0290
	dw $028a,$0284,$027e,$0278,$0271,$026b,$0265,$025f
	dw $0259,$0252,$024c,$0246,$0240,$0239,$0233,$022d
	dw $0227,$0221,$021a,$0214,$020e,$0208,$0201,$01fb
	dw $01f5,$01ef,$01e8,$01e2,$01dc,$01d6,$01cf,$01c9
	dw $01c3,$01bd,$01b6,$01b0,$01aa,$01a4,$019d,$0197
	dw $0191,$018b,$0184,$017e,$0178,$0172,$016b,$0165
	dw $015f,$0159,$0152,$014c,$0146,$0140,$0139,$0133
	dw $012d,$0127,$0120,$011a,$0114,$010d,$0107,$0101
	dw $00fb,$00f4,$00ee,$00e8,$00e2,$00db,$00d5,$00cf
	dw $00c8,$00c2,$00bc,$00b6,$00af,$00a9,$00a3,$009d
	dw $0096,$0090,$008a,$0083,$007d,$0077,$0071,$006a
	dw $0064,$005e,$0057,$0051,$004b,$0045,$003e,$0038
	dw $0032,$002b,$0025,$001f,$0019,$0012,$000c,$0006
	dw $0000,$fffa,$fff4,$ffee,$ffe7,$ffe1,$ffdb,$ffd5
	dw $ffce,$ffc8,$ffc2,$ffbb,$ffb5,$ffaf,$ffa9,$ffa2
	dw $ff9c,$ff96,$ff8f,$ff89,$ff83,$ff7d,$ff76,$ff70
	dw $ff6a,$ff63,$ff5d,$ff57,$ff51,$ff4a,$ff44,$ff3e
	dw $ff38,$ff31,$ff2b,$ff25,$ff1e,$ff18,$ff12,$ff0c
	dw $ff05,$feff,$fef9,$fef3,$feec,$fee6,$fee0,$fed9
	dw $fed3,$fecd,$fec7,$fec0,$feba,$feb4,$feae,$fea7
	dw $fea1,$fe9b,$fe95,$fe8e,$fe88,$fe82,$fe7c,$fe75
	dw $fe6f,$fe69,$fe63,$fe5c,$fe56,$fe50,$fe4a,$fe43
	dw $fe3d,$fe37,$fe31,$fe2a,$fe24,$fe1e,$fe18,$fe11
	dw $fe0b,$fe05,$fdff,$fdf8,$fdf2,$fdec,$fde6,$fddf
	dw $fdd9,$fdd3,$fdcd,$fdc7,$fdc0,$fdba,$fdb4,$fdae
	dw $fda7,$fda1,$fd9b,$fd95,$fd8f,$fd88,$fd82,$fd7c
	dw $fd76,$fd70,$fd69,$fd63,$fd5d,$fd57,$fd51,$fd4a
	dw $fd44,$fd3e,$fd38,$fd32,$fd2b,$fd25,$fd1f,$fd19
	dw $fd13,$fd0d,$fd06,$fd00,$fcfa,$fcf4,$fcee,$fce8
	dw $fce1,$fcdb,$fcd5,$fccf,$fcc9,$fcc3,$fcbc,$fcb6
	dw $fcb0,$fcaa,$fca4,$fc9e,$fc98,$fc91,$fc8b,$fc85
	dw $fc7f,$fc79,$fc73,$fc6d,$fc67,$fc60,$fc5a,$fc54
	dw $fc4e,$fc48,$fc42,$fc3c,$fc36,$fc30,$fc29,$fc23
	dw $fc1d,$fc17,$fc11,$fc0b,$fc05,$fbff,$fbf9,$fbf3
	dw $fbed,$fbe6,$fbe0,$fbda,$fbd4,$fbce,$fbc8,$fbc2
	dw $fbbc,$fbb6,$fbb0,$fbaa,$fba4,$fb9e,$fb98,$fb92
	dw $fb8c,$fb86,$fb80,$fb7a,$fb74,$fb6e,$fb68,$fb62
	dw $fb5b,$fb55,$fb4f,$fb49,$fb43,$fb3d,$fb37,$fb31
	dw $fb2b,$fb25,$fb20,$fb1a,$fb14,$fb0e,$fb08,$fb02
	dw $fafc,$faf6,$faf0,$faea,$fae4,$fade,$fad8,$fad2
	dw $facc,$fac6,$fac0,$faba,$fab4,$faae,$faa8,$faa3
	dw $fa9d,$fa97,$fa91,$fa8b,$fa85,$fa7f,$fa79,$fa73
	dw $fa6d,$fa67,$fa62,$fa5c,$fa56,$fa50,$fa4a,$fa44
	dw $fa3e,$fa39,$fa33,$fa2d,$fa27,$fa21,$fa1b,$fa15
	dw $fa10,$fa0a,$fa04,$f9fe,$f9f8,$f9f2,$f9ed,$f9e7
	dw $f9e1,$f9db,$f9d5,$f9d0,$f9ca,$f9c4,$f9be,$f9b8
	dw $f9b3,$f9ad,$f9a7,$f9a1,$f99c,$f996,$f990,$f98a
	dw $f985,$f97f,$f979,$f973,$f96e,$f968,$f962,$f95d
	dw $f957,$f951,$f94b,$f946,$f940,$f93a,$f935,$f92f
	dw $f929,$f924,$f91e,$f918,$f913,$f90d,$f907,$f902
	dw $f8fc,$f8f6,$f8f1,$f8eb,$f8e5,$f8e0,$f8da,$f8d5
	dw $f8cf,$f8c9,$f8c4,$f8be,$f8b8,$f8b3,$f8ad,$f8a8
	dw $f8a2,$f89d,$f897,$f891,$f88c,$f886,$f881,$f87b
	dw $f876,$f870,$f86b,$f865,$f860,$f85a,$f854,$f84f
	dw $f849,$f844,$f83e,$f839,$f833,$f82e,$f829,$f823
	dw $f81e,$f818,$f813,$f80d,$f808,$f802,$f7fd,$f7f7
	dw $f7f2,$f7ed,$f7e7,$f7e2,$f7dc,$f7d7,$f7d2,$f7cc
	dw $f7c7,$f7c1,$f7bc,$f7b7,$f7b1,$f7ac,$f7a6,$f7a1
	dw $f79c,$f796,$f791,$f78c,$f786,$f781,$f77c,$f776
	dw $f771,$f76c,$f767,$f761,$f75c,$f757,$f751,$f74c
	dw $f747,$f742,$f73c,$f737,$f732,$f72d,$f727,$f722
	dw $f71d,$f718,$f712,$f70d,$f708,$f703,$f6fe,$f6f8
	dw $f6f3,$f6ee,$f6e9,$f6e4,$f6df,$f6d9,$f6d4,$f6cf
	dw $f6ca,$f6c5,$f6c0,$f6bb,$f6b5,$f6b0,$f6ab,$f6a6
	dw $f6a1,$f69c,$f697,$f692,$f68d,$f688,$f683,$f67e
	dw $f679,$f673,$f66e,$f669,$f664,$f65f,$f65a,$f655
	dw $f650,$f64b,$f646,$f641,$f63c,$f637,$f632,$f62d
	dw $f629,$f624,$f61f,$f61a,$f615,$f610,$f60b,$f606
	dw $f601,$f5fc,$f5f7,$f5f2,$f5ee,$f5e9,$f5e4,$f5df
	dw $f5da,$f5d5,$f5d0,$f5cb,$f5c7,$f5c2,$f5bd,$f5b8
	dw $f5b3,$f5af,$f5aa,$f5a5,$f5a0,$f59b,$f597,$f592
	dw $f58d,$f588,$f584,$f57f,$f57a,$f575,$f571,$f56c
	dw $f567,$f563,$f55e,$f559,$f554,$f550,$f54b,$f546
	dw $f542,$f53d,$f538,$f534,$f52f,$f52b,$f526,$f521
	dw $f51d,$f518,$f514,$f50f,$f50a,$f506,$f501,$f4fd
	dw $f4f8,$f4f4,$f4ef,$f4eb,$f4e6,$f4e1,$f4dd,$f4d8
	dw $f4d4,$f4cf,$f4cb,$f4c6,$f4c2,$f4be,$f4b9,$f4b5
	dw $f4b0,$f4ac,$f4a7,$f4a3,$f49e,$f49a,$f496,$f491
	dw $f48d,$f488,$f484,$f480,$f47b,$f477,$f473,$f46e
	dw $f46a,$f466,$f461,$f45d,$f459,$f454,$f450,$f44c
	dw $f448,$f443,$f43f,$f43b,$f436,$f432,$f42e,$f42a
	dw $f426,$f421,$f41d,$f419,$f415,$f411,$f40c,$f408
	dw $f404,$f400,$f3fc,$f3f8,$f3f3,$f3ef,$f3eb,$f3e7
	dw $f3e3,$f3df,$f3db,$f3d7,$f3d3,$f3cf,$f3ca,$f3c6
	dw $f3c2,$f3be,$f3ba,$f3b6,$f3b2,$f3ae,$f3aa,$f3a6
	dw $f3a2,$f39e,$f39a,$f396,$f392,$f38e,$f38a,$f387
	dw $f383,$f37f,$f37b,$f377,$f373,$f36f,$f36b,$f367
	dw $f363,$f360,$f35c,$f358,$f354,$f350,$f34c,$f349
	dw $f345,$f341,$f33d,$f339,$f336,$f332,$f32e,$f32a
	dw $f327,$f323,$f31f,$f31b,$f318,$f314,$f310,$f30d
	dw $f309,$f305,$f302,$f2fe,$f2fa,$f2f7,$f2f3,$f2ef
	dw $f2ec,$f2e8,$f2e4,$f2e1,$f2dd,$f2da,$f2d6,$f2d3
	dw $f2cf,$f2cb,$f2c8,$f2c4,$f2c1,$f2bd,$f2ba,$f2b6
	dw $f2b3,$f2af,$f2ac,$f2a8,$f2a5,$f2a1,$f29e,$f29b
	dw $f297,$f294,$f290,$f28d,$f289,$f286,$f283,$f27f
	dw $f27c,$f279,$f275,$f272,$f26f,$f26b,$f268,$f265
	dw $f261,$f25e,$f25b,$f257,$f254,$f251,$f24e,$f24a
	dw $f247,$f244,$f241,$f23e,$f23a,$f237,$f234,$f231
	dw $f22e,$f22b,$f227,$f224,$f221,$f21e,$f21b,$f218
	dw $f215,$f212,$f20e,$f20b,$f208,$f205,$f202,$f1ff
	dw $f1fc,$f1f9,$f1f6,$f1f3,$f1f0,$f1ed,$f1ea,$f1e7
	dw $f1e4,$f1e1,$f1de,$f1db,$f1d8,$f1d5,$f1d3,$f1d0
	dw $f1cd,$f1ca,$f1c7,$f1c4,$f1c1,$f1be,$f1bc,$f1b9
	dw $f1b6,$f1b3,$f1b0,$f1ad,$f1ab,$f1a8,$f1a5,$f1a2
	dw $f1a0,$f19d,$f19a,$f197,$f195,$f192,$f18f,$f18c
	dw $f18a,$f187,$f184,$f182,$f17f,$f17c,$f17a,$f177
	dw $f175,$f172,$f16f,$f16d,$f16a,$f168,$f165,$f162
	dw $f160,$f15d,$f15b,$f158,$f156,$f153,$f151,$f14e
	dw $f14c,$f149,$f147,$f144,$f142,$f140,$f13d,$f13b
	dw $f138,$f136,$f133,$f131,$f12f,$f12c,$f12a,$f128
	dw $f125,$f123,$f121,$f11e,$f11c,$f11a,$f118,$f115
	dw $f113,$f111,$f10e,$f10c,$f10a,$f108,$f106,$f103
	dw $f101,$f0ff,$f0fd,$f0fb,$f0f8,$f0f6,$f0f4,$f0f2
	dw $f0f0,$f0ee,$f0ec,$f0ea,$f0e8,$f0e5,$f0e3,$f0e1
	dw $f0df,$f0dd,$f0db,$f0d9,$f0d7,$f0d5,$f0d3,$f0d1
	dw $f0cf,$f0cd,$f0cb,$f0c9,$f0c7,$f0c5,$f0c4,$f0c2
	dw $f0c0,$f0be,$f0bc,$f0ba,$f0b8,$f0b6,$f0b5,$f0b3
	dw $f0b1,$f0af,$f0ad,$f0ab,$f0aa,$f0a8,$f0a6,$f0a4
	dw $f0a3,$f0a1,$f09f,$f09d,$f09c,$f09a,$f098,$f097
	dw $f095,$f093,$f092,$f090,$f08e,$f08d,$f08b,$f089
	dw $f088,$f086,$f085,$f083,$f081,$f080,$f07e,$f07d
	dw $f07b,$f07a,$f078,$f077,$f075,$f074,$f072,$f071
	dw $f06f,$f06e,$f06c,$f06b,$f06a,$f068,$f067,$f065
	dw $f064,$f063,$f061,$f060,$f05f,$f05d,$f05c,$f05b
	dw $f059,$f058,$f057,$f055,$f054,$f053,$f052,$f050
	dw $f04f,$f04e,$f04d,$f04c,$f04a,$f049,$f048,$f047
	dw $f046,$f045,$f043,$f042,$f041,$f040,$f03f,$f03e
	dw $f03d,$f03c,$f03b,$f03a,$f039,$f038,$f037,$f036
	dw $f035,$f034,$f033,$f032,$f031,$f030,$f02f,$f02e
	dw $f02d,$f02c,$f02b,$f02a,$f029,$f028,$f027,$f027
	dw $f026,$f025,$f024,$f023,$f022,$f022,$f021,$f020
	dw $f01f,$f01f,$f01e,$f01d,$f01c,$f01c,$f01b,$f01a
	dw $f019,$f019,$f018,$f017,$f017,$f016,$f015,$f015
	dw $f014,$f014,$f013,$f012,$f012,$f011,$f011,$f010
	dw $f010,$f00f,$f00f,$f00e,$f00e,$f00d,$f00d,$f00c
	dw $f00c,$f00b,$f00b,$f00a,$f00a,$f009,$f009,$f009
	dw $f008,$f008,$f007,$f007,$f007,$f006,$f006,$f006
	dw $f005,$f005,$f005,$f005,$f004,$f004,$f004,$f004
	dw $f003,$f003,$f003,$f003,$f002,$f002,$f002,$f002
	dw $f002,$f002,$f001,$f001,$f001,$f001,$f001,$f001
	dw $f001,$f001,$f001,$f001,$f001,$f001,$f001,$f001
	dw $f000,$f001,$f001,$f001,$f001,$f001,$f001,$f001
	dw $f001,$f001,$f001,$f001,$f001,$f001,$f001,$f002
	dw $f002,$f002,$f002,$f002,$f002,$f003,$f003,$f003
	dw $f003,$f004,$f004,$f004,$f004,$f005,$f005,$f005
	dw $f005,$f006,$f006,$f006,$f007,$f007,$f007,$f008
	dw $f008,$f009,$f009,$f009,$f00a,$f00a,$f00b,$f00b
	dw $f00c,$f00c,$f00d,$f00d,$f00e,$f00e,$f00f,$f00f
	dw $f010,$f010,$f011,$f011,$f012,$f012,$f013,$f014
	dw $f014,$f015,$f015,$f016,$f017,$f017,$f018,$f019
	dw $f019,$f01a,$f01b,$f01c,$f01c,$f01d,$f01e,$f01f
	dw $f01f,$f020,$f021,$f022,$f022,$f023,$f024,$f025
	dw $f026,$f027,$f027,$f028,$f029,$f02a,$f02b,$f02c
	dw $f02d,$f02e,$f02f,$f030,$f031,$f032,$f033,$f034
	dw $f035,$f036,$f037,$f038,$f039,$f03a,$f03b,$f03c
	dw $f03d,$f03e,$f03f,$f040,$f041,$f042,$f043,$f045
	dw $f046,$f047,$f048,$f049,$f04a,$f04c,$f04d,$f04e
	dw $f04f,$f050,$f052,$f053,$f054,$f055,$f057,$f058
	dw $f059,$f05b,$f05c,$f05d,$f05f,$f060,$f061,$f063
	dw $f064,$f065,$f067,$f068,$f06a,$f06b,$f06c,$f06e
	dw $f06f,$f071,$f072,$f074,$f075,$f077,$f078,$f07a
	dw $f07b,$f07d,$f07e,$f080,$f081,$f083,$f085,$f086
	dw $f088,$f089,$f08b,$f08d,$f08e,$f090,$f092,$f093
	dw $f095,$f097,$f098,$f09a,$f09c,$f09d,$f09f,$f0a1
	dw $f0a3,$f0a4,$f0a6,$f0a8,$f0aa,$f0ab,$f0ad,$f0af
	dw $f0b1,$f0b3,$f0b5,$f0b6,$f0b8,$f0ba,$f0bc,$f0be
	dw $f0c0,$f0c2,$f0c4,$f0c5,$f0c7,$f0c9,$f0cb,$f0cd
	dw $f0cf,$f0d1,$f0d3,$f0d5,$f0d7,$f0d9,$f0db,$f0dd
	dw $f0df,$f0e1,$f0e3,$f0e5,$f0e8,$f0ea,$f0ec,$f0ee
	dw $f0f0,$f0f2,$f0f4,$f0f6,$f0f8,$f0fb,$f0fd,$f0ff
	dw $f101,$f103,$f106,$f108,$f10a,$f10c,$f10e,$f111
	dw $f113,$f115,$f118,$f11a,$f11c,$f11e,$f121,$f123
	dw $f125,$f128,$f12a,$f12c,$f12f,$f131,$f133,$f136
	dw $f138,$f13b,$f13d,$f140,$f142,$f144,$f147,$f149
	dw $f14c,$f14e,$f151,$f153,$f156,$f158,$f15b,$f15d
	dw $f160,$f162,$f165,$f168,$f16a,$f16d,$f16f,$f172
	dw $f175,$f177,$f17a,$f17c,$f17f,$f182,$f184,$f187
	dw $f18a,$f18c,$f18f,$f192,$f195,$f197,$f19a,$f19d
	dw $f1a0,$f1a2,$f1a5,$f1a8,$f1ab,$f1ad,$f1b0,$f1b3
	dw $f1b6,$f1b9,$f1bc,$f1be,$f1c1,$f1c4,$f1c7,$f1ca
	dw $f1cd,$f1d0,$f1d3,$f1d5,$f1d8,$f1db,$f1de,$f1e1
	dw $f1e4,$f1e7,$f1ea,$f1ed,$f1f0,$f1f3,$f1f6,$f1f9
	dw $f1fc,$f1ff,$f202,$f205,$f208,$f20b,$f20e,$f212
	dw $f215,$f218,$f21b,$f21e,$f221,$f224,$f227,$f22b
	dw $f22e,$f231,$f234,$f237,$f23a,$f23e,$f241,$f244
	dw $f247,$f24a,$f24e,$f251,$f254,$f257,$f25b,$f25e
	dw $f261,$f265,$f268,$f26b,$f26f,$f272,$f275,$f279
	dw $f27c,$f27f,$f283,$f286,$f289,$f28d,$f290,$f294
	dw $f297,$f29b,$f29e,$f2a1,$f2a5,$f2a8,$f2ac,$f2af
	dw $f2b3,$f2b6,$f2ba,$f2bd,$f2c1,$f2c4,$f2c8,$f2cb
	dw $f2cf,$f2d3,$f2d6,$f2da,$f2dd,$f2e1,$f2e4,$f2e8
	dw $f2ec,$f2ef,$f2f3,$f2f7,$f2fa,$f2fe,$f302,$f305
	dw $f309,$f30d,$f310,$f314,$f318,$f31b,$f31f,$f323
	dw $f327,$f32a,$f32e,$f332,$f336,$f339,$f33d,$f341
	dw $f345,$f349,$f34c,$f350,$f354,$f358,$f35c,$f360
	dw $f363,$f367,$f36b,$f36f,$f373,$f377,$f37b,$f37f
	dw $f383,$f387,$f38a,$f38e,$f392,$f396,$f39a,$f39e
	dw $f3a2,$f3a6,$f3aa,$f3ae,$f3b2,$f3b6,$f3ba,$f3be
	dw $f3c2,$f3c6,$f3ca,$f3cf,$f3d3,$f3d7,$f3db,$f3df
	dw $f3e3,$f3e7,$f3eb,$f3ef,$f3f3,$f3f8,$f3fc,$f400
	dw $f404,$f408,$f40c,$f411,$f415,$f419,$f41d,$f421
	dw $f426,$f42a,$f42e,$f432,$f436,$f43b,$f43f,$f443
	dw $f448,$f44c,$f450,$f454,$f459,$f45d,$f461,$f466
	dw $f46a,$f46e,$f473,$f477,$f47b,$f480,$f484,$f488
	dw $f48d,$f491,$f496,$f49a,$f49e,$f4a3,$f4a7,$f4ac
	dw $f4b0,$f4b5,$f4b9,$f4be,$f4c2,$f4c6,$f4cb,$f4cf
	dw $f4d4,$f4d8,$f4dd,$f4e1,$f4e6,$f4eb,$f4ef,$f4f4
	dw $f4f8,$f4fd,$f501,$f506,$f50a,$f50f,$f514,$f518
	dw $f51d,$f521,$f526,$f52b,$f52f,$f534,$f538,$f53d
	dw $f542,$f546,$f54b,$f550,$f554,$f559,$f55e,$f563
	dw $f567,$f56c,$f571,$f575,$f57a,$f57f,$f584,$f588
	dw $f58d,$f592,$f597,$f59b,$f5a0,$f5a5,$f5aa,$f5af
	dw $f5b3,$f5b8,$f5bd,$f5c2,$f5c7,$f5cb,$f5d0,$f5d5
	dw $f5da,$f5df,$f5e4,$f5e9,$f5ee,$f5f2,$f5f7,$f5fc
	dw $f601,$f606,$f60b,$f610,$f615,$f61a,$f61f,$f624
	dw $f629,$f62d,$f632,$f637,$f63c,$f641,$f646,$f64b
	dw $f650,$f655,$f65a,$f65f,$f664,$f669,$f66e,$f673
	dw $f679,$f67e,$f683,$f688,$f68d,$f692,$f697,$f69c
	dw $f6a1,$f6a6,$f6ab,$f6b0,$f6b5,$f6bb,$f6c0,$f6c5
	dw $f6ca,$f6cf,$f6d4,$f6d9,$f6df,$f6e4,$f6e9,$f6ee
	dw $f6f3,$f6f8,$f6fe,$f703,$f708,$f70d,$f712,$f718
	dw $f71d,$f722,$f727,$f72d,$f732,$f737,$f73c,$f742
	dw $f747,$f74c,$f751,$f757,$f75c,$f761,$f767,$f76c
	dw $f771,$f776,$f77c,$f781,$f786,$f78c,$f791,$f796
	dw $f79c,$f7a1,$f7a6,$f7ac,$f7b1,$f7b7,$f7bc,$f7c1
	dw $f7c7,$f7cc,$f7d2,$f7d7,$f7dc,$f7e2,$f7e7,$f7ed
	dw $f7f2,$f7f7,$f7fd,$f802,$f808,$f80d,$f813,$f818
	dw $f81e,$f823,$f829,$f82e,$f833,$f839,$f83e,$f844
	dw $f849,$f84f,$f854,$f85a,$f860,$f865,$f86b,$f870
	dw $f876,$f87b,$f881,$f886,$f88c,$f891,$f897,$f89d
	dw $f8a2,$f8a8,$f8ad,$f8b3,$f8b8,$f8be,$f8c4,$f8c9
	dw $f8cf,$f8d5,$f8da,$f8e0,$f8e5,$f8eb,$f8f1,$f8f6
	dw $f8fc,$f902,$f907,$f90d,$f913,$f918,$f91e,$f924
	dw $f929,$f92f,$f935,$f93a,$f940,$f946,$f94b,$f951
	dw $f957,$f95d,$f962,$f968,$f96e,$f973,$f979,$f97f
	dw $f985,$f98a,$f990,$f996,$f99c,$f9a1,$f9a7,$f9ad
	dw $f9b3,$f9b8,$f9be,$f9c4,$f9ca,$f9d0,$f9d5,$f9db
	dw $f9e1,$f9e7,$f9ed,$f9f2,$f9f8,$f9fe,$fa04,$fa0a
	dw $fa10,$fa15,$fa1b,$fa21,$fa27,$fa2d,$fa33,$fa39
	dw $fa3e,$fa44,$fa4a,$fa50,$fa56,$fa5c,$fa62,$fa67
	dw $fa6d,$fa73,$fa79,$fa7f,$fa85,$fa8b,$fa91,$fa97
	dw $fa9d,$faa3,$faa8,$faae,$fab4,$faba,$fac0,$fac6
	dw $facc,$fad2,$fad8,$fade,$fae4,$faea,$faf0,$faf6
	dw $fafc,$fb02,$fb08,$fb0e,$fb14,$fb1a,$fb20,$fb25
	dw $fb2b,$fb31,$fb37,$fb3d,$fb43,$fb49,$fb4f,$fb55
	dw $fb5b,$fb62,$fb68,$fb6e,$fb74,$fb7a,$fb80,$fb86
	dw $fb8c,$fb92,$fb98,$fb9e,$fba4,$fbaa,$fbb0,$fbb6
	dw $fbbc,$fbc2,$fbc8,$fbce,$fbd4,$fbda,$fbe0,$fbe6
	dw $fbed,$fbf3,$fbf9,$fbff,$fc05,$fc0b,$fc11,$fc17
	dw $fc1d,$fc23,$fc29,$fc30,$fc36,$fc3c,$fc42,$fc48
	dw $fc4e,$fc54,$fc5a,$fc60,$fc67,$fc6d,$fc73,$fc79
	dw $fc7f,$fc85,$fc8b,$fc91,$fc98,$fc9e,$fca4,$fcaa
	dw $fcb0,$fcb6,$fcbc,$fcc3,$fcc9,$fccf,$fcd5,$fcdb
	dw $fce1,$fce8,$fcee,$fcf4,$fcfa,$fd00,$fd06,$fd0d
	dw $fd13,$fd19,$fd1f,$fd25,$fd2b,$fd32,$fd38,$fd3e
	dw $fd44,$fd4a,$fd51,$fd57,$fd5d,$fd63,$fd69,$fd70
	dw $fd76,$fd7c,$fd82,$fd88,$fd8f,$fd95,$fd9b,$fda1
	dw $fda7,$fdae,$fdb4,$fdba,$fdc0,$fdc7,$fdcd,$fdd3
	dw $fdd9,$fddf,$fde6,$fdec,$fdf2,$fdf8,$fdff,$fe05
	dw $fe0b,$fe11,$fe18,$fe1e,$fe24,$fe2a,$fe31,$fe37
	dw $fe3d,$fe43,$fe4a,$fe50,$fe56,$fe5c,$fe63,$fe69
	dw $fe6f,$fe75,$fe7c,$fe82,$fe88,$fe8e,$fe95,$fe9b
	dw $fea1,$fea7,$feae,$feb4,$feba,$fec0,$fec7,$fecd
	dw $fed3,$fed9,$fee0,$fee6,$feec,$fef3,$fef9,$feff
	dw $ff05,$ff0c,$ff12,$ff18,$ff1e,$ff25,$ff2b,$ff31
	dw $ff38,$ff3e,$ff44,$ff4a,$ff51,$ff57,$ff5d,$ff63
	dw $ff6a,$ff70,$ff76,$ff7d,$ff83,$ff89,$ff8f,$ff96
	dw $ff9c,$ffa2,$ffa9,$ffaf,$ffb5,$ffbb,$ffc2,$ffc8
	dw $ffce,$ffd5,$ffdb,$ffe1,$ffe7,$ffee,$fff4,$fffa
	dw $0000,$0006,$000c,$0012,$0019,$001f,$0025,$002b
	dw $0032,$0038,$003e,$0045,$004b,$0051,$0057,$005e
	dw $0064,$006a,$0071,$0077,$007d,$0083,$008a,$0090
	dw $0096,$009d,$00a3,$00a9,$00af,$00b6,$00bc,$00c2
	dw $00c8,$00cf,$00d5,$00db,$00e2,$00e8,$00ee,$00f4
	dw $00fb,$0101,$0107,$010d,$0114,$011a,$0120,$0127
	dw $012d,$0133,$0139,$0140,$0146,$014c,$0152,$0159
	dw $015f,$0165,$016b,$0172,$0178,$017e,$0184,$018b
	dw $0191,$0197,$019d,$01a4,$01aa,$01b0,$01b6,$01bd
	dw $01c3,$01c9,$01cf,$01d6,$01dc,$01e2,$01e8,$01ef
	dw $01f5,$01fb,$0201,$0208,$020e,$0214,$021a,$0221
	dw $0227,$022d,$0233,$0239,$0240,$0246,$024c,$0252
	dw $0259,$025f,$0265,$026b,$0271,$0278,$027e,$0284
	dw $028a,$0290,$0297,$029d,$02a3,$02a9,$02af,$02b6
	dw $02bc,$02c2,$02c8,$02ce,$02d5,$02db,$02e1,$02e7
	dw $02ed,$02f3,$02fa,$0300,$0306,$030c,$0312,$0318
	dw $031f,$0325,$032b,$0331,$0337,$033d,$0344,$034a
	dw $0350,$0356,$035c,$0362,$0368,$036f,$0375,$037b
	dw $0381,$0387,$038d,$0393,$0399,$03a0,$03a6,$03ac
	dw $03b2,$03b8,$03be,$03c4,$03ca,$03d0,$03d7,$03dd
	dw $03e3,$03e9,$03ef,$03f5,$03fb,$0401,$0407,$040d
	dw $0413,$041a,$0420,$0426,$042c,$0432,$0438,$043e
	dw $0444,$044a,$0450,$0456,$045c,$0462,$0468,$046e
	dw $0474,$047a,$0480,$0486,$048c,$0492,$0498,$049e
	dw $04a5,$04ab,$04b1,$04b7,$04bd,$04c3,$04c9,$04cf
	dw $04d5,$04db,$04e0,$04e6,$04ec,$04f2,$04f8,$04fe
	dw $0504,$050a,$0510,$0516,$051c,$0522,$0528,$052e
	dw $0534,$053a,$0540,$0546,$054c,$0552,$0558,$055d
	dw $0563,$0569,$056f,$0575,$057b,$0581,$0587,$058d
	dw $0593,$0599,$059e,$05a4,$05aa,$05b0,$05b6,$05bc
	dw $05c2,$05c7,$05cd,$05d3,$05d9,$05df,$05e5,$05eb
	dw $05f0,$05f6,$05fc,$0602,$0608,$060e,$0613,$0619
	dw $061f,$0625,$062b,$0630,$0636,$063c,$0642,$0648
	dw $064d,$0653,$0659,$065f,$0664,$066a,$0670,$0676
	dw $067b,$0681,$0687,$068d,$0692,$0698,$069e,$06a3
	dw $06a9,$06af,$06b5,$06ba,$06c0,$06c6,$06cb,$06d1
	dw $06d7,$06dc,$06e2,$06e8,$06ed,$06f3,$06f9,$06fe
	dw $0704,$070a,$070f,$0715,$071b,$0720,$0726,$072b
	dw $0731,$0737,$073c,$0742,$0748,$074d,$0753,$0758
	dw $075e,$0763,$0769,$076f,$0774,$077a,$077f,$0785
	dw $078a,$0790,$0795,$079b,$07a0,$07a6,$07ac,$07b1
	dw $07b7,$07bc,$07c2,$07c7,$07cd,$07d2,$07d7,$07dd
	dw $07e2,$07e8,$07ed,$07f3,$07f8,$07fe,$0803,$0809
	dw $080e,$0813,$0819,$081e,$0824,$0829,$082e,$0834
	dw $0839,$083f,$0844,$0849,$084f,$0854,$085a,$085f
	dw $0864,$086a,$086f,$0874,$087a,$087f,$0884,$088a
	dw $088f,$0894,$0899,$089f,$08a4,$08a9,$08af,$08b4
	dw $08b9,$08be,$08c4,$08c9,$08ce,$08d3,$08d9,$08de
	dw $08e3,$08e8,$08ee,$08f3,$08f8,$08fd,$0902,$0908
	dw $090d,$0912,$0917,$091c,$0921,$0927,$092c,$0931
	dw $0936,$093b,$0940,$0945,$094b,$0950,$0955,$095a
	dw $095f,$0964,$0969,$096e,$0973,$0978,$097d,$0982
	dw $0987,$098d,$0992,$0997,$099c,$09a1,$09a6,$09ab
	dw $09b0,$09b5,$09ba,$09bf,$09c4,$09c9,$09ce,$09d3
	dw $09d7,$09dc,$09e1,$09e6,$09eb,$09f0,$09f5,$09fa
	dw $09ff,$0a04,$0a09,$0a0e,$0a12,$0a17,$0a1c,$0a21
	dw $0a26,$0a2b,$0a30,$0a35,$0a39,$0a3e,$0a43,$0a48
	dw $0a4d,$0a51,$0a56,$0a5b,$0a60,$0a65,$0a69,$0a6e
	dw $0a73,$0a78,$0a7c,$0a81,$0a86,$0a8b,$0a8f,$0a94
	dw $0a99,$0a9d,$0aa2,$0aa7,$0aac,$0ab0,$0ab5,$0aba
	dw $0abe,$0ac3,$0ac8,$0acc,$0ad1,$0ad5,$0ada,$0adf
	dw $0ae3,$0ae8,$0aec,$0af1,$0af6,$0afa,$0aff,$0b03
	dw $0b08,$0b0c,$0b11,$0b15,$0b1a,$0b1f,$0b23,$0b28
	dw $0b2c,$0b31,$0b35,$0b3a,$0b3e,$0b42,$0b47,$0b4b
	dw $0b50,$0b54,$0b59,$0b5d,$0b62,$0b66,$0b6a,$0b6f
	dw $0b73,$0b78,$0b7c,$0b80,$0b85,$0b89,$0b8d,$0b92
	dw $0b96,$0b9a,$0b9f,$0ba3,$0ba7,$0bac,$0bb0,$0bb4
	dw $0bb8,$0bbd,$0bc1,$0bc5,$0bca,$0bce,$0bd2,$0bd6
	dw $0bda,$0bdf,$0be3,$0be7,$0beb,$0bef,$0bf4,$0bf8
	dw $0bfc,$0c00,$0c04,$0c08,$0c0d,$0c11,$0c15,$0c19
	dw $0c1d,$0c21,$0c25,$0c29,$0c2d,$0c31,$0c36,$0c3a
	dw $0c3e,$0c42,$0c46,$0c4a,$0c4e,$0c52,$0c56,$0c5a
	dw $0c5e,$0c62,$0c66,$0c6a,$0c6e,$0c72,$0c76,$0c79
	dw $0c7d,$0c81,$0c85,$0c89,$0c8d,$0c91,$0c95,$0c99
	dw $0c9d,$0ca0,$0ca4,$0ca8,$0cac,$0cb0,$0cb4,$0cb7
	dw $0cbb,$0cbf,$0cc3,$0cc7,$0cca,$0cce,$0cd2,$0cd6
	dw $0cd9,$0cdd,$0ce1,$0ce5,$0ce8,$0cec,$0cf0,$0cf3
	dw $0cf7,$0cfb,$0cfe,$0d02,$0d06,$0d09,$0d0d,$0d11
	dw $0d14,$0d18,$0d1c,$0d1f,$0d23,$0d26,$0d2a,$0d2d
	dw $0d31,$0d35,$0d38,$0d3c,$0d3f,$0d43,$0d46,$0d4a
	dw $0d4d,$0d51,$0d54,$0d58,$0d5b,$0d5f,$0d62,$0d65
	dw $0d69,$0d6c,$0d70,$0d73,$0d77,$0d7a,$0d7d,$0d81
	dw $0d84,$0d87,$0d8b,$0d8e,$0d91,$0d95,$0d98,$0d9b
	dw $0d9f,$0da2,$0da5,$0da9,$0dac,$0daf,$0db2,$0db6
	dw $0db9,$0dbc,$0dbf,$0dc2,$0dc6,$0dc9,$0dcc,$0dcf
	dw $0dd2,$0dd5,$0dd9,$0ddc,$0ddf,$0de2,$0de5,$0de8
	dw $0deb,$0dee,$0df2,$0df5,$0df8,$0dfb,$0dfe,$0e01
	dw $0e04,$0e07,$0e0a,$0e0d,$0e10,$0e13,$0e16,$0e19
	dw $0e1c,$0e1f,$0e22,$0e25,$0e28,$0e2b,$0e2d,$0e30
	dw $0e33,$0e36,$0e39,$0e3c,$0e3f,$0e42,$0e44,$0e47
	dw $0e4a,$0e4d,$0e50,$0e53,$0e55,$0e58,$0e5b,$0e5e
	dw $0e60,$0e63,$0e66,$0e69,$0e6b,$0e6e,$0e71,$0e74
	dw $0e76,$0e79,$0e7c,$0e7e,$0e81,$0e84,$0e86,$0e89
	dw $0e8b,$0e8e,$0e91,$0e93,$0e96,$0e98,$0e9b,$0e9e
	dw $0ea0,$0ea3,$0ea5,$0ea8,$0eaa,$0ead,$0eaf,$0eb2
	dw $0eb4,$0eb7,$0eb9,$0ebc,$0ebe,$0ec0,$0ec3,$0ec5
	dw $0ec8,$0eca,$0ecd,$0ecf,$0ed1,$0ed4,$0ed6,$0ed8
	dw $0edb,$0edd,$0edf,$0ee2,$0ee4,$0ee6,$0ee8,$0eeb
	dw $0eed,$0eef,$0ef2,$0ef4,$0ef6,$0ef8,$0efa,$0efd
	dw $0eff,$0f01,$0f03,$0f05,$0f08,$0f0a,$0f0c,$0f0e
	dw $0f10,$0f12,$0f14,$0f16,$0f18,$0f1b,$0f1d,$0f1f
	dw $0f21,$0f23,$0f25,$0f27,$0f29,$0f2b,$0f2d,$0f2f
	dw $0f31,$0f33,$0f35,$0f37,$0f39,$0f3b,$0f3c,$0f3e
	dw $0f40,$0f42,$0f44,$0f46,$0f48,$0f4a,$0f4b,$0f4d
	dw $0f4f,$0f51,$0f53,$0f55,$0f56,$0f58,$0f5a,$0f5c
	dw $0f5d,$0f5f,$0f61,$0f63,$0f64,$0f66,$0f68,$0f69
	dw $0f6b,$0f6d,$0f6e,$0f70,$0f72,$0f73,$0f75,$0f77
	dw $0f78,$0f7a,$0f7b,$0f7d,$0f7f,$0f80,$0f82,$0f83
	dw $0f85,$0f86,$0f88,$0f89,$0f8b,$0f8c,$0f8e,$0f8f
	dw $0f91,$0f92,$0f94,$0f95,$0f96,$0f98,$0f99,$0f9b
	dw $0f9c,$0f9d,$0f9f,$0fa0,$0fa1,$0fa3,$0fa4,$0fa5
	dw $0fa7,$0fa8,$0fa9,$0fab,$0fac,$0fad,$0fae,$0fb0
	dw $0fb1,$0fb2,$0fb3,$0fb4,$0fb6,$0fb7,$0fb8,$0fb9
	dw $0fba,$0fbb,$0fbd,$0fbe,$0fbf,$0fc0,$0fc1,$0fc2
	dw $0fc3,$0fc4,$0fc5,$0fc6,$0fc7,$0fc8,$0fc9,$0fca
	dw $0fcb,$0fcc,$0fcd,$0fce,$0fcf,$0fd0,$0fd1,$0fd2
	dw $0fd3,$0fd4,$0fd5,$0fd6,$0fd7,$0fd8,$0fd9,$0fd9
	dw $0fda,$0fdb,$0fdc,$0fdd,$0fde,$0fde,$0fdf,$0fe0
	dw $0fe1,$0fe1,$0fe2,$0fe3,$0fe4,$0fe4,$0fe5,$0fe6
	dw $0fe7,$0fe7,$0fe8,$0fe9,$0fe9,$0fea,$0feb,$0feb
	dw $0fec,$0fec,$0fed,$0fee,$0fee,$0fef,$0fef,$0ff0
	dw $0ff0,$0ff1,$0ff1,$0ff2,$0ff2,$0ff3,$0ff3,$0ff4
	dw $0ff4,$0ff5,$0ff5,$0ff6,$0ff6,$0ff7,$0ff7,$0ff7
	dw $0ff8,$0ff8,$0ff9,$0ff9,$0ff9,$0ffa,$0ffa,$0ffa
	dw $0ffb,$0ffb,$0ffb,$0ffb,$0ffc,$0ffc,$0ffc,$0ffc
	dw $0ffd,$0ffd,$0ffd,$0ffd,$0ffe,$0ffe,$0ffe,$0ffe
	dw $0ffe,$0ffe,$0fff,$0fff,$0fff,$0fff,$0fff,$0fff
	dw $0fff,$0fff,$0fff,$0fff,$0fff,$0fff,$0fff,$0fff

;------------------------------------------------------------------------------
