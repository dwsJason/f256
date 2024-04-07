; pvp frisbee
; @dwsJason
; April F256 GameJam !!
		mx %11
; ifdef for debug vs release
; set to 1 for final release!
RELEASE = 1

; System Bus Pointer's
;pSource  equ $10
;pDest    equ pSource+4
; Do not use anything below $20, the mmu module owns it

SNES_A       = %0000_1000_0000_0000
SNES_X       = %0000_0100_0000_0000
SNES_L       = %0000_0010_0000_0000
SNES_R       = %0000_0001_0000_0000
SNES_B       = %0000_0000_1000_0000
SNES_Y       = %0000_0000_0100_0000
SNES_SELECT  = %0000_0000_0010_0000
SNES_START   = %0000_0000_0001_0000
SNES_UP      = %0000_0000_0000_1000
SNES_DOWN    = %0000_0000_0000_0100
SNES_LEFT    = %0000_0000_0000_0010
SNES_RIGHT   = %0000_0000_0000_0001

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

event_data ds 16

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

;
; Frisbee Physics
;
frisbee_x  ds 2
frisbee_y  ds 2
frisbee_vx ds 2
frisbee_vy ds 2

;
; Red Player Physics
;

p1_x ds 2
p1_y ds 2
p1_vx ds 2
p1_vy ds 2

;
; Blue Player Physics
;

p2_x ds 2
p2_y ds 2
p2_vx ds 2
p2_vy ds 2

p1_dpad_input_raw ds 2
p1_dpad_input_down ds 2
p1_dpad_input_up ds 2

p2_dpad_input_raw ds 2
p2_dpad_input_down ds 2
p2_dpad_input_up ds 2

	dend

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

		jsr init320x200

		jsr TermInit

		jsr mmu_unlock


		plp

		lda #2
		sta io_ctrl

		ldax #txt_frisbee
		jsr TermPUTS

;------------------------------------------------------------------------------
;
; Some Kernel Stuff here
;
		ldax #event_data
		stax kernel_args_events

; Initialize some state


		; Frisbee position, and velocity

		lda #128
		stz frisbee_x
		sta frisbee_x+1
		stz frisbee_y
		sta frisbee_y+1

		stz frisbee_vx
		stz frisbee_vx+1
		stz frisbee_vy
		stz frisbee_vy+1

		; Red Player 1 position, and velocity

		lda #128-64
		stz p1_x
		sta p1_x+1

		lda #128
		stz p1_y
		sta p1_y+1

		stz p1_vx
		stz p1_vx+1
		stz p1_vy
		stz p1_vy+1

		; Blue Player 2 position, and velocity

		lda #128+64
		stz p2_x
		sta p2_x+1

		lda #128
		stz p2_y
		sta p2_y+1

		stz p2_vx
		stz p2_vx+1
		stz p2_vy
		stz p2_vy+1


		ldax #$080
		stax p1_vx
		ldax #$180
		stax p1_vy

		ldax #$100
		stax p2_vx
		ldax #$100
		stax p2_vy

		ldax #$100
		stax frisbee_vx
		ldax #$080
		stax frisbee_vy



;;-----------------------------------------------------------------------------
;;
;;  MAIN LOOP HERE ------------------------------------------------------------
;;

]main_loop
		jsr kernel_NextEvent
		bcs :no_events
		jsr DoKernelEvent
:no_events
		;
		; Do Game Logic
		;
		jsr GameControls

		jsr FrisbeeLogic

		ldax #p1_bounds_table
		stax temp0

		ldx #p1_x
		jsr PlayerBounds

		ldax #p2_bounds_table
		stax temp0

		ldx #p2_x
		jsr PlayerBounds

		jsr MoveFrisbee

;------------------------------------------------------------------------------
		; We should let the SNES data come in, while we're waiting
		stz io_ctrl
		lda #%10000101
		sta $D880   		; NES_CTRL, trigger and read
		lda #2
		sta io_ctrl
;------------------------------------------------------------------------------

		inc <jiffy  ; since we don't have IRQ doing this
		jsr WaitVBLPoll

		jsr DrawSprites

		bra ]main_loop

;;
;;  MAIN LOOP HERE ------------------------------------------------------------
;;
;;-----------------------------------------------------------------------------
;
;
GameControls

		stz io_ctrl

:prev_input = temp0
:latch_input = temp0+2
:inv_input = temp1

		ldax p1_dpad_input_raw
		stax :prev_input

		ldax $D884
		stax :inv_input
		eor #$FF
		sta p1_dpad_input_raw
		eor :prev_input
		sta :latch_input

		txa
		eor #$FF
		sta p1_dpad_input_raw+1
		eor :prev_input+1
		sta :latch_input+1

