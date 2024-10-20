; platform demo
; @dwsJason
;
		mx %11
; ifdef for debug vs release
; set to 1 for final release!
RELEASE = 1
KEYBOARD_ONLY = 0   ; need this for IDE

; Player physics tuning

PLAYER_FRICTION = $00E0   ; 8.8 here

; Player Acceleration constants

ACCEL_X  = $0030 	;$0030    ; 8.8 fixed point, if max speed is 2.0, then lets spend 16 frames getting there
ACCEL_Y  = $0030

JUMP_VEL = $0800

GRAVITY = $0029       ; 9.8/60 ; 8.8 FIXED POINT


MIN_FRISBEE_VX = $0080

;NOTE, the largest this can be is 15
; with the current code
CATCH_RADIUS = 8 ; this is +/- pixels radius, so 8 would be 16 pixel sized circle


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

;-------------------------------
;
; Camera Variables
;

camera_x ds 2
camera_y ds 2

;-------------------------------
;
; Player Physics
;

p1_x ds 3
p1_y ds 3
p1_vx ds 2
p1_vy ds 2

p1_is_falling  ds 1
p1_is_grounded ds 1

pAnim ds 2 ; pointer to the current animation sequence 
anim_index ds 1
anim_timer ds 2
anim_speed ds 2
anim_sprite_frame ds 1
anim_hflip ds 1

;-------------------------------

p1_keyboard_raw ds 2
p1_dpad_input_raw ds 2
p1_dpad_input_down ds 2
p1_dpad_input_up ds 2

map_width_pixels ds 2
map_width_tiles  ds 1
map_height_pixels ds 2
map_height_tiles ds 1

	dend


;------------------------------------------------------------------------------
; frame enumeration
	dum 0
sp_frames_idle ds 10 	 ; first of 10 frames
sp_frames_jump ds 1 	 ; first of 3 frames
sp_frames_jump_peak ds 1 ;
sp_frames_jump_fall ds 1 ;
sp_frames_run  ds 8 	 ; first of 8 frames
sp_frames_walk ds 8 	 ; first of 8 frames
	dend

; animation commands
	dum $80
anim_cmd_end   ds 1       ; animation end
anim_cmd_loop  ds 1  	  ; jump back to start address
anim_cmd_speed ds 1       ; set animation speed $100=60fps, $80=30fps, $40=15fps
	dend

	dum 0
; animation enum
sp_anim_idle ds 1
sp_anim_jump ds 1
sp_anim_run  ds 1
sp_anim_walk ds 1
	dend	   

;------------------------------------------------------------------------------
; The plan here is to keep the attribute map under 8k bytes
; if we keep each attribute cell down to 8 bits, we can still have a sizeable
; map  4096x512, 2048x1024, as a couple of examples in pixel sizes

SKY_MAP = $10000	; MAP data for Tile backround, for the sky
BG_MAP  = $14000	; MAP data for Tile background, for the playfield, behind player
FG_MAP  = $18000	; MAP data for Tile background, for the playfield, in front of player
AT_MAP  = $0A000    ; MAP attribute data, that I use for collision detection

MAP_ATTR = $A000	; collision buffer \o/ 64x64 tiles (each tile is 2 bytes, $$TODO, Squish in to 1 bytes)

MAP_DATA0 = FG_MAP
MAP_DATA1 = BG_MAP
MAP_DATA2 = SKY_MAP

SKY_CHAR = $20000   ; up to 256 tiles for the SKY
MAP_CHAR = $30000   ; up to 256 tiles for the Current MAP

SPRITE_TILES       = $40000  ; currently hold to 64k
SPRITE_TILES_HFLIP = $50000  ; the same tiles, all HFlipped

TILE_DATA0 = MAP_CHAR
TILE_DATA1 = SKY_CHAR
TILE_DATA2 = MAP_CHAR
TILE_DATA3 = SKY_CHAR
TILE_DATA4 = MAP_CHAR
TILE_DATA5 = SKY_CHAR
TILE_DATA6 = MAP_CHAR
TILE_DATA7 = SKY_CHAR

;
; This will copy the color table into memory, then set the video registers
; to display the bitmap
;
start
		php
		sei

		jsr mmu_unlock

		jsr initColors

		; Gah -> I want this data driven, but it's just not setup that way
		; right now.
		;--------------------------

		; So we can set the correct dimensions when initializing the video
		ldax #1024
		stax map_width_pixels
		stax map_height_pixels
		lda #64
		sta map_width_tiles
		sta map_height_tiles

		;--------------------------

		jsr init320x200

		jsr TermInit

		jsr LoadNamcoFont

		plp

		lda #2
		sta io_ctrl


		ldx #24
		ldy #24
		jsr TermSetXY

		ldax #txt_platform
		jsr TermPUTS

;------------------------------------------------------------------------------
;
; Some Kernel Stuff here
;
		ldax #event_data
		stax kernel_args_events

; Initialize some state


		; this simulates raw SNES pad
		lda #-1
		sta p1_keyboard_raw
		sta p1_keyboard_raw+1
		;sta p2_keyboard_raw
		;sta p2_keyboard_raw+1


; Wait here for now

		; Player 1 position, and velocity

		stz p1_x
		;ldax #128
		ldax #500
		stax p1_x+1
		
		stz p1_y
		;ldax #1024-48-32
		ldax #768
		stax p1_y+1

		stz p1_vx
		stz p1_vx+1
		stz p1_vy
		stz p1_vy+1
		stz anim_hflip

		lda #1
		sta p1_is_falling

		ldax #anim_def_idle
		;ldax #anim_def_walk
		;ldax #anim_def_run
		jsr  AnimSetAX

