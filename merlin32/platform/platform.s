; platform demo
; @dwsJason
;
		mx %11
; ifdef for debug vs release
; set to 1 for final release!
RELEASE = 1

; Player physics tuning

PLAYER_FRICTION = $00E0   ; 8.8 here

; Player Acceleration constants

ACCEL_X  = $0030    ; 8.8 fixed point, if max speed is 2.0, then lets spend 16 frames getting there
ACCEL_Y  = $0030
ACCEL_XY = {ACCEL_X*181}/256  ; SIN of ACCEL_X

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


;
; Frisbee Physics
;
frisbee_x  ds 2
frisbee_y  ds 2
frisbee_vx ds 2
frisbee_vy ds 2

;
; -1 -> no player
;  0 -> player 1
;  1 -> player 2
;
frisbee_state ds 1 ; which player has the fris?


;-------------------------------
;
; Red Player Physics
;
; DO NOT SEPARATE FROM THE p2 VARIABLES

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
; DO NOT SEPARATE FROM THE p1 VARIABLES
;-------------------------------

p1_keyboard_raw ds 2
p1_dpad_input_raw ds 2
p1_dpad_input_down ds 2
p1_dpad_input_up ds 2

p2_keyboard_raw ds 2
p2_dpad_input_raw ds 2
p2_dpad_input_down ds 2
p2_dpad_input_up ds 2

map_width_pixels ds 2
map_width_tiles  ds 1
map_height_pixels ds 2
map_height_tiles ds 1

	dend


;------------------------------------------------------------------------------
; The plan here is to keep the attribute map under 8k bytes
; if we keep each attribute cell down to 8 bits, we can still have a sizeable
; map  4096x512, 2048x1024, as a couple of examples in pixel sizes

SKY_MAP = $10000	; MAP data for Tile backround, for the sky
BG_MAP  = $14000	; MAP data for Tile background, for the playfield, behind player
FG_MAP  = $18000	; MAP data for Tile background, for the playfield, in front of player
AT_MAP  = $1C000    ; MAP attribute data, that I use for collision detection

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
		sta p2_keyboard_raw
		sta p2_keyboard_raw+1


; Wait here for now

]wait_here bra ]wait_here

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

		; this mostly controls the logic to do collision
		; and if the frisbee is in someone's posession

		lda #-1
		sta frisbee_state

;;-----------------------------------------------------------------------------
;;
;;  MAIN LOOP HERE ------------------------------------------------------------
;;
;		sei ; will the keyboard work, without IRQ?, no it won't

VIRQ = $FFFE


]main_loop
;		php
;		ldx #0
;		jsr (VIRQ,x)  			; fake IRQ?

		jsr kernel_NextEvent
		bcs :no_events
		jsr DoKernelEvent
:no_events
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

		ldx #p1_x
		jsr PlayerBounds

		ldax #p2_bounds_table
		stax temp0

		ldx #p2_x
		jsr PlayerBounds

		; so to make sure frisbee is ok when being carried
		jsr FrisbeeLogic

;------------------------------------------------------------------------------

		jsr PlayerDiscCollision

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

PlayerDiscCollision

		; Collision detect disc and player
		;
		
		lda frisbee_state
		bmi :lets_go		; the frisbee is airborn

		; someone already has frisbee
		rts

:lets_go

		jsr Player1Check
		; fall to player2

Player2Check


:dx = temp0
:dy = temp0+1

		; Get DX from player 1
		sec
		lda p2_x+1
		sbc frisbee_x+1
		bcs :no_borrow

		; negate, so we have a positive value
		eor #$ff
		inc

:no_borrow
		sta :dx

		; Get DY from player 1
		sec
		lda p2_y+1
		sbc frisbee_y+1
		bcs :no_borrow2

		; negate, so we have a positive value
		eor #$FF
		inc

:no_borrow2

		sta :dy

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
		sta frisbee_state ; P2

		stz frisbee_vx
		stz frisbee_vx+1
		stz frisbee_vy
		stz frisbee_vy+1