; if latch_input is set, and the button is set, then it just went down

		lda :latch_input
		and p1_dpad_input_raw
		sta p1_dpad_input_down

		lda :latch_input+1
		and p1_dpad_input_raw+1
		sta p1_dpad_input_down+1

; if latch input is set, and the button is clear, then it just came up

		lda :latch_input
		and :inv_input
		sta p1_dpad_input_up
		lda :latch_input+1
		and :inv_input+1
		sta p1_dpad_input_up+1


;------------------------------------------------------------------------------
; hack code to test the button up/ button down

		do 0
		ldy #2
		sty io_ctrl

		lda p1_dpad_input_down+1
		and #>SNES_A
		beq :not_down

		ldax #txt_button_down
		jsr TermPUTS

:not_down

		lda p1_dpad_input_up+1
		and #>SNES_A
		beq :not_up

		ldax #txt_button_up
		jsr TermPUTS
:not_up
		fin


;------------------------------------------------------------------------------
		stz io_ctrl
		ldax $D886
		stax p2_dpad_input_raw

		ldy #2
		sty io_ctrl


		lda term_x
		pha
		lda term_y
		pha

; debug show game controls
		ldx #40
		ldy #0
		jsr TermSetXY

		ldax p1_dpad_input_raw
		jsr TermPrintAXH

		ldx #40
		ldy #1
		jsr TermSetXY

		ldax p2_dpad_input_raw
		jsr TermPrintAXH


		do 0     ; raw snes pad 3 and 4, don't need them
		ldx #40
		ldy #2
		jsr TermSetXY

		stz io_ctrl
		ldax $D888
		ldy #2
		sty io_ctrl

		jsr TermPrintAXH

		ldx #40
		ldy #3
		jsr TermSetXY

		stz io_ctrl
		ldax $D88A
		ldy #2
		sty io_ctrl

		jsr TermPrintAXH
		fin

		ply
		plx
		jsr TermSetXY

		rts

;------------------------------------------------------------------------------
; minx, maxx, miny, maxy
p1_bounds_table
		db 8, 128-16,
		db 88,171
p2_bounds_table
		db 128+16, 248,
		db 88,171

		dum 0
minx    ds 1
maxx    ds 1
miny    ds 1
maxy    ds 1
		dend

		dum 0
player_x  ds 2
player_y  ds 2
player_vx ds 2
player_vy ds 2
		dend

PlayerBounds

:minmax = temp0

		lda player_y+1,x
		ldy #miny
		cmp (:minmax),y  			; TOP BOUNDS
		bcs :next_y_check

		jsr :negate_vy

		bra :check_the_x_now

:next_y_check

		ldy #maxy
		cmp (:minmax),y			    ; BOTTOM BOUNDS
		bcc :check_the_x_now

		jsr :negate_vy

:check_the_x_now

		lda player_x+1,x
		ldy #minx
		cmp (:minmax),y		  	    ; LEFT BOUNDS
		bcs :next_x_check

		jsr :negate_vx

		rts

:next_x_check
		ldy #maxx
		cmp (:minmax),y				; RIGHT BOUNDS
		bcc :rts

		jsr :negate_vx

:rts
		rts

:negate_vx

		lda player_vx,x
		eor #$ff
		inc
		sta player_vx,x
		beq :hi_inc_x
		lda player_vx+1,x
		eor #$ff
		sta player_vx+1,x
		rts

:hi_inc_x
		lda player_vx+1,x
		eor #$ff
		inc
		sta player_vx+1,x
		rts


:negate_vy

		lda player_vy,x
		eor #$ff
		inc
		sta player_vy,x
		beq :hi_inc_y
		lda player_vy+1,x
		eor #$ff
		sta player_vy+1,x
		rts

:hi_inc_y
		lda player_vy+1,x
		eor #$ff
		inc
		sta player_vy+1,x
		rts


;------------------------------------------------------------------------------
FrisbeeLogic

		lda frisbee_y+1
		cmp #88 	   			; TOP BOUNDS FOR FRISBEE
		bcs :next_y_check

		jsr :negate_vy

		bra :check_the_x_now

:next_y_check

		cmp #168+3			    ; BOTTOM BOUNDS FOR FRISBEE
		bcc :check_the_x_now

		jsr :negate_vy

:check_the_x_now

		lda frisbee_x+1
		cmp #8  		  	    ; LEFT BOUNDS FOR FRISBEE
		bcs :next_x_check

		jsr :negate_vx

		rts

