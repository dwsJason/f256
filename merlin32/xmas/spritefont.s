;------------------------------------------------------------------------------
		mx %11

;
MAX_NUM_SPRITES = 20

; Define some structures

sprite_message 
			   asc '0123456789'
			   asc 'ABCDEFGHIJ'
			   asc 'KLMNOPQRST'
			   asc 'UVWXYZ!+-.'
			   asc '..........'
			   asc '=========='
			   asc ';;;;;;;;;;'

			   asc 'DAGEN IS COOL!!'
			   asc ' TEXT SCROLLER MESSAGE, WITH GREETZ AND ALL THAT KIND OF '
               asc 'STUFF, BECAUSE WE ARE SO LEET....'
			   db 0

SPRITE_SPAWN_TIME = 7 ; 8x per second


; My own copy of the hardware sprite structure
		dum 0
vky_sp_ctrl ds 1
vky_sp_addy ds 3
vky_sp_posx ds 2
vky_sp_posy ds 2
		dend

; structure for our sprite object

			dum 0
spr_number 	ds 1    ; which hardware sprite are we using
spr_glyph   ds 1    ; what the glyph number from the map

spr_xpos    ds 3    ; 16.8 fixed point
spr_ypos    ds 3	; 16.8 fixed point

spr_vel_X   ds 2	; 8.8 fixed point
spr_vel_y   ds 2    ; 8.8 fixed point

sizeof_spr  ds 0
			dend

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
; So we can add more life into this

MAX_TEXT_SPAWN_Y = 200

text_spawn_x dw 320+32  ; just off the right side of the screen
text_spawn_y dw MAX_TEXT_SPAWN_Y

text_up_down dw 0

;text_spawn_vx dw 0
;text_spawn_vy dw 0

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

		; Decompress the glyphs, all 32x32 in size

		ldaxy #f6font		   ; source image
		jsr set_read_address

		ldaxy #SPRITE_TILES    ; destination RAM address
		jsr set_write_address

		jsr decompress_pixels


		; Decompress the map, so we can translate characters into Glyphs

		ldaxy #f6font         ; source image
		jsr set_read_address

		ldaxy #SPRITE_MAP
		jsr set_write_address
		jsr decompress_map

		; Decompress and upload CLUT
		ldaxy #f6font         ; source image
		jsr set_read_address

		ldaxy #CLUT_DATA
		jsr set_write_address

		jsr decompress_clut

		; Copy the LUT into LUT RAM

		lda io_ctrl
		pha

		; set access to vicky CLUTs
		lda #1
		sta io_ctrl
		; copy the clut up there
		; putting it in LUT#3
		ldx #0
]lp		lda CLUT_DATA,x
		sta VKY_GR_CLUT_3,x
		lda CLUT_DATA+$100,x
		sta VKY_GR_CLUT_3+$100,x
		lda CLUT_DATA+$200,x
		sta VKY_GR_CLUT_3+$200,x
		lda CLUT_DATA+$300,x
		sta VKY_GR_CLUT_3+$300,x
		dex
		bne ]lp

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

		; start at the beginning of the message
		ldax #sprite_message
		stax p_sprite_message

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
;
; Service the Sprite Font Show
;
; This assumes we get called once per frame
;
ShowSpriteFont

		do 1
; Animate the spawn point
		lda <jiffy
		and #3
		bne :spawn_movement_done

		lda text_up_down
		beq :text_up

; text down

		lda text_spawn_y
		inc
		cmp #MAX_TEXT_SPAWN_Y
		bcc :down_ok

		lda #MAX_TEXT_SPAWN_Y
		stz text_up_down ; change to going up

:down_ok
		sta text_spawn_y
		bra :spawn_movement_done

:text_up
		lda text_spawn_y
		bne :up_ok
		inc text_up_down ; going down
		sta text_spawn_y
		bra :spawn_movement_done
:up_ok
		dec
		sta text_spawn_y

:spawn_movement_done
		fin

		jsr MoveSprites

		dec :tick
		beq :spawn
		rts
:spawn
		lda #SPRITE_SPAWN_TIME
		sta :tick

		lda (p_sprite_message)
		bne :spawn_glyph

		; we're out of message, loop the message
		ldax #sprite_message
		stax p_sprite_message

		rts

:spawn_glyph
		cmp #' '
		bne :not_a_space
		; skip spaces
		jmp :get_glyph   ; auto increment, but don't do work


:not_a_space
		jsr AllocSprite
		bcc :ok
		rts					; if we didn't get one, then do nothing
:ok

:pSprite = temp0
:pHW     = temp0+2

		pha
		jsr GetSpriteObjPtr

		stax :pSprite		; we get to initialize the object

		pla
		pha
		jsr GetSpriteHWPtr ; we get to initialize hw, so we don't have update it all the time

		stax :pHW

		; let's initialize the sprite
		pla
		sta (:pSprite)  ; spr_number

		ldy #spr_glyph
		jsr :get_glyph ; we have the ASCII CHARACTER, lets translate it into an index
		               ; we only have 60 or so possible sprites with the current setup
		sec
		sbc #' '
		cmp #60
		bcc :in_range
		lda #0			; out of range, make it blank
:in_range
		asl
		tax
		lda SPRITE_MAP,x

		sta (:pSprite),y ; spr_glyph

; SPAWN LOCATION ON THE SCREEN

		iny
		lda #0
		sta (:pSprite),y ; xpos .8
		iny
		lda text_spawn_x
		sta (:pSprite),y ; xpos lo
		iny
		lda text_spawn_x+1
		sta (:pSprite),y ; xpos hi
		iny

		lda #0
		sta (:pSprite),y ; ypos.8
		iny
		lda text_spawn_y
		sta (:pSprite),y ; ypos lo
		lda text_spawn_y+1
		iny
		sta (:pSprite),y ; ypos hi

; SPAWN VELOCITY

		lda #0
		iny
		sta (:pSprite),y ; spr_vel_x
		iny
		sta (:pSprite),y ; spr_vel_x
		iny
		sta (:pSprite),y ; spr_vel_y
		iny
		sta (:pSprite),y ; spr_vel_y

		ldy #spr_glyph
		lda (:pSprite),y
		asl
		asl
		tax ; we got this

		lda io_ctrl
		pha

		stz io_ctrl

		ldy #vky_sp_addy
		lda #0
		sta (:pHW),y
		iny
		txa
		sta (:pHW),y
		lda #^SPRITE_TILES
		iny
		sta (:pHW),y

		; we need to copy the x and y

		; load X
		ldy #spr_xpos+2
		lda (:pSprite),y
		tax
		dey
		lda (:pSprite),y
		; store X
		ldy #vky_sp_posx
		sta (:pHW),y
		iny
		txa
		sta (:pHW),y
		; load y
		ldy #spr_ypos+2
		lda (:pSprite),y
		tax
		dey
		lda (:pSprite),y

		; store y
		ldy #vky_sp_posy
		sta (:pHW),y
		iny
		txa
		sta (:pHW),y

		lda #%111  ; enable the sprite
		sta (:pHW) ; vky_sp_ctrl -> do this last

		lda (:pSprite) ; spr_number
		jsr AddActiveSprite

		pla
		sta io_ctrl

		rts

;------------------------------------------------------------------------------

:get_glyph
		lda (p_sprite_message)
		inc p_sprite_message
		bne :rts
		inc p_sprite_message+1
:rts
		rts

:tick ds 1



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


