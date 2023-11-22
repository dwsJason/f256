;
; Merlin32 Compressed Bitmap example for Jr
;
; To Assemble "merlin32 -v . link.s"
;
		mx %11

; Zero Page defines
;mmu_ctrl equ 0
;io_ctrl  equ 1
; reserved addresses 2-7 for future expansion, use at your own peril

; System Bus Pointer's
;pSource  equ $10
;pDest    equ pSource+4

xpos = $20
ping = $22
irq_mode     = $23
state        = $24

;LINE0 = 16
;LINE1 = 480-16

LINE0 = 16
LINE1 = 480-16

VIRQ = $FFFE

temp0 = $D0
temp1 = $D4
temp2 = $D8
temp3 = $DC

MAP_DATA0  = $010000
MAP_DATA1  = $012000

TILE_DATA0 = $020000

; tiles are 16k for 256 in 8x8 mode
TILE_SIZE = {8*8*256}
TILE_DATA1 = TILE_DATA0+TILE_SIZE
TILE_DATA2 = TILE_DATA1+TILE_SIZE
TILE_DATA3 = TILE_DATA2+TILE_SIZE
TILE_DATA4 = TILE_DATA3+TILE_SIZE
TILE_DATA5 = TILE_DATA4+TILE_SIZE
TILE_DATA6 = TILE_DATA5+TILE_SIZE
TILE_DATA7 = TILE_DATA8+TILE_SIZE


CLUT_DATA  = $007C00

;
; This will copy the color table into memory, then set the video registers
; to display the bitmap
;

start
; We're going to load compressed picture data at $04/0000, since currently
; Jr Vicky can't see above this
;		jsr InstallIRQ
;		cli
;]nope bra ]nope

		jsr init320x240
		jsr TermInit

		do 0
		ldy #0
]lp		lda :bleck,y
		beq :dne
		jsr TermCOUT
		iny
		bra ]lp

:bleck  asc 'Hello'
		db 13
		asc 'Moto'
		db 13,0
:dne

		lda #<txt_test
		ldx #>txt_test
		jsr TermPUTS

		ldx #0
		lda #0
]lp		pha
		phx
		jsr TermPrintAXI

		lda #13
		jsr TermCOUT

		plx
		pla
		inc
		bne ]lp
		inx
		bne ]lp

]wait bra ]wait

txt_test asc '01234567890123456789012345678901234567890123456789012345678901234567890123456789Wrapped?'
		db 13,0
		fin

		jsr mmu_unlock

		lda #<txt_unlock
		ldx #>txt_unlock
		jsr TermPUTS

		lda #<CLUT_DATA
		ldx #>CLUT_DATA
		ldy #^CLUT_DATA
		jsr set_write_address

		lda #<txt_setaddr
		ldx #>txt_setaddr
		jsr TermPUTS

PICNUM = 0   ; Floor, 1 is BG
BGPICNUM = 1 ;1 is BG

		ldx #PICNUM ; picture #
		jsr set_pic_address

		lda #<txt_setpicaddr
		ldx #>txt_setpicaddr
		jsr TermPUTS

		jsr get_read_address
		phx
		pha
		tya
		jsr TermPrintAH
		pla
		plx
		jsr TermPrintAXH
		lda #13
		jsr TermCOUT

		jsr get_write_address
		phx
		pha
		tya
		jsr TermPrintAH
		pla
		plx
		jsr TermPrintAXH
		lda #13
		jsr TermCOUT

		jsr decompress_clut
		bcc :good

		jsr TermPrintAI
		lda #13
		jsr TermCOUT