:next_x_check

		cmp #248				; RIGHT BOUNDS FOR FRISBEE
		bcc :rts

		jsr :negate_vx

:rts
		rts

:negate_vx

		lda frisbee_vx
		eor #$ff
		inc
		sta frisbee_vx
		beq :hi_inc_x
		lda frisbee_vx+1
		eor #$ff
		sta frisbee_vx+1
		rts

:hi_inc_x
		lda frisbee_vx+1
		eor #$ff
		inc
		sta frisbee_vx+1
		rts


:negate_vy

		lda frisbee_vy
		eor #$ff
		inc
		sta frisbee_vy
		beq :hi_inc_y
		lda frisbee_vy+1
		eor #$ff
		sta frisbee_vy+1
		rts

:hi_inc_y
		lda frisbee_vy+1
		eor #$ff
		inc
		sta frisbee_vy+1
		rts


;------------------------------------------------------------------------------
;
; I know this is hacky, right now, I just need this stuff to work so
; keeping it braindead
;
MoveFrisbee

; Red Player 1

		clc
		lda <p1_x
		adc <p1_vx
		sta <p1_x
		lda <p1_x+1
		adc <p1_vx+1
		sta <p1_x+1

		clc
		lda <p1_y
		adc <p1_vy
		sta <p1_y
		lda <p1_y+1
		adc <p1_vy+1
		sta <p1_y+1


; Blue Player 2
		clc
		lda <p2_x
		adc <p2_vx
		sta <p2_x
		lda <p2_x+1
		adc <p2_vx+1
		sta <p2_x+1

		clc
		lda <p2_y
		adc <p2_vy
		sta <p2_y
		lda <p2_y+1
		adc <p2_vy+1
		sta <p2_y+1


; Frisbee
		clc
		lda <frisbee_x
		adc <frisbee_vx
		sta <frisbee_x
		lda <frisbee_x+1
		adc <frisbee_vx+1
		sta <frisbee_x+1

		; Probably some arena bounds check can happen here, since after we
		; leave here, we will have lost the carry state, and we haven't
		; left enough space ni the frisbee coordinate system to help us check later

		clc
		lda <frisbee_y
		adc <frisbee_vy
		sta <frisbee_y
		lda <frisbee_y+1
		adc <frisbee_vy+1
		sta <frisbee_y+1

		; Probably some arena bounds check can happen here, since after we
		; leave here, we will have lost the carry state, and we haven't
		; left enough space ni the frisbee coordinate system to help us check later

		rts



		dum 0
SP_CTRL ds 1
SP_AD_L ds 1
SP_AD_M ds 1
SP_AD_H ds 1
SP_POS_X ds 2
SP_POS_Y ds 2
		dend

;------------------------------------------------------------------------------
;
DrawSprites

		stz io_ctrl		; edit sprites

P1_SP_NUM = {8*1}
P1_SP_CTRL = VKY_SP0_CTRL+P1_SP_NUM
P1_SP_AD_L = VKY_SP0_AD_L+P1_SP_NUM
P1_SP_AD_M = VKY_SP0_AD_M+P1_SP_NUM
P1_SP_AD_H = VKY_SP0_AD_H+P1_SP_NUM
P1_SP_POS_X = VKY_SP0_POS_X_L+P1_SP_NUM
P1_SP_POS_Y = VKY_SP0_POS_Y_L+P1_SP_NUM

P2_SP_NUM = {8*2}
P2_SP_CTRL = VKY_SP0_CTRL+P2_SP_NUM
P2_SP_AD_L = VKY_SP0_AD_L+P2_SP_NUM
P2_SP_AD_M = VKY_SP0_AD_M+P2_SP_NUM
P2_SP_AD_H = VKY_SP0_AD_H+P2_SP_NUM
P2_SP_POS_X = VKY_SP0_POS_X_L+P2_SP_NUM
P2_SP_POS_Y = VKY_SP0_POS_Y_L+P2_SP_NUM

