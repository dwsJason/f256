PIXEL_DATA_TEST5 = PIXEL_DATA+320*240
PIXEL_DATA_TEST4 = PIXEL_DATA+320*192
PIXEL_DATA_TEST3 = PIXEL_DATA+320*144
PIXEL_DATA_TEST2 = PIXEL_DATA+320*96
PIXEL_DATA_TEST1 = PIXEL_DATA+320*48

** ZERO PAGE / DIRECT PAGE AREA
ptr0    = $20
ptr1    = $22
ptr2    = $24
ptr3    = $26
ptr4    = $28
ptr5    = $2A
ptr6    = $2C
ptr7    = $2E
scratch = $80 ; to $8F?  I dunno.. just use ZP if ya like



        
IntroPix    mx %11    
        jsr BlackoutClut   
        jsr introinit320x240
        _ClutToColor #$00;#$22;#$FF
        jsr TermInit
        _TermPuts txt_intro_0
        jsr mmu_unlock


        _SetIntroImgOffset PIXEL_DATA_TEST5 ; DEBUG STUFF - set image offset to bottom

        _TermPuts txt_intro_1
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

        _TermPuts txt_intro_2
                                ; DEBUG - read/write addresses for pixel data 
        ; jsr get_read_address  
   		; jsr TermPrintAXYH
        ; _TermCR
        ;
        ; jsr get_write_address
        ; jsr TermPrintAXYH
        ; _TermCR
        
        jsr decompress_pixels

        _TermPuts txt_intro_3
        
        
        php


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

* clut in a - final color table ptr in x/y
* return carry clear = all done
* return carry set   = more fades left
FadeClutToClutPtrXy
        stx ptr0        ; setup all our pointers
        sty ptr0+1
        jsr SetClutPtrs ; sets ptr1-ptr4
                        ; but in this case we only use ptr1 and 
                        ; work our way through each value 1 by 1


        lda #1
        sta _fctcpxy_not_done ; tracks doneness - zero will trigger more work
                              ; one means it IS done
        


_fctcpxy_not_done db 0 


* clut in a - sets series of ptr4-ptr7 
SetClutPtrs
        tax
        tax ; clut
        lda ClutTblL,x
        sta ptr4        ; note this starts at 4, for clut 0
        sta ptr5
        sta ptr6
        sta ptr7 
        lda ClutTblH,x
        sta ptr4+1
        inc
        sta ptr5+1      ; +$100
        inc 
        sta ptr6+1      ; +$200
        inc 
        sta ptr7+1      ; +$300
        rts

ClutTblL  db <VKY_GR_CLUT_0
        db <VKY_GR_CLUT_1
        db <VKY_GR_CLUT_2
        db <VKY_GR_CLUT_3
ClutTblH db >VKY_GR_CLUT_0
        db >VKY_GR_CLUT_1
        db >VKY_GR_CLUT_2
        db >VKY_GR_CLUT_3

* a = clut  x/y = ptr to color (BGRA)
SetClutToColorPtrXY
        stx ptr0        ; setup all our pointers
        sty ptr0+1
        jsr SetClutPtrs ; sets ptr1-ptr4
        lda #1          
        sta io_ctrl     ; <--- access vicky CLUTs

        ldy #0
        lda (ptr0),y    ; B
:writeB sta (ptr4),y
        sta (ptr5),y
        sta (ptr6),y
        sta (ptr7),y
        iny
        iny
        iny
        iny
        bne :writeB

        ldy #1
        lda (ptr0),y    ; G
:writeG sta (ptr4),y
        sta (ptr5),y
        sta (ptr6),y
        sta (ptr7),y
        iny
        iny
        iny
        iny
        cpy #1
        bne :writeG

        ldy #2
        lda (ptr0),y    ; R
:writeR sta (ptr4),y
        sta (ptr5),y
        sta (ptr6),y
        sta (ptr7),y
        iny
        iny
        iny
        iny
        cpy #2
        bne :writeR

        ; we ignore "A"lpha byte, doesn't seem to matter on f256k (dgb)

        lda #2          ; <--- access text IO
        sta io_ctrl
        rts
        
; #RR;#GG;#BB
_ClutToColor MAC
        lda #]3
        sta scratch
        lda #]2
        sta scratch+1
        lda #]1
        sta scratch+2
        lda #$00
        sta scratch+3 
        lda #0          ;-- vicky clut 0
        ldx #<scratch   ;\_ ptr to color (BGRA)
        ldy #>scratch   ;/ 
        jsr SetClutToColorPtrXY
        EOM


BlackoutClut
        lda #$00
        sta scratch
        lda #$00
        sta scratch+1
        lda #$00
        sta scratch+2
        lda #$00
        sta scratch+3 
        lda #0          ;-- vicky clut 0
        ldx #<scratch   ;\_ ptr to color (BGRA)
        ldy #>scratch   ;/ 
        jmp SetClutToColorPtrXY


**** This wasn't generic but helps explain the logic of wiping a clut
* BlackoutClutOG
*         lda #1          
*         sta io_ctrl     ; <--- access vicky CLUTs
*         ; copy the clut up there
*         ldx #0
* ]lp     stz VKY_GR_CLUT_0,x
*         stz VKY_GR_CLUT_0+$100,x
*         stz VKY_GR_CLUT_0+$200,x
*         stz VKY_GR_CLUT_0+$300,x
*         dex
*         bne ]lp
*         lda #2          ; <--- access text IO
*         sta io_ctrl
*         rts


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




txt_intro_0 asc '  DreamOS v2.3 init !',0D,0D,00
txt_intro_1 asc '    - decompressing snowflakes',0D,00
txt_intro_2 asc '    - wrapping presents',0D,00
txt_intro_3 asc '    - baking cookies',0D,00

txt_intro_clut_ok asc '! CLUT  ok'
        db 13,0
