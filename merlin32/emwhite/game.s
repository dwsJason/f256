;
; Merlin32 Line draw example for Jr
;
; To Assemble "merlin32 -v . link.s"
;
		mx %11

io_ctrl  equ 1

;
; Enemy #s
;

	dum 0
SPRITE_MSPAC_RIGHT   ds 1  ; 0
SPRITE_MSPAC_LEFT    ds 1  ; 1
SPRITE_PAC_RIGHT     ds 1  ; 2
SPRITE_PAC_LEFT      ds 1  ; 3
SPRITE_BLINKY_RIGHT  ds 1  ; 4
SPRITE_BLINKY_LEFT   ds 1  ; 5
SPRITE_PINKY_RIGHT   ds 1  ; 6
SPRITE_PINKY_LEFT    ds 1  ; 7
SPRITE_INKY_RIGHT    ds 1  ; 8
SPRITE_INKY_LEFT     ds 1  ; 9
SPRITE_CLYDE_LEFT    ds 1  ; 10
SPRITE_CLYDE_RIGHT   ds 1  ; 11
SPRITE_GHOST_BLUE    ds 1  ; 12
SPRITE_GHOST_WHITE   ds 1  ; 13
SPRITE_CHERRY        ds 1  ; 14
SPRITE_STRAWBERRY    ds 1  ; 15
SPRITE_ORANGE        ds 1  ; 16
SPRITE_PRETZEL       ds 1  ; 17
SPRITE_APPLE         ds 1  ; 18
SPRITE_PEAR          ds 1  ; 19
SPRITE_BANANA        ds 1  ; 20
SPRITE_HEART         ds 1  ; 21
SPRITE_GRENADE       ds 1  ; 22
SPRITE_SHIP          ds 1  ; 23
SPRITE_BELL          ds 1  ; 24
SPRITE_KEY           ds 1  ; 25
SPRITE_BOOM          ds 1  ; 26
	dend


	dum $20
temp0 ds 4
temp1 ds 4
temp2 ds 4
temp3 ds 4
temp4 ds 4
temp5 ds 4
temp6 ds 4
temp7 ds 4

jiffy ds 1

spawn_x    ds 2  ; x position
spawn_no   ds 1  ; sprite type
spawn_size ds 1  ; which size

pSpriteFrame ds 3      ; sprite frame pointer

	dend

RAST_COL = $D018
RAST_ROW = $D01A

;------------------------------------------------------------------------------
;
		;jmp Initialize		; set video mode, hide sprites, reset stuff, designed to be called once
		jmp FramePump
		jmp SpawnEnemy
		;jmp CollideMissile
		jmp WaitVBLPoll
		jmp RandomTest

		; diagnostic code, verify the sprites are good
		;jmp show8
		;jmp show16
		;jmp show24
		;jmp show32

start

; This will copy the color table into memory, then set the video registers
; to display the bitmap

		jsr init320x240

		jsr initColors

		jsr TermInit

		ldx #60
		ldy #1
		jsr TermSetXY

		lda #<txt_title
		ldx #>txt_title
		jsr TermPUTS

;------------------------------------------------------------------------------
;
; Random Seed Init

		stz io_ctrl

		lda #$12
		sta |VKY_SEEDL
		lda #$34
		sta |VKY_SEEDH
		lda #3
		sta |VKY_RND_CTRL
		lda #1
		sta |VKY_RND_CTRL

;------------------------------------------------------------------------------

		jmp RandomTest

;------------------------------------------------------------------------------
show8
show16
show24
show32


		stz io_ctrl  ; access sprite registers

;]spr_size = %00000001 ; 32x32
;]spr_size = %00100001  ; 24x24
]spr_size = %01000001  ; 16x16
;]spr_size = %01100001  ; 8x8

:x            = temp0
:y            = temp1
:sprite_frame = temp2
:pSprite      = temp3
;:sp_size      = temp4
;:sp_delta     = temp5


		lda #32
		sta <:x
		stz <:x+1

		sta <:y
		stz <:y+1
		

		lda #<sprite_sheet32
		lda #<sprite_sheet24
		lda #<sprite_sheet16
		;lda #<sprite_sheet8
		sta <:sprite_frame+0

		lda #>sprite_sheet32
		lda #>sprite_sheet24
		lda #>sprite_sheet16
		;lda #>sprite_sheet8
		sta <:sprite_frame+1

		lda #^sprite_sheet32
		lda #^sprite_sheet24
		lda #^sprite_sheet16
		;lda #^sprite_sheet8
		sta <:sprite_frame+2

		lda #<VKY_SP0_CTRL
		sta <:pSprite
		lda #>VKY_SP0_CTRL
		sta <:pSprite+1

		ldx #8
		ldy #8
]lp
		; plot sprite frame a :x,:y
		lda #]spr_size
		jsr :store
		lda :sprite_frame
		jsr :store
		lda :sprite_frame+1
		jsr :store
		lda :sprite_frame+2
		jsr :store

		lda :x
		jsr :store
		lda :x+1
		jsr :store

		lda :y
		jsr :store
		lda :y+1
		jsr :store

		; sprite_frame increment
		clc
		;32x32
		;lda <:sprite_frame+1
		;adc #$04
		;sta <:sprite_frame+1

		;24x24
		;lda <:sprite_frame
		;adc #$40
		;sta <:sprite_frame
		;lda <:sprite_frame+1
		;adc #$02
		;sta <:sprite_frame+1

		;16x16
		inc <:sprite_frame+1

		;8x8
		;lda <:sprite_frame
		;adc #64
		;sta <:sprite_frame
		;lda <:sprite_frame+1
		;adc #0
		;sta <:sprite_frame+1

		clc
		lda <:x
		adc #32
		sta <:x
		lda <:x+1
		adc #0
		sta <:x+1

		dex
		bne ]lp

		; next line
		ldx #8

		clc
		lda <:y
		adc #32  	; inc y
		sta <:y

		lda #32
		sta <:x  	; reset x
		stz <:x+1

		dey
		bne ]lp

]wait
		bra ]wait