;;-----------------------------------------------------------------------------
;;
;;  MAIN LOOP HERE ------------------------------------------------------------
;;
;		sei ; will the keyboard work, without IRQ?, no it won't

VIRQ = $FFFE

		stz <jiffy
		jsr QueueTickTimer

]main_loop
		jsr kernel_NextEvent
		bcs ]main_loop

		jsr DoKernelEvent
		bcc ]main_loop

		; c=1, we did the timer event - VBlank Ran, now run the game logic

		;
		; Do Game Logic
		;
		jsr GameControls

		; move stuff - also moves the players
		jsr MoveFrisbee

		; then bounds check stuff
		; get rid of player bouncing

		ldax #p1_bounds_table
		stax temp0

		;ldx #p1_x
		;jsr PlayerBounds

		; so to make sure frisbee is ok when being carried
		;jsr FrisbeeLogic

;------------------------------------------------------------------------------

		;jsr PlayerDiscCollision

;------------------------------------------------------------------------------

		jsr AnimUpdate

		jsr CameraUpdate

;------------------------------------------------------------------------------
		; We should let the SNES data come in, while we're waiting
		stz io_ctrl
		lda #%10000101
		sta $D880   		; NES_CTRL, trigger and read
		lda #2
		sta io_ctrl
;------------------------------------------------------------------------------

		bra ]main_loop

		;inc <jiffy  ; since we don't have IRQ doing this
		;jsr WaitVBLPoll

		;jsr CameraBlit
		;jsr DrawSprites

		bra ]main_loop

;;
;;  MAIN LOOP HERE ------------------------------------------------------------
;;
;;-----------------------------------------------------------------------------

;
; It's VBLANK, update those video registers
;
CameraBlit
		stz io_ctrl

		ldax camera_x
		stax VKY_TM0_POS_X_L
		stax VKY_TM1_POS_X_L

		ldax camera_y
		stax VKY_TM0_POS_Y_L
		stax VKY_TM1_POS_Y_L

		lda #2
		sta io_ctrl
		rts

;
; What the heck
; We need to follow the dude around
;
CameraUpdate


		; for now, put him in the center of the screen
		sec
		lda p1_x+1
		sbc #160-8
		sta camera_x
		lda p1_x+2
		sbc #0
		sta camera_x+1

		sec
		lda p1_y+1
		sbc #160-16
		sta camera_y
		lda p1_y+2
		sbc #0
		sta camera_y+1

		; if camerax < 0, then camerax must be 0
		lda camera_x+1
		bpl :keep_going

		stz camera_x
		stz camera_x+1
		lda #0

:keep_going
		; if camerax > (1024-320), then camerax must be 1024-320
		cmp #>{1008-320}
		bcc :check_that_y
		bne :over
		; when it's equal, check the low bits
		lda camera_x
		cmp #<{1008-320}
		bcc :check_that_y
:over
		ldax #1008-320
		stax camera_x

:check_that_y
		; if cameray < 0, then cameray must be 0

		lda camera_y+1
		bpl :keep_going2

		stz camera_y
		stz camera_y+1
		lda #0

		; if cameray > (1024-320), then cameray must be 1024-200
:keep_going2

		cmp #>{1008-200}
		bcc :we_done
		bne :clampy
		; when it's equal, we can check the low bits
		lda camera_y
		cmp #<{1008-200}
		bcc :we_done
:clampy
		ldax #1008-200
		sta camera_y
:we_done

		rts

;
; We just assume this is called once per jiffy, if you want frame rate
; compensation, then put that logic outside of here, you can call this more
; than once per frame
;
; The animation parses a command list, which is compromised of frames, and commands
; most commands execute immediately, and move forward
;
; When a valid frame is encountered, we set it, and are done parsing for the frame
;
AnimUpdate

		sec
		lda anim_timer
		sbc anim_speed
		sta anim_timer
		lda anim_timer+1
		sbc anim_speed+1
		sta anim_timer+1
		bcc :update_anim

		rts	; nothing to do until time runs out


:update_anim
		; c = 0
		; we want to maintain the fractional update, so instead of reseting
		; the time back to $100, we just add $100
		inc anim_timer+1

AnimUpdateImediate  ; used by the AnimSet functions to get us into the first frame

		ldy anim_index ; anim_index points to the next command
]loop
		lda (pAnim),y
		bpl :set_frame

		; we have a command
		asl
		tax
		jmp (:commands,x)

:commands
		da :anim_cmd_end
		da :anim_cmd_loop
		da :anim_cmd_speed

:anim_cmd_end
		; end command will just keep coming here, and doing nothing
		; because we are done
		rts

:anim_cmd_loop
		ldy #0  ; loop takes us back to the beginning of the anim, no waiting
		bra ]loop

:anim_cmd_speed ; set the speed of the anim, no waiting
		iny
		lda (pAnim),y
		sta anim_speed
		iny
		lda (pAnim),y
		sta anim_speed+1
		iny
		bra ]loop

:set_frame
		sta anim_sprite_frame
		iny
		sty anim_index

		rts

;------------------------------------------------------------------------------
;
; AX has pointer to the anim
;
AnimSetAX
		; set the pointer to the animation in memory
		sta pAnim
		stx pAnim+1

		; set Anim Timer to $100
		stz anim_timer
		ldy #1
		sty anim_timer+1

		; default anim speed to 10fps
		stz anim_speed+1
		ldy #256/6
		sty anim_speed

		stz anim_index			; zero the animation index

		jmp AnimUpdateImediate  ; jsr+rts

;;-----------------------------------------------------------------------------

PlayerDiscCollision
		rts

		do 0
