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
BLIT_BLOCK = $A000
BLIT_MMU   = mmu+{BLIT_BLOCK/8192}


DMA_CLEAR_LEN = $10000
DMA_CLEAR_ADDY = SPRITE_TILES


;------------------------------------------------------------------------------
; Stuff here is executed in the $A000 space

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
		sta mmu4
		; map our RAM replacement
		lda #$3f
		sta mmu7

; - this copies firmware into RAM, so we have vectors

		; in case we get called more than 1 time
		lda #$80
		sta :src+2
		lda #$E0
		sta :dst+2

		ldx #0
		ldy #32
]lp
:src	lda $8000,x
:dst	sta $E000,x
		dex
		bne ]lp

		inc :src+2
		inc :dst+2

		dey
		bne ]lp

; - this relocates our code up into firmware space

		lda #$A0
		sta :mysrc+2
		lda #$E0
		sta :mydst+2

		ldx #0
		ldy #{main_code_end-main_code_start-$4000+255}/256
]lp
:mysrc	lda $A000,x
:mydst	sta $E000,x
		dex
		bne ]lp

		inc :mysrc+2
		inc :mydst+2

		dey
		bne ]lp

		lda #4
		sta mmu4

		;lda #7    ; this stays mapped out buddy
		;sta mmu7

		pla
		sta mmu_ctrl

		pla
		sta io_ctrl
		
		plp
		rts

;-----------------------------------------------------------------------------
;
; This will copy the color table into memory, then set the video registers
; to display the bitmap
;
start
; we need to boot load ourself out of here
		sei
		jsr copy_rom			; copy this code up to $E000
		jmp high_start			; start running from the new home

		org *+$4000				; put us up in the $E000 range

high_start

		jsr init320x240 		; init display

		jsr mmu_unlock

;		jsr clear_bitmap

		jsr hgr_init

;		jsr mmu_lock		    ; we'll try to make this safe (I know I need this)

;]wait bra ]wait

		cli

		jmp starblazer_image


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

;------------------------------------------------------------------------------
;
; Table of which mmu block needs paged in for this scanline
;
blit_block_table
]addr = HGR_CODE
	lup 192
	db ]addr/8192
]addr = ]addr+512
	--^
;------------------------------------------------------------------------------
;
; Local address, based on the scanline
;
blit_jump_table_hi

]addr = HGR_CODE

	lup 192
	db	>{]addr&$1FFF}.BLIT_BLOCK

]addr = ]addr+512
	--^

;------------------------------------------------------------------------------

; This table has pixel patterns, that we use once we load memory from the HGR
; buffer
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

		;lda #0
		;jsr DmaClear
		;jsr clear_bitmap

		plp
		rts

;------------------------------------------------------------------------------
;     

hgr_init
		; create the glyphs
		jsr glyph_init

		jsr blit_init

; sprite init

:pSprite = temp0
:xpos    = temp0+2

; start at x position 32+20
		lda #32+20
		sta <:xpos
		stz <:xpos+1


		lda #<VKY_SP0_CTRL
		sta <:pSprite
		lda #>VKY_SP0_CTRL
		sta <:pSprite+1

		ldx #40  ; counter
]loop
		lda #%01100001   ; 8x8, layer 0, lut 0, enabled
		sta (:pSprite)

		ldy #1
		lda #0
		sta (:pSprite),y   ; AD_L
		iny
		lda #%01010100	   
		sta (:pSprite),y   ; AD_M
		iny
		lda #^SPRITE_TILES
		sta (:pSprite),y   ; AD_H
		iny

		; X position
		lda <:xpos
		sta (:pSprite),y
		iny
		lda <:xpos+1
		sta (:pSprite),y
		iny

		clc
		lda <:xpos
		adc #7
		sta <:xpos
		bcc :xpok
		inc <:xpos+1
:xpok

		; YPosition
		lda #32
		sta (:pSprite),y
		iny
		lda #0
		sta (:pSprite),y

		clc
		lda <:pSprite
		adc #8
		sta <:pSprite
		bcc :spkk
		inc <:pSprite+1
:spkk
		dex
		bne ]loop

		rts

;------------------------------------------------------------------------------
;
; now we're doing a weird thing, generating code into each bank
; 16 programs in each 8k
; each program gets 512 bytes
; line 0 is little longer than the rest, since it has to set all the Y positions
;
; 12 * 40 = 480 clocks
;
; 4
; 4 	  = 8 * 40 = 320 + 20 = 340
; 4
;
;		ldx #0   ; scanline #     ; 2 -> 1 per scanline
;		stx VKY_SP0_POS_Y_L 	  ; 3 -> 40 per scanline
;
;		lda $2000   			  ; 3 -> 40 per scanline
;		sta VKY_SP0_AD_M		  ; 3   = 9 bytes * 40 = 360 * 192 = 69120
;
;		; How about this, how many lines in 8k?
;		; 8192 / (360+2+1) = 363 = 22,  192/ 22 = 9 blocks, with 22 lines in each
;
;		; or 12 block, each with 16 lines, (12 * 8k = 96k)
;
;		; each IRQ will have to choose a block, and dispatch from 0-15
;
blit_init