:store
		sta (:pSprite)
		inc :pSprite
		bne :rts
		inc :pSprite+1
:rts	rts



;------------------------------------------------------------------------------
;
; Some Kernel Stuff here
;
		;ldax #event_data
		;stax kernel_args_events
RandomTest
		jsr InitSpriteFont

main_loop
		;jsr kernel_NextEvent
		;bcs :no_events
		;jsr DoKernelEvent
		jsr WaitVBLPoll

		jsr FramePump

		lda jiffy
		inc
		sta jiffy
		and #$3
		bne main_loop

; about once per second spawn
		lda |VKY_RNDL
		and #$1F
		ora #$20
		sta <spawn_x
		clc
		lda |VKY_RNDL
		adc <spawn_x
		sta <spawn_x
		lda #0
		adc #0
		sta <spawn_x+1

;		lda #<]spawn
;		sta spawn_x
;		lda #>]spawn
;		sta spawn_x+1

		lda #SPRITE_CHERRY
		sta <spawn_no

:again	lda |VKY_RNDL
		and #$1f ; down to 31
		cmp #SPRITE_BOOM
		bcc :ok
		bra :again
:ok
		sta <spawn_no


		;lda #%01000001
		;lda #1  		  ; 0=8,1=16,2=24,3=32
		lda |VKY_RNDL
		sta <spawn_size

		jsr SpawnEnemy

		; choose something to splode
		lda in_use_sprites_count
		cmp #11
		bcc :no_events

		jsr RandomExplode


:no_events

		bra main_loop


;------------------------------------------------------------------------------

RandomExplode

		lda |VKY_RNDL
		and #3
		clc
		adc #7
		;pha
		tax
		lda in_use_sprites,x

:pSprite = temp0
:pHW     = temp0+2

		jsr GetSpriteObjPtr
		stax :pSprite

		ldy #spr_number

		lda (:pSprite),y
		jsr GetSpriteHWPtr ; we get to initialize hw, so we don't have update it all the time
		stax :pHW


		ldy #spr_type
		lda #LOGIC_EXPLODE
		cmp (:pSprite),y
		beq :rts
		sta (:pSprite),y

		; zero sprite velocity
		ldy #spr_vel_x
		lda #0
		sta (:pSprite),y
		iny
		sta (:pSprite),y
		ldy #spr_vel_y
		sta (:pSprite),y
		iny
		sta (:pSprite),y

		ldy #spr_size
		lda (:pSprite),y
		sta spawn_size
		
		lda #0
		ldy #spr_logic
		sta (:pSprite),y
		
		ldy #spr_glyph
		lda #FRAME_BOOM
		sta (:pSprite),y
		
		ldx #FRAME_BOOM
		lda spawn_size
		jsr GetFrame
		
		ldy #1   		; get the hardware frame updated
		lda pSpriteFrame
		sta (:pHW),y
		iny
		lda pSpriteFrame+1
		sta (:pHW),y
		iny
		lda pSpriteFrame+2
		sta (:pHW),y

:rts
		rts



		do 0
		pla
		jsr GetSpriteHWPtr ; we get to initialize hw, so we don't have update it all the time
		stax :pHW
		pla

		pha
		jsr FreeSprite

		plx

		ldy in_use_sprites_count
		dey
		sty in_use_sprites_count
		beq :happy

		lda in_use_sprites,y
		sta in_use_sprites,x

:happy
		fin
		rts

;------------------------------------------------------------------------------

init320x240
		php
		sei

		; Access to vicky generate registers
		stz io_ctrl

		; enable the graphics mode
		; X GAMMA SPRITE TILE BITMAP GRAPH OVRLY TEXT

		lda #%00100111  ; sprite + graph + overlay + text
		sta VKY_MSTR_CTRL_0

		lda #0
		sta VKY_MSTR_CTRL_1

		; layer stuff - take from Jr manual
		;lda #$10
		;sta VKY_LAYER_CTRL_0  ; tile map layers
		;lda #$02
		;sta VKY_LAYER_CTRL_1  ; tile map layers

		; Tile Map Disable
		stz VKY_TM0_CTRL
		stz VKY_TM1_CTRL
		stz VKY_TM2_CTRL

		; bitmap disables
		stz VKY_BM0_CTRL  ; disable
		stz VKY_BM1_CTRL  ; disable
		stz VKY_BM2_CTRL  ; disable

		stz VKY_BRDR_CTRL

		lda #2
		sta io_ctrl
		plp

		rts
;------------------------------------------------------------------------------

txt_title asc 'game thing'
		db 13,0

;------------------------------------------------------------------------------

WaitVBLPoll
		php
		sei
		lda $1
		pha
		stz $1
LINE_NO = 261*2
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
		plp
        rts

;------------------------------------------------------------------------------
;
; Sprite Definitions
;
;------------------------------------------------------------------------------
; Sprite Character Index Definitions

	dum 0
