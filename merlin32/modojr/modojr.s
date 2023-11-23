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

line_color ds 1
line_x0 ds 2
line_y0 ds 1
line_x1 ds 2
line_y1 ds 1

xpos ds 2
ping ds 2

frame_number ds 1

jiffy ds 1		; 60hz jiffy timer

; mixer - variables

; mod player - variables
mod_start ds 3
mod_sig   ds 4   ; M.K. most common

mod_num_tracks   ds 1  ; expects 4
mod_pattern_size ds 2  ; expects 1024 (for 4 tracks)
mod_row_size     ds 1  ; expects 4*4
mod_bpm          ds 1  ; expects 125
mod_speed        ds 1  ; default speed is 6

mod_num_instruments ds 1 ; expected 31

mod_song_length       ds 1     ; length in patterns
mod_p_current_pattern ds 3     ; pointer to the current pattern
mod_p_pattern_dir     ds 3	   ; pointer to directory of patterns (local ptr, and mmu block number)
mod_current_row       ds 1     ; current row #
mod_pattern_index     ds 1     ; current index into pattern directory
mod_num_patterns      ds 1     ; total number of patterns
mod_jiffy             ds 1     ; mod player jiffy

mod_temp0			ds 4
mod_temp1           ds 4
mod_temp2			ds 4
mod_temp3			ds 4
mod_temp4			ds 4
mod_temp5			ds 4


SongIsPlaying ds 1 ; flag for if a song is playing

	dend

; Jiffy Alias
dpJiffy = jiffy

PIXEL_DATA = $010000

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
;		jsr init320x240_fireplace
		jsr mmu_unlock

		jsr init320x240_bitmap

		jsr initColors

		jsr TermInit


		lda #<txt_modo
		ldx #>txt_modo
		jsr TermPUTS

		ldx #68
		ldy #0
		jsr TermSetXY

		ldax #txt_sampler
		jsr TermPUTS

;------------------------------------------------------------------------------
; bitmap demo
;
		lda #2  	; Fill Color
		jsr DmaClear

;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;
; Setup a Jiffy Timer, using Kernel Jump Table
; Trying to be friendly, in case we can friendly exit
;

		;jsr InstallJiffy		; SOF timer
		;jsr InstallModJiffy     ; 50hz timer
		;jsr InstallMixerJiffy   ; 16k mixer

		; hey needs to start on an 8k boundary
		ldaxy #mod_song
		jsr ModInit

]main_loop
		jsr WaitVBL

		jmp ]main_loop



;----------------------------------------------------------------------------
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


WaitVBL_poll
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

;------------------------------------------------------------------------------
init320x240_bitmap
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
		sta VKY_BM0_CTRL  ; enable
		stz VKY_BM1_CTRL  ; disable
		stz $D110  ; disable

		; set address of image, since image uncompressed, we just display it
		; where we loaded it.
		lda #<PIXEL_DATA
		sta VKY_BM0_ADDR_L
		lda #>PIXEL_DATA
		sta VKY_BM0_ADDR_M
		lda #^PIXEL_DATA
		sta VKY_BM0_ADDR_H

		lda #2
		sta io_ctrl
		plp

		rts

;------------------------------------------------------------------------------

init320x240_fireplace
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
txt_modo asc 'ModoJr'
		db 13,0

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

txt_unsupported asc 'ERROR Unsupported Mod Type = '
		db 0

txt_instruments asc ' Instruments'
		db 13,0

txt_tracks asc ' Tracks'
		db 13,0

txt_song_length cstr 'Length:'
txt_patterns cstr 'Patterns:'
txt_sampler cstr 'Mixer:16khz'
txt_L cstr ' L'


;------------------------------------------------------------------------------
;
; A = Fill Color
;
; Clear 320x240 buffer PIXEL_DATA with A
;
DmaClear
		php
		sei

		ldy io_ctrl
		phy

		stz io_ctrl

		ldx #DMA_CTRL_ENABLE+DMA_CTRL_FILL
		stx |DMA_CTRL

		sta |DMA_FILL_VAL

		lda #<PIXEL_DATA
		sta |DMA_DST_ADDR
		lda #>PIXEL_DATA
		sta |DMA_DST_ADDR+1
		lda #^PIXEL_DATA
		sta |DMA_DST_ADDR+2

]size = {320*240}

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
;
; no real regard given to performance, just make it work
;
plot_line_8x8y

:x0 = temp0
:y0 = temp0+1
:x1 = temp1
:y1 = temp1+1
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

		do 0
; plot a pixel at :x0,:y0, with line_color
; with no regards to efficiency
:plot
		ldx <:y0
		clc
		lda |:block_low_320,x   ; low byte of address in our mapped block
		adc <:x0
		sta |:p+1				; modify the store code, with abs address

		lda |:block_hi_320,x
		adc #0  				; Or adc x0+1 for 16-bit

		ldy |:block_num,x
		cmp #>{WRITE_BLOCK+$2000}
		bcc :good_to_go

		iny

		lda #>WRITE_BLOCK

:good_to_go
		sty <mmu5
		sta |:p+2
		lda line_color
:p		sta |WRITE_BLOCK

		rts
		fin

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


