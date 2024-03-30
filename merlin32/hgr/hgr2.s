;
; Merlin32 HGR to Jr display toy
;
; To Assemble "merlin32 -v . link.s"
;
		mx %11

	dum $20
temp0 ds 4
temp1 ds 4
temp2 ds 4
temp3 ds 4
temp4 ds 4

dpJiffy ds 1  ; vblank counter

line_no ds 1  ; used in the current IRQ

	dend

; TODO - add a macros file

bccl mac
    bcs skip@
    jmp ]1
skip@
    <<<

VIRQ = $FFFE
LINE0 = 16

;-----------------------------------------------------------------------------
;
; Memory Layout
;

SPRITE_TILES = $10000  	; 64k of them

HGR_CODE = $20000       ; 12 blocks = 96k  

DMA_CLEAR_LEN = $10000
DMA_CLEAR_ADDY = SPRITE_TILES
 


;-----------------------------------------------------------------------------
;
; This will copy the color table into memory, then set the video registers
; to display the bitmap
;

start
		jsr init320x240

		jsr mmu_unlock

		jsr hgr_init

		jsr irq_install


; :count here is for flipping through the 8k page snapshots of HGR RAM

:count = temp1+3
		stz :count

]alter_loop

		lda :count
		cmp #0
		bne :try1
		inc
		sta :count
		lda #<hardhat_image
		ldx #>hardhat_image
		ldy #^hardhat_image
		jmp :do_it
:try1
		cmp #1
		bne :try2
		inc
		sta <:count
		lda #<starblazer_image
		ldx #>starblazer_image
		ldy #^starblazer_image
		jmp :do_it

:try2
		stz <:count

		lda #<blitz_image
		ldx #>blitz_image
		ldy #^blitz_image
:do_it

:y_pos = temp3
:write_address = temp2
:hgr_pix = temp4

		jsr set_read_address	; mmu is going to map this to $2000, woot

		jsr WaitVBL

		bra ]alter_loop

;-----------------------------------------------------------------------------
; take a byte, and crap out pixels that can be used (Bits to pixels)
byte2pix mac
	do ]1&$01
	db 1
	else
	db 0
	fin
	do ]1&$02
	db 1
	else
	db 0
	fin
	do ]1&$04
	db 1
	else
	db 0
	fin
	do ]1&$08
	db 1
	else
	db 0
	fin
	do ]1&$10
	db 1
	else
	db 0
	fin
	do ]1&$20
	db 1
	else
	db 0
	fin
	do ]1&$40
	db 1
	else
	db 0
	fin
	<<<

; perhaps misnamed, but a table of 7 pixel entries (each are 8 pixels)
pixelmap equ *
]v = 0
	lup 256
	byte2pix ]v
]v = ]v+1
	--^


lines mac
	da ]1+$0000
	da ]1+$0400
	da ]1+$0800
	da ]1+$0C00
	da ]1+$1000
	da ]1+$1400
	da ]1+$1800
	da ]1+$1C00
	<<<

lines_lo mac
	db <]1+$0000
	db <]1+$0400
	db <]1+$0800
	db <]1+$0C00
	db <]1+$1000
	db <]1+$1400
	db <]1+$1800
	db <]1+$1C00
	<<<

lines_hi mac
	db >]1+$0000
	db >]1+$0400
	db >]1+$0800
	db >]1+$0C00
	db >]1+$1000
	db >]1+$1400
	db >]1+$1800
	db >]1+$1C00
	<<<

rows mac
	lines ]1
	lines ]1+$080
	lines ]1+$100
	lines ]1+$180
	lines ]1+$200
	lines ]1+$280
	lines ]1+$300
	lines ]1+$380
	<<<

rows_lo mac
	lines_lo ]1
	lines_lo ]1+$080
	lines_lo ]1+$100
	lines_lo ]1+$180
	lines_lo ]1+$200
	lines_lo ]1+$280
	lines_lo ]1+$300
	lines_lo ]1+$380
	<<<

rows_hi mac
	lines_hi ]1
	lines_hi ]1+$080
	lines_hi ]1+$100
	lines_hi ]1+$180
	lines_hi ]1+$200
	lines_hi ]1+$280
	lines_hi ]1+$300
	lines_hi ]1+$380
	<<<

;
; Switzzled like the Apple 2
; Since we're looking at RAW Apple2 data
; in the hopes of porting some small games
;

scanline_table_lo
]addr = $2000
	lup 3
	rows_lo ]addr
]addr = ]addr+40
	--^

scanline_table_hi
]addr = $2000
	lup 3
	rows_hi ]addr
]addr = ]addr+40
	--^



pixelmap_addr_lo
]addr = 0
	lup 256
	db <pixelmap+]addr
]addr = ]addr+7
	--^