FRAME_BLANK         ds 1
FRAME_MSPAC_RIGHT   ds 3
FRAME_MSPAC_LEFT    ds 3
FRAME_PAC_RIGHT     ds 2
FRAME_PAC_CLOSED    ds 1
FRAME_PAC_LEFT      ds 2
FRAME_BLINKY_RIGHT  ds 2
FRAME_BLINKY_LEFT   ds 2
FRAME_PINKY_RIGHT   ds 2
FRAME_PINKY_LEFT    ds 2
FRAME_INKY_RIGHT    ds 2
FRAME_INKY_LEFT     ds 2
FRAME_CLYDE_LEFT    ds 2
FRAME_CLYDE_RIGHT   ds 2
FRAME_GHOST_BLUE    ds 2
FRAME_GHOST_WHITE   ds 2
FRAME_CHERRY        ds 1
FRAME_STRAWBERRY    ds 1
FRAME_ORANGE        ds 1
FRAME_PRETZEL       ds 1
FRAME_APPLE         ds 1
FRAME_PEAR          ds 1
FRAME_BANANA        ds 1
FRAME_HEART         ds 1
FRAME_GRENADE       ds 1
FRAME_SHIP          ds 1
FRAME_BELL          ds 1
FRAME_KEY           ds 1
FRAME_BIRD_LEFT     ds 3
FRAME_BIRD_RIGHT    ds 3
FRAME_BOOM          ds 6
	dend

	dum 0
LOGIC_MSPAC_RIGHT  db 1
LOGIC_MSPAC_LEFT   db 1
LOGIC_PAC_RIGHT    db 1
LOGIC_PAC_LEFT     db 1
LOGIC_GHOST_LEFT   db 1
LOGIC_GHOST_RIGHT  db 1
LOGIC_GHOST_ZOMBIE db 1
LOGIC_FRUIT        db 1
LOGIC_EXPLODE      db 1
	dend

;------------------------------------------------------------------------------
; Borrow some stuff from Xmas Demo
;------------------------------------------------------------------------------
		mx %11

; lower this number, if you want to reserve some sprites
; for things outside this system
MAX_NUM_SPRITES = 64
SPRITE_SPAWN_TIME = 7 ; 8x per second

;------------------------------------------------------------------------------
; Define some structures
;------------------------------------------------------------------------------
; My own copy of the hardware sprite structure
		dum 0
vky_sp_ctrl ds 1
vky_sp_addy ds 3
vky_sp_posx ds 2
vky_sp_posy ds 2
		dend


;------------------------------------------------------------------------------
; structure for our sprite object

			dum 0
spr_number 	ds 1    ; which hardware sprite are we using

spr_glyph   ds 1    ; which sprite #
spr_size    ds 1    ; which sprite size
spr_type    ds 1    ; which sprite logic
spr_logic   ds 1    ; temp space
spr_anim    ds 2    ;

spr_xpos    ds 3    ; 16.8 fixed point
spr_ypos    ds 3	; 16.8 fixed point

spr_vel_x   ds 2	; 8.8 fixed point
spr_vel_y   ds 2    ; 8.8 fixed point

sizeof_spr  ds 0
			dend
;------------------------------------------------------------------------------
; Values from XMAS Demo for physics on the Letters
GRAVITY = $14    ;$29       ; 9.8/60
;WIND    = $14   	; about half gravity?
WIND    = 5   	; about half gravity?


;
;  I know this way of doing isn't the best for 6502
;
sprites_ram ds MAX_NUM_SPRITES*sizeof_spr

;
; pointers to our high level objects
;
sprites_obj_addresses
]start = 0
		lup MAX_NUM_SPRITES
		da sprites_ram+{]start*sizeof_spr}
]start = ]start+1
		--^
;
; pointers to the hardware
;
hw_sprites_obj_addresses
]start = 0
		lup MAX_NUM_SPRITES
		da VKY_SP0_CTRL+{]start*8}
]start = ]start+1
		--^

; Sprite allocator memory
num_available_sprites db MAX_NUM_SPRITES

available_sprites
		lup MAX_NUM_SPRITES
		db ]no
]no = ]no+1
		--^
;
; Track the living sprites, so we can just apply physics to them
; and detect when they "die"
;
in_use_sprites_count db 0
in_use_sprites ds MAX_NUM_SPRITES


;------------------------------------------------------
AddActiveSprite
			ldx in_use_sprites_count
			sta in_use_sprites,x
			inx
			stx in_use_sprites_count
			rts

;
; Decompress the f6font
;
InitSpriteFont

		lda io_ctrl
		pha

;------- disable the sprites, for the moment

		stz io_ctrl

		ldx #0
]lp 	stz VKY_SP0_CTRL,x
		stz VKY_SP0_CTRL+256,x
		dex
		bne ]lp

;--------------------------------------------

		pla
		sta io_ctrl

		rts

;------------------------------------------------------------------------------		
;
; Return A with the sprite object number
;  c = 0 success
;  c = 1 fail
;
AllocSprite
		lda num_available_sprites
		bne :lets_go
		sec
		rts
:lets_go
		tax
		dex
		stx num_available_sprites ; book keeping

		; grab the next one
		lda available_sprites,x
		clc
		rts

;-----------------------------------------------------------------------------
;
; Call with A as the sprite index to free up
; Do me a favor, and don't call this when you shouldn't
; or with invalid data
;
FreeSprite
		ldx num_available_sprites
		cpx #MAX_NUM_SPRITES
		bcc :run
		; It's bad if we hit this, don't do it!
		rts
:run
		sta available_sprites,x
		inx
		stx num_available_sprites

		rts
;------------------------------------------------------------------------------
; A = enemy number
; temp0 = enemy X position
SpawnEnemy

:pSprite = temp0
:pHW     = temp0+2

		jsr AllocSprite
		bcc :good2go

		; oh no, we couldn't get a sprite
		rts

