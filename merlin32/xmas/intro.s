
        mx %11
IntroPix    jsr introinit320x240
        jsr TermInit

        jsr mmu_unlock

        _TermPuts txt_intro

        lda #<CLUT_DATA
		ldx #>CLUT_DATA
		ldy #^CLUT_DATA
		jsr set_write_address

		ldx #1 ; picture #
		jsr set_pic_address

		jsr decompress_clut
		bcc :good

		jsr TermPrintAI
		_TermCR

:good   
        _TermPuts txt_intro_clut_ok
	
        lda #<PIXEL_DATA
        ldx #>PIXEL_DATA
        ldy #^PIXEL_DATA
        jsr set_write_address

        ldx #1
        jsr set_pic_address

        ; read + write address for pixels
        jsr get_read_address
        phx
        pha
        tya
        jsr TermPrintAH
        pla
        plx
        jsr TermPrintAXH
        lda #13
        jsr TermCOUT

        jsr get_write_address
        phx
        pha
        tya
        jsr TermPrintAH
        pla
        plx
        jsr TermPrintAXH
        lda #13
        jsr TermCOUT


        jsr decompress_pixels

        lda #<txt_decompress
        ldx #>txt_decompress
        jsr TermPUTS

        php
        sei

        ; set access to vicky CLUTs
        lda #1
        sta io_ctrl
        ; copy the clut up there
        ldx #0
]lp     lda CLUT_DATA,x
        sta VKY_GR_CLUT_0,x
        lda CLUT_DATA+$100,x
        sta VKY_GR_CLUT_0+$100,x
        lda CLUT_DATA+$200,x
        sta VKY_GR_CLUT_0+$200,x
        lda CLUT_DATA+$300,x
        sta VKY_GR_CLUT_0+$300,x
        dex
        bne ]lp

        ; set access back to text buffer, for the text stuff
        lda #2
        sta io_ctrl

        plp
        jsr Wait3Seconds
        rts



introinit320x240
        php
        sei

        ; Access to vicky generate registers
        stz io_ctrl

        ; enable the graphics mode
        lda #%00001111  ; gamma + bitmap + graphics + overlay + text
;               lda #%00000001  ; text
        sta $D000
        ;lda #%110       ; text in 40 column when it's enabled
        ;sta $D001
        stz $D001

        ; layer stuff - take from Jr manual
        stz $D002  ; layer ctrl 0
        stz $D003  ; layer ctrl 3

        ; set address of image, since image uncompressed, we just display it
        ; where we loaded it.
        lda #<PIXEL_DATA
        sta $D101
        lda #>PIXEL_DATA
        sta $D102
        lda #^PIXEL_DATA
        sta $D103

        lda #1
        sta $D100  ; bitmap enable, use clut 0
        stz $D108  ; disable
        stz $D110  ; disable

        lda #2
        sta io_ctrl
        plp

        rts


DumbWait lda #$ff
		sta _w1
]outer  lda #$ff
		sta _w2
]inner	dec _w2
		bne ]inner
		dec _w1
		bne ]outer
		rts
_w1 db 0
_w2 db 0 

Wait3Seconds
		ldy #$27
]wait	jsr DumbWait ; WaitVBL
		dey
		bne ]wait
		rts




txt_intro asc '! INTRO --------------------------------'
		db 13,0

txt_intro_clut_ok asc '! CLUT  ok'
        db 13,0