:good
		lda #<txt_decompress_clut
		ldx #>txt_decompress_clut
		jsr TermPUTS

		php
		sei

		; set access to vicky CLUTs
		lda #1
		sta io_ctrl
		; copy the clut up there
		ldx #0
]lp		lda CLUT_DATA,x
		sta VKY_GR_CLUT_0,x
		lda CLUT_DATA+$100,x
		sta VKY_GR_CLUT_0+$100,x
		lda CLUT_DATA+$200,x
		sta VKY_GR_CLUT_0+$200,x
		lda CLUT_DATA+$300,x
		sta VKY_GR_CLUT_0+$300,x
		dex
		bne ]lp

		; set access back to text buffer, for the text stuff
		lda #2
		sta io_ctrl

		plp

		lda #<txt_copy_clut
		ldx #>txt_copy_clut
		jsr TermPUTS

		lda #<TILE_DATA0
		ldx #>TILE_DATA0
		ldy #^TILE_DATA0
		jsr set_write_address

		ldx #PICNUM
		jsr set_pic_address

		; read + write address for pixels
		jsr get_read_address
		phx
		pha
		tya
		jsr TermPrintAH
		pla
		plx
		jsr TermPrintAXH
		lda #13
		jsr TermCOUT

		jsr get_write_address
		phx
		pha
		tya
		jsr TermPrintAH
		pla
		plx
		jsr TermPrintAXH
		lda #13
		jsr TermCOUT

		php
		sei

		jsr decompress_pixels

		plp

		lda #<txt_decompress
		ldx #>txt_decompress
		jsr TermPUTS

;-----------------------------------------------

		ldx #PICNUM ; picture #
		jsr set_pic_address

		lda #<MAP_DATA0
		ldx #>MAP_DATA0
		ldy #^MAP_DATA0
		jsr set_write_address

		jsr decompress_map

		lda #<txt_decompress_map
		ldx #>txt_decompress_map
		jsr TermPUTS
;-----------------------------------------------

		ldx #BGPICNUM ; picture #
		jsr set_pic_address

		lda #<MAP_DATA1
		ldx #>MAP_DATA1
		ldy #^MAP_DATA1
		jsr set_write_address

		jsr decompress_map

		; fix map, add 512 to each map tile reference
		lda #<MAP_DATA1
		ldx #>MAP_DATA1
		ldy #^MAP_DATA1
		jsr set_read_address

		lda #<MAP_DATA1
		ldx #>MAP_DATA1
		ldy #^MAP_DATA1
		jsr set_write_address

		ldx #<$2000
		ldy #>$2000

]lp
		jsr readbyte
		jsr writebyte

		jsr readbyte
		ora #$02  ; add 512 to the tile number
		jsr writebyte

		dex
		bne ]lp
		dey
		bne ]lp


;-----------------------------------------------

		lda #<TILE_DATA2
		ldx #>TILE_DATA2
		ldy #^TILE_DATA2
		jsr set_write_address

		ldx #BGPICNUM
		jsr set_pic_address

		jsr decompress_pixels

;-----------------------------------------------
		sei
		jsr InstallIRQ

;]stop bra ]stop

		jsr init_rate_tables
		jsr init_default_scroll_positions

		;jsr mmu_lock

; Going to image at $01/0000
; Going to put palette at $03/0000 
		cli

;--------------------------------------------------------

		;lda #2
		;sta io_ctrl         ; swap in the text memory, so I can use term

		stz io_ctrl 	; for wait vbl
		; make debug text easier
		stz VKY_TXT_FGLUT+{4*1}+0
		stz VKY_TXT_FGLUT+{4*1}+1
		stz VKY_TXT_FGLUT+{4*1}+2

		; clear text etc
		jsr TermInit

		stz io_ctrl 	; for wait vbl
		lda #{176-88}
		sta xpos
		stz xpos+1
		stz ping


;		lda bg_x1+10
;		pha
;		jsr scroll_left
;		jsr scroll_left
;		pla
;]done
;		cmp bg_x1+10
;		beq ]done

]wait 
;		ldy #60
;]slower
;		phy
		jsr WaitVBL
;		ply
;		dey
;		bpl ]slower

		jsr blit_scroll

;		jsr debug_scroll

		do 0
;--  copy X Position into Register
		lda <xpos
		and #7
		sta <temp0

		lda <xpos
		asl
		and #$F0
		ora <temp0
		sta $D208 ; tile map 0
		sta $D214 ; tile map 1

		lda <xpos+1
		rol
		sta $D209
		sta $D215
		fin
;-----------------------

		lda ping
		beq :inc

		; else dec
		dec <xpos

		lda <xpos
		cmp #$FF
		bne :scroll_left

		stz <xpos
		stz <ping

		bra ]wait

