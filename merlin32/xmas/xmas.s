; fnXmas demo
; by two guys
; december 2023
		mx %11
; ifdef for debug vs release
; set to 1 for final release!
RELEASE = 0

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

p_sprite_message ds 2

jiffy ds 2 ; IRQ counts this up every VBL, really doesn't need to be 2 bytes

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

SongIsPlaying ds 1 ; flag for if a song is playing

	dend

SPRITE_MAP   ds 120   ; 10x6x2 bytes (120 bytes), this can fit anywhere probably
; we are stomping on some stuff here
SPRITE_TILES = $60000 ; could be up to 64k worth, but will be less

MAP_DATA0  = $010000
TILE_DATA0 = $012000 
;
; PUMP BAR STUFF
;
PUMPBAR_SPRITE0 = $6F800  ; sprite 0, and sprite 1 for pump bars
PUMPBAR_SPRITE1 = $6FC00  ; sprite 0, and sprite 1 for pump bars
PUMPBAR_SPRITE_NO = 20    ; sprite 20, and sprite 21
PUMPBAR_CLUT = VKY_GR_CLUT_2
PUMPBAR_XPOS = 240
PUMPBAR_YPOS = 48
PUMPBAR_SPRITE_CTRL = %00000101      ; LUT#2
;
; END PUMP BAR STUFF
;


; tiles are 16k for 256 in 8x8 mode
TILE_SIZE = {16*16*256}
TILE_DATA1 = $22000 ;TILE_DATA0+TILE_SIZE
TILE_DATA2 = $32000 ;TILE_DATA1+TILE_SIZE
TILE_DATA3 = $42000 ;TILE_DATA2+TILE_SIZE
TILE_DATA4 = TILE_DATA3+TILE_SIZE
TILE_DATA5 = TILE_DATA4+TILE_SIZE
TILE_DATA6 = TILE_DATA5+TILE_SIZE
TILE_DATA7 = TILE_DATA6+TILE_SIZE
TILE_DATA8 = TILE_DATA7+TILE_SIZE

CLUT_DATA  = $005C00
PIXEL_DATA = $010000            ; @dwsJason - I may need to move this if you want to unpack at launch as you use it too

;
; This will copy the color table into memory, then set the video registers
; to display the bitmap
;

start
		sei

		; Test for minimum version of hardware
		jsr HasGoodHardware
		jsr TermInit
		jsr IntroScreen 	; <-- stubbing in my part here (db)

; Jr Vicky can't see above this
		jsr init320x240


		jsr TermInit
		jsr mmu_unlock

		_TermPuts txt_unlock



		lda #<CLUT_DATA
		ldx #>CLUT_DATA
		ldy #^CLUT_DATA
		jsr set_write_address

		_TermPuts txt_setaddr

PICNUM = 0   ; fireplace picture

		ldx #PICNUM ; picture #
		jsr set_pic_address

		_TermPuts txt_setpicaddr
		
		jsr get_read_address
		jsr TermPrintAXYH
		_TermCR

		jsr get_write_address
		jsr TermPrintAXYH
		_TermCR

		jsr decompress_clut
		bcc :good

		jsr TermPrintAI
		_TermCR

:good
		_TermPuts txt_decompress_clut
		
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

		_TermPuts txt_copy_clut
		
		lda #<TILE_DATA0
		ldx #>TILE_DATA0
		ldy #^TILE_DATA0
		jsr set_write_address

		ldx #PICNUM
		jsr set_pic_address

		; read + write address for pixels
		jsr get_read_address
		jsr TermPrintAXYH
		_TermCR

		jsr get_write_address
		jsr TermPrintAXYH
		_TermCR
		
		php
		sei

		jsr decompress_pixels

		plp

		_TermPuts txt_decompress
		
;-----------------------------------------------

		ldx #PICNUM ; picture #
		jsr set_pic_address

		lda #<MAP_DATA0
		ldx #>MAP_DATA0
		ldy #^MAP_DATA0
		jsr set_write_address

		jsr decompress_map

		_TermPuts txt_decompress_map
