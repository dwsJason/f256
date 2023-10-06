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


temp0 = $D0
temp1 = $D4
temp2 = $D8
temp3 = $DC

VKY_GR_CLUT_0 = $D000

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
		sei

; We're going to load compressed picture data at $04/0000, since currently
; Jr Vicky can't see above this
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






; Going to image at $01/0000
; Going to put palette at $03/0000 


		sei

		stz io_ctrl
		stz xpos
		stz xpos+1
		stz ping

]wait 
		jsr WaitVBL

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
;-----------------------

		lda ping
		beq :inc

		; else dec
		dec <xpos

		lda <xpos
		cmp #$FF
		bne ]wait

		stz <xpos
		stz <ping


		bra ]wait
:inc


		inc <xpos
		;bne ]continue
		;inc <xpos+1

		lda <xpos
		cmp #512-320-16
		bcc ]wait

		inc ping

		bra ]wait

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
; 176 pixels is the range, so center is 88 pixels


	dum *

floor_x0 ds 240
floor_x1 ds 240
floor_x2 ds 240
floor_x3 ds 240

bg_x0 ds 240
bg_x1 ds 240
bg_x2 ds 240
bg_x3 ds 240

	dend