:scroll_left
		jsr scroll_left
		bra ]wait
:inc

		inc <xpos
		;bne ]continue
		;inc <xpos+1
		jsr scroll_right

		lda <xpos
		cmp #512-320-16
		bcc ]wait

		inc ping

		bra ]wait

WaitVBL
;LINE_NO = 21*2  ; seems to be top line
LINE_NO = 261*2  ; 240+21
		lda #<LINE_NO
		ldx #>LINE_NO
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
		rts

;------------------------------------------------------------------------------
; debug_scroll
;
debug_scroll

		;sei
		lda #2
		sta io_ctrl         ; swap in the text memory, so I can use term

		ldx #0
;		txy
		ldy #0
		jsr TermSetXY

		ldy #0
]lp
		tya
		jsr TermPrintAH
		lda #' '
		jsr TermCOUT

		lda |bg_rate_h,y
		tax
		lda |bg_rate_l,y
		jsr TermPrintAXH
		lda #' '
		jsr TermCOUT

		lda |bg_x1,y
		tax
		lda |bg_x0,y
		jsr TermPrintAXH
		jsr TermCR

		iny
		cpy #40
		bcc ]lp

		stz io_ctrl
		;cli
		rts

;------------------------------------------------------------------------------

;
; X = offset to picture to set
; 
set_pic_address
		lda :pic_table_h,x
		tay
		lda :pic_table_m,x
		pha
		lda :pic_table_l,x
		plx

		jmp set_read_address

; memory bus addresses
:pic_table_l
		db <pic1
		db <pic2
:pic_table_m
		db >pic1
		db >pic2
:pic_table_h
		db ^pic1
		db ^pic2

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
		stz VKY_MSTR_CTRL_1

		; layer stuff - take from Jr manual
		lda #$54
		sta VKY_LAYER_CTRL_0  ; tile map layers
		lda #$06
		sta VKY_LAYER_CTRL_1  ; tile map layers

		; Tile Map 0
		lda #$11
		sta $D200 ; tile size 8x8 + enable

		lda #<MAP_DATA0
		sta $D201
		lda #>MAP_DATA0
		sta $D202
		lda #^MAP_DATA0
		sta $D203

		lda #512/8
		sta $D204  ; map size X
		stz $D205  ; reserved
		;lda #232/8
		sta $D206  ; map size y
		stz $D207  ; reserved
		stz $D208  ; scroll x lo
		stz $D209  ; scroll x hi
		stz $D20A  ; scroll y lo
		stz $D20B  ; scroll y hi

		; Tile Map 1
		lda #$11
		sta $D20C ; tile size 8x8 + enable

		lda #<MAP_DATA1
		sta $D20D
		lda #>MAP_DATA1
		sta $D20E
		lda #^MAP_DATA1
		sta $D20F

		lda #512/8
		sta $D210  ; map size X
		stz $D211  ; reserved
		;lda #232/8
		sta $D212  ; map size y
		stz $D213  ; reserved
		stz $D214  ; scroll x lo
		stz $D215  ; scroll x hi
		;lda #1
		stz $D216  ; scroll y lo
		stz $D217  ; scroll y hi

		; tile map 2
		stz $D218 ; disable

		; bitmap disables
		stz $D100  ; disable
		stz $D108  ; disable
		stz $D110  ; disable

		; tiles locations
		lda #<TILE_DATA0
		sta $D280
		lda #>TILE_DATA0
		sta $D281
		lda #^TILE_DATA0
		sta $D282
		stz $D283

		lda #<TILE_DATA1
		sta $D284
		lda #>TILE_DATA1
		sta $D285
		lda #^TILE_DATA1
		sta $D286
		stz $D287

		lda #<TILE_DATA2
		sta $D288
		lda #>TILE_DATA2
		sta $D289
		lda #^TILE_DATA2
		sta $D28A
		stz $D28B

		lda #<TILE_DATA3
		sta $D28C
		lda #>TILE_DATA3
		sta $D28D
		lda #^TILE_DATA3
		sta $D28E
		stz $D28F


	    do 0