pixelmap_addr_hi
]addr = 0
	lup 256
	db >pixelmap+]addr
]addr = ]addr+7
	--^

;------------------------------------------------------------------------------
; WaitVBL
; Preserve all registers
;
WaitVBL
		pha
		lda <dpJiffy
]lp
		cmp <dpJiffy
		beq ]lp
		pla
		rts

;------------------------------------------------------------------------------
clear_bitmap

image_start = DMA_CLEAR_ADDY

		lda #<image_start
		ldx #>image_start
		ldy #^image_start
		jsr set_write_address   ; mmu is going to map this to $6000

		ldx #0
		ldy #0
		lda #0
]clr	jsr writebyte
		jsr writebyte 
		dex
		bne ]clr
		dey
		bne ]clr
		rts
;------------------------------------------------------------------------------
;
; A = Fill Color
;
; Clear the Sprite Tile Catalog
;
DmaClear
		php
		sei

]size = DMA_CLEAR_LEN
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
init320x240
		php
		sei

		; set access to vicky CLUTs
		lda #1
		sta io_ctrl

;-----------------------------------------------------------------------------

; Black index 0
		stz VKY_GR_CLUT_0
		stz VKY_GR_CLUT_0+1
		stz VKY_GR_CLUT_0+2
		stz VKY_GR_CLUT_0+3
; Green index 1
		stz VKY_GR_CLUT_0+4
		lda #$FF
		sta VKY_GR_CLUT_0+5
		stz VKY_GR_CLUT_0+6
		sta VKY_GR_CLUT_0+7

;-----------------------------------------------------------------------------
		; Access to vicky generate registers
		stz io_ctrl

		lda #%00100100 ; Sprite + Graphics
		sta VKY_MSTR_CTRL_0
		stz VKY_MSTR_CTRL_1

		; fix the BG Color
		stz VKY_BKG_COL_B
		stz VKY_BKG_COL_G
		stz VKY_BKG_COL_R

		; Border off
		stz VKY_BRDR_CTRL

;------- disable the sprites, for the moment

		ldx #0
]lp 	stz VKY_SP0_CTRL,x
		stz VKY_SP0_CTRL+256,x
		dex
		bne ]lp

;--------------------------------------------

		lda #0
		jsr DmaClear

		plp
		rts

;------------------------------------------------------------------------------
;     
; 12 * 40 = 480 clocks
;
; 4
; 4 	  = 8 * 40 = 320 + 20 = 340
; 4

		ldx #0   ; scanline #     ; 2 -> 1 per scanline
		stx VKY_SP0_POS_Y_L 	  ; 3 -> 40 per scanline

		lda $2000   			  ; 3 -> 40 per scanline
		sta VKY_SP0_AD_M		  ; 3   = 9 bytes * 40 = 360 * 192 = 69120

		; How about this, how many lines in 8k?
		; 8192 / (360+2+1) = 363 = 22,  192/ 22 = 9 blocks, with 22 lines in each

		; or 12 block, each with 16 lines, (12 * 8k = 96k)

		; each IRQ will have to choose a block, and dispatch from 0-15


hgr_init
		; create the glyphs
		jsr glyph_init

		rts

;------------------------------------------------------------------------------
;
; Each glyph Starts on a page boundary
;
glyph_init

:pGlyph     = temp0   ; current system memory pointer
:pSrcPixels = temp1   ; 16 bit pointers to array of 7 pixels

		lda #<pixelmap
		ldx #>pixelmap
		sta <:pSrcPixels+0
		stx <:pSrcPixels+1

		lda #<SPRITE_TILES
		ldx #>SPRITE_TILES
		ldy #^SPRITE_TILES

]loop
		sta <:pGlyph+0
		stx <:pGlyph+1
		sty <:pGlyph+2

		jsr set_write_address

; for each place, we want to create an 8x8 sprite
; so we copy the pixels 8 times, with a 1 pixel padding

		jsr :create
		; c = 0

		lda <:pSrcPixels+0
		adc #7
		sta <:pSrcPixels+0
		bcc :kk
		inc <:pSrcPixels+1 	; address wrap over
:kk
		inc <:pGlyph+1  ; this is going forward 1 page, doubling as count
		beq :done

		lda <:pGlyph
		ldx <:pGlyph+1
		ldy <:pGlyph+2

		bra ]loop

:done
		rts


:create
		ldx #8  ; doing this 8 times

		clc		; c=0 in the loop

]line_loop
		; copy 1 line
		ldy #7
		lda #0
		sta (pDest),y

		dey
]pix_lp
		lda (:pSrcPixels),y
		sta (pDest),y

		dey
		bpl ]pix_lp

		lda <pDest
		adc #8		; c = 0
		sta <pDest

		dex
		bne ]line_loop

		rts


	






		rts