; ok, did we catch it?

		stz io_ctrl

		lda :dx 		; dx * dx
		sta MULU_A_L
		stz MULU_A_H
		sta MULU_B_L
		stz MULU_B_H

		ldax MULU_LL
		stax ADD_A_LL

		lda :dy
		sta MULU_A_L  	; dy * dy
		stz MULU_A_H
		sta MULU_B_L
		stz MULU_B_H

		ldax MULU_LL
		stax ADD_B_LL

		lda ADD_R_LH   ; total of the squared values
		bne :no_catch

		lda ADD_R_LL
		cmp #CATCH_RADIUS*CATCH_RADIUS
		bcs :no_catch

		; caught it, we'll have to add something
		; to player movement, to drag this along with us
		lda #1
		;sta frisbee_state ; P2

		;stz frisbee_vx
		;stz frisbee_vx+1
		;stz frisbee_vy
		;stz frisbee_vy+1

:no_catch

		ldy #2
		sty io_ctrl
		fin
		rts

Player1Check
		rts
		do 0
:dx = temp0
:dy = temp0+1

		; Get DX from player 1
		sec
		lda p1_x+1
		sbc frisbee_x+1
		bcs :no_borrow

		; negate, so we have a positive value
		eor #$ff
		inc

:no_borrow
		sta :dx

		; Get DY from player 1
		sec
		lda p1_y+1
		sbc frisbee_y+1
		bcs :no_borrow2

		; negate, so we have a positive value
		eor #$FF
		inc

:no_borrow2

		sta :dy

; these values look good
;		ldx #0
;		ldy #1
;		jsr TermSetXY
;
;		ldax :dx
;		jsr TermPrintAXH


; ok, did we catch it?

		stz io_ctrl

		lda :dx 		; dx * dx
		sta MULU_A_L
		stz MULU_A_H
		sta MULU_B_L
		stz MULU_B_H

		ldax MULU_LL
		stax ADD_A_LL

		lda :dy
		sta MULU_A_L  	; dy * dy
		stz MULU_A_H
		sta MULU_B_L
		stz MULU_B_H

		ldax MULU_LL
		stax ADD_B_LL

		lda ADD_R_LH   ; total of the squared values
		bne :no_catch

		lda ADD_R_LL
		cmp #CATCH_RADIUS*CATCH_RADIUS
		bcs :no_catch

		; caught it, we'll have to add something
		; to player movement, to drag this along with us
		stz frisbee_state ; P1

		stz frisbee_vx
		stz frisbee_vx+1
		stz frisbee_vy
		stz frisbee_vy+1

:no_catch

;		ldax MULU_LL

		ldy #2
		sty io_ctrl

;		jsr TermPrintAXH
		fin
		rts

;------------------------------------------------------------------------------


GameControls

		jsr ReadHardware
		jsr MovePlayerControls

		do 0
		lda frisbee_state
		bne :not_p1

		; P1 has the frisbee, see if they should throw
		; Throw the Frisbee!

		lda p1_dpad_input_up
		asl
		asl
		asl
		asl
		ora p1_dpad_input_up+1
		bit #>SNES_A.SNES_X		; checks AXYB

		beq :rts

		lda #-1
		sta frisbee_state  ; it's launched

		; P1 has the Disc, and they have launched the Frisbee
		lda p1_x+1
		adc #16 	   		; this is an attempt to keep me from re-catching
		sta frisbee_x+1

		;
		; Here's the thing, VX we aren't going to allow it to be negative
		; and probably nothing less than than 00.20
		;

		ldax p1_vx
		;jsr  make_ax_positive
		bpl :fine1

		ldax #MIN_FRISBEE_VX

:fine1
		stax frisbee_vx

		cpx #0
		bne :p1_xisok

		cmp #MIN_FRISBEE_VX
		bcs :p1_xisok

		lda #MIN_FRISBEE_VX
		sta frisbee_vx

:p1_xisok
		lda p1_vy
		sta frisbee_vy
		lda p1_vy+1
		sta frisbee_vy+1

		jsr BoostFrisbeeSpeed

		jmp frisbee_dy

:rts
		rts
:not_p1
		dec
		bne :not_p2

		; P2 has the frisbee, see if they should throw
		; Throw the Frisbee!

		lda p2_dpad_input_up
		asl
		asl
		asl
		asl
		ora p2_dpad_input_up+1
		bit #>SNES_A.SNES_X		; checks AXYB

		beq :rts

		lda #-1
		sta frisbee_state  ; it's launched

		; P1 has the Disc, and they have launched the Frisbee
		lda p2_x+1
		sbc #16 	   		; this is an attempt to keep me from re-catching
		sta frisbee_x+1

		;
		; Here's the thing, VX we aren't going to allow it to be negative
		; and probably nothing less than than 00.20
		;

		ldax p2_vx
		;jsr  make_ax_negative
		bmi :isfine2

		ldax #0-MIN_FRISBEE_VX

:isfine2
		stax frisbee_vx

		jsr negate_ax
		cpx #0
		bne :p2_xisok

		cmp #MIN_FRISBEE_VX
		bcs :p2_xisok

		lda #-MIN_FRISBEE_VX
		sta frisbee_vx
		lda #-1
		sta frisbee_vx+1

:p2_xisok
		lda p2_vy
		sta frisbee_vy
		lda p2_vy+1
		sta frisbee_vy+1

		jsr BoostFrisbeeSpeed

		jmp frisbee_dy

:not_p2
		fin
		rts
;------------------------------------------------------------------------------
;
; Frisbee speed feels not good enough
;
; Add a 50% speed boost
;
BoostFrisbeeSpeed
		do 0