:good2go

		pha
		jsr GetSpriteObjPtr     ; our fancy object structure
		stax :pSprite

		pla
		pha

		jsr GetSpriteHWPtr		; hardware sprite

		stax :pHW

		pla
		pha
		sta (:pSprite)  ; spr_number 
		ldy #1

		ldx spawn_no    ; which sprite #
		lda sprite_to_frame_table,x
		sta (:pSprite),y
		iny

		lda spawn_size  	; needed so we grab the correct sprite address for each frame
		sta (:pSprite),y
		iny

		ldx spawn_no
		lda sprite_to_logic_table,x
		;lda #LOGIC_FRUIT    ; logic $$TODO fetch from table, base on the glyph
		sta (:pSprite),y
		iny

		cmp #LOGIC_FRUIT
		bne :not_fruit

		lda |VKY_RNDL
		and #$F
		sec
		sbc #7  		  ; spr_logic
		sta (:pSprite),y  ; wind direction
		iny
		bra :wefruit


:not_fruit
		lda #0 				; spr_logic
		sta (:pSprite),y
		iny
:wefruit
		lda #0 				; spr_anim
		sta (:pSprite),y
		iny
		sta (:pSprite),y
		iny

		lda #0
		sta (:pSprite),y	; x fraction
		iny
		lda spawn_x   		; x position
		sta (:pSprite),y
		iny
		lda spawn_x+1   	; x high
		sta (:pSprite),y
		iny

		lda #0				; y fraction
		sta (:pSprite),y
		iny
		lda #32
		sta (:pSprite),y    ; y position
		iny
		sta (:pSprite),y    ; y high

		; velocity

		lda #0				; vel x
		sta (:pSprite),y
		iny
		sta (:pSprite),y    ; vel x m
		iny
		sta (:pSprite),y    ; vel x high

		lda #0				; vel y
		sta (:pSprite),y
		iny
		sta (:pSprite),y    ; vel y m
		iny
		sta (:pSprite),y    ; vel y high

		; we did it!
		pla
		jsr AddActiveSprite

		lda spawn_size
		and #3				; clamp to 4 sizes
		tax
		lda obj_size_table,x ; get the right size here
		sta (:pHW)
		ldy #1

		; need to take sprite_no x size
		; and add it to the base address of the sprite
		; sheet
		phy
		ldx spawn_no
		lda sprite_to_frame_table,x
		tax
		lda spawn_size
		and #3
		jsr GetFrame
		ply

		lda pSpriteFrame
		sta (:pHW),y
		iny
		lda pSpriteFrame+1
		sta (:pHW),y
		iny

		lda pSpriteFrame+2
		sta (:pHW),y
		iny

		lda spawn_x
		sta (:pHW),y
		iny
		lda spawn_x+1
		sta (:pHW),y
		iny
		lda #0
		sta (:pHW),y
		iny
		sta (:pHW),y
		iny

		rts

;------------------------------------------------------------------------------		
;
; Service the Sprite Font Show
;
; This assumes we get called once per frame
;
ShowSpriteFont
FramePump

		jsr MoveSprites

		rts

;----------------------------------------------------------------------
;    A = hw sprite number
; Output:
;   AX = pointer
GetSpriteHWPtr
		asl
		tay
		lda hw_sprites_obj_addresses+1,y
		tax
		lda hw_sprites_obj_addresses,y
		rts

;----------------------------------------------------------------------
; Input: 
;    A = spriteobj number
; Output:
;   AX = pointer to sprite structure
;
GetSpriteObjPtr
		asl
		tay
		lda sprites_obj_addresses+1,y
		tax
		lda sprites_obj_addresses,y
		rts

;------------------------------------------------------------------------------
;
; Apply Physics to Active Sprites
;
MoveSprites

		lda io_ctrl
		pha

		stz io_ctrl

		ldx in_use_sprites_count
		beq :done
		dex
]loop   lda in_use_sprites,x

		phx
		pha
		jsr UpdateSprite
		pla
		bcc :happy
		; c=1 - the sprite has died

		jsr FreeSprite

		plx
		phx

		ldy in_use_sprites_count
		dey
		sty in_use_sprites_count
		beq :happy

		lda in_use_sprites,y
		sta in_use_sprites,x

:happy
		plx


		dex
		bpl ]loop

:done
		pla
		sta io_ctrl

		rts


;------------------------------------------------------------------------------
;
; Apply Physics to an Active Sprite
;
UpdateSprite

:pSprite = temp0
:pHW     = temp0+2
:vx      = temp1
:vy      = temp2

:xpos    = temp3
:ypos    = temp4


		pha
		jsr GetSpriteObjPtr
		stax :pSprite

		pla
		jsr GetSpriteHWPtr ; we get to initialize hw, so we don't have update it all the time
		stax :pHW

		; adjust sprite velocity

		ldy #spr_type
		lda (:pSprite),y
		asl
		tax
		jmp (:logic,x)

:logic
		da :mspac_right
		da :mspac_left
		da :pac_right
		da :pac_left
		da :ghost_left
		da :ghost_right
		da :ghost_zombie
		da :fruit
		da :explode

:explode      
		stz :vx
		stz :vx+1
		stz :vx+2

		stz :vy
		stz :vy+1
		stz :vy+2

		ldy #spr_logic
		lda (:pSprite),y
		inc
		sta (:pSprite),y
		cmp #5
		bcc :skip_explode_anim

		lda #0   			; reset timer
		sta (:pSprite),y

		ldy #spr_glyph
		lda (:pSprite),y
		cmp #FRAME_BOOM+5
		bcc :update_anim

		lda #>512  ; which will be 2
		ldy #spr_ypos+2
		sta (:pSprite),y	; this will trigger, destruction, by moving off the bottom of the screen

