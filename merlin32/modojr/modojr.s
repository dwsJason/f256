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

jiffy ds 2		; 60hz jiffy timer
;
; mixer - variables - I'm hogging up like 64 bytes here
; if need be, we could give mixer it's own DP (by using the mmu)
;
mixer_voices ds sizeof_osc*VOICES

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

mod_jiffy_rate        ds 2
mod_jiffy_countdown   ds 2
mod_jiffy             ds 2     ; mod player jiffy

mod_temp0			ds 4
mod_temp1           ds 4
mod_temp2			ds 4
mod_temp3			ds 4
mod_temp4			ds 4
mod_temp5			ds 4

irq_num ds 2


SongIsPlaying ds 1 ; flag for if a song is playing

	dend

; Jiffy Alias
dpJiffy = jiffy


;
; Let's do some memory management
;
; Frame Buffer at $01/0000 - 320x240 = 76,800, end address 02/2C00
;
; 2k gap at 02/2C00
; Pump Bars, 2 pump bar sprites.
;
; 44*33*2 = 3k 2,904 bytes
; Map Data for 8x8 tile-map, need 3k for the static screen
; $02/3400 -> $02/4000 - 3k
;
; $02/4000->$02/7FFF = 256 8x8 tiles
;
; $02/8000 -> $07/DFFF - space for songs 352,256 (max song size) $5/6000

PIXEL_DATA = $010000

PUMPBAR_SPRITE0 = $022C00
PUMPBAR_SPRITE1 = $023000

MAP_DATA0  = $023400
TILE_DATA0 = $024000

; tiles are 16k for 256 in 8x8 mode
TILE_SIZE = {8*8*256}
TILE_DATA1 = TILE_DATA0+TILE_SIZE
TILE_DATA2 = TILE_DATA1+TILE_SIZE
TILE_DATA3 = TILE_DATA2+TILE_SIZE
TILE_DATA4 = TILE_DATA3+TILE_SIZE
TILE_DATA5 = TILE_DATA4+TILE_SIZE
TILE_DATA6 = TILE_DATA5+TILE_SIZE
TILE_DATA7 = TILE_DATA6+TILE_SIZE
TILE_DATA8 = TILE_DATA7+TILE_SIZE

CLUT_DATA  = $006000

;
; This will copy the color table into memory, then set the video registers
; to display the bitmap
;

start
		sei

		jsr mmu_unlock

		jsr init320x240_video

		jsr initColors    	; copy GS colors over into the font LUT, and the LUT0 for the bitmap

		jsr initFont

		jsr initBackground
		jsr initPumpBars

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
		lda #2  	; Fill Color - opaque (easier debugging)
;		lda #0  	; Transparent
		jsr DmaClear

;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;
; Setup a Jiffy Timer, using Kernel Jump Table
; Trying to be friendly, in case we can friendly exit
;

		jsr MixerInit   ; init those OSCilattors

		; hey needs to start on an 8k boundary
		ldaxy #mod_song
		jsr ModInit

		; All in wonder interrupt
		; - SOF timer, for dpJiffy
		; - 50hz timer, for the Mod Sequencer
		; - 16Khz timer, for the PCM player
		jsr InstallIRQ

		cli
		jsr ModPlay		;; Are you Crazy ?#@!


TEST_VOICE equ VOICE3 ; all 4 voices work

		do 0

:pInst = temp0

		lda #1
		asl
		tax
		lda |inst_address_table,x
		sta <:pInst
		lda |inst_address_table+1,x
		sta <:pInst+1

		stz TEST_VOICE+osc_pWave
		ldy #i_sample_start_badr
		lda (:pInst),y
		sta TEST_VOICE+osc_pWave+1
		iny
		lda (:pInst),y
		sta TEST_VOICE+osc_pWave+2
		iny
		lda (:pInst),y
		sta TEST_VOICE+osc_pWave+3

;		ldax #$100
; 8363.42*256/16000
;
		ldax #134
		stax TEST_VOICE+osc_frequency

		ldy #i_sample_loop_bend
		lda (:pInst),y
		sta TEST_VOICE+osc_pWaveEnd
		iny
		lda (:pInst),y
		sta TEST_VOICE+osc_pWaveEnd+1
		iny
		lda (:pInst),y
		sta TEST_VOICE+osc_pWaveEnd+2

;		; tell the oscillator to go!
;		lda #os_playing_singleshot
;		sta VOICE0+osc_state
		fin

		do 0
		; This actually works, and sounds ok
seadragon_test