:temp = temp0

		ldax frisbee_vx
		stax :temp

		jsr :half

		clc
		lda :temp
		adc frisbee_vx
		sta frisbee_vx
		lda :temp+1
		adc frisbee_vx+1
		sta frisbee_vx+1
		
		ldax frisbee_vy
		stax :temp

		jsr :half

		clc
		lda :temp
		adc frisbee_vy
		sta frisbee_vy
		lda :temp+1
		adc frisbee_vy+1
		sta frisbee_vy+1

		rts

:half
		lda :temp+1
		cmp #$80
		ror :temp+1
		ror :temp
		fin
		rts

;------------------------------------------------------------------------------

MovePlayerControls

; Player 1 Control pad do your thing, acceleration!

		lda p1_dpad_input_raw
		and #$F
		tay
		asl
		asl
		tax

		; when we're pushing we apply an acceleration
		; these load 4 bits
		; Up, Down, Left, Right respectively

		lda p1_is_falling
		bne :on_ground

		; These accelerations do not apply, unless we are on the ground

		;c=0 already
		lda :accel_table_x,x
		adc p1_vx
		sta p1_vx
		lda :accel_table_x+1,x
		adc p1_vx+1
		sta p1_vx+1
		;lda :accel_table_x+2,x
		;adc p1_x+2
		;sta p1_x+2

		clc
		lda :accel_table_y,x
		adc p1_vy
		sta p1_vy
		lda :accel_table_y+1,x
		adc p1_vy+1
		sta p1_vy+1
		;lda :accel_table_y+2,x
		;adc p1_y+2
		;sta p1_y+2

:on_ground
		tya
		and #$3
		tax

		lda :hflip_table,x
		bmi :nope
		sta anim_hflip
:nope
		rts

:hflip_table
		db -1
		db 0 ; player is right
		db 1 ; plater is left
		db -1


:accel_table_x

		adrl $0000     ; nothing
		adrl ACCEL_X   ; right
		adrl -ACCEL_X  ; left
		adrl $0000     ; left+right

		adrl $0000     ; down
		adrl ACCEL_X   ; down+right
		adrl -ACCEL_X  ; down+left
		adrl $0000     ; down+left+right

		adrl $0000     ; up
		adrl ACCEL_X   ; up+right
		adrl -ACCEL_X  ; up+left
		adrl $0000     ; up+left+right

		adrl $0000     ; up+down
		adrl ACCEL_X   ; up+down+right
		adrl -ACCEL_X  ; up+down+left
		adrl $0000     ; up+down+left+right

:accel_table_y

		adrl $0000     ; nothing
		adrl $0000     ; right
		adrl $0000     ; left
		adrl $0000     ; left+right

		adrl ACCEL_Y   ; down
		adrl ACCEL_Y   ; down+right
		adrl ACCEL_Y   ; down+left
		adrl ACCEL_Y   ; down+left+right

		adrl -ACCEL_Y  ; up
		adrl -ACCEL_Y  ; up+right
		adrl -ACCEL_Y  ; up+left
		adrl -ACCEL_Y  ; up+left+right

		adrl $0000     ; up+down
		adrl $0000     ; up+down+right
		adrl $0000     ; up+down+left
		adrl $0000     ; up+down+left+right



;------------------------------------------------------------------------------
;
; Deal with actual hardware reads
;
ReadHardware

		stz io_ctrl

; player 1 controller read + input latching

:prev_input = temp0
:latch_input = temp0+2
:inv_input = temp1

		ldax p1_dpad_input_raw
		stax :prev_input

		do KEYBOARD_ONLY
		lda #$FF
		else
		lda $D885
		fin

		and p1_keyboard_raw+1
		tax

		do KEYBOARD_ONLY
		lda #$FF
		else
		lda $D884
		fin

		and p1_keyboard_raw

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
; player 2 controller read + input latching
		do 0
		ldax p2_dpad_input_raw
		stax :prev_input

		;ldax $D886
		lda $D887
		and p2_keyboard_raw+1
		tax
		lda $D886
		and p2_keyboard_raw
		stax :inv_input

		eor #$FF
		sta p2_dpad_input_raw
		eor :prev_input
		sta :latch_input

		txa
		eor #$FF
		sta p2_dpad_input_raw+1
		eor :prev_input+1
		sta :latch_input+1

; if latch_input is set, and the button is set, then it just went down

		lda :latch_input
		and p2_dpad_input_raw
		sta p2_dpad_input_down

		lda :latch_input+1
		and p2_dpad_input_raw+1
		sta p2_dpad_input_down+1

; if latch input is set, and the button is clear, then it just came up

		lda :latch_input
		and :inv_input
		sta p2_dpad_input_up
		lda :latch_input+1
		and :inv_input+1
		sta p2_dpad_input_up+1
		fin
;------------------------------------------------------------------------------
; hack code to test the button up/ button down

		do 0
		ldy #2
		sty io_ctrl

		lda p2_dpad_input_down+1
		and #>SNES_A
		beq :not_down

		ldax #txt_button_down
		jsr TermPUTS

:not_down

		lda p2_dpad_input_up+1
		and #>SNES_A
		beq :not_up

		ldax #txt_button_up
		jsr TermPUTS
:not_up
		fin


;------------------------------------------------------------------------------

		ldy #2
		sty io_ctrl


		lda term_x
		pha
		lda term_y
		pha

; debug show game controls
		do 0 ; show SNES PADS for DEBUG
		ldx #35
		ldy #0
		jsr TermSetXY

		ldax p1_dpad_input_raw
		;ldax p1_keyboard_raw
		jsr TermPrintAXH

		ldx #35
		ldy #1
		jsr TermSetXY

		ldax p2_dpad_input_raw
		jsr TermPrintAXH
		fin


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