FRISB_SP_NUM = {8*0}
FRISB_SP_NUM_FRONT   = FRISB_SP_NUM
FRISB_SP_NUM_BEHIND  = {8*3}
FRISB_SP_CTRL = VKY_SP0_CTRL+FRISB_SP_NUM
FRISB_SP_AD_L = VKY_SP0_AD_L+FRISB_SP_NUM
FRISB_SP_AD_M = VKY_SP0_AD_M+FRISB_SP_NUM
FRISB_SP_AD_H = VKY_SP0_AD_H+FRISB_SP_NUM
FRISB_SP_POS_X = VKY_SP0_POS_X_L+FRISB_SP_NUM
FRISB_SP_POS_Y = VKY_SP0_POS_Y_L+FRISB_SP_NUM



		; Draw Red Player

		; frame 1 will work for now

		lda #%0000011   ; 32x32, layer0, lut1, enable
		sta P1_SP_CTRL

		stz P1_SP_AD_L

		lda #>0+{1*1024}
		sta P1_SP_AD_M

		lda #^SPRITE_TILES
		sta P1_SP_AD_H

		clc
		lda p1_x+1
		adc #32+32-16
		sta P1_SP_POS_X
		lda #0
		adc #0
		sta P1_SP_POS_X+1

		lda p1_y+1
		adc #32-7-31
		sta P1_SP_POS_Y
		stz P1_SP_POS_Y+1

		; Draw Blue Player

		; frame 1 will work for now

		lda #%0000101   ; 32x32, layer0, lut2, enable
		sta P2_SP_CTRL

		stz P2_SP_AD_L

		lda #>0+{{21+1}*1024}  ; 21 frame offset for the blue guy
		sta P2_SP_AD_M

		lda #^SPRITE_TILES
		sta P2_SP_AD_H

		clc
		lda p2_x+1
		adc #32+32-16
		sta P2_SP_POS_X
		lda #0
		adc #0
		sta P2_SP_POS_X+1

		lda p2_y+1
		adc #32-7-31
		sta P2_SP_POS_Y
		stz P2_SP_POS_Y+1

		; Draw Frisbee

		; frame 16 will work for now

		;
		; Erase both
		; 
		stz VKY_SP0_CTRL+FRISB_SP_NUM_BEHIND
		stz VKY_SP0_CTRL+FRISB_SP_NUM_FRONT

		ldx #FRISB_SP_NUM_BEHIND

		lda frisbee_x+1
		bpl :sort_vs_player_1

		; sort vs player 2
		lda p2_y+1
		bra :cmp

:sort_vs_player_1
		lda p1_y+1
:cmp	cmp frisbee_y+1
		bcs :behind
:front
		ldx #FRISB_SP_NUM_FRONT
:behind
		lda #%0000101   ; 32x32, layer0, lut2, enable
		sta VKY_SP0_CTRL,x

		stz VKY_SP0_AD_L,x

		lda #>0+{16*1024}  ; Frisbee is frame 16
		sta VKY_SP0_AD_M,x

		lda #^SPRITE_TILES
		sta VKY_SP0_AD_H,x

		clc
		lda frisbee_x+1
		adc #32+32-8 ; (putting 128 at location 160, half way there) (-8 for sprite cx)
		sta VKY_SP0_POS_X_L,x
		lda #0
		adc #0
		sta VKY_SP0_POS_X_H,x

		lda frisbee_y+1
		adc #32-7-4-16	; putting 128 at location 121, half way there) (-4 for sprite cy) (-16 for altitude)
		sta VKY_SP0_POS_Y_L,x
		stz VKY_SP0_POS_Y_H,x


		;
		; Draw Sprites, + update scroll positions + color animations
		;

		; Red Player Shadow

		; frame 20, and 21
		;

		lda #%0000011   ; 32x32, layer0, lut1, enable
		sta P1_SP_CTRL+{8*32}
		stz P1_SP_AD_L+{8*32}

		lda <jiffy
;		eor p1_x+1
;		eor p1_y+1
		lsr
		lda #>0+{19*1024}
		bcc :kk
		lda #>0+{20*1024}
:kk
		sta P1_SP_AD_M+{8*32}
		lda #^SPRITE_TILES
		sta P1_SP_AD_H+{8*32}

		clc
		lda p1_x+1
		adc #32+32-17
		sta P1_SP_POS_X+{8*32}
		lda #0
		adc #0
		sta P1_SP_POS_X+1+{8*32}

		lda p1_y+1
		adc #32-32
		sta P1_SP_POS_Y+{8*32}
		stz P1_SP_POS_Y+1+{8*32}

		; Blue Player Shadow

		; frame 20, and 21
		;

		lda #%0000011   ; 32x32, layer0, lut1, enable
		sta P2_SP_CTRL+{8*32}
		stz P2_SP_AD_L+{8*32}

		lda <jiffy
		lsr
		lda #>0+{{21+19}*1024}
		bcc :k2
		lda #>0+{{21+20}*1024}