:pCode   = temp0
:line_no = temp1
:pHGR    = temp2
:pSprite = temp3

		stz <:line_no
		lda <:line_no
]lp
		jsr :get_addr

		jsr :gen_code

		lda <:line_no
		inc
		sta <:line_no
		cmp #192
		bcc ]lp
:done
		rts

:get_addr
		tax
		lda |blit_block_table,x
		sta <BLIT_MMU				; map in the memory

		stz :pCode
		lda |blit_jump_table_hi,x
		sta :pCode+1

		rts

:gen_code

		; x has the line #, handy for looking up table stuff
		lda |scanline_table_lo,x
		sta <:pHGR
		lda |scanline_table_hi,x
		sta <:pHGR+1

		jsr :y_stores
		jsr :sprite_stores

		lda #$60  ; RTS
		jsr :putCode

		lda #0  ; BRK
		jsr :putCode
		jsr :putCode
		jsr :putCode
		jsr :putCode

		rts


:y_stores
		lda |:sprite_start_lo,x
		sta <:pSprite
		lda |:sprite_start_hi,x
		sta <:pSprite+1

		lda #$A2   		; ldx #im
		jsr :putCode
		txa
		clc
		adc #40
		jsr :putCode		; start at 32, and work it

		lda |:sprite_count,x  ; count down for how many stores we we need, for y positions
		tay

:emit_stx_go

		lda #$8E          ; stx |abs
		jsr :putCode
		lda <:pSprite
		jsr :putCode
		lda <:pSprite+1
		jsr :putCode

		clc
		lda <:pSprite
		adc #8
		sta <:pSprite
		bcc :skk
		inc <:pSprite+1
:skk
		dey 			  ; count down
		bne :emit_stx_go

		rts

:sprite_stores
:emit_sprite_no

		lda #<VKY_SP0_AD_M
		sta <:pSprite
		lda #>VKY_SP0_AD_M
		sta <:pSprite+1

		ldy #40  ; we have 40 sprites to update buddy
		;ldy #31

]sp_loop
		lda #$AD      ; LDA |abs - get the hgr data into A
		jsr :putCode
		lda <:pHGR
		jsr :putCode
		lda <:pHGR+1
		jsr :putCode

		inc <:pHGR   	; auto increment the read address
		bne :hgok
		inc <:pHGR+1
:hgok
		lda #$8D     ; STA |ABS
		jsr :putCode
		lda <:pSprite
		jsr :putCode
		lda <:pSprite+1
		jsr :putCode

		; inc sprite
		clc
		lda <:pSprite
		adc #8
		sta <:pSprite
		bcc :spok
		inc <:pSprite+1
:spok
		dey
		bne ]sp_loop

		rts

:putCode
		sta (:pCode)
		inc <:pCode
		bne :nx
		inc <:pCode+1
:nx
		rts


:sprite_start_lo
]spr_start = VKY_SP0_POS_Y_L

		lup 24
		db <{]spr_start+{0*40}}
		db <{]spr_start+{1*40}}
		db <{]spr_start+{2*40}}
		db <{]spr_start+{3*40}}
		db <{]spr_start+{4*40}}
		db <{]spr_start+{5*40}}
		db <{]spr_start+{6*40}}
		db <{]spr_start+{7*40}}
		--^

:sprite_start_hi

		lup 24
		db >{]spr_start+{0*40}}
		db >{]spr_start+{1*40}}
		db >{]spr_start+{2*40}}
		db >{]spr_start+{3*40}}
		db >{]spr_start+{4*40}}
		db >{]spr_start+{5*40}}
		db >{]spr_start+{6*40}}
		db >{]spr_start+{7*40}}
		--^

:sprite_count
		db 40
		lup 191
		db 5
		--^

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

;		jsr copy_rom

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

		lda <BLIT_MMU
		pha


;------------------------------------------------------------------------------

		lda INT_PEND_0
		sta INT_PEND_0 			; clear SOL/SOF interrupts

		bit #INT00_VKY_SOF      ; check for VBL interrupt 
		beq :not_jibby			; branch no

		; DO SPRITE RENDER FOR LINE 0
		; ALL Y POSITIONS AT 0
		; FIRST LINE OF SPRITES FILLED IN

		lda |blit_block_table
		sta <BLIT_MMU

		lda |blit_jump_table_hi
		sta :jsr1+2

:jsr1   JSR |$A000

		bra :keep_going

:not_jibby

; line interrupt handled here

		ldy #1   ; start at line 1, and work our way down
]loop
		; DO SPRITE DRAW SERVICE
		lda |blit_block_table,y
		sta <BLIT_MMU

		lda |blit_jump_table_hi,y
		sta :jsr2+2

:jsr2  	JSR |$A000

		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		;nop
		;nop
		lda <$40


		iny
		cpy #192
		bcc ]loop


:keep_going

		pla
		sta <BLIT_MMU

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




