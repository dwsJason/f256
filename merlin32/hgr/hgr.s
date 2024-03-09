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

DMA_CLEAR_ADDY = image_start
DMA_CLEAR_LEN  = $12000


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

		; fix the BG Color
		stz VKY_BKG_COL_B
		stz VKY_BKG_COL_G
		stz VKY_BKG_COL_R

; experiment people

;		jsr clear_bitmap
		lda #0
		jsr DmaClear


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

		lda #<image_start
		ldx #>image_start
		ldy #^image_start
		sta :write_address
		stx :write_address+1
		sty :write_address+2
		jsr set_write_address   ; mmu is going to map this to $6000

;------------------------------------------------------------------------------
		; DMA VERSION

		stz	io_ctrl

		stz |DMA_CTRL	; turn it off
		lda #DMA_CTRL_ENABLE
		sta |DMA_CTRL

		lda #7
		sta |DMA_COUNT
		stz |DMA_COUNT+1
		stz |DMA_COUNT+2



		lda mmu3
		inc
		sta mmu4 	; this guarantees we don't have to look for page wrap

		stz :y_pos
]lp
		lda :write_address
		ldx :write_address+1
		ldy :write_address+2
		sta |DMA_DST_ADDR
		stx |DMA_DST_ADDR+1
		sty |DMA_DST_ADDR+2

		ldx :y_pos
		lda scanline_table_lo,x
		sta :mod_load+1
		lda scanline_table_hi,x
		sta :mod_load+2

		ldx #0

:mod_load ldy $2000,x   			; the raw HGR data in A here

		lda pixelmap_addr_lo,y
		sta |DMA_SRC_ADDR
		lda pixelmap_addr_hi,y
		sta |DMA_SRC_ADDR+1
		;stz |DMA_SRC_ADDR+2

		;lda #7
		;sta |DMA_COUNT
		;stz |DMA_COUNT+1
		;stz |DMA_COUNT+2

		lda #DMA_CTRL_ENABLE.DMA_CTRL_START
		sta |DMA_CTRL
		; assuming DMA Controller halts CPU

]wait   lda |DMA_STATUS
		bmi ]wait


;		stz |DMA_CTRL	; turn it off
		lda #DMA_CTRL_ENABLE
		sta |DMA_CTRL

		; I wish I didn't have to have this
		clc
		lda |DMA_DST_ADDR
		adc #7
		sta |DMA_DST_ADDR
		bcc :okkk
		inc |DMA_DST_ADDR+1


:okkk
		inx
		cpx #40
		bcc :mod_load

		jsr :inc_write_address

		lda :y_pos
		inc
		cmp #192
		sta :y_pos
		bccl ]lp

		jmp ]alter_loop
		jmp :wait

:inc_write_address
		clc
		lda <:write_address
		adc #<320
		sta <:write_address
		lda <:write_address+1
		adc #>320
		sta <:write_address+1
		bcc :rts
		inc <:write_address+2
:rts
		rts

;------------------------------------------------------------------------------
; CPU VERSION

;		lda mmu3
;		inc
;		sta mmu4 	; this guarantees we don't have to look for page wrap
;
;		stz :y_pos
;]lp
;		;lda :write_address
;		;ldx :write_address+1
;		;ldy :write_address+2
;		;jsr set_write_address
;
;		lda pDest
;		sta :write_address
;		lda pDest+1
;		sta :write_address+1
;		
;		;lda mmu3
;		;inc
;		;sta mmu4 	; this guarantees we don't have to look for page wrap
;
;		ldx :y_pos
;		lda scanline_table_lo,x
;		sta :mod_load+1
;		lda scanline_table_hi,x
;		sta :mod_load+2
;
;		ldx #0
;		ldy #0
;
;:mod_load lda $2000,x   			; the raw HGR data in A here
;		sta <:hgr_pix
;
;;		tay 					   	; this is an address look up, to look up the 7 pixel expansion
;;		lda pixelmap_addr_lo,y
;;		sta :mod_pix+1
;;		lda pixelmap_addr_hi,y
;;		sta :mod_pix+2
;
;;		; 7 byte blit, which potentially cloud be done via DMA
;;		ldy #6
;;:mod_pix lda $2000,y
;;:mod_sto sta $6000
;;
;;		inc :mod_sto+1
;;		bne :ok1
;;		inc :mod_sto+2
;;:ok1
;;		dey
;;		bpl :mod_pix
;
;
;		lup 7
;
;		lsr <:hgr_pix
;		lda #0
;		bcc :sk0
;		inc
;:sk0	sta (:write_address),y
;		iny
;		bne :sk1
;		inc :write_address+1
;:sk1
;		--^
;
;		inx
;		cpx #40
;		bcc :mod_load
;
;		jsr :inc_write_address
;
;		lda :y_pos
;		inc
;		cmp #192
;		sta :y_pos
;		bccl ]lp
;
;		jmp ]alter_loop
;		jmp :wait
;
;:inc_write_address
;		;clc
;		;lda <:write_address
;		;adc #<320
;		;sta <:write_address
;		;lda <:write_address+1
;		;adc #>320
;		;sta <:write_address+1
;		;lda #0
;		;adc <:write_address+2
;		;sta <:write_address+2
;
;		clc
;		lda <pDest
;		adc #<320
;		sta <pDest
;		lda <pDest+1
;		adc #>320
;		bpl :go_go
;		; c=0
;		;sec
;		;sbc #$20
;		sbc #$1F
;		inc mmu3
;		inc mmu4
;:go_go
;		sta <pDest+1
;		rts
;
;-----------------------------------------------------------------------------
;
; CPU 2
;

;		lda mmu3
;		inc
;		sta mmu4 	; this guarantees we don't have to look for page wrap
;
;		stz :y_pos
;]lp
;		;lda :write_address
;		;ldx :write_address+1
;		;ldy :write_address+2
;		;jsr set_write_address
;
;		lda pDest
;		sta :write_address
;		sta :mod_sto+1
;		lda pDest+1
;		sta :write_address+1
;		sta :mod_sto+2
;
;		ldx :y_pos
;		lda scanline_table_lo,x
;		sta :mod_load+1
;		lda scanline_table_hi,x
;		sta :mod_load+2
;
;		ldx #0
;
;:mod_load ldy $2000,x   			; the raw HGR data in A here
;		;sty <:hgr_pix
;
;		lda pixelmap_addr_lo,y
;		sta :mod_pix+1
;		lda pixelmap_addr_hi,y
;		sta :mod_pix+2
;
;;		; 7 byte blit, which potentially cloud be done via DMA
;		ldy #0
;:mod_pix lda $2000,y
;:mod_sto sta $6000,y
;		iny
;		cpy #7
;		bcc :mod_pix
;
;		lda :mod_sto+1
;		adc #6    		; c=1
;		sta :mod_sto+1
;		bcc :dd
;		inc :mod_sto+2
;:dd
;
;		inx
;		cpx #40
;		bcc :mod_load
;
;		jsr :inc_write_address
;
;		lda :y_pos
;		inc
;		cmp #192
;		sta :y_pos
;		bccl ]lp
;
;		jmp ]alter_loop
;		jmp :wait
;
;:inc_write_address
;		clc
;		lda <pDest
;		adc #<320
;		sta <pDest
;		lda <pDest+1
;		adc #>320
;		bpl :go_go
;		; c=0
;		sbc #$1F
;		inc mmu3
;		inc mmu4
;:go_go
;		sta <pDest+1
;
;		rts



; this stops the program from exiting back into DOS or SuperBASIC 
; so we can see
:wait   bra :wait  
		rts
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

