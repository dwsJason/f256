PIXEL_DATA_TEST5 = PIXEL_DATA+320*240
PIXEL_DATA_TEST4 = PIXEL_DATA+320*192
PIXEL_DATA_TEST3 = PIXEL_DATA+320*144
PIXEL_DATA_TEST2 = PIXEL_DATA+320*96
PIXEL_DATA_TEST1 = PIXEL_DATA+320*48

        mx %11
IntroPix    jsr introinit320x240
        jsr TermInit
        _TermPuts txt_intro
        
        jsr mmu_unlock
        jsr BlackClut

        _SetIntroImgOffset PIXEL_DATA_TEST5

        
:unpack_i256
        lda #<CLUT_DATA
		ldx #>CLUT_DATA
		ldy #^CLUT_DATA
		jsr set_write_address

		ldx #1 ; picture #
		jsr set_pic_address

		jsr decompress_clut
		bcc :good
        * NOPE
		* jsr TermPrintAI   
		* _TermCR
:good   
        * _TermPuts txt_intro_clut_ok
	
        lda #<PIXEL_DATA
        ldx #>PIXEL_DATA
        ldy #^PIXEL_DATA
        jsr set_write_address

        ldx #1
        jsr set_pic_address     ; set write address to our i256 data

        jsr get_read_address
   		jsr TermPrintAXYH
        _TermCR

        jsr get_write_address
        jsr TermPrintAXYH
        _TermCR


        jsr decompress_pixels

        * _TermPuts txt_decompress
        
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
        jsr WaitShorty
        jsr WaitShorty
        jsr WaitShorty
        jsr WaitShorty
        _SetIntroImgOffset PIXEL_DATA_TEST4
        jsr WaitShorty
        _SetIntroImgOffset PIXEL_DATA_TEST3
        jsr WaitShorty
        _SetIntroImgOffset PIXEL_DATA_TEST2
        jsr WaitShorty
        _SetIntroImgOffset PIXEL_DATA_TEST1
        jsr WaitShorty
        _SetIntroImgOffset PIXEL_DATA        
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

BlackClut
 ; set access to vicky CLUTs
        lda #1
        sta io_ctrl
        ; copy the clut up there
        ldx #0
]lp     stz VKY_GR_CLUT_0,x
        stz VKY_GR_CLUT_0+$100,x
        stz VKY_GR_CLUT_0+$200,x
        stz VKY_GR_CLUT_0+$300,x
        dex
        bne ]lp

        ; set access back to text buffer, for the text stuff
        lda #2
        sta io_ctrl
        rts

* This is just for debug
_SetIntroImgOffset   mac
        stz io_ctrl
        lda #<]1
        sta $D101
        lda #>]1
        sta $D102
        lda #^]1
        sta $D103
        lda #2
        sta io_ctrl
        eom

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

WaitShorty
		ldy #$2
]wait	jsr DumbWait ; WaitVBL
		dey
		bne ]wait
		rts

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