:k2
		sta P2_SP_AD_M+{8*32}
		lda #^SPRITE_TILES
		sta P2_SP_AD_H+{8*32}

		clc
		lda p2_x+1
		adc #32+32-17
		sta P2_SP_POS_X+{8*32}
		lda #0
		adc #0
		sta P2_SP_POS_X+1+{8*32}

		lda p2_y+1
		adc #32-32
		sta P2_SP_POS_Y+{8*32}
		stz P2_SP_POS_Y+1+{8*32}


		; Frisbee Shadow

		; frame 17, and 18
		;

		lda #%0000011   ; 32x32, layer0, lut1, enable
		sta FRISB_SP_CTRL+{8*32}
		stz FRISB_SP_AD_L+{8*32}

		lda <jiffy
		lsr
		lda #>0+{{21+17}*1024}
		bcc :sk
		lda #>0+{{21+18}*1024}
:sk
		sta FRISB_SP_AD_M+{8*32}
		lda #^SPRITE_TILES
		sta FRISB_SP_AD_H+{8*32}

		clc
		lda frisbee_x+1
		adc #32+32-17 ; (putting 128 at location 160, half way there) (-17 for sprite cx)
		sta FRISB_SP_POS_X+{8*32}
		lda #0
		adc #0
		sta FRISB_SP_POS_X+1+{8*32}

		lda frisbee_y+1
		adc #32-7-27	; putting 128 at location 121, half way there) (-27 for sprite cy)
		sta FRISB_SP_POS_Y+{8*32} 
		stz FRISB_SP_POS_Y+1+{8*32}


		lda #2
		sta io_ctrl     ; edit text

		rts


;------------------------------------------------------------------------------
;
DoKernelEvent

		ldx #0
		ldy #1
		jsr TermSetXY

		lda #'$'
		jsr TermCOUT

		lda event_data+kernel_event_t
		jsr TermPrintAH

		lda #' '
		jsr TermCOUT
		lda event_data+3
		jsr TermPrintAH

		lda #' '
		jsr TermCOUT
		lda event_data+4
		jsr TermPrintAH

		lda #' '
		jsr TermCOUT
		lda event_data+5
		jsr TermPrintAH

		lda #' '
		jsr TermCOUT
		lda event_data+6
		jsr TermPrintAH
		jsr TermCR

		rts



;------------------------------------------------------------------------------
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
;LINE_NO = 241*2
LINE_NO = 201*2
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
init320x200
		php
		sei

		; Access to vicky generate registers
		stz io_ctrl

		; enable the graphics mode
		;lda #%01111111  ; everything is enabled
		lda #%00111111  ; everything is enabled
		sta VKY_MSTR_CTRL_0
		lda #1 ; CLK_70
		sta VKY_MSTR_CTRL_1

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

		lda #16+20           ; 200 vertical mode
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


;------- disable the sprites, for the moment

		stz io_ctrl

		ldx #0
]lp 	stz VKY_SP0_CTRL,x
		stz VKY_SP0_CTRL+256,x
		dex
		bne ]lp

;------------------------------------------------------------------------------
;
; Let's Gooo Baller Sprites!!
;

; Get the LUT Data

		ldaxy #CLUT_DATA
		jsr set_write_address
		ldaxy #baller_sheet
		jsr set_read_address

		jsr decompress_clut

		; set access to vicky CLUTs
		lda #1
		sta io_ctrl
		; copy the clut up there
		ldx #0
]lp		lda CLUT_DATA,x
		sta VKY_GR_CLUT_1,x
		sta VKY_GR_CLUT_2,x
		lda CLUT_DATA+$100,x
		sta VKY_GR_CLUT_1+$100,x
		sta VKY_GR_CLUT_2+$100,x
		lda CLUT_DATA+$200,x
		sta VKY_GR_CLUT_1+$200,x
		sta VKY_GR_CLUT_2+$200,x
		lda CLUT_DATA+$300,x
		sta VKY_GR_CLUT_1+$300,x
		sta VKY_GR_CLUT_2+$300,x
		dex
		bne ]lp

		; Let's go! Blue Baller!

		; Index 62 must be #452EEF

		ldaxy #$452EEF
		staxy VKY_GR_CLUT_2+{62*4}

		; Index 63 must be #2E2097

		ldaxy #$2E2097
		staxy VKY_GR_CLUT_2+{63*4}

		stz io_ctrl

; Get the Sprite Pixels

		ldaxy #SPRITE_TILES
		jsr set_write_address
		ldaxy #baller_sheet
		jsr set_read_address

		jsr decompress_pixels

		lda #2 			; back to text mapping
		sta io_ctrl
		plp

		rts

;------------------------------------------------------------------------------

txt_frisbee asc 'frisbee 0.1',0D,00
txt_button_down asc 'button down',0D,00
txt_button_up asc 'button up',0D,00


;------------------------------------------------------------------------------