:update_anim
		inc
		sta (:pSprite),y
		; look up the sprite frame
		tax
		; update the hardware
		ldy #spr_size
		lda (:pSprite),y
		jsr GetFrame

		ldy #1   		; get the hardware frame updated
		lda pSpriteFrame
		sta (:pHW),y
		iny
		lda pSpriteFrame+1
		sta (:pHW),y
		iny
		lda pSpriteFrame+2
		sta (:pHW),y

:skip_explode_anim
		jmp :doPhysics

:mspac_right
		ldy #spr_size
		lda (:pSprite),y
		inc
		stz <:vx
		lda #1
		sta <:vx+1
		stz <:vx+2

		stz <:vy
		sta <:vy+1
		stz <:vy+2

		ldy #spr_logic
		lda (:pSprite),y
		inc
		sta (:pSprite),y
		cmp #4
		bcc :skip_ms_anim_right
		; increment frame
		lda #0
		sta (:pSprite),y

		ldy #spr_glyph
		lda (:pSprite),y
		inc
		cmp #FRAME_MSPAC_RIGHT+3
		bcc :ms_pac_frame_ok
		lda #FRAME_MSPAC_RIGHT
:ms_pac_frame_ok
		sta (:pSprite),y

		; look up the sprite frame
		tax
		; update the hardware
		ldy #spr_size
		lda (:pSprite),y
		jsr GetFrame

		ldy #1   		; get the hardware frame updated
		lda pSpriteFrame
		sta (:pHW),y
		iny
		lda pSpriteFrame+1
		sta (:pHW),y
		iny
		lda pSpriteFrame+2
		sta (:pHW),y

:skip_ms_anim_right

		; if ms pac is off the side of the screen, lets move her over

		ldy #spr_xpos
		lda (:pSprite),y
		sta :xpos
		iny
		lda (:pSprite),y
		sta :xpos+1
		iny
		lda (:pSprite),y
		sta :xpos+2

		ldax :xpos+1
		cmpax #352
		bcc :no_ms_pac_warp_right

		; time to warp
		;ldy #spr_ypos
		;lda (:pSprite),y
		;sta :ypos
		;iny
		;lda (:pSprite),y
		;sta :ypos+1
		;iny
		;lda (:pSprite),y
		;sta :ypos+2

		; zero out x
		lda #0
		ldy #spr_xpos
		sta (:pSprite),y
		iny
		sta (:pSprite),y
		iny
		sta (:pSprite),y
		iny

		; adjust y
		;ldy #spr_size
		;lda (:pSprite),y
		;tax
		;lda sprite_size_pixels,x

		;clc
		;adc :ypos+1
		;sta :ypos+1
		;lda :ypos+2
		;adc #0
		;sta :ypos+2
		
		;ldy #spr_ypos+1
		;lda :ypos+1
		;sta (:pSprite),y
		;iny
		;lda :ypos+2
		;sta (:pSprite),y

:no_ms_pac_warp_right
		jmp :doPhysics

:mspac_left

		stz <:vx
		lda #-1
		sta <:vx+1
		sta <:vx+2

		lda #1
		stz <:vy
		sta <:vy+1
		stz <:vy+2

		ldy #spr_logic
		lda (:pSprite),y
		inc
		sta (:pSprite),y
		cmp #4
		bcc :skip_ms_anim_left
		; increment frame
		lda #0
		sta (:pSprite),y

		ldy #spr_glyph
		lda (:pSprite),y
		inc
		cmp #FRAME_MSPAC_LEFT+3
		bcc :mspac_frame_okl
		lda #FRAME_MSPAC_LEFT
:mspac_frame_okl
		sta (:pSprite),y

		; look up the sprite frame
		tax
		; update the hardware
		ldy #spr_size
		lda (:pSprite),y
		jsr GetFrame

		ldy #1   		; get the hardware frame updated
		lda pSpriteFrame
		sta (:pHW),y
		iny
		lda pSpriteFrame+1
		sta (:pHW),y
		iny
		lda pSpriteFrame+2
		sta (:pHW),y

:skip_ms_anim_left

		; if ms pac is off the side of the screen, lets move her over

		ldy #spr_xpos+2
		lda (:pSprite),y
		bpl :no_ms_pac_warp_left

		; Warp the xposition
		ldy #spr_xpos+1
		lda #<352
		sta (:pSprite),y
		iny
		lda #>352
		sta (:pSprite),y

:no_ms_pac_warp_left

		jmp :doPhysics

:pac_right

		ldy #spr_size
		lda (:pSprite),y
		inc
		stz <:vx
		lda #1
		sta <:vx+1
		stz <:vx+2

		stz <:vy
		sta <:vy+1
		stz <:vy+2

		ldy #spr_logic
		lda (:pSprite),y
		inc
		sta (:pSprite),y
		cmp #4
		bcc :skip_pac_anim_right
		; increment frame
		lda #0
		sta (:pSprite),y

		ldy #spr_glyph
		lda (:pSprite),y
		inc
		cmp #FRAME_PAC_RIGHT+3
		bcc :pac_frame_ok
		lda #FRAME_PAC_RIGHT
:pac_frame_ok
		sta (:pSprite),y

		; look up the sprite frame
		tax
		; update the hardware
		ldy #spr_size
		lda (:pSprite),y
		jsr GetFrame

		ldy #1   		; get the hardware frame updated
		lda pSpriteFrame
		sta (:pHW),y
		iny
		lda pSpriteFrame+1
		sta (:pHW),y
		iny
		lda pSpriteFrame+2
		sta (:pHW),y