;------------------------------------------------------------------------------
; CLAMP, BORING
;
PlayerBounds
		rts
:minmax = temp0

		lda player_y+1,x
		ldy #miny
		cmp (:minmax),y  			; TOP BOUNDS
		bcs :next_y_check

		lda (:minmax),y   		    ; stay in here
		sta player_y+1,x

		bra :check_the_x_now

:next_y_check

		ldy #maxy
		cmp (:minmax),y			    ; BOTTOM BOUNDS
		bcc :check_the_x_now

		lda (:minmax),y
		sta player_y+1,x            ; stay in here

:check_the_x_now

		lda player_x+1,x
		ldy #minx
		cmp (:minmax),y		  	    ; LEFT BOUNDS
		bcs :next_x_check

		lda (:minmax),y
		sta player_x+1,x            ; stay

		rts

:next_x_check
		ldy #maxx
		cmp (:minmax),y				; RIGHT BOUNDS
		bcc :rts

		lda (:minmax),y
		sta player_x+1,x              ; stay
:rts
		rts

;------------------------------------------------------------------------------
; BOUNCE LIKE A BALL
PlayerBounds_Bouncy

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
		rts

		do 0
		lda frisbee_state
		bmi :in_flight

		tay

		asl
		asl
		asl
		tax


		lda p1_x+1,x  ; DO NOT SEPARATE THESE p1 and p2 variables
		adc :x_anchor,y
		sta frisbee_x+1

		lda p1_y+1,x
		sta frisbee_y+1

		rts

:x_anchor
		db 8
		db -8


:in_flight
;-------------- bounce and stuff

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
		fin


;------------------------------------------------------------------------------
;
; I know this is hacky, right now, I just need this stuff to work so
; keeping it braindead
;
MoveFrisbee

:oldx_tile = temp0			; the tile we started in
:oldy_tile = temp0+2

:x_tile = temp1				; the tile we're somehow in now, due to physics
:y_tile = temp1+1			; placing us there

:p1_vx_ext = temp1+2
:p1_vy_ext = temp1+3

; sign extension for vx and vy, for math below
		stz <:p1_vx_ext
		stz <:p1_vy_ext

		ldx #-1

		lda <p1_vx+1
		bpl :vx_pos
		stx <:p1_vx_ext
:vx_pos
		lda <p1_vy+1
		bpl :vy_pos
		stx <:p1_vy_ext
:vy_pos
; end sign extension

		; Tile X = pixel X / 16
		lda <p1_x+1
		sta :oldx_tile
		lda <p1_x+2
		lsr
		ror :oldx_tile 		; tiles are 16 x 16 pixels
		lsr
		ror :oldx_tile
		lsr
		ror :oldx_tile
		lsr
		ror :oldx_tile			 	; this is now the :x_tile number \o/

		; Tile Y = pixel y / 16
		lda <p1_y+1
		sta :oldy_tile
		lda <p1_y+2
		lsr
		ror :oldy_tile 		; tiles are 16 x 16 pixels
		lsr
		ror :oldy_tile
		lsr
		ror :oldy_tile
		lsr
		ror :oldy_tile			 	; this is now the :y_tile number \o/

; Player Physics
		lda io_ctrl
		pha

		stz io_ctrl				; want access to fast math

; Straight up movement
;  x = x + vx
		clc
		lda <p1_x
		adc <p1_vx
		sta <p1_x
		lda <p1_x+1
		adc <p1_vx+1
		sta <p1_x+1
		lda <p1_x+2
		adc <:p1_vx_ext
		sta <p1_x+2

; Straight up movement
; y = y + vy
		clc
		lda <p1_y
		adc <p1_vy
		sta <p1_y
		lda <p1_y+1
		adc <p1_vy+1
		sta <p1_y+1
		lda <p1_y+2
		adc <:p1_vy_ext
		sta <p1_y+2

;---------------------------
; Apply Gravity
;
; vy = vy + gravity

		clc
		lda #GRAVITY
		adc <p1_vy
		sta <p1_vy
		lda #0
		adc <p1_vy+1
		sta <p1_vy+1