:pInst     = temp0
:pStart    = temp1
:iLength   = temp2

		ldaxy #sfx_waves_start
		jsr set_read_address
		ldaxy #sfx_waves_start
		jsr set_write_address

		ldaxy #sfx_waves_end-sfx_waves_start
		sta <:iLength

		ldx <:iLength
		ldy <:iLength+1

]mloop
		jsr readbyte
		eor #$FF
		lsr
		lsr
		lsr
		lsr
		jsr writebyte

		dex
		bne ]mloop

		dey
		bpl ]mloop

		ldaxy #sfx_waves_start
		jsr set_read_address

		; start of wave to play
		ldax pSource
		stax TEST_VOICE+osc_pWave+1
		lda READ_MMU
		sta TEST_VOICE+osc_pWave+3

		ldaxy #sfx_waves_end
		jsr set_read_address

		; end of wave to play
		ldax pSource
		stac TEST_VOICE+osc_pWaveEnd
		lda READ_MMU
		sta TEST_VOICE+osc_pWaveEnd+2

		;ldax #{11025*256/16000}		 ; why not try for 11khz
		ldax #176		 ; why not try for 11khz
		stax TEST_VOICE+osc_frequency

;		lda #os_playing_singleshot
;		sta TEST_VOICE+osc_state

		fin


		do 0
; before we single shot
; print some debug info


		ldaxy TEST_VOICE+osc_pWave+1
		stax pSource
		sty  READ_MMU

		jsr TermPrintAXYH
		lda #' '
		jsr TermCOUT

		ldaxy TEST_VOICE+osc_pWaveEnd
		stax pDest
		sty WRITE_MMU

		jsr TermPrintAXYH
		jsr TermCR

		jsr get_read_address
		jsr TermPrintAXYH
		lda #' '
		jsr TermCOUT

		jsr get_write_address
		jsr TermPrintAXYH
		jsr TermCR

		ldax TEST_VOICE+osc_frequency
		jsr TermPrintAXH
		jsr TermCR


; before we single shot
; lets print some stuff out, for my own sanity

		lda #os_playing_singleshot
		sta TEST_VOICE+osc_state
		fin

		ldax #:txt
		jsr TermPUTS

		jmp forward

:txt    db $C0,$C1,$C2,$C3,$C4,$C5,$C6,$C7,$C8,$C9,$CA,$CB,$CC,$CD,$CE,$CF,
		db $D0,$D1,$D2,$D3,$D4,$D5,$D6,$D7,$D8,$D9,$DA,$DB,$DC,$DD,$DE,$DF,13
		db $E0,$E1,$E2,$E3,$E4,$E5,$E6,$E7,$E8,$E9,$EA,$EB,$EC,$ED,$EE,$EF,
		db $F0,$F1,$F2,$F3,$F4,$F5,$F6,$F7,$F8,$F9,$FA,$FB,$FC,$FD,$FE,$FF,13
		db 0

forward


]main_loop
		jsr WaitVBL

		;JSR SCNKEY      ;SCAN KEYBOARD
        ;JSR GETIN       ;GET CHARACTER
		;CMP #0          ;IS IT NULL?
        ;BEQ :no_key
		;jsr TermCOUT
  
:no_key
		jsr UpdateMarker

		jsr PatternRender

		do 1
		ldx #63
		ldy #25
		jsr TermSetXY

		ldax jiffy
		jsr TermPrintAXH

		lda #' '
		jsr TermCOUT

		ldax mod_jiffy
		jsr TermPrintAXH
		fin

		ldx #0
		ldy #25
		jsr TermSetXY

		lda mod_pattern_index
		jsr TermPrintAI
		jsr TermCR

		lda mod_current_row
		jsr TermPrintAI
		lda #' '
		jsr TermCOUT

		jmp ]main_loop

PatternRender
		rts

UpdateMarker

:pColor = temp0
:color = temp1

		ldx |:current
	    cpx <mod_pattern_index
		bne :update
		rts
:update
		lda #3
		sta io_ctrl		; color matrix

		; block # in x

		;lda #$F2		; white on, blue for erase
		lda #$F0		; white on transparent
		sta <:color

		jsr :draw_color

		ldx <mod_pattern_index
		stx |:current

		lda #$F1        ; white on red
		sta <:color

		jsr :draw_color

		lda #2
		sta <io_ctrl	; text matrix
		rts


:draw_color
		lda :table_l,x
		sta :pColor
		lda :table_h,x
		sta :pColor+1

		ldy #3
		lda <:color
]lp		sta (:pColor),y
		dey
		bpl ]lp

		rts

]base = $C000+{19*80}

:table_l
]ct = 0
		lup 26
		db <{]base+{]ct*3}}
]ct = ]ct+1
		--^
]base = ]base+80
]ct = 0
		lup 26
		db <{]base+{]ct*3}}
]ct = ]ct+1
		--^
]base = ]base+80
]ct = 0
		lup 26
		db <{]base+{]ct*3}}
]ct = ]ct+1
		--^
]base = ]base+80
]ct = 0
		lup 26
		db <{]base+{]ct*3}}
]ct = ]ct+1
		--^


]base = $C000+{19*80}
:table_h
]ct = 0
		lup 26
		db >{]base+{]ct*3}}
]ct = ]ct+1
		--^
]base = ]base+80
]ct = 0
		lup 26
		db >{]base+{]ct*3}}
]ct = ]ct+1
		--^
]base = ]base+80
]ct = 0
		lup 26
		db >{]base+{]ct*3}}
]ct = ]ct+1
		--^
]base = ]base+80
]ct = 0
		lup 26
		db >{]base+{]ct*3}}
]ct = ]ct+1
		--^

