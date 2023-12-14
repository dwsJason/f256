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

        lda #0                  ; clut 0
        jsr BlackoutClut   
        jsr introinit320x240
        _ClutToColor #$00;#$22;#$BB
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

:fade   ldx #<CLUT_DATA
        ldy #>CLUT_DATA
        lda #0 ; clut 0
        jsr FadeClutToClutPtrXy
        bcc :done
        ;jsr WaitShorty
        bra :fade

:done   ; we out - clear text  and start intro
        jsr TermClearTextBuffer

        

        jsr WaitShorty
        jsr WaitShorty
        jsr WaitShorty
        jsr WaitShorty
        jsr BounceIntroPic

        ldy #20
:sound_stoppage        jsr WaitTiny
        jsr BleepOffControl
        dey
        bne :sound_stoppage

        jsr Wait3Seconds
        lda #0
        jsr BlackoutClut
        lda #1
        jsr BlackoutClut
        lda #2
        jsr BlackoutClut
        lda #3
        rts


bounce_table_ptr = ptr0
bounce_table_val = scratch
BounceIntroPic
        lda #<bounce_table
        sta bounce_table_ptr
        lda #>bounce_table
        sta bounce_table_ptr+1
:bounce_loop
:fetchadr lda (bounce_table_ptr)
        sta bounce_table_val
        inc bounce_table_ptr
        bne :nowrap
:wrap   inc bounce_table_ptr+1 ; next page of memory
:nowrap
        lda (bounce_table_ptr) ; second byte
        sta bounce_table_val+1
        inc bounce_table_ptr
        bne :nowrap2
:wrap2  inc bounce_table_ptr+1 ; next page of memory
:nowrap2
        lda (bounce_table_ptr) ; third byte
        sta bounce_table_val+2
        inc bounce_table_ptr
        bne :nowrap3
:wrap3  inc bounce_table_ptr+1 ; next page of memory
:nowrap3
        lda bounce_table_val
        cmp #$ff
        bne :ok
        lda bounce_table_val+1
        cmp #$ff
        bne :ok
        lda bounce_table_val+2
        cmp #$ff
        bne :ok
        rts                     ; <-- return is here
:ok     
        lda bounce_table_val+1  ; sound check!
        bne :not_zero
        jsr BleepOn
        bra :cont
:not_zero 
        jsr BleepOffControl
:cont        
        stz io_ctrl
        
        lda #<PIXEL_DATA
        clc
        adc bounce_table_val
        sta $d101

        lda #>PIXEL_DATA
        clc
        adc bounce_table_val+1
        sta $d102

        lda #^PIXEL_DATA
        clc
        adc bounce_table_val+2
        sta $d103

        * _SetIntroImgOffset PIXEL_DATA        
        * stz io_ctrl
        * lda #<]1
        * sta $D101
        * lda #>]1
        * sta $D102
        * lda #^]1
        * sta $D103
        lda #2
        sta io_ctrl
        jsr WaitTiny
        bra :bounce_loop


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
        * sec
        * rts


        stx ptr0        ; setup all our pointers
        stx ptr1
        stx ptr2
        stx ptr3
        sty ptr0+1
        iny
        sty ptr1+1
        iny
        sty ptr2+1
        iny 
        sty ptr3+1

        jsr SetClutPtrs ; sets ptr4-ptr7
                        ; but in this case we only use ptr1 and 
                        ; work our way through each value 1 by 1
        

        lda #1
        sta _fctcpxy_not_done ; tracks doneness - zero will trigger more work
                              ; one means it IS done

        lda #1          
        sta io_ctrl     ; <--- access vicky CLUTs

        ; THIS IS IT!                      
        ldy #0
:cloop  
        lda (ptr4),y      ; actual palette
        cmp (ptr0),y
        beq :p0done
        stz _fctcpxy_not_done
        bcs :p0over
:p0und  inc
        bra :p0save
:p0over dec 
:p0save sta (ptr4),y
:p0done

        lda (ptr5),y      ; actual palette
        cmp (ptr1),y
        beq :p1done
        stz _fctcpxy_not_done
        bcs :p1over
:p1und  inc
        bra :p1save
:p1over dec 
:p1save sta (ptr5),y
:p1done

        lda (ptr6),y      ; actual palette
        cmp (ptr2),y
        beq :p2done
        stz _fctcpxy_not_done
        bcs :p2over
:p2und  inc
        bra :p2save
:p2over dec 
:p2save sta (ptr6),y
:p2done


        lda (ptr7),y      ; actual palette
        cmp (ptr3),y
        beq :p3done
        stz _fctcpxy_not_done
        bcs :p3over
:p3und  inc
        bra :p3save
:p3over dec 
:p3save sta (ptr7),y
:p3done



        iny
        bne :cloop


        lda #2          ; <--- access text IO
        sta io_ctrl


        lda _fctcpxy_not_done
        beq :not_done
        clc
        rts
:not_done   sec
        rts

_fctcpxy_not_done db 0 ; change to zp


* clut in a - sets series of ptr4-ptr7 
SetClutPtrs
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

* clut in a
BlackoutClut
        sta :clut+1
        lda #$00
        sta scratch
        lda #$00
        sta scratch+1
        lda #$00
        sta scratch+2
        lda #$00
        sta scratch+3 
:clut   lda #0          ;-- vicky clut 0 (SMC)
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