; Velocity Clamps - player is not allowed to exceed 15 units per frame
; (which is something like 1050 pixels per second / over 3 screens per second horizontal
; over 5 screens per second vertical (it sounds fast to me)
;
		ldax <p1_vy
		phx
		jsr make_ax_positive
		cpx #15
		bcc :no_clamp

		ldx #15	; clamped to 15
		lda #0

		ply
		bpl :save_clamp_result

		jsr make_ax_negative

:save_clamp_result
		stax <p1_vy

		bra :clamped

:no_clamp
		ply 	; we have to fix the stack

:clamped

;------------------------------
; Do Map Collision, first calcuate the tile we're inside of now

		; Tile X = pixel X / 16
		lda <p1_x+1
		sta :x_tile
		lda <p1_x+2
		lsr
		ror :x_tile 		; tiles are 16 x 16 pixels
		lsr
		ror :x_tile
		lsr
		ror :x_tile
		lsr
		ror :x_tile			 	; this is now the :x_tile number \o/

		; Tile Y = pixel y / 16
		lda <p1_y+1
		sta :y_tile
		lda <p1_y+2
		lsr
		ror :y_tile 		; tiles are 16 x 16 pixels
		lsr
		ror :y_tile
		lsr
		ror :y_tile
		lsr
		ror :y_tile			 	; this is now the :y_tile number \o/

; If we're in the same tile as before, and we're not on the ground, then it's
; like there's no collision

		lda p1_is_falling
		beq :not_falling1

		lda :y_tile
		cmp :oldy_tile




:not_falling1

:pRowOld = temp2
:pRowNow = temp2+2

		lda :y_tile
		jsr GetRowAddr
		stax :pRowNow

		lda :oldy_tile
		jsr GetRowAddr
		stax :pRowOld

		lda :x_tile
		asl
		tay
		lda (:pRowNow),y
		beq :nothing_to_do

		; We only have one kind of tile, and at the moment we only have
		; 1 kind of velocity
		stz p1_vy
		stz p1_vy+1		   ; you hit stuff, so slow down
		stz p1_is_falling  ; you're also not falling

		; up you go big guy - to the top of our tile, in fact into the tile
		; above us, bye
		lda p1_y+1
		and #$F0
		sta p1_y+1
		dec p1_y+1
		bne :y_is_good
		dec p1_y+2
:y_is_good

:nothing_to_do

		lda p1_is_falling
		bne :isfalling

		; player is on the ground, he needs friction
		ldax p1_vx
		jsr :friction
		stax p1_vx

:isfalling

		; restore the io_ctrl page
		pla
		sta io_ctrl
		rts	 		;; haha, friction is making him drop slow

;---------------------------
; Only Apply Friction, if the player is in contact with the ground

; Apply Friction to Red Player 1 X


		ldax p1_vx
		jsr :friction
		stax p1_vx

; Apply Friction to Red Player 1 u

		ldax p1_vy
		jsr :friction
		stax p1_vy

		; restore the io_ctrl page
		pla
		sta io_ctrl

		rts

:friction
		php
		jsr :negate

		stax MULU_A_L
		ldax #PLAYER_FRICTION
		stax MULU_B_L
		ldax MULU_LH
		plp
		;jsr :negate
		; drop through
:negate

make_ax_positive
		bpl :no_work

		pha
		txa
		eor #$ff
		tax
		pla
		eor #$ff
		inc
		bne :no_work
		inx

:no_work
		rts

make_ax_negative
		bmi no_work
negate_ax
		pha
		txa
		eor #$ff
		tax
		pla
		eor #$ff
		inc
		bne :no_work
		inx

no_work
		rts


;------------------------------------------------------------------------------
;
; Input A = Row
; Output AX = pRow
;
GetRowAddr
		tay
		lda :rowtableH,y
		tax
		lda :rowtableL,y
		rts

:rowtableL
]v = MAP_ATTR
		lup 64
		db <]v
]v = ]v+128
		--^

:rowtableH
]v = MAP_ATTR
		lup 64
		db >]v
]v = ]v+128
		--^


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

:p1x = temp0
:p1y = temp0+2

;
; If I do something here, I can see my man idling in the middle of the screen "ish"
;

P1_SP_NUM = {8*32}
P1_SP_CTRL = VKY_SP0_CTRL+P1_SP_NUM
P1_SP_AD_L = VKY_SP0_AD_L+P1_SP_NUM
P1_SP_AD_M = VKY_SP0_AD_M+P1_SP_NUM
P1_SP_AD_H = VKY_SP0_AD_H+P1_SP_NUM
P1_SP_POS_X = VKY_SP0_POS_X_L+P1_SP_NUM
P1_SP_POS_Y = VKY_SP0_POS_Y_L+P1_SP_NUM


		lda #%00_01_01_1   ; 32x32, layer1, lut1, enable
		sta P1_SP_CTRL

		stz P1_SP_AD_L

		lda anim_sprite_frame
		asl 					; seems quicker than table lookup
		asl
		sta P1_SP_AD_M

		lda #^SPRITE_TILES  ; change this to a ram address, so we can set bit 1 for hflip
		ora anim_hflip
		sta P1_SP_AD_H

		; Sprite Hot Spot Adjustment
		clc
		lda p1_x+1
		adc #16
		sta :p1x
		lda p1_x+2
		adc #0
		sta :p1x+1

		clc
		lda p1_y+1
		adc #1
		sta :p1y
		lda p1_y+2
		adc #0
		sta :p1y+1

		sec
		lda :p1x
		sbc camera_x
		sta P1_SP_POS_X
		lda :p1x+1
		sbc camera_x+1
		sta P1_SP_POS_X+1

		sec
		lda :p1y
		sbc camera_y
		sta P1_SP_POS_Y
		lda :p1y+1
		sbc camera_y+1
		sta P1_SP_POS_Y+1

		do 0

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

		fin

		lda #2
		sta io_ctrl     ; edit text

		rts


;------------------------------------------------------------------------------
;
DoKernelEvent
		lda event_data+kernel_event_t
		cmp #kernel_event_timer_EXPIRED
		bne :not_timer

		lda event_data+kernel_event_timer_t_cookie+3
		cmp #$EA
		bne :not_timer

		inc <jiffy
		jsr QueueTickTimer

; VBlank Stuff

		jsr CameraBlit
		jsr DrawSprites

		sec
		rts

:not_timer

		jsr :check_stuff
		clc
		rts

:check_stuff

		do 0    ; for debugging the kernel events
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
		fin


		lda event_data+kernel_event_t
		cmp #kernel_event_key_PRESSED
		beq DoKeyDown
		cmp #kernel_event_key_RELEASED
		beq DoKeyUp
		rts

		; Player 1 throw keys
		;77 = W - up
		;61 = A - left
		;73 = S - down
		;64 = D - right
		;78 = X
		;71 = Q
		;65 = E

		; player 2 keys
		;B6 = up arrow
		;B8 = left arrow
		;B7 = down arrow
		;B9 = right arrow 
		;20 = space
		;94 = enter


DoKeyUp
		lda event_data+kernel_event_event_t_key_raw

		; player 1 keys
		cmp #$77  ; W - up
		bne :nx1
		lda #SNES_UP
		tsb p1_keyboard_raw
		rts