;		stz $D002  ; layer ctrl 0
;		stz $D003  ; layer ctrl 3


		; set address of image, since image uncompressed, we just display it
		; where we loaded it.
		lda #<PIXEL_DATA
		sta $D101
		lda #>PIXEL_DATA
		sta $D102
		lda #^PIXEL_DATA
		sta $D103

		lda #1
		sta $D100  ; bitmap enable, use clut 0
		sta $D108  ; disable
		stz $D110  ; disable
		fin

		lda #2
		sta io_ctrl
		plp

		rts
;------------------------------------------------------------------------------
txt_unlock asc 'mmu_unlock'
		db 13,0

txt_setaddr asc 'set_write_address'
		db 13,0

txt_setpicaddr asc 'set_pic_address'
		db 13,0

txt_decompress_clut asc 'decompress_clut'
		db 13,0

txt_copy_clut asc 'copy_clut'
		db 13,0

txt_decompress asc 'decompress_pixels'
		db 13,0

txt_decompress_map asc 'decompress_map'
		db 13,0


;------------------------------------------------------------------------------
; HiJack page $3F, $07E000 -> we will just mirror the ROM, from PAGE $7F
; then patch it, in attempt to keep the micro-kernel functioning, but
; limit it's interrupt service window to the vblank
;
; During the retrace, we can't have random interrupts being serviced, or the
; screen will have rendering glitches
;
InstallIRQ mx %11
		php
		sei

		jsr CopyROM

		stz irq_mode  ; all IRQ like normal

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
		and #INT01_VKY_SOL!$FF  ; clear mask for SOL
		;and #INT00_VKY_SOF!$FF  ; clear mask for SOF
		sta |INT_MASK_0

		lda #$FF
		sta |INT_PEND_0 	; clear any pending interrupts
		sta |INT_PEND_1
;		sta |INT_PEND_2 

		;lda |INT_MASK_0
		;lda #$FF

		;
		; my_irq_handler, only deals with SOL interrupts
		; I know, it's sad, but maybe version 2 will do the magic we all need
		; to keep the kernel humming, and have SOL interrupts that no one
		; is fucking with
		;

		;lda #VKY_LINE_ENABLE
		;sta |VKY_LINE_CTRL 	; enable line interrupts

		;stz |VKY_LINE_NBR_L
		;stz |VKY_LINE_NBR_H

;--- test code from PJW

		lda #$01
		sta |VKY_BRDR_CTRL

		lda #16
		sta |VKY_BRDR_VERT
		sta |VKY_BRDR_HORI

		lda #$80
		sta VKY_BRDR_COL_B
		sta VKY_BRDR_COL_G
		sta VKY_BRDR_COL_R
;--------------------------------

		lda #VKY_LINE_ENABLE
		sta |VKY_LINE_CTRL 	; enable line interrupts

		lda #<LINE0 ; set the line to interrupt on
		sta VKY_LINE_NBR_L
		lda #>LINE0
		sta VKY_LINE_NBR_H

		stz state ; Start in state 0

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
		; on the last line, increment the jiffy, so we can use that for VSync


;------------------------------------------------------------------------------
; Border Stuff

		;lda #VKY_LINE_ENABLE
		;sta |VKY_LINE_CTRL 	; enable line interrupts

		ldx state
		lda mangled_floor_x1,x
		sta $D209
		lda mangled_floor_x0,x
		sta $D208

		lda mangled_bg_x1,x
		sta $D215
		lda mangled_bg_x0,x
		sta $D214

		inx
		cpx #{240-32}
		bcc :keep_going

		ldx #0
:keep_going
		stx state

		txa
		clc
;		adc #LINE0
		asl
		sta VKY_LINE_NBR_L
		lda #0
		rol
		sta VKY_LINE_NBR_H

		do 0
		lda state ; Check the state
		beq is_zero
		stz state ; If state 1: Set the state to 0
		lda #<LINE0 ; Set the line to interrupt on
		sta VKY_LINE_NBR_L
		lda #>LINE0
		sta VKY_LINE_NBR_H
		lda #$80 ; Make the border blue
		sta VKY_BRDR_COL_B
		stz VKY_BRDR_COL_G
		stz VKY_BRDR_COL_R
		bra return