BleepOn 
        lda #10 
        sta _bleepcontrol

        stz io_ctrl
        lda #$F0       ; %10010000 = Channel 3 attenuation = 0
        * sta $D600    ; Send it to left PSG
        * sta $D610    ; Send it to right PSG
        sta $D608
        
        
        lda #$E6       ; %11100100 = white noise, f = C/512
        * sta $D600    ; Send it to left PSG
        * sta $D610    ; Send it to right PSG
        sta $D608
        lda #2
        sta io_ctrl
        rts

BleepOffControl
        lda _bleepcontrol
        beq :off
        dec _bleepcontrol
        beq :off
        rts
:off    jmp BleepOff

BleepOff        
        stz io_ctrl
        lda #$FF
        * sta $D600    ; Send it to left PSG
        * sta $D610    ; Send it to right PSG
        sta $D608
        lda #2
        sta io_ctrl
        rts

_bleepcontrol db 0


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

WaitTiny lda #$10
        sta _w1
]outer  lda #$ff
        sta _w2
]inner	dec _w2
        bne ]inner
        dec _w1
        bne ]outer
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




txt_intro_0 asc ' ',0D,0D,'    DreamOS v2.3 init !',0D,0D,00
txt_intro_1 asc '       - decompressing snowflakes',0D,00
txt_intro_2 asc '       - wrapping presents',0D,00
txt_intro_3 asc '       - baking cookies',0D,00

txt_intro_clut_ok asc '! CLUT  ok',0D,00

bounce_table
  adr $012c00,$012ac0,$012ac0,$012980,$012980,$012840,$0125c0,$012480,$012200,$011f80
  adr $011d00,$011940,$0116c0,$011300,$010f40,$010a40,$010680,$010180,$00fc80,$00f780
  adr $00f280,$00ec40,$00e600,$00e100,$00d980,$00d340,$00cd00,$00c580,$00be00,$00b7c0
  adr $00b040,$00a780,$00a000,$009880,$008fc0,$008700,$007f80,$0076c0,$006e00,$006540
  adr $005c80,$005280,$0049c0,$004100,$003700,$002e40,$002580,$001b80,$0012c0,$0008c0
  adr $000000,$000640,$000dc0,$001400,$001b80,$002300,$002940,$0030c0,$003700,$003e80
  adr $0044c0,$004b00,$005280,$0058c0,$005f00,$006540,$006b80,$0071c0,$007800,$007e40
  adr $008340,$008980,$008e80,$0094c0,$0099c0,$009ec0,$00a3c0,$00a8c0,$00ac80,$00b180
  adr $00b540,$00b900,$00bcc0,$00c080,$00c440,$00c800,$00ca80,$00ce40,$00d0c0,$00d340
  adr $00d5c0,$00d700,$00d980,$00dac0,$00dc00,$00dd40,$00de80,$00dfc0,$00dfc0,$00dfc0
  adr $00e100,$00dfc0,$00dfc0,$00dfc0,$00de80,$00dd40,$00dc00,$00dac0,$00d980,$00d700
  adr $00d5c0,$00d340,$00d0c0,$00ce40,$00ca80,$00c800,$00c440,$00c080,$00bcc0,$00b900
  adr $00b540,$00b180,$00ac80,$00a8c0,$00a3c0,$009ec0,$0099c0,$0094c0,$008e80,$008980
  adr $008340,$007e40,$007800,$0071c0,$006b80,$006540,$005f00,$0058c0,$005280,$004b00
  adr $0044c0,$003e80,$003700,$0030c0,$002940,$002300,$001b80,$001400,$000dc0,$000640
  adr $000000,$000500,$000a00,$000f00,$001400,$001900,$001e00,$002440,$002940,$002e40
  adr $003340,$003700,$003c00,$004100,$004600,$0049c0,$004ec0,$0053c0,$005780,$005b40
  adr $006040,$006400,$0067c0,$006b80,$006f40,$0071c0,$007580,$007940,$007bc0,$007e40
  adr $0080c0,$008340,$0085c0,$008840,$008ac0,$008c00,$008e80,$008fc0,$009100,$009240
  adr $009380,$009380,$0094c0,$0094c0,$0094c0,$009600,$0094c0,$0094c0,$0094c0,$009380
  adr $009380,$009240,$009100,$008fc0,$008e80,$008c00,$008ac0,$008840,$0085c0,$008340
  adr $0080c0,$007e40,$007bc0,$007940,$007580,$0071c0,$006f40,$006b80,$0067c0,$006400
  adr $006040,$005b40,$005780,$0053c0,$004ec0,$0049c0,$004600,$004100,$003c00,$003700
  adr $003340,$002e40,$002940,$002440,$001e00,$001900,$001400,$000f00,$000a00,$000500
  adr $000000,$000280,$000500,$0008c0,$000b40,$000dc0,$001180,$001400,$001680,$001900
  adr $001b80,$001f40,$0021c0,$002440,$0026c0,$002940,$002bc0,$002e40,$002f80,$003200
  adr $003480,$003700,$003840,$003ac0,$003c00,$003d40,$003fc0,$004100,$004240,$004380
  adr $0044c0,$004600,$004740,$004740,$004880,$004880,$0049c0,$0049c0,$0049c0,$0049c0
  adr $004b00,$0049c0,$0049c0,$0049c0,$0049c0,$004880,$004880,$004740,$004740,$004600
  adr $0044c0,$004380,$004240,$004100,$003fc0,$003d40,$003c00,$003ac0,$003840,$003700
  adr $003480,$003200,$002f80,$002e40,$002bc0,$002940,$0026c0,$002440,$0021c0,$001f40
  adr $001b80,$001900,$001680,$001400,$001180,$000dc0,$000b40,$0008c0,$000500,$000280
  adr $000000,$FFFFFF
