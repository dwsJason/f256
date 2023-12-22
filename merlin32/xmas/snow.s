;
; fnxMas 2023 - LET IT SNOW!!
;
; Each Snow Canvas is 960x1216, the top 16 pixels is the catalog
;                     992x1248, with padding
;
; 60 tiles wide x 76 tiles tall, I've added a 1 tile border for the vicky hardware
;
; 62 tiles wide x 78 tiles tall.
;
; It's 3 screens wide, repeating pattern, the idea is X position for center
; should be used by default, then you can scroll indefinitely / left / right
; and by adjusting coordinates we get wrapping
;
; the top 480 pixels (ignoring the first 32, because dummy row + catalog)
; are setup to repeat, so that as we scroll off the top we just add 240 to the
; vertical scroll register to get it to repeat indefinitely
;
		mx %11

;------------------------------------------------------------------------------
SnowInit

		; Decompress Backgound tilemap
		ldaxy #snow_bg
		jsr set_read_address

		ldaxy #MAP_SNOWBG
		jsr set_write_address

		jsr decompress_map

		; Decompress the ForeGround tilemap

		ldaxy #snow_fg
		jsr set_read_address

		ldaxy #MAP_SNOWFG
		jsr set_write_address

		jsr decompress_map

		; fg/bg share the same tiles
		ldaxy #snow_bg
		jsr set_read_address

		ldaxy #TILE_SNOW
		jsr set_write_address

		jsr decompress_pixels

;------------------------------------------------------------------------------
; Map Data needs some massaging

		ldaxy #MAP_SNOWBG
		jsr set_read_address

		jsr :massage_map_names

		ldaxy #MAP_SNOWFG
		jsr set_read_address

:massage_map_names
		lda mmu3		; $6000 start of map data
		inc
		sta mmu4 		; ends at $85C8

:pMap = temp0

		ldax pSource
		stax :pMap

		ldx #4836/128 ; 62*78

		ldy #0
]lp		clc
		lda (:pMap),y
		adc #<SNOW_TILE_OFFSET
		sta (:pMap),y
		iny
		lda (:pMap),y
		adc #>SNOW_TILE_OFFSET
		ora #SNOWMAP_CLUT*8			; remap clut
		sta (:pMap),y
		iny

		bne ]lp

		inc :pMap+1

		dex
		bpl ]lp

;
; Initial Snow BG positions
;
		ldax #0+SNOWMAP_SIZE_Y-240
		stax snow_bg_y+1
		stax snow_fg_y+1

		ldax #320
		stax snow_bg_x+1
		stax snow_fg_x+1

		rts

;------------------------------------------------------------------------------
;
;
;
SnowPump
		lda io_ctrl
		pha
		stz io_ctrl

; Step one, reflect registers into HW
; and pray we're in VBlank
		ldax snow_bg_x+1
		stax VKY_TM1_POS_X_L
		ldax snow_bg_y+1
		stax VKY_TM1_POS_Y_L

		ldax snow_fg_x+1
		stax VKY_TM2_POS_X_L
		ldax snow_fg_y+1
		stax VKY_TM2_POS_Y_L

;
; Now Animate the Planes, by applying some velocity to the positions
;
		sec
		lda snow_bg_y
		sbc #<SNOW_BG_VY
		sta snow_bg_y
		lda snow_bg_y+1
		sbc #>SNOW_BG_VY
		sta snow_bg_y+1
		lda snow_bg_y+2
		sbc #0
		sta snow_bg_y+2

		clc
		lda snow_bg_x
		adc #<SNOW_BG_VX
		sta snow_bg_x
		lda snow_bg_x+1
		adc #>SNOW_BG_VX
		sta snow_bg_x+1
		lda snow_bg_x+2
		adc #0
		sta snow_bg_x+2

		sec
		lda snow_fg_y
		sbc #<SNOW_FG_VY
		sta snow_fg_y
		lda snow_fg_y+1
		sbc #>SNOW_FG_VY
		sta snow_fg_y+1
		lda snow_fg_y+2
		sbc #0
		sta snow_fg_y+2

		clc
		lda snow_fg_x
		adc #<SNOW_FG_VX
		sta snow_fg_x
		lda snow_fg_x+1
		adc #>SNOW_FG_VX
		sta snow_fg_x+1
		lda snow_fg_x+2
		adc #0
		sta snow_fg_x+2



;
; Now Clamp the coordinates for perfect wrapping
;

		ldax snow_bg_y+1
		cmpax #32
		bcs :no_y_wrap
		; wrap the snow
		adc #240
		sta snow_bg_y+1
		lda snow_bg_y+2
		adc #0
		sta snow_bg_y+2
:no_y_wrap

		ldax snow_bg_x+1
		cmpax #320
		bcc :no_x_wrap
		; wrap the snow
		sbc #<320
		sta snow_bg_x+1
		lda snow_bg_x+2
		sbc #>320
		sta snow_bg_x+2
:no_x_wrap


		ldax snow_fg_y+1
		cmpax #32
		bcs :fgno_y_wrap
		; wrap the snow
		adc #240
		sta snow_fg_y+1
		lda snow_fg_y+2
		adc #0
		sta snow_fg_y+2
:fgno_y_wrap


		ldax snow_fg_x+1
		cmpax #320
		bcs :fgno_x_wrap
		; wrap the snow
		sbc #<320
		sta snow_fg_x+1
		lda snow_fg_x+2
		sbc #>320
		sta snow_fg_x+2
:fgno_x_wrap

		pla
		sta io_ctrl

		rts

snow_bg_x ds 3
snow_bg_y ds 3

snow_fg_x ds 3
snow_fg_y ds 3

;------------------------------------------------------------------------------

