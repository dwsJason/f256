; fnXmas demo
; by two guys
; december 2023
		mx %11
; ifdef for debug vs release
; set to 1 for final release!
RELEASE = 1

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
;mixer_voices ds sizeof_osc*VOICES

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

;------------------------------------------------------------------------------
;
; SNOW STUFF
;
; SNOWMAP SIZE = 62*78*2 = 9672, $25C8 bytes, we need 2 of these
; SNOWTILES 14*256 = 3584, $E00 bytes

SNOWMAP_SIZE_X = 992
SNOWMAP_SIZE_Y = 1248

SNOWMAP_CLUT = 0 ; Needs to be on fireplace clut to work around bug

MAP_SNOWBG = $70000
MAP_SNOWFG = $72800
TILE_SNOW  = $76000

SNOW_TILE_OFFSET = 1792  ; 7*256

SNOW_BG_VX = $40  ; 0.25
SNOW_BG_VY = $80  ; 0.5

SNOW_FG_VX = $60  ; 0.37
SNOW_FG_VY = $C0  ; 0.75


;
; END SNOW STUFF
;
;------------------------------------------------------------------------------
;
; FIREPLACE STUFF
;
MAP_DATA0  = $010000
TILE_DATA0 = $012000 

;------------------------------------------------------------------------------
;
; PUMP BAR STUFF
;
PUMPBAR_SPRITE0 = $6F800  ; sprite 0, and sprite 1 for pump bars
PUMPBAR_SPRITE1 = $6FC00  ; sprite 0, and sprite 1 for pump bars
PUMPBAR_SPRITE_NO = 20    ; sprite 20, and sprite 21
PUMPBAR_CLUT = VKY_GR_CLUT_2
PUMPBAR_XPOS = 145
PUMPBAR_YPOS = 42
PUMPBAR_SPRITE_CTRL = %00000101      ; LUT#2
;
; END PUMP BAR STUFF
;
;------------------------------------------------------------------------------


; tiles are 16k for 256 in 8x8 mode
TILE_SIZE = {16*16*256}
TILE_DATA1 = $22000 ;TILE_DATA0+TILE_SIZE
TILE_DATA2 = $32000 ;TILE_DATA1+TILE_SIZE
TILE_DATA3 = $42000 ;TILE_DATA2+TILE_SIZE
TILE_DATA4 = TILE_DATA3+TILE_SIZE
TILE_DATA5 = TILE_DATA4+TILE_SIZE
TILE_DATA6 = TILE_DATA5+TILE_SIZE
TILE_DATA7 = TILE_SNOW

CLUT_DATA  = $005C00
PIXEL_DATA = $010000            ; @dwsJason - I may need to move this if you want to unpack at launch as you use it too

;
; This will copy the color table into memory, then set the video registers
; to display the bitmap
;

start
		php
		sei

		jsr initColors

		jsr init320x240

		jsr TermInit

		jsr mmu_unlock


		plp

		lda #2
		sta io_ctrl

		ldax #txt_frisbee
		jsr TermPUTS

;;-----------------------------------------------------------------------------
;;
;;  MAIN LOOP HERE ------------------------------------------------------------
;;

]main_loop
		jsr WaitVBL

		bra ]main_loop

;;
;;  MAIN LOOP HERE ------------------------------------------------------------
;;
;;-----------------------------------------------------------------------------

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

;
;------------------------------------------------------------------------------
;

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

;------------------------------------------------------------------------------
;
;
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
		lda #$56
		sta VKY_LAYER_CTRL_0  ; tile map layers
		lda #$04
		sta VKY_LAYER_CTRL_1  ; tile map layers

		; Tile Map 0  - Court
		lda #$01  ; enabled + 16x16
		sta VKY_TM0_CTRL ; tile size

		ldaxy #MAP_DATA0
		staxy VKY_TM0_ADDR_L

		lda #{320+32}/16	  ; pixels into tiles
		sta VKY_TM0_SIZE_X    ; map size X
		stz VKY_TM0_SIZE_X+1  ; reserved

		lda #272/16
		sta VKY_TM0_SIZE_Y   ; map size y
		stz VKY_TM0_SIZE_Y+1 ; reserved
		lda #16
		sta VKY_TM0_POS_X_L  ; scroll x lo
		stz VKY_TM0_POS_X_H  ; scroll x hi
		sta VKY_TM0_POS_Y_L  ; scroll y lo
		stz VKY_TM0_POS_Y_H  ; scroll y hi

		; Tile Map 1
		; Snow Background
		lda #$01  ; enabled + 16x16
		lda #0
		sta VKY_TM1_CTRL

		ldaxy #MAP_SNOWBG
		staxy VKY_TM1_ADDR_L

		lda #SNOWMAP_SIZE_X/16
		sta VKY_TM1_SIZE_X
		stz VKY_TM1_SIZE_X+1

		lda #SNOWMAP_SIZE_Y/16
		sta VKY_TM1_SIZE_Y
		stz VKY_TM1_SIZE_Y+1

		stz VKY_TM1_POS_X_L  ; scroll x lo
		stz VKY_TM1_POS_X_H  ; scroll x hi

		ldax #0+SNOWMAP_SIZE_Y-240			; 32 - 32
		stax VKY_TM1_POS_Y_L  ; scroll y

		; tile map 2
		; Snow ForeGround
		lda #$01  ; enabled + 16x16
		lda #0
		sta VKY_TM2_CTRL

		ldaxy #MAP_SNOWFG
		staxy VKY_TM2_ADDR_L

		lda #SNOWMAP_SIZE_X/16
		sta VKY_TM2_SIZE_X
		stz VKY_TM2_SIZE_X+1

		lda #SNOWMAP_SIZE_Y/16
		sta VKY_TM2_SIZE_Y
		stz VKY_TM2_SIZE_Y+1

		ldax #0+SNOWMAP_SIZE_Y-240		; 32 - 32 
		stz VKY_TM2_POS_X_L  ; scroll x lo
		stz VKY_TM2_POS_X_H  ; scroll x hi
		stax VKY_TM2_POS_Y_L ; scroll y

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

		; snow tiles NOTE, I'm only depending on TS7, but since I'm hogging
		; all the BG planes, it probably doesn't matter
		ldaxy #TILE_SNOW
		staxy VKY_TS4_ADDR_L
		staxy VKY_TS5_ADDR_L
		staxy VKY_TS6_ADDR_L
		staxy VKY_TS7_ADDR_L
		stz VKY_TS4_ADDR_H+1
		stz VKY_TS5_ADDR_H+1
		stz VKY_TS6_ADDR_H+1
		stz VKY_TS7_ADDR_H+1

;------------------------------------------------------------------------------
;
; Let's get our Arena displayed
;

; Get the LUT Data

		ldaxy #CLUT_DATA
		jsr set_write_address
		ldaxy #img_court
		jsr set_read_address

		jsr decompress_clut

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

		stz io_ctrl

; Get the Map

		ldaxy #MAP_DATA0
		jsr set_write_address
		ldaxy #img_court
		jsr set_read_address

		jsr decompress_map

; Get the Tiles

		ldaxy #TILE_DATA0
		jsr set_write_address
		ldaxy #img_court
		jsr set_read_address

		jsr decompress_pixels

		lda #2 			; back to text mapping
		sta io_ctrl
		plp

		rts

;------------------------------------------------------------------------------

txt_frisbee asc 'frisbee 0.1',0D,00

;------------------------------------------------------------------------------

