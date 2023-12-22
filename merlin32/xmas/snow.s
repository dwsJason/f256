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

		rts

;------------------------------------------------------------------------------

SnowPump
		rts

;------------------------------------------------------------------------------