:skip_pac_anim_right

		; if ms pac is off the side of the screen, lets move her over

		ldy #spr_xpos
		lda (:pSprite),y
		sta :xpos
		iny
		lda (:pSprite),y
		sta :xpos+1
		iny
		lda (:pSprite),y
		sta :xpos+2

		ldax :xpos+1
		cmpax #352
		bcc :no_pac_warp_right

		; zero out x
		lda #0
		ldy #spr_xpos
		sta (:pSprite),y
		iny
		sta (:pSprite),y
		iny
		sta (:pSprite),y
		iny

:no_pac_warp_right
		jmp :doPhysics

:pac_left

		stz <:vx
		lda #-1
		sta <:vx+1
		sta <:vx+2

		lda #1
		stz <:vy
		sta <:vy+1
		stz <:vy+2

		ldy #spr_logic
		lda (:pSprite),y
		inc
		sta (:pSprite),y
		cmp #4
		bcc :skip_pac_anim_left
		; increment frame
		lda #0
		sta (:pSprite),y

		ldy #spr_glyph
		lda (:pSprite),y
		inc
		cmp #FRAME_PAC_CLOSED+3
		bcc :pac_frame_okl
		lda #FRAME_PAC_CLOSED
:pac_frame_okl
		sta (:pSprite),y

		; look up the sprite frame
		tax
		; update the hardware
		ldy #spr_size
		lda (:pSprite),y
		jsr GetFrame

		ldy #1   		; get the hardware frame updated
		lda pSpriteFrame
		sta (:pHW),y
		iny
		lda pSpriteFrame+1
		sta (:pHW),y
		iny
		lda pSpriteFrame+2
		sta (:pHW),y

:skip_pac_anim_left

		; if ms pac is off the side of the screen, lets move her over

		ldy #spr_xpos+2
		lda (:pSprite),y
		bpl :no_pac_warp_left

		; Warp the xposition
		ldy #spr_xpos+1
		lda #<352
		sta (:pSprite),y
		iny
		lda #>352
		sta (:pSprite),y

:no_pac_warp_left

		jmp :doPhysics

:ghost_left

		stz <:vx
		lda #-1
		sta <:vx+1
		sta <:vx+2

		lda #1
		stz <:vy
		sta <:vy+1
		stz <:vy+2

		ldy #spr_logic
		lda (:pSprite),y
		inc
		sta (:pSprite),y
		cmp #8
		bcc :skip_ghost_anim_left
		; increment frame
		lda #0
		sta (:pSprite),y

		ldy #spr_glyph
		lda (:pSprite),y
		eor #1  			; 2 frame toggle
		sta (:pSprite),y

		; look up the sprite frame
		tax
		; update the hardware
		ldy #spr_size
		lda (:pSprite),y
		jsr GetFrame

		ldy #1   		; get the hardware frame updated
		lda pSpriteFrame
		sta (:pHW),y
		iny
		lda pSpriteFrame+1
		sta (:pHW),y
		iny
		lda pSpriteFrame+2
		sta (:pHW),y

:skip_ghost_anim_left

		; if is off the side of the screen, lets move her over

		ldy #spr_xpos+2
		lda (:pSprite),y
		bpl :no_ghost_warp_left

		; Warp the xposition
		ldy #spr_xpos+1
		lda #<352
		sta (:pSprite),y
		iny
		lda #>352
		sta (:pSprite),y

:no_ghost_warp_left
		jmp :doPhysics


:ghost_right

		ldy #spr_size
		lda (:pSprite),y
		inc
		stz <:vx
		lda #1
		sta <:vx+1
		stz <:vx+2

		stz <:vy
		sta <:vy+1
		stz <:vy+2

		ldy #spr_logic
		lda (:pSprite),y
		inc
		sta (:pSprite),y
		cmp #8
		bcc :skip_ghost_anim_right
		; increment frame
		lda #0
		sta (:pSprite),y

		ldy #spr_glyph
		lda (:pSprite),y
		eor #1             ; 2 frame toggle
		sta (:pSprite),y

		; look up the sprite frame
		tax
		; update the hardware
		ldy #spr_size
		lda (:pSprite),y
		jsr GetFrame

		ldy #1   		; get the hardware frame updated
		lda pSpriteFrame
		sta (:pHW),y
		iny
		lda pSpriteFrame+1
		sta (:pHW),y
		iny
		lda pSpriteFrame+2
		sta (:pHW),y

:skip_ghost_anim_right

		; if ms pac is off the side of the screen, lets move her over

		ldy #spr_xpos
		lda (:pSprite),y
		sta :xpos
		iny
		lda (:pSprite),y
		sta :xpos+1
		iny
		lda (:pSprite),y
		sta :xpos+2

		ldax :xpos+1
		cmpax #352
		bcc :no_ghost_warp_right

		; zero out x
		lda #0
		ldy #spr_xpos
		sta (:pSprite),y
		iny
		sta (:pSprite),y
		iny
		sta (:pSprite),y
		iny

:no_ghost_warp_right


		jmp :doPhysics

:ghost_zombie
:fruit
		; apply wind
		ldy #spr_logic
		lda (:pSprite),y
		bpl :east
		; west
		eor #$FF
		dec
		and #$7 			; shouldn't need this
		sta :ww+1			; self mod code
		ldy #spr_vel_x
		sec
		lda (:pSprite),y
:ww		sbc #WIND
		sta <:vx
		iny
		lda (:pSprite),y
		sbc #0
		sta <:vx+1

		bra :do_gravity

:east
		sta :ew+1  ; self mod code

		ldy #spr_vel_x
		clc
		lda (:pSprite),y
:ew		adc #WIND
		sta <:vx
		iny
		lda (:pSprite),y
		adc #0
		sta <:vx+1
		; fall through to gravity