:current db $7f


;----------------------------------------------------------------------------
;
; Decompress the Background onto TileMap0
; use CLUT 1
;
initBackground

; Decompress the CLUT
		ldaxy #CLUT_DATA
		jsr set_write_address

		ldaxy #background
		jsr set_read_address

		jsr decompress_clut

; Copy CLUT into Color Memory
		php
		sei

		lda io_ctrl
		pha

		lda #1
		sta io_ctrl ; access LUT data

		; copy the clut up there
		ldx #0
]lp		lda WRITE_BLOCK,x
		sta VKY_GR_CLUT_3,x
		lda WRITE_BLOCK+$100,x
		sta VKY_GR_CLUT_3+$100,x
		lda WRITE_BLOCK+$200,x
		sta VKY_GR_CLUT_3+$200,x
		lda WRITE_BLOCK+$300,x
		sta VKY_GR_CLUT_3+$300,x
		dex
		bne ]lp

		pla
		sta io_ctrl
		plp

		; Decompress the tile data
		ldaxy #TILE_DATA0
		jsr set_write_address

		ldaxy #background
		jsr set_read_address

		jsr decompress_pixels

		; Decompress the map data
		lda #<MAP_DATA0
		ldx #>MAP_DATA0
		ldy #^MAP_DATA0
		jsr set_write_address

		ldaxy #background
		jsr set_read_address

		jsr decompress_map

		do 1
		; map is 44x34
		
		ldaxy #MAP_DATA0
		jsr set_read_address
		jsr get_read_address
		jsr set_write_address

		ldxy #1496 ;{44*34}
]loop
		jsr readbyte
		jsr writebyte

		jsr readbyte
		ora #{8*3}		; remap to palette index 3
		jsr writebyte

		dexy
		bne ]loop
		fin

		rts


initPumpBars

		; Decompress the tile data
		ldaxy #PUMPBAR_SPRITE0
		jsr set_write_address

		ldaxy #pump_bars
		jsr set_read_address

		jsr decompress_pixels

		php
		sei

		lda io_ctrl
		pha

		stz io_ctrl

		lda #%00000101
		sta VKY_SP0_CTRL
		sta VKY_SP1_CTRL

		ldaxy #PUMPBAR_SPRITE0
		staxy VKY_SP0_AD_L

		ldax #320-24
		stax VKY_SP0_POS_X_L
		ldax #240
		stax VKY_SP0_POS_Y_L

		ldaxy #PUMPBAR_SPRITE1
		staxy VKY_SP1_AD_L

		ldax #320
		stax VKY_SP1_POS_X_L
		ldax #240
		stax VKY_SP1_POS_Y_L

		pla
		sta io_ctrl
		plp

		rts

;------------------------------------------------------------------------------
init320x240_video
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
		;lda #6
		;lda #1 ; clock_70
		lda #0
		;lda #%10000   ; Font Overlay Mode - BG color can be on top
		sta VKY_MSTR_CTRL_1

		; layer stuff - take from Jr manual
		; 0,1, and 2 are bitmap layers
		; 4,5, and 6 are tilemap layers

		lda #$40		      ; bitmap0 on top of tilemap 0
		sta VKY_LAYER_CTRL_0
		lda #$05
		sta VKY_LAYER_CTRL_1  ; tile map layer 2

		; Tile Map Enable/Disable
		lda #$11
		sta VKY_TM0_CTRL  ; enable 8x8
		stz VKY_TM1_CTRL  ; disable
		stz VKY_TM2_CTRL  ; disable

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

		;
		; Initialize Tile Map 0
		;
		ldaxy #MAP_DATA0
		staxy VKY_TM0_ADDR_L

		ldax #44
		stax VKY_TM0_SIZE_X
		ldax #34
		stax VKY_TM0_SIZE_Y

		ldax #0
		stax VKY_TM0_POS_X_L
		ldax #32
		stax VKY_TM0_POS_Y_L

		;
		; Catalog Address
		;
		ldaxy #TILE_DATA0
		staxy VKY_TS0_ADDR_L
		staxy VKY_TS1_ADDR_L
		staxy VKY_TS2_ADDR_L
		staxy VKY_TS3_ADDR_L
		staxy VKY_TS4_ADDR_L
		staxy VKY_TS5_ADDR_L
		staxy VKY_TS6_ADDR_L
		staxy VKY_TS7_ADDR_L

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

txt_unsupported db 13
		asc 'ERROR Unsupported Mod Type = '
		db 0

txt_instruments asc ' Instruments'
		db 13,0

txt_tracks asc ' Tracks'
		db 13,0

txt_song_length cstr 'Length:'
txt_patterns cstr 'Patterns:'
txt_sampler cstr 'Mixer:16khz'
txt_L cstr ' L'

txt_massage_wave asc 'Massage the instruments'
		db 13,0


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