;------------------------------------------------------------------------------
; HiJack page $3F, $07E000 -> we will just mirror the ROM, from PAGE $7F
; then patch it, in attempt to keep the micro-kernel functioning, but
; limit it's interrupt service window to the vblank
;
; During the retrace, we can't have random interrupts being serviced, or the
; screen will have rendering glitches
;
irq_install mx %11
		php
		sei

		jsr copy_rom

;		stz irq_mode  ; all IRQ like normal

		lda VIRQ
		sta original_irq
		lda VIRQ+1
		sta original_irq+1

		lda #<my_irq_handler
		sta VIRQ

		lda #>my_irq_handler
		sta VIRQ+1
;]nope 				; just confirms it's installed
;		cmp VIRQ+1
;		bne ]nope

		stz io_ctrl

		;plp
		;rts


		;
		; Here's we're just going to fuck over kernel (I'm sad too)
		;
		lda #$FF
;		sta |INT_MASK_0		; disable the interrupts
		sta |INT_MASK_1
;		sta |INT_MASK_2
		and #{INT01_VKY_SOL.INT00_VKY_SOF}!$FF  ; clear mask for SOL, and SOF
		sta |INT_MASK_0

		lda #$FF
		sta |INT_PEND_0 	; clear any pending interrupts
		sta |INT_PEND_1
;		sta |INT_PEND_2 

		;lda |INT_MASK_0
		;lda #$FF

;--------------------------------

		lda #VKY_LINE_ENABLE
		sta |VKY_LINE_CTRL 	; enable line interrupts

		lda #<LINE0 ; set the line to interrupt on
		sta VKY_LINE_NBR_L
		lda #>LINE0
		sta VKY_LINE_NBR_H

		stz line_no ; Start in state 0

		plp
		rts

my_irq_handler

		pha
		phx
		phy

		lda <MMU_IO_CTRL
		pha

		; Switch to I/O page 0
		stz <MMU_IO_CTRL
		; ideally, I would just read the rast_row, and use that to index
		; into the table, but the number in there doesn't seem to really
		; match the scanline, we're just going to be more weird about it
		; start with 0, and increment, for 240 lines?
		; jiffy can reset to 0, do Line 0 sprite Init, since it's special


;------------------------------------------------------------------------------
return
		lda INT_PEND_0
		sta INT_PEND_0 			; clear SOL/SOF interrupts

		bit #INT00_VKY_SOF      ; check for VBL interrupt 
		beq :not_jibby			; branch no

		inc <dpJiffy			; do VBL

		;bit #INT00_VKY_SOL		; make sure it's not a line interrupt
		;beq :not_sol
		stz line_no

		; DO SPRITE RENDER FOR LINE 0
		; ALL Y POSITIONS AT 0
		; FIRST LINE OF SPRITES FILLED IN


		bra :done_irq

:not_jibby

; line interrupt handled here

		ldx line_no				; which line are we servicing

		; DO SPRITE DRAW SERVICE

		inx
		cpx #192			    ; auto increment, only 192 lines
		bcc :keep_going

		ldx #0  	   			; wrap back to zero
		clc

:keep_going
		stx line_no

		adc #LINE0

		txa  					; set the line interrupt register, for the next line

		asl
		sta VKY_LINE_NBR_L		; x2 since vicky counts 480 lines, instead of 240, for high res text
		
		lda #0
		rol
		sta VKY_LINE_NBR_H

; put stuff back
:done_irq

		pla
		sta <MMU_IO_CTRL

		ply
		plx

		pla
		rti

:original_irq


		pla
		sta <MMU_IO_CTRL

		ply
		plx

		pla
		jmp (original_irq) ; $$JGA, this might unmap our IRQ handler


; keep a copy, even though I guess we can always get another copy
original_irq ds 2

;
; Copy the ROM to RAM, so we can patch it, taking the end of memory
;
copy_rom
		php
		sei
	
		lda io_ctrl
		pha

		lda mmu_ctrl
		pha

		and #$3
		sta temp0 ; active MLUT

		asl
		asl
		asl
		asl

		ora temp0
		ora #$80
		sta mmu_ctrl

		; map the kernel ROM to $A000
		lda #$7f
		sta mmu5
		; map our RAM replacement
		lda #$3f
		sta mmu7

		; in case we get called more than 1 time
		lda #$A0
		sta :src+2
		lda #$E0
		sta :dst+2

		ldx #0
		ldy #32
]lp
:src	lda $A000,x
:dst	sta $E000,x
		dex
		bne ]lp

		inc :src+2
		inc :dst+2

		dey
		bne ]lp

		lda #5
		sta mmu5

		;lda #7
		;sta mmu7

		pla
		sta mmu_ctrl

		pla
		sta io_ctrl
		
		plp
		rts

;------------------------------------------------------------------------------