;-----------------------------------------------

; Going to image at $01/0000
; Going to put palette at $03/0000 

		sei

		jsr InitSpriteFont

		jsr initPumpBars  ; decompress the pump bars, and initialize the colors

		stz io_ctrl
		stz xpos
		stz xpos+1
		stz ping

		stz frame_number

		jsr MixerInit

		; hey needs to start on an 8k boundary
		lda io_ctrl
		pha

		ldaxy #mod_xmas
		jsr ModInit

		jsr InstallIRQ
		cli
		jsr ModPlay

		pla
		sta io_ctrl

;;
;;  MAIN LOOP HERE ------------------------------------------------------------
;;

]main_loop
		jsr WaitVBL

		jsr ShowSpriteFont

		jsr UpdateFirePlace

		jsr PumpBarRender

		bra ]main_loop

;;
;;  MAIN LOOP HERE ------------------------------------------------------------
;;

;------------------------------------------------------------------------------
UpdateFirePlace
		dec <ping		; 10 FPS update
		bpl :rts

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
:rts
		rts


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

;
; Wait for VBL by waitching counter that changes with VBL IRQ
;
WaitVBL
		pha
		lda <jiffy
]wait   cmp <jiffy
		beq ]wait
		pla
		rts

WaitVBLPassedPoll
	rts
		lda $1
		pha
		stz $1
* LINE_NO = 241*2
LINE_ALT = 100*2
        lda #<LINE_ALT
        ldx #>LINE_ALT
]wait
        cpx $D01B
        bcc ]wait
]wait
        cmp $D01A
        bcc ]wait
		pla 
		sta $1
        rts

WaitVBLPollAX
		ldy $1
		phy 
		stz $1
		bra :waitforlineAX


WaitVBLPoll
		lda $1
		pha
		stz $1
LINE_NO = 241*2
        lda #<LINE_NO
        ldx #>LINE_NO
:waitforlineAX		
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
		pla 
		sta $1
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
		lda #%01111111  ; everything is enabled
		sta VKY_MSTR_CTRL_0
		stz VKY_MSTR_CTRL_1

		; layer stuff - take from Jr manual
		lda #$54
		sta VKY_LAYER_CTRL_0  ; tile map layers
		lda #$06
		sta VKY_LAYER_CTRL_1  ; tile map layers

		; Tile Map 0
		lda #$01  ; enabled + 16x16
		sta VKY_TM0_CTRL ; tile size

		ldaxy #MAP_DATA0
		staxy VKY_TM0_ADDR_L

		lda #{320+32}/16	  ; pixels into tiles
		sta VKY_TM0_SIZE_X    ; map size X
		stz VKY_TM0_SIZE_X+1  ; reserved

		lda #2432/16
		sta VKY_TM0_SIZE_Y   ; map size y
		stz VKY_TM0_SIZE_Y+1 ; reserved
		stz VKY_TM0_POS_X_L  ; scroll x lo
		stz VKY_TM0_POS_X_H  ; scroll x hi
		stz VKY_TM0_POS_Y_L  ; scroll y lo
		stz VKY_TM0_POS_Y_H  ; scroll y hi

		; Tile Map 1
		stz VKY_TM1_CTRL ; disabled

		; tile map 2
		stz VKY_TM2_CTRL ; disable

		; bitmap disables
		stz VKY_BM0_CTRL  ; disable
		stz VKY_BM1_CTRL  ; disable
		stz VKY_BM2_CTRL  ; disable

		; tiles locations
		ldaxy #TILE_DATA0
		staxy VKY_TS0_ADDR_L
		stz VKY_TS0_ADDR_H+1

		ldaxy #TILE_DATA1
		staxy VKY_TS1_ADDR_L
		stz VKY_TS1_ADDR_H+1

		ldaxy #TILE_DATA2
		staxy VKY_TS2_ADDR_L
		stz VKY_TS2_ADDR_H+1

		ldaxy #TILE_DATA3
		staxy VKY_TS3_ADDR_L
		stz VKY_TS3_ADDR_H+1

		lda #2 			; back to text mapping
		sta io_ctrl
		plp

		rts

