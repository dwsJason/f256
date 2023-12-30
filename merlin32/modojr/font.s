;
;
;
		mx %11

initFont

]font_addr0 = {$C000+{$C0*8}}

		lda io_ctrl
		pha

		ldaxy #led_font
		jsr set_write_address

		lda #1
		sta io_ctrl  ; page font glyph data

		ldx #0
]loop
		lda WRITE_BLOCK,x
		sta ]font_addr0,x
		lda WRITE_BLOCK+$100,x
		sta ]font_addr0+$100,x
		dex
		bne ]loop

		pla
		sta io_ctrl

		rts