:nx1
		cmp #$61  ; A - left
		bne :nx2
		lda #SNES_LEFT
		tsb p1_keyboard_raw
		rts
:nx2
		cmp #$73  ; S - down
		bne :nx3
		lda #SNES_DOWN
		tsb p1_keyboard_raw
		rts
:nx3
		cmp #$64  ; D - right
		bne :nx4
		lda #SNES_RIGHT
		tsb p1_keyboard_raw
		rts
:nx4
		do 0
		; player 2 keys
		cmp #$B6  ; up
		bne :nx5
		lda #SNES_UP
		tsb p2_keyboard_raw
		rts
:nx5
		cmp #$B8  ; left
		bne :nx6
		lda #SNES_LEFT
		tsb p2_keyboard_raw
		rts
:nx6
		cmp #$B7  ; down
		bne :nx7
		lda #SNES_DOWN
		tsb p2_keyboard_raw
		rts
:nx7
		cmp #$B9  ; right
		bne :nx8
		lda #SNES_RIGHT
		tsb p2_keyboard_raw
		rts
:nx8
		fin

		cmp #$78 ; Throw
		bne :nx9
		lda #>SNES_A
		tsb p1_keyboard_raw+1
		rts
:nx9
		;cmp #$20 ; Throw
		;bne :nx10
		;lda #>SNES_A
		;tsb p2_keyboard_raw+1
		;rts
:nx10

		rts



DoKeyDown
		lda event_data+kernel_event_event_t_key_raw

		; player 1 keys
		cmp #$77  ; W - up
		bne :nx1
		lda #SNES_UP
		trb p1_keyboard_raw
		rts
:nx1
		cmp #$61  ; A - left
		bne :nx2
		lda #SNES_LEFT
		trb p1_keyboard_raw
		rts
:nx2
		cmp #$73  ; S - down
		bne :nx3
		lda #SNES_DOWN
		trb p1_keyboard_raw
		rts
:nx3
		cmp #$64  ; D - right
		bne :nx4
		lda #SNES_RIGHT
		trb p1_keyboard_raw
		rts

		do 0
:nx4
		; player 2 keys
		cmp #$B6  ; up
		bne :nx5
		lda #SNES_UP
		trb p2_keyboard_raw
		rts
:nx5
		cmp #$B8  ; left
		bne :nx6
		lda #SNES_LEFT
		trb p2_keyboard_raw
		rts
:nx6
		cmp #$B7  ; down
		bne :nx7
		lda #SNES_DOWN
		trb p2_keyboard_raw
		rts
:nx7
		cmp #$B9  ; right
		bne :nx8
		lda #SNES_RIGHT
		trb p2_keyboard_raw
		rts
:nx8
		fin

		cmp #$78 ; Throw
		bne :nx9
		lda #>SNES_A
		trb p1_keyboard_raw+1
		rts
:nx9

		;cmp #$20 ; Throw
		;bne :nx10
		;lda #>SNES_A
		;trb p2_keyboard_raw+1
		;rts
:nx10


		rts


;------------------------------------------------------------------------------
; Used for kernel timers
QueueTickTimer
		lda #kernel_args_timer_QUERY.kernel_args_timer_FRAMES
		sta kernel_args_timer_units
		jsr kernel_Clock_SetTimer

		inc
		stz kernel_args_timer_units    ; frames
		sta kernel_args_timer_absolute ; 1

		lda #$EA
		sta kernel_args_timer_cookie
		jmp kernel_Clock_SetTimer


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
LINE_NO = 201*2
        lda #<LINE_NO
        ldx #>LINE_NO
:waitforlineAX		
]wait
        cpx $D01B
        bne ]wait

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
		;lda #1 ; CLK_70
		lda #%00100111  ; alternate font, double sized font, 70hz
		sta VKY_MSTR_CTRL_1

		; layer stuff - take from Jr manual
		lda #$54
		sta VKY_LAYER_CTRL_0  ; tile map layers
		lda #$06
		sta VKY_LAYER_CTRL_1  ; tile map layers

		; Tile Map 0 - ForeGound
		lda #$01  		 ; enabled + 16x16
		sta VKY_TM0_CTRL ; tile size

		ldaxy #MAP_DATA0
		staxy VKY_TM0_ADDR_L

		lda map_width_tiles   ; data driven
		sta VKY_TM0_SIZE_X    ; map size X
		stz VKY_TM0_SIZE_X+1  ; reserved

		lda map_height_tiles  ; data driven
		sta VKY_TM0_SIZE_Y    ; map size y
		stz VKY_TM0_SIZE_Y+1  ; reserved

		lda #16
		sta VKY_TM0_POS_X_L  ; scroll x lo
		stz VKY_TM0_POS_X_H  ; scroll x hi

		ldax #1024-16-200    ; put it at the bottom
		stax VKY_TM0_POS_Y_L  ; scroll y

		; Tile Map 1
		; Snow Background
		lda #$01  ; enabled + 16x16
		sta VKY_TM1_CTRL

		ldaxy #MAP_DATA1
		staxy VKY_TM1_ADDR_L

		lda map_width_tiles
		sta VKY_TM1_SIZE_X
		stz VKY_TM1_SIZE_X+1

		lda map_height_tiles
		sta VKY_TM1_SIZE_Y
		stz VKY_TM1_SIZE_Y+1

		lda #16
		sta VKY_TM1_POS_X_L  ; scroll x lo
		stz VKY_TM1_POS_X_H  ; scroll x hi

		ldax #1024-16-200    ; put it at the bottom
		stax VKY_TM1_POS_Y_L  ; scroll y

		; sky map 2
		; TBD, I need to add this
		lda #$01  ; enabled + 16x16
		stz VKY_TM2_CTRL

		ldaxy #MAP_DATA2
		staxy VKY_TM2_ADDR_L

		lda #22
		sta VKY_TM2_SIZE_X
		stz VKY_TM2_SIZE_X+1

		lda #16
		sta VKY_TM2_SIZE_Y
		stz VKY_TM2_SIZE_Y+1

		stz VKY_TM2_POS_X_L  ; scroll x lo
		stz VKY_TM2_POS_X_H  ; scroll x hi
		stz VKY_TM2_POS_Y_L  ; scroll y
		stz VKY_TM2_POS_Y_H  ; scroll y

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
		ldaxy #TILE_DATA4
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