:do_gravity
		; apply gravity
		ldy #spr_vel_y
		clc
		lda (:pSprite),y
		adc #GRAVITY
		;sta (:pSprite),y
		sta <:vy
		iny
		lda (:pSprite),y
		adc #0
		;sta (:pSprite),y
		sta <:vy+1

		; adjust sprite positions

		; sign extend vx
		stz :vx+2
		lda :vx+1
		bpl :no_adj
		dec :vx+2
:no_adj

		; sign extend vy
		stz :vy+2
		lda :vy+1
		bpl :no_ady
		dec :vy+2
:no_ady

		; Get new sprite positions
:doPhysics
		; copy x into local
		ldy #spr_xpos
		lda (:pSprite),y
		sta :xpos
		iny
		lda (:pSprite),y
		sta :xpos+1
		iny
		lda (:pSprite),y
		sta :xpos+2

		ldy #spr_ypos
		lda (:pSprite),y
		sta :ypos
		iny
		lda (:pSprite),y
		sta :ypos+1
		iny
		lda (:pSprite),y
		sta :ypos+2

		; do the physics math
		clc
		lda :xpos
		adc :vx
		sta :xpos
		lda :xpos+1
		adc :vx+1
		sta :xpos+1
		lda :xpos+2
		adc :vx+2
		sta :xpos+2

		clc
		lda :ypos
		adc :vy
		sta :ypos
		lda :ypos+1
		adc :vy+1
		sta :ypos+1
		lda :ypos+2
		adc :vy+2
		sta :ypos+2

; Here's our chance to bounds check, and adjust velocity
; also we can detect destruction here

		ldax :ypos+1
		cmpax #240+32  ; bottom of the screen
		bcc :y_remains_good

		; sprite is dead now
		; c=1, important for the kill
		jmp :kill_sprite


		do 0
		ldax #240 		; clamp
		stax :ypos+1
		stz  :ypos

		; I think Dagen says this is better
		; cut vy in half
		lda :vy+2
		cmp #$80
		ror
		sta :vy+2
		ror :vy+1
		ror :vy 

		; negate vy
		lda :vy
		eor #$ff
		sta :vy
		lda :vy+1
		eor #$ff
		sta :vy+1
		lda :vy+2
		eor #$ff
		sta :vy+2

		inc :vy
		bne :done_negate
		inc :vy+1
		bne :done_negate
		inc :vy+2

:done_negate
		fin

:y_remains_good

		; copy local x back into the object
		ldy #spr_xpos
		lda :xpos
		sta (:pSprite),y
		iny
		lda :xpos+1
		sta (:pSprite),y
		iny
		lda :xpos+2
		sta (:pSprite),y

		ldy #spr_ypos
		lda :ypos
		sta (:pSprite),y
		iny
		lda :ypos+1
		sta (:pSprite),y
		iny
		lda :ypos+2
		sta (:pSprite),y

		; copy the vx and vy back into the object
		ldy #spr_vel_x
		lda <:vx
		sta (:pSprite),y
		iny
		lda <:vx+1
		sta (:pSprite),y

		ldy #spr_vel_y
		lda <:vy
		sta (:pSprite),y
		iny
		lda <:vy+1
		sta (:pSprite),y


		; update the hardware sprite
		ldy #vky_sp_posx
		lda :xpos+1
		sta (:pHW),y
		iny
		lda :xpos+2
		sta (:pHW),y

		ldy #vky_sp_posy
		lda :ypos+1
		sta (:pHW),y
		iny
		lda :ypos+2
		sta (:pHW),y

; Check to see if we need to kill this sprite

		lda :xpos+2
		bmi :kill_sprite
		clc
		rts

:kill_sprite
		lda #0
		sta (:pHW) ; disable the hardware
		sec
		rts

;------------------------------------------------------------------------------
obj_size_table
		db %01100001  ; 8x8
		db %01000001  ; 16x16
		db %00100001  ; 24x24
		db %00000001  ; 32x32

pix_size_table
		db 8
		db 16
		db 24
		db 32

sprite_to_frame_table
		db FRAME_MSPAC_RIGHT
		db FRAME_MSPAC_LEFT
		db FRAME_PAC_RIGHT
		db FRAME_PAC_LEFT
		db FRAME_BLINKY_RIGHT
		db FRAME_BLINKY_LEFT
		db FRAME_PINKY_RIGHT
		db FRAME_PINKY_LEFT
		db FRAME_INKY_RIGHT
		db FRAME_INKY_LEFT
		db FRAME_CLYDE_RIGHT
		db FRAME_CLYDE_LEFT
		db FRAME_GHOST_BLUE
		db FRAME_GHOST_WHITE
		db FRAME_CHERRY
		db FRAME_STRAWBERRY
		db FRAME_ORANGE
		db FRAME_PRETZEL
		db FRAME_APPLE
		db FRAME_PEAR
		db FRAME_BANANA
		db FRAME_HEART
		db FRAME_GRENADE
		db FRAME_SHIP
		db FRAME_BELL
		db FRAME_KEY
		db FRAME_BOOM

;LOGIC_MSPAC_RIGHT  db 1
;LOGIC_MSPAC_LEFT   db 1
;LOGIC_PAC_RIGHT    db 1
;LOGIC_PAC_LEFT     db 1
;LOGIC_GHOST_LEFT   db 1
;LOGIC_GHOST_RIGHT  db 1
;LOGIC_GHOST_ZOMBIE db 1
;LOGIC_FRUIT        db 1
;LOGIC_EXPLODE      db 1