;------------------------------------------------------------------------------


initPumpBars

		; Decompress the tile data
		ldaxy #PUMPBAR_SPRITE0
		jsr set_write_address

		ldaxy #pump_bar_sprites
		jsr set_read_address

		jsr decompress_pixels

		php
		sei

		lda io_ctrl
		pha

		stz io_ctrl

		lda #PUMPBAR_SPRITE_CTRL
		sta VKY_SP0_CTRL+{8*PUMPBAR_SPRITE_NO}	; vu 1-2, right
		sta VKY_SP1_CTRL+{8*PUMPBAR_SPRITE_NO}	; vu 3-4, right

		ldaxy #PUMPBAR_SPRITE0
		staxy VKY_SP0_AD_L+{8*PUMPBAR_SPRITE_NO}

		;ldax #PUMPBAR_XPOS-24
		lda #<{PUMPBAR_XPOS-24}
		ldx #>{PUMPBAR_XPOS-24}
		stax VKY_SP0_POS_X_L+{8*PUMPBAR_SPRITE_NO}

		ldax #PUMPBAR_YPOS
		stax VKY_SP0_POS_Y_L+{8*PUMPBAR_SPRITE_NO}
		stax VKY_SP1_POS_Y_L+{8*PUMPBAR_SPRITE_NO}

		ldaxy #PUMPBAR_SPRITE1
		staxy VKY_SP1_AD_L+{8*PUMPBAR_SPRITE_NO}

		ldax #PUMPBAR_XPOS
		stax VKY_SP1_POS_X_L+{8*PUMPBAR_SPRITE_NO}

		; initialize some of those LUT Colors

		lda #1
		sta io_ctrl

		; verify the backdrop color
		ldaxy #0
		staxy PUMPBAR_CLUT+{16*4}

		ldx #{15*4}-1       ; 15 colors
]lp		lda vu_colors_off,x
		sta PUMPBAR_CLUT+{1*4},x		
		sta PUMPBAR_CLUT+{17*4},x		
		sta PUMPBAR_CLUT+{33*4},x		
		sta PUMPBAR_CLUT+{49*4},x

		lda vu_colors_peak,x
		sta PUMPBAR_CLUT+{65*4},x		
		sta PUMPBAR_CLUT+{81*4},x		
		sta PUMPBAR_CLUT+{97*4},x		
		sta PUMPBAR_CLUT+{113*4},x

		dex
		bpl ]lp

		pla
		sta io_ctrl
		plp

		rts

;------------------------------------------------------------------------------

PumpBarRender mx %11

:levels = temp0
:max_lit = temp1

		php
		sei
		; grab samples
		lda |mod_pump_vol+{4*1}
		stz |mod_pump_vol+{4*1}
		sta <:levels+0
		lda |mod_pump_vol+{4*2}
		stz |mod_pump_vol+{4*2}
		sta <:levels+1
		lda |mod_pump_vol+{4*3}
		stz |mod_pump_vol+{4*3}
		sta <:levels+2
		lda |mod_pump_vol+{4*4}
		stz |mod_pump_vol+{4*4}
		sta <:levels+3
		plp

]ct = 0
		lup 4
		lda <:levels+]ct 			; no value
		beq :no_new_value

		; here would be a good place to scale + clamp, if we want that
		lsr  ; this will make them move 2x speed (1/2 second to empty the bar)

		cmp |pump_bar_levels+]ct	; new value is less than what we have, so ignore
		bcc :no_new_value

		sta |pump_bar_levels+]ct    ; new level, since it's >=
		cmp |pump_bar_peaks+]ct     ; check to see if it's a new peak
		bcc :no_new_value

		sta |pump_bar_peaks+]ct		; set new peak
		lda #20	; hang time for new peak  (1/3) of a second
		sta |pump_bar_peak_timer+]ct

