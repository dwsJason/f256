;------------------------------------------------------------------------------
		mx %11


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

		pla
		sta io_ctrl

		rts


;------------------------------------------------------------------------------		