is_zero lda #$01 ; Set the state to 1
		sta state
		lda #<LINE1 ; set the line to interrupt on
		sta VKY_LINE_NBR_L
		lda #>LINE1
		sta VKY_LINE_NBR_H
		lda #$80 ; Make the border red
		stz VKY_BRDR_COL_B
		stz VKY_BRDR_COL_G
		sta VKY_BRDR_COL_R
		fin

;------------------------------------------------------------------------------
return
		lda INT_PEND_0
		;lda #INT01_VKY_SOL
		;bit INT_PEND_0  		; check SOL
		;beq not_this
		;beq return

		sta INT_PEND_0 			; clear SOL interrupt

		pla
		sta <MMU_IO_CTRL

		ply
		plx

		pla
		rti

not_this

		lda INT_PEND_0
		;lda #INT01_VKY_SOL
		;bit INT_PEND_0  		; check SOL
		;beq not_this
		;beq return

		sta INT_PEND_0 			; clear SOL interrupt

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
CopyROM
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
;
; copy rates from array of short values
; into arrays of 8 bit values for easier indexing
;
init_rate_tables

:pSrc = temp0
:pDstLow  = temp1
:pDstHigh = temp1+2

		; floor table
		lda #<default_fg_rate
		sta :pSrc
		lda #>default_fg_rate
		sta :pSrc+1

		lda #<floor_rate_l
		sta <:pDstLow
		lda #>floor_rate_l
		sta <:pDstLow+1

		lda #<floor_rate_h
		sta <:pDstHigh
		lda #>floor_rate_h
		sta <:pDstHigh+1

		jsr :copy

		; background table

		lda #<default_bg_rate
		sta <:pSrc
		lda #>default_bg_rate
		sta <:pSrc+1

		lda #<bg_rate_l
		sta <:pDstLow
		lda #>bg_rate_l
		sta <:pDstLow+1

		lda #<bg_rate_h
		sta <:pDstHigh
		lda #>bg_rate_h
		sta <:pDstHigh+1

:copy
		ldx #240
]loop
		lda (:pSrc)
		sta (:pDstLow)

		inc <:pSrc
		bne :skip1
		inc <:pSrc+1
:skip1
		lda (:pSrc)
		sta (:pDstHigh)

		inc <:pSrc
		bne :skip2
		inc <:pSrc+1
:skip2


		inc <:pDstLow
		bne :skip3
		inc <:pDstLow+1
:skip3

		inc <:pDstHigh
		bne :skip4
		inc <:pDstHigh+1
:skip4
		dex
		bne ]loop

		rts

;------------------------------------------------------------------------------
init_default_scroll_positions

		ldx #240
		lda #{176-88}
]lp
		stz |floor_x0,x
		sta |floor_x1,x
;		stz |floor_x2,x

		stz |bg_x0,x
		sta |bg_x1,x
;		stz |bg_x2,x
		
		dex
		bne ]lp

		rts

;------------------------------------------------------------------------------
;
; Supports a max rate of 0.99, to make the code quicker
;
scroll_left

		do 0
		ldx #240
		sec
]lp
		lda |floor_x0-1,x
		sbc |floor_rate_l-1,x
		sta |floor_x0-1,x
		bcs :skip1
		dec |floor_x1-1,x
		sec
:skip1
		lda |bg_x0-1,x
		sbc |bg_rate_l-1,x
		sta |bg_x0-1,x
		bcs :skip2
		dec |bg_x1-1,x
		sec
:skip2
		dex
		bne ]lp
		fin

		do 1
		ldx #240
]lp
		sec
		lda |floor_x0-1,x
		sbc |floor_rate_l-1,x
		sta |floor_x0-1,x
		lda |floor_x1-1,x
		sbc |floor_rate_h-1,x
		sta |floor_x1-1,x

		sec
		lda |bg_x0-1,x
		sbc |bg_rate_l-1,x
		sta |bg_x0-1,x
		lda |bg_x1-1,x
		sbc |bg_rate_h-1,x
		sta |bg_x1-1,x
:skip2
		dex
		bne ]lp
		fin

		rts
