;
; Merlin32 Compressed Bitmap example for Jr
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

xpos ds 2
ping ds 2

frame_number ds 1

	dend

SPRITE_MAP   ds 120   ; 10x6x2 bytes (120 bytes), this can fit anywhere probably
SPRITE_TILES = $50000 ; could be up to 64k worth, but will be less

MAP_DATA0  = $010000
TILE_DATA0 = $012000 

; tiles are 16k for 256 in 8x8 mode
TILE_SIZE = {16*16*256}
TILE_DATA1 = TILE_DATA0+TILE_SIZE
TILE_DATA2 = TILE_DATA1+TILE_SIZE
TILE_DATA3 = TILE_DATA2+TILE_SIZE
TILE_DATA4 = TILE_DATA3+TILE_SIZE
TILE_DATA5 = TILE_DATA4+TILE_SIZE
TILE_DATA6 = TILE_DATA5+TILE_SIZE
TILE_DATA7 = TILE_DATA6+TILE_SIZE
TILE_DATA8 = TILE_DATA7+TILE_SIZE

CLUT_DATA  = $007C00

;
; This will copy the color table into memory, then set the video registers
; to display the bitmap
;

start
		sei

; Jr Vicky can't see above this
		jsr init320x240

		jsr TermInit

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

PICNUM = 0   ; fireplace picture

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

; Going to image at $01/0000
; Going to put palette at $03/0000 

		sei

		jsr InitSpriteFont


		stz io_ctrl
		stz xpos
		stz xpos+1
		stz ping

		stz frame_number

]wait 
		jsr WaitVBL

		dec <ping		; 10 FPS update
		bpl ]wait

		lda #6
		sta <ping

		lda frame_number
		inc 
		cmp #10
		bcc :ok

		lda #0

:ok
		sta frame_number

		asl
		tax
		lda |:vregister,x
		sta |VKY_TM0_POS_Y_L

		lda |:vregister+1,x
		sta |VKY_TM0_POS_Y_H

		bra ]wait

:vregister
		dw  16+{240*0}
		dw  16+{240*1}
		dw  16+{240*2}
		dw  16+{240*3}
		dw  16+{240*4}
		dw  16+{240*5}
		dw  16+{240*6}
		dw  16+{240*7}
		dw  16+{240*8}
		dw  16+{240*9}


WaitVBL
LINE_NO = 241*2
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
:pic_table_m
		db >pic1
:pic_table_h
		db ^pic1

init320x240
		php
		sei

		; Access to vicky generate registers
		stz io_ctrl

		; enable the graphics mode
;;		lda #%00001111	; gamma + bitmap + graphics + overlay + text
;		lda #%00000001	; text
		lda #%01111111
		sta $D000
		;lda #%110       ; text in 40 column when it's enabled
		;sta $D001
		stz $D001

		; layer stuff - take from Jr manual
		lda #$54
		sta $D002  ; tile map layers
		lda #$06
		sta $D003  ; tile map layers

		; Tile Map 0
;		lda #$11  ; 8x8 + enabled
		lda #$01  ; enabled
		sta $D200 ; tile size

		lda #<MAP_DATA0
		sta $D201
		lda #>MAP_DATA0
		sta $D202
		lda #^MAP_DATA0
		sta $D203

		lda #{320+32}/16			; pixels into tiles
		sta $D204  ; map size X
		stz $D205  ; reserved

		lda #2432/16
		sta $D206  ; map size y
		stz $D207  ; reserved
		stz $D208  ; scroll x lo
		stz $D209  ; scroll x hi
		stz $D20A  ; scroll y lo
		stz $D20B  ; scroll y hi

		; Tile Map 1
		;lda #$11
		stz $D20C ; disabled

;		lda #<MAP_DATA1
;		sta $D20D
;		lda #>MAP_DATA1
;		sta $D20E
;		lda #^MAP_DATA1
;		sta $D20F

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