sprite_to_logic_table
		db LOGIC_MSPAC_RIGHT   ;FRAME_MSPAC_RIGHT
		db LOGIC_MSPAC_LEFT    ;FRAME_MSPAC_LEFT
		db LOGIC_PAC_RIGHT     ;FRAME_PAC_RIGHT
		db LOGIC_PAC_LEFT      ;FRAME_PAC_LEFT
		db LOGIC_GHOST_RIGHT   ;FRAME_BLINKY_RIGHT
		db LOGIC_GHOST_LEFT    ;FRAME_BLINKY_LEFT
		db LOGIC_GHOST_RIGHT   ;FRAME_PINKY_RIGHT
		db LOGIC_GHOST_LEFT    ;FRAME_PINKY_LEFT
		db LOGIC_GHOST_RIGHT   ;FRAME_INKY_RIGHT
		db LOGIC_GHOST_LEFT    ;FRAME_INKY_LEFT
		db LOGIC_GHOST_LEFT    ;FRAME_CLYDE_LEFT
		db LOGIC_GHOST_RIGHT   ;FRAME_CLYDE_RIGHT
		db LOGIC_GHOST_ZOMBIE  ;FRAME_GHOST_BLUE
		db LOGIC_GHOST_ZOMBIE  ;FRAME_GHOST_WHITE
		db LOGIC_FRUIT         ;FRAME_CHERRY
		db LOGIC_FRUIT         ;FRAME_STRAWBERRY
		db LOGIC_FRUIT         ;FRAME_ORANGE
		db LOGIC_FRUIT         ;FRAME_PRETZEL
		db LOGIC_FRUIT         ;FRAME_APPLE
		db LOGIC_FRUIT         ;FRAME_PEAR
		db LOGIC_FRUIT         ;FRAME_BANANA
		db LOGIC_FRUIT         ;FRAME_HEART
		db LOGIC_FRUIT         ;FRAME_GRENADE
		db LOGIC_FRUIT         ;FRAME_SHIP
		db LOGIC_FRUIT         ;FRAME_BELL
		db LOGIC_FRUIT         ;FRAME_KEY
		db LOGIC_EXPLODE       ;FRAME_BOOM

sprite_sheet_table_lo
		db sprite_sheet8
		db sprite_sheet16
		db sprite_sheet24
		db sprite_sheet32

sprite_sheet_table_med
		db >sprite_sheet8
		db >sprite_sheet16
		db >sprite_sheet24
		db >sprite_sheet32

sprite_sheet_table_hi
		db ^sprite_sheet8
		db ^sprite_sheet16
		db ^sprite_sheet24
		db ^sprite_sheet32

sprite_size_pixels
		db 8
		db 16
		db 24
		db 32

;------------------------------------------------------------------------------
; pre compute sprite addresses, so I don't have to do math
sprite_addy8_lo
]var = $38000 ;sprite_sheet8
		lup 256
		db ]var
]var = ]var+$40
		--^
sprite_addy8_med
]var = $38000 ;sprite_sheet8
		lup 256
		db >]var
]var = ]var+$40
		--^
sprite_addy8_hi
]var = $38000 ;sprite_sheet8
		lup 256
		db ^]var
]var = ]var+$40
		--^

;------------------------------------------------------------------------------

sprite_addy16_lo
]var = $30000 ;sprite_sheet16
		lup 256
		db ]var
]var = ]var+$100
		--^

sprite_addy16_med
]var = $30000 ;sprite_sheet16
		lup 256
		db >]var
]var = ]var+$100
		--^

sprite_addy16_hi
]var = $30000 ;sprite_sheet16
		lup 256
		db ^]var
]var = ]var+$100
		--^

;------------------------------------------------------------------------------

sprite_addy24_lo
]var = $20000 ;sprite_sheet24
		lup 256
		db ]var
]var = ]var+$240
		--^
sprite_addy24_med
]var = $20000 ;sprite_sheet24
		lup 256
		db >]var
]var = ]var+$240
		--^
sprite_addy24_hi
]var = $20000 ;sprite_sheet24
		lup 256
		db ^]var
]var = ]var+$240
		--^

;------------------------------------------------------------------------------

sprite_addy32_lo
]var = $10000 ;sprite_sheet32
		lup 256
		db ]var
]var = ]var+$400
		--^
sprite_addy32_med
]var = $10000 ;sprite_sheet32
		lup 256
		db >]var
]var = ]var+$400
		--^
sprite_addy32_hi
]var = $10000 ;sprite_sheet32
		lup 256
		db ^]var
]var = ]var+$400
		--^
;------------------------------------------------------------------------------
;
; use spawn_no, and spawn_size
; to return frame address
;
; A = size
; X = frame #
; 
GetFrame
	phy
	;txy
	phx
	ply

	and #3
	asl 
	tax
	jmp (:table,x)

:table
	da :do8
	da :do16
	da :do24
	da :do32

:do8
	lda sprite_addy8_lo,y
	sta pSpriteFrame
	lda sprite_addy8_med,y
	sta pSpriteFrame+1
	lda sprite_addy8_hi,y
	sta pSpriteFrame+2

	ply
	rts

:do16
	lda sprite_addy16_lo,y
	sta pSpriteFrame
	lda sprite_addy16_med,y
	sta pSpriteFrame+1
	lda sprite_addy16_hi,y
	sta pSpriteFrame+2

	ply
	rts

:do24
	lda sprite_addy24_lo,y
	sta pSpriteFrame
	lda sprite_addy24_med,y
	sta pSpriteFrame+1
	lda sprite_addy24_hi,y
	sta pSpriteFrame+2

	ply
	rts

:do32
	lda sprite_addy32_lo,y
	sta pSpriteFrame
	lda sprite_addy32_med,y
	sta pSpriteFrame+1
	lda sprite_addy32_hi,y
	sta pSpriteFrame+2

	ply
	rts

;------------------------------------------------------------------------------