:no_catch

		ldy #2
		sty io_ctrl

		rts

Player1Check

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

		rts

;------------------------------------------------------------------------------


GameControls

		jsr ReadHardware
		jsr MovePlayerControls

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
		rts
;------------------------------------------------------------------------------
;
; Frisbee speed feels not good enough
;
; Add a 50% speed boost
;
BoostFrisbeeSpeed

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
		rts

;------------------------------------------------------------------------------

MovePlayerControls

; Player 1 Control pad do your thing, acceleration!

		lda p1_dpad_input_raw
		and #$F
		asl
		tax

		; when we're pushing we apply an acceleration
		; these load 4 bits
		; Up, Down, Left, Right respectively

		;c=0 already
		lda :accel_table_x,x
		adc p1_vx
		sta p1_vx
		lda :accel_table_x+1,x
		adc p1_vx+1
		sta p1_vx+1

		clc
		lda :accel_table_y,x
		adc p1_vy
		sta p1_vy
		lda :accel_table_y+1,x
		adc p1_vy+1
		sta p1_vy+1

; Player 2 Control pad do your thing acceleration

		lda p2_dpad_input_raw
		and #$F
		asl
		tax

		; when we're pushing we apply an acceleration
		; these load 4 bits
		; Up, Down, Left, Right respectively

		;c=0 already
		lda :accel_table_x,x
		adc p2_vx
		sta p2_vx
		lda :accel_table_x+1,x
		adc p2_vx+1
		sta p2_vx+1

		clc
		lda :accel_table_y,x
		adc p2_vy
		sta p2_vy
		lda :accel_table_y+1,x
		adc p2_vy+1
		sta p2_vy+1


		rts

:accel_table_x

		dw $0000     ; nothing
		dw ACCEL_X   ; right
		dw -ACCEL_X  ; left
		dw $0000     ; left+right

		dw $0000     ; down
		dw ACCEL_XY  ; down+right
		dw -ACCEL_XY ; down+left
		dw $0000     ; down+left+right

		dw $0000     ; up
		dw ACCEL_XY  ; up+right
		dw -ACCEL_XY ; up+left
		dw $0000     ; up+left+right

		dw $0000     ; up+down
		dw ACCEL_XY  ; up+down+right
		dw -ACCEL_XY ; up+down+left
		dw $0000     ; up+down+left+right

:accel_table_y

		dw $0000     ; nothing
		dw $0000     ; right
		dw $0000     ; left
		dw $0000     ; left+right

		dw ACCEL_Y   ; down
		dw ACCEL_XY  ; down+right
		dw ACCEL_XY  ; down+left
		dw ACCEL_Y   ; down+left+right

		dw -ACCEL_Y  ; up
		dw -ACCEL_XY ; up+right
		dw -ACCEL_XY ; up+left
		dw -ACCEL_Y  ; up+left+right

		dw $0000     ; up+down
		dw $0000     ; up+down+right
		dw $0000     ; up+down+left
		dw $0000     ; up+down+left+right



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

		;ldax $D884
		lda $D885
		and p1_keyboard_raw+1
		tax
		lda $D884
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

;---------------------------
; Apply Friction to Red Player 1 X

		stz io_ctrl

		ldax p1_vx
		jsr :friction
		stax p1_vx

; Apply Friction to Red Player 1 u

		ldax p1_vy
		jsr :friction
		stax p1_vy


		lda #2
		sta io_ctrl


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
;---------------------------------
; Apply Blue player friction
		stz io_ctrl

		ldax p2_vx
		jsr :friction
		stax p2_vx

		ldax p2_vy
		jsr :friction
		stax p2_vy

		lda #2
		sta io_ctrl

;---------------------------------


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
frisbee_dy = *
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
		do 1
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
		cmp #$20 ; Throw
		bne :nx10
		lda #>SNES_A
		tsb p2_keyboard_raw+1
		rts
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

		do 1
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

		cmp #$20 ; Throw
		bne :nx10
		lda #>SNES_A
		trb p2_keyboard_raw+1
		rts
:nx10


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