:no_new_value

		lda |pump_bar_peak_timer+]ct
		beq :skip_peak_timer
		dec
		sta |pump_bar_peak_timer+]ct
		bne :skip_peak_timer
		stz |pump_bar_peaks+]ct
:skip_peak_timer
		lda |pump_bar_levels+]ct
		beq :skip_level
		dec
		sta |pump_bar_levels+]ct
:skip_level
]ct = ]ct+1
		--^

		lda io_ctrl
		pha

		lda #1			; page in the palettes
		sta io_ctrl

	    do 1
; render the colors
]ct = 0
		lup 4

		lda |pump_bar_levels+]ct
		lsr
		cmp #15
		bcc :no_clamp
		lda #15
:no_clamp

		ldx #0

		asl
		asl
		sta :max_lit
		beq :colors_off
:colors_on
		lda |vu_colors_on,x
		sta PUMPBAR_CLUT+{1*4}+{]ct*64},x
		inx
		cpx :max_lit
		bcc :colors_on
		bra :check_end
:colors_off
		lda |vu_colors_off,x
		sta PUMPBAR_CLUT+{1*4}+{]ct*64},x
		inx
:check_end
		cpx #15*4
		bcc :colors_off
:done
]ct = ]ct+1
		--^
		fin

; Render the Peak Meters
		do 1

]ct = 0
		lup 4

		lda pump_bar_last_peak+]ct
		cmp pump_bar_peaks+]ct
		beq :next_peak				; no change, leave alone

		; erase old peak
		and #%11111110
		cmp #30
		bcc :eok
		lda #30
:eok
		asl
		tax

		lda #$08
		sta PUMPBAR_CLUT+$100+{]ct*64}+0,x
		sta PUMPBAR_CLUT+$100+{]ct*64}+1,x
		sta PUMPBAR_CLUT+$100+{]ct*64}+2,x

		; draw new peak
		lda pump_bar_peaks+]ct
		sta pump_bar_last_peak+]ct


		and #%11111110
		cmp #30
		bcc :drawok
		lda #30
:drawok

		asl
		tax

		lda #$FF
		sta PUMPBAR_CLUT+$100+{]ct*64}+0,x
		sta PUMPBAR_CLUT+$100+{]ct*64}+1,x
		sta PUMPBAR_CLUT+$100+{]ct*64}+2,x
:next_peak
]ct = ]ct+1
		--^

		fin

		pla
		sta io_ctrl

		rts

;------------------------------------------------------------------------------
; Pump Bar colors
vu_colors_off
	adrl $ff0B0000
	adrl $ff0B0100
	adrl $ff0B0200
	adrl $ff0C0300
	adrl $ff0C0400
	adrl $ff0C0500
	adrl $ff0D0600
	adrl $ff0D0800
	adrl $ff0D0900
	adrl $ff0E0A00
	adrl $ff0E0B00
	adrl $ff0E0C00
	adrl $ff0F0D00
	adrl $ff0F0E00
	adrl $ff0F0F00

vu_colors_on
	adrl $ffB00202
	adrl $ffB61402
	adrl $ffBB2602
	adrl $ffC13802
	adrl $ffC74A01
	adrl $ffCC5C01
	adrl $ffD26E01
	adrl $ffD88001
	adrl $ffDD9301
	adrl $ffE3A501
	adrl $ffE8B701
	adrl $ffEEC900 
	adrl $ffF4DB00 
	adrl $ffF9ED00 
	adrl $ffFFFF00 

vu_colors_peak
	adrl $ff080808
	adrl $ff080808
	adrl $ff080808
	adrl $ff080808
	adrl $ff080808

	adrl $ff080808
	adrl $ff080808
	adrl $ff080808
	adrl $ff080808
	adrl $ff080808
			 
	adrl $ff080808
	adrl $ff080808
	adrl $ff080808
	adrl $ff080808
	adrl $ff080808

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

txt_unsupported asc 'unsuppored mod format'
		db 13,0

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

