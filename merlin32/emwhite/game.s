;
; Merlin32 Line draw example for Jr
;
; To Assemble "merlin32 -v . link.s"
;
		mx %11

io_ctrl  equ 1

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
		and #$3f
		bne main_loop

; about once per second spawn

		lda |VKY_RNDL
		and #$3F
		sta <spawn_x
		clc
		lda |VKY_RNDL
		adc <spawn_x
		sta <spawn_x
		adc #0
		sta <spawn_x+1

		lda #SPRITE_CHERRY
		sta <spawn_no

		;lda #%01000001
		lda #1
		sta <spawn_size

		jsr SpawnEnemy

:no_events

		bra main_loop

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
		plp
        rts

;------------------------------------------------------------------------------
;
; Sprite Definitions
;
;------------------------------------------------------------------------------
; Sprite Character Index Definitions

	dum 0
SPRITE_BLANK         ds 1
SPRITE_MSPAC_RIGHT   ds 3
SPRITE_MSPAC_LEFT    ds 3
SPRITE_PAC_RIGHT     ds 2
SPRITE_PAC_CLOSED    ds 1
SPRITE_PAC_LEFT      ds 2
SPRITE_BLINKY_RIGHT  ds 2
SPRITE_BLINKY_LEFT   ds 2
SPRITE_PINKY_RIGHT   ds 2
SPRITE_PINKY_LEFT    ds 2
SPRITE_INKY_RIGHT    ds 2
SPRITE_INKY_LEFT     ds 2
SPRITE_CLYDE_LEFT    ds 2
SPRITE_CLYDE_RIGHT   ds 2
SPRITE_GHOST_BLUE    ds 2
SPRITE_GHOST_WHITE   ds 2
SPRITE_CHERRY        ds 1
SPRITE_STRAWBERRY    ds 1
SPRITE_ORANGE        ds 1
SPRITE_PRETZEL       ds 1
SPRITE_APPLE         ds 1
SPRITE_PEAR          ds 1
SPRITE_BANANA        ds 1
SPRITE_HEART         ds 1
SPRITE_GRENADE       ds 1
SPRITE_SHIP          ds 1
SPRITE_BELL          ds 1
SPRITE_KEY           ds 1
SPRITE_BIRD_LEFT     ds 3
SPRITE_BIRD_RIGHT    ds 3
SPRITE_BOOM          ds 6
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

spr_xpos    ds 3    ; 16.8 fixed point
spr_ypos    ds 3	; 16.8 fixed point

spr_vel_X   ds 2	; 8.8 fixed point
spr_vel_y   ds 2    ; 8.8 fixed point

sizeof_spr  ds 0
			dend
;------------------------------------------------------------------------------
; Values from XMAS Demo for physics on the Letters
GRAVITY = $29       ; 9.8/60
WIND    = $14   	; about half gravity?


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

		lda spawn_no    ; which sprite glyph number
		sta (:pSprite),y
		iny

		lda spawn_size  	; needed so we grab the correct sprite address for each frame
		sta (:pSprite),y
		iny

		lda #LOGIC_FRUIT    ; logic $$TODO fetch from table, base on the glyph
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

		lda #%01000001  ; 16x16
		sta (:pHW)
		ldy #1

		lda #<sprite_sheet16
		sta (:pHW),y
		iny
		lda #>{sprite_sheet16+$100}
		sta (:pHW),y
		iny

		lda #^sprite_sheet16
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

		; apply wind
		ldy #spr_vel_X
		sec
		lda (:pSprite),y
		sbc #WIND
		;sta (:pSprite),y
		sta <:vx
		iny
		lda (:pSprite),y
		sbc #0
		;sta (:pSprite),y
		sta <:vx+1

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
		cmpax #240
		bcc :y_remains_good

		ldax #240 		; clamp
		stax :ypos+1
		stz  :ypos

		; I think Dagen says this is better
		do 1
		; cut vy in half
		lda :vy+2
		cmp #$80
		ror
		sta :vy+2
		ror :vy+1
		ror :vy 
		fin

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
		ldy #spr_vel_X
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