; Get the Collision Attributes

		ldaxy #AT_MAP
		jsr set_write_address
		ldaxy #img_court
		jsr set_read_address

		jsr decompress_map		; grabs layer 0, which is collision in these level files


; Get the Map

		ldaxy #MAP_DATA0
		jsr set_write_address
		ldaxy #img_court
		jsr set_read_address

		; first map layer is the attribute map
		; second map layer is the foreground
		; third map layer is the background

		lda #1  					; Get map layer 1, if it exists
		jsr decompress_map_layer

		ldaxy #MAP_DATA1
		jsr set_write_address
		ldaxy #img_court
		jsr set_read_address

		; first map layer is the attribute map
		; second map layer is the foreground
		; third map layer is the background

		lda #2  					; Get map layer 2, if it exists
		jsr decompress_map_layer


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
; Decompress the Platformer Dude
;

; Get the LUT Data

		ldaxy #CLUT_DATA
		jsr set_write_address
		ldaxy #sprite_idle
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

;------------------------------------------------------------------------------
;
; Decompress the 32x32 sprite frames
;

		stz io_ctrl

		ldx #3*7

]lp
		phx

		lda :anims+2,x
		tay
		lda :anims+1,x
		pha
		lda :anims,x
		plx

		jsr set_read_address

		plx
		phx

		lda :target+2,x
		tay
		lda :target+1,x
		pha
		lda :target,x
		plx

		jsr set_write_address

		jsr decompress_pixels

		plx
		dex
		dex
		dex
		bpl ]lp

		lda #2 			; back to text mapping
		sta io_ctrl
		plp

		rts



:anims  adr sprite_idle
		adr sprite_idlel
		adr sprite_jump
		adr sprite_jumpl
		adr sprite_run
		adr sprite_runl
		adr sprite_walk
		adr sprite_walkl

:target adr SPRITE_TILES
		adr SPRITE_TILES_HFLIP
		adr SPRITE_TILES+{1024*10}
		adr SPRITE_TILES_HFLIP+{1024*10}
		adr SPRITE_TILES+{1024*13}
		adr SPRITE_TILES_HFLIP+{1024*13}
		adr SPRITE_TILES+{1024*21}
		adr SPRITE_TILES_HFLIP+{1024*21}

		; next space is at 1024*29

;------------------------------------------------------------------------------

txt_platform asc 'PLATFORM SAMPLE',00
;txt_help2	asc 'KEEP THE DISC FROM PASSING BY',00
;txt_button_down asc 'BUTTON DOWN',0D,00
;txt_button_up asc 'BUTTON UP',0D,00
;txt_help asc 'SNES 1VS2 OR WASD+X VS ARROW KEYS+SPACE',00

;------------------------------------------------------------------------------
;
LoadNamcoFont

		lda #1		  ; Font Memory
		sta io_ctrl

		ldaxy #namco_font
		jsr set_read_address

		; This font is 64 glyphs / 512 bytes

		ldx #0

]loop	jsr readbyte
		sta $C900,x		; alternative font
		inx
		bne ]loop

]loop	jsr readbyte
		sta $CA00,x		; alternative font
		inx
		bne ]loop

]loop	jsr readbyte
		sta $CB00,x		; alternative font
		inx
		bne ]loop

]loop	jsr readbyte
		sta $CC00,x		; alternative font
		inx
		bne ]loop

		rts

;------------------------------------------------------------------------------
; Animation Data for our guy sprite

; List of addresses to the start of animations

anim_table_lo
		db anim_def_idle
		db anim_def_jump
		db anim_def_run
		db anim_def_walk

anim_table_hi
		db >anim_def_idle
		db >anim_def_jump
		db >anim_def_run
		db >anim_def_walk

anim_def_idle
		db anim_cmd_speed
		dw 256/6		  ; 10 fps
		db sp_anim_idle+0,sp_anim_idle+1,sp_anim_idle+2,sp_anim_idle+3,sp_anim_idle+4
		db sp_anim_idle+5,sp_anim_idle+6,sp_anim_idle+7,sp_anim_idle+8,sp_anim_idle+9
		db anim_cmd_loop

anim_def_jump
		db anim_cmd_speed
		dw 0			  ; frozen
		db sp_frames_jump,sp_frames_jump_peak,sp_frames_jump_fall,anim_cmd_end

anim_def_run
		db anim_cmd_speed
		dw 256/6		  ; 10 fps
		db sp_frames_run+0,sp_frames_run+1,sp_frames_run+2,sp_frames_run+3
		db sp_frames_run+4,sp_frames_run+5,sp_frames_run+6,sp_frames_run+7
		db anim_cmd_loop

anim_def_walk
		db anim_cmd_speed
		dw 256/6		  ; 10 fps
		db sp_frames_walk+0,sp_frames_walk+1,sp_frames_walk+2,sp_frames_walk+3
		db sp_frames_walk+4,sp_frames_walk+5,sp_frames_walk+6,sp_frames_walk+7
		db anim_cmd_loop



		 