;------------------------------------------------------------------------------
;
; Supports a max rate of 0.99, to make the code quicker
;
scroll_right

		do 0
		ldx #240
		clc
]lp
		lda |floor_x0-1,x
		adc |floor_rate_l-1,x
		sta |floor_x0-1,x
		bcc :skip1
		inc |floor_x1-1,x
		clc
:skip1
		lda |bg_x0-1,x
		adc |bg_rate_l-1,x
		sta |bg_x0-1,x
		bcc :skip2
		inc |bg_x1-1,x
		clc
:skip2
		dex
		bne ]lp
		fin

		do 1
		ldx #240
]lp
		clc
		lda |floor_x0-1,x
		adc |floor_rate_l-1,x
		sta |floor_x0-1,x
		lda |floor_x1-1,x
		adc |floor_rate_h-1,x
		sta |floor_x1-1,x
		clc
		lda |bg_x0-1,x
		adc |bg_rate_l-1,x
		sta |bg_x0-1,x
		lda |bg_x1-1,x
		adc |bg_rate_h-1,x
		sta |bg_x1-1,x

		dex
		bne ]lp
		fin

		rts
;------------------------------------------------------------------------------
blit_scroll

;		ldx #0
;]lp
;		dex
;		lda :xlate_lo,x
;		bne :ct
;		ora #$F
;		sta :xlate_lo,x
;:ct
;		dex
;		bne ]lp

]i = 0
		lup 240
		ldx |floor_x1+]i
		lda :xlate_lo,x
		sta |mangled_floor_x0+]i
		lda :xlate_hi,x
		sta |mangled_floor_x1+]i

		ldx |bg_x1+]i
		lda :xlate_lo,x
		sta |mangled_bg_x0+]i
		lda :xlate_hi,x
		sta |mangled_bg_x1+]i

]i = ]i+1
		--^

		rts

:xlate_lo
]src = 0
		lup 256
]value = {{]src&$F8}*2}
]value = ]value+{]src&7}
		db	<{]value}
]src = ]src+1
		--^

]src = 0

:xlate_hi
		lup 256
]value = {{]src&$F8}*2}
]value = ]value+{]src&7}
		db	>{]value}
]src = ]src+1
		--^

;------------------------------------------------------------------------------
default_fg_rate
		lup 127
		dw $00C0 ; 75% - for the balloons
		--^

		; upper lip of the hot tub
]target = $0094
]start  = $0080
]delta  = ]target-]start
]steps  = 13
]step   = 0
		lup 13
		dw ]start+{{]delta*]step}/]steps}  ; 13 lines here (0.5->0.58)
]step = ]step+1
		--^

		; 140-175 - tub body, needs to be constant
		lup 35
		dw $0094
		--^

		; floor (168->215) (0.5->1.0)

		; 176->215 ; 0.58->1.0
]start  = $0094
]target = $0100
]delta  = ]target-]start
]steps  = 39
]step   = 0
		lup 39
		dw ]start+{{]delta*]step}/]steps}
]step = ]step+1
		--^

		; 215->240
		lup 25
		;dw $0100
		dw $00FF
		--^

;------------------------------------------------------------------------------
default_bg_rate

		lup 7
		dw $0080  ; 50%, but revist because ceiling can parallax
		--^

]start  = $00C0
]target = $0080
]delta  = ]start-]target
]steps  = 23
]step   = 0
		lup 24
		dw ]start-{{]delta*]step}/]steps}
]step = ]step+1
		--^

		lup 208
		dw $0080  ; 50%, but revist because ceiling can parallax
		--^
;------------------------------------------------------------------------------
; 176 pixels is the range, so center is 88 pixels

	;dum *

;------------------------------------------------------------------------------

bg_rate_l ds 240
bg_rate_h ds 240 

floor_rate_l ds 240
floor_rate_h ds 240 

;------------------------------------------------------------------------------

floor_x0 ds 240
floor_x1 ds 240
;floor_x2 ds 240

bg_x0 ds 240
bg_x1 ds 240
;bg_x2 ds 240

mangled_floor_x0 ds 240
mangled_floor_x1 ds 240

mangled_bg_x0 ds 240
mangled_bg_x1 ds 240

;	dend
;------------------------------------------------------------------------------

