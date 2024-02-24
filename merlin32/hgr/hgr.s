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
	dend

VKY_GR_CLUT_0 = $D000

;
; This will copy the color table into memory, then set the video registers
; to display the bitmap
;

start
		jsr mmu_unlock

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

		; enable the graphics mode
		;lda #%01001110	; gamma + bitmap + graphics + overlay, text disabled
		lda #%00001100	; bitmap + graphics 
		sta $D000
		;lda #%110       ; text in 40 column when it's enabled
		;sta $D001
		stz $D001

		; layer stuff - take from Jr manual
		stz $D002  ; layer ctrl 0
		stz $D003  ; layer ctrl 3

image_start = $010000

		; set address of image, since image uncompressed, we just display it
		; where we loaded it.
		lda #<image_start
		sta $D101
		lda #>image_start
		sta $D102
		lda #^image_start
		sta $D103

		lda #1
		sta $D100  ; bitmap enable, use clut 0
		stz $D108  ; disable
		stz $D110  ; disable

; experiment people

		jsr clear_bitmap


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
		jsr set_read_address	; mmu is going to map this to $2000, woot

		lda #<image_start
		ldx #>image_start
		ldy #^image_start
		sta :write_address
		stx :write_address+1
		sty :write_address+2
		jsr set_write_address   ; mmu is going to map this to $6000

		lda mmu3
		inc
		sta mmu4 	; this guarantees we don't have to look for page wrap

:y_pos = temp3
:write_address = temp2

		stz :y_pos
]lp
		;lda :write_address
		;ldx :write_address+1
		;ldy :write_address+2
		;jsr set_write_address

		lda pDest
		sta :mod_sto+1
		lda pDest+1
		sta :mod_sto+2
		
		;lda mmu3
		;inc
		;sta mmu4 	; this guarantees we don't have to look for page wrap

		ldx :y_pos
		lda scanline_table_lo,x
		sta :mod_load+1
		lda scanline_table_hi,x
		sta :mod_load+2

		ldx #0

:mod_load lda $2000,x   			; the raw HGR data in A here

		tay 					   	; this is an address look up, to look up the 7 pixel expansion
		lda pixelmap_addr_lo,y
		sta :mod_pix+1
		lda pixelmap_addr_hi,y
		sta :mod_pix+2

		; 7 byte blit, which potentially cloud be done via DMA
		ldy #6
:mod_pix lda $2000,y
:mod_sto sta $6000

		inc :mod_sto+1
		bne :ok1
		inc :mod_sto+2
:ok1
		dey
		bpl :mod_pix

		inx
		cpx #40
		bcc :mod_load

		jsr :inc_write_address

		lda :y_pos
		inc
		cmp #192
		sta :y_pos
		bcc ]lp

		jmp ]alter_loop
		jmp :wait

:inc_write_address
		;clc
		;lda <:write_address
		;adc #<320
		;sta <:write_address
		;lda <:write_address+1
		;adc #>320
		;sta <:write_address+1
		;lda #0
		;adc <:write_address+2
		;sta <:write_address+2

		clc
		lda <pDest
		adc #<320
		sta <pDest
		lda <pDest+1
		adc #>320
		bpl :go_go
		; c=0
		;sec
		;sbc #$20
		sbc #$1F
		inc mmu3
		inc mmu4
:go_go
		sta <pDest+1
		rts




; this stops the program from exiting back into DOS or SuperBASIC 
; so we can see
:wait   bra :wait  
		rts
;-----------------------------------------------------------------------------
; take a byte, and crap out pixels that can be used (Bits to pixels)
byte2pix mac
;	do ]1&$80
;	db 1
;	else
;	db 0
;	fin
	do ]1&$40
	db 1
	else
	db 0
	fin
	do ]1&$20
	db 1
	else
	db 0
	fin
	do ]1&$10
	db 1
	else
	db 0
	fin
	do ]1&$08
	db 1
	else
	db 0
	fin
	do ]1&$04
	db 1
	else
	db 0
	fin
	do ]1&$02
	db 1
	else
	db 0
	fin
	do ]1&$01
	db 1
	else
	db 0
	fin
	<<<

; perhaps misnamed, but a table of 7 pixel entries
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
clear_bitmap
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

