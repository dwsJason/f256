IntroTick dw 0000
IntroTickPassed
        cpx IntroTick+1
        bcc :no
        bne :yes
        cmp IntroTick
        bcc :no
:yes    sec     
        rts
:no     clc
        rts

IntroTickInc
        inc IntroTick
        beq :inchi
        rts
:inchi  inc IntroTick+1
        rts

IntroScreen mx %11    
        ; SET BITMAP PAL BLACK
        lda #0                  ; clut 0
        jsr BlackoutClut   
        ; SET TEXT PAL WE'LL USE
        jsr SetTlut
        ; SET TEXT FG/BG
        lda #$FF
        jsr TermClearTextColorBuffer
        ; SET BITMAP/LAYERS/TEXT MODE
        jsr IntroInit320x240
        _ClutToColor #$00;#$22;#$BB
        ; ...
        _TermPuts txt_intro_0
        jsr mmu_unlock
        ; @TODO - CLEAR THIS AREA FIRST?
        ; SET BITMAP OFFSET TO BOTTOM OF TALL SCREEN
        _SetIntroImgOffset PIXEL_DATA_OFFSET_1SCREEN ; set image offset to bottom of 2x tall intro image
        jsr SetFireBlockFont
        _TermPuts txt_intro_1
        ; UNPACK CLUT
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
        ; UNPACK PIXELS
        lda #<PIXEL_DATA
        ldx #>PIXEL_DATA
        ldy #^PIXEL_DATA
        jsr set_write_address

        ldx #1
        jsr set_pic_address     ; set write address to our i256 data

        _TermPuts txt_intro_2
        jsr decompress_pixels

        _TermPuts txt_intro_3
        ; FADE
:fade   ;jsr WaitVBLPoll
        ldx #<CLUT_DATA
        ldy #>CLUT_DATA
        lda #0 ; clut 0
        jsr FadeClutToClutPtrXy
        bcc :donefade
        bra :fade

:donefade
        jsr BlackoutClutData  ; prep for fadeout before we start
        ; CLEAR STARTUP TEXT
        jsr TermClearTextBuffer
        ; SET FIRE TEXT COLOR (#14)
        lda #$E0
        jsr ColorClearBuffer
        ; SET FONT SET
        jsr SetFireBlockFont
        ; IMMEDIATELY START BOUNCE
        jsr BounceIntroPic
        ; CHANGE FIRE COLOR
        * lda #$33
        * ldx #$44
        * ldy #$FF
        * jsr SetFireColor14FG
        lda #HEIGHT
        jsr SetAverage8Height
        ; PLAY OUT SOUND
        ldy #20
:sound_stoppage        
        jsr BleepOffControl
        dey
        bne :sound_stoppage

        ; @TODO - EXIT BACK FROM THIS, or write as new flame integration here with sprite.
        ; DO FLAME
*for i in [0..300]:        ; number of total/fire frames we'll see
*  update_star_sprite      ;  this goes to say 100
*  update_fire             ;  always
*  update_fire_color       ;  always
*  crackle                 ;   always... until??
*  update_fade             ;  this triggers at say 200
BufR = scratch+1
BufG = scratch+2
BufB = scratch+3

        lda #$FF
        sta BufR
        lda #$44
        sta BufG
        lda #$22
        sta BufB
:fire_intro
        jsr IntroTickInc
        * ldx IntroTick+1
        * lda IntroTick
        * jsr TermPrintAXH
        * lda #' '
        * jsr TermCOUT

        lda #<100
        ldx #>100
        jsr IntroTickPassed
        bcs :notyet120

        ldx #<CLUT_DATA
        ldy #>CLUT_DATA
        lda #0 ; clut 0
        jsr FadeClutToClutPtrXy
        * jsr BlackoutFireColorTbl
:notyet120        
        lda #<255
        ldx #>255
        jsr IntroTickPassed
        bcs :notyet235
        jsr BlackoutFireColorTbl
:notyet235

        jsr UpdateFireColor
        jsr UpdateFireColor

        jsr MakeHeat
        jsr Scroll8
        jsr Average8
        lda #<200
        ldx #>200
        jsr WaitVBLPollAX
        jsr DrawBufFullScreen
        jsr Crackle
        lda #<410
        ldx #>410
        jsr IntroTickPassed
        bcc :nextpart

        bra :fire_intro
        

:nextpart        
        jsr BleepOff
        jsr TermClearTextBuffer ; omg this is all so bad
        lda #$FF
        jsr TermClearTextColorBuffer
        
        lda #0
        jsr BlackoutClut
        lda #1
        jsr BlackoutClut
        lda #2
        jsr BlackoutClut
        lda #3
        rts


BlackoutFireColorTbl
:runonce  nop
        ldx #FireColors*3
        lda #0
:blanken sta FireColorTbl,X
        dex
        bpl :blanken
        lda #$60 
        sta :runonce

        rts
_fireisdone db 0
UpdateFireColor
    

        stz _fireisdone

        ldx FireColorCur
:blue   lda BufB    
        cmp FireColorTblB,x
        beq :green
        bcc :b_up
:b_dn   dec BufB
        bra :b_chng
:b_up   inc BufB
:b_chng inc _fireisdone ; Nope

:green  lda BufG 
        cmp FireColorTblG,x
        beq :red
        bcc :g_up
:g_dn   dec BufG
        bra :g_chng
:g_up   inc BufG
:g_chng inc _fireisdone ; Nope

:red    lda BufR
        cmp FireColorTblR,x
        beq :check
        bcc :r_up
:r_dn   dec BufR
        bra :r_chng
:r_up   inc BufR
:r_chng inc _fireisdone ; Nope

:check  lda _fireisdone
        bne :return
:next_color inx
        stx FireColorCur
        cpx #FireColors
        bne :return
        stz FireColorCur

:return 
        lda $1
	pha
	stz $1  ; save i/o - set to $0 (luts)
        lda BufB
        ldx BufG
        ldy BufR
        jsr SetFireColor14FG
        pla     
        sta $1
        rts



FireColorCur db 0
FireColors equ #4
FireColorTbl
FireColorTblR
        db $99,$ee,$ff,$FF
        
FireColorTblG
        db $25,$ee,$00,$FF
        
FireColorTblB
        db $BE,$00,$00,$00
        


bounce_table_ptr = ptr0
bounce_table_val = scratch
BounceIntroPic
	jsr SetColorIdxF256A    ; needed for flame
        lda #$33
        ldx #$44
        ldy #$55
        jsr SetFireColor14FG    ; dark dust color
        lda #HEIGHT-8           ; shorten window
        jsr SetAverage8Height

        lda #<bounce_table
        sta bounce_table_ptr
        lda #>bounce_table
        sta bounce_table_ptr+1
:bounce_loop
 ;       jsr Scroll8    ; trololol... fuck accuracy
	jsr Average8
        lda $1
        pha
        lda #2
        sta $1
	jsr DrawBufFullScreen
        pla 
        sta $1
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
        jsr BleepOn2
        jsr MakeHeatAlt
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

        lda #2
        sta io_ctrl
        lda #<200
        ldX #>200

        jsr WaitVBLPollAX
        bra :bounce_loop


        * _SetIntroImgOffset PIXEL_DATA        
        * stz io_ctrl
        * lda #<]1
        * sta $D101
        * lda #>]1
        * sta $D102
        * lda #^]1
        * sta $D103



IntroInit320x240
        php
        sei

        ; Access to vicky generate registers
        stz io_ctrl

        ; enable the graphics mode
        lda #%00001111  ;  bitmap + graphics + overlay + text
        sta $D000
        stz $D001       ; 80x60

        ; layer stuff - assign bitmap layer zero (0) to all three layers
        stz $D002  ; layer1 + layer0
        stz $D003  ; layer2

        ; set address of uncompressed image to display
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
Tlut0Fg equ $D800
Tlut0Bg equ Tlut0Fg+$40
Tlut1Fg equ $D804
Tlut1Bg equ Tlut1Fg+$40
Tlut2Fg equ $D808
Tlut2Bg equ Tlut2Fg+$40
Tlut3Fg equ $D80C
Tlut3Bg equ Tlut3Fg+$40
Tlut4Fg equ $D810
Tlut4Bg equ Tlut4Fg+$40
Tlut5Fg equ $D814
Tlut5Bg equ Tlut5Fg+$40
Tlut6Fg equ $D818
Tlut6Bg equ Tlut6Fg+$40
Tlut14Fg equ $D838
Tlut14Bg equ Tlut14Fg+$40
Tlut15Fg equ $D83C
Tlut15Bg equ Tlut15Fg+$40
SetFireColor14FG
        pha
        lda $1
	pha
	stz $1  ; save i/o - set to $0 (luts)

    
       
        stx Tlut14Fg+1
        sty Tlut14Fg+2
        pla
        plx ; R val
        stx Tlut14Fg
	sta $1
	rts

SetTlut 
        lda $1
	pha
	stz $1  ; save i/o - set to $0 (luts)


        lda #$FF        
        sta Tlut15Fg    ; 15 - white on "black"
        sta Tlut15Fg+1
        sta Tlut15Fg+2

        stz Tlut15Bg
        stz Tlut15Bg+1
        stz Tlut15Bg+2
        
        lda #$11
        sta Tlut14Fg    ; 14 - red on "black"
        sta Tlut14Fg+1
        lda #$ff
        sta Tlut14Fg+2

        stz Tlut14Bg
        stz Tlut14Bg+1
        stz Tlut14Bg+2
        
        pla  
	sta $1
	rts


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


BlackoutClutData 
:runonce nop        
        lda #<CLUT_DATA
        sta ptr0
        sta ptr1
        sta ptr2
        sta ptr3
        lda #>CLUT_DATA
        sta ptr0+1
        inc
        sta ptr1+1
        inc
        sta ptr2+1
        inc
        sta ptr3+1
        ldy #0
        tya
:blanken sta (ptr0),y
        sta (ptr1),y
        sta (ptr2),y
        sta (ptr3),y
        iny
        bne :blanken  
        lda #$60
        sta :runonce
        rts
        



Crackle
        lda $1
        pha
        stz $1

        jsr galois16o
        cmp #$F0
        bcc :cont
        bra :crack
        
        lda _crack_is_wack
        bne :cont
:crack  cmp #$F6
        bcs :c2
:c1     lda #$F7       ; %11110000 = Channel 3 attenuation = 0
        sta $D608
        lda #%11100010       ; %11100110 = white noise, f = C/512
        sta $D608
        bra :done
:c2     cmp #$F8
        bcs :c3
        lda #$F6       ; %11110000 = Channel 3 attenuation = 0
        sta $D608
        lda #%11100110       ; %11100110 = white noise, f = C/512
        sta $D608
        bra :done
:c3     lda #$F9       ; %11110000 = Channel 3 attenuation = 0
        sta $D608
        lda #%11100111       ; %11100110 = white noise, f = C/512
        sta $D608
        bra :done
        


:cont  ;dec _crack_is_wack
        lda #$FF        ; off - silenve
        sta $D608 
        lda #$9F        ; %10011111 = Channel 1 attenuation = 15 (silence)
        sta $D608
:done
        pla
        sta $1
        rts
_crack_is_wack db 0



BleepOn2
        lda #2 
        sta _bleepcontrol

        stz io_ctrl
        lda #$F8       ; %11110000 = Channel 3 attenuation = 0
        sta $D608
        lda #%11101110       ; %11100110 = white noise, f = C/512
        sta $D608



        lda #$98        ; %10010000 = Channel 1 attenuation = 0
        sta $D608
        lda #$8E        ; %1rrrffff = set the low 4 bits of the frequency code
        sta $D608
        lda #$3F        ; %0nffffff = Set the high 6 bits of the frequency
        sta $D608

        lda #2
        sta io_ctrl
        rts
        



BleepOn 
        lda #2 
        sta _bleepcontrol

        stz io_ctrl
        lda #$F0       ; %10010000 = Channel 3 attenuation = 0
        sta $D608
        lda #$E6       ; %11100100 = white noise, f = C/512
        sta $D608

        lda #$90        ; %10010000 = Channel 1 attenuation = 0
        sta $D608
        lda #$8E        ; Set the low 4 bits of the frequency code
        sta $D608

        lda #$3F        ; %00001111 = Set the high 6 bits of the frequency
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
        sta $D608 
        lda #$9F        ; %10011111 = Channel 1 attenuation = 15 (silence)
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

TextIo          ldx   #2
                stx   MMU_IO_CTRL           ; map IO buffer at $C000 to text memory
                rts

ColorIo         ldx   #3
                stx   MMU_IO_CTRL           ; map IO buffer at $C000 to text memory
                rts
* fg/bg color in A
ColorClearBuffer jsr  ColorIo
                bra   FillTextBuffer
TextClearBuffer jsr TextIo
                lda #' '

FillTextBuffer  ldx   #0
:lp1
                sta   $C000,x
                sta   $C100,x
                sta   $C200,x
                sta   $C300,x
                sta   $C400,x
                sta   $C500,x
                sta   $C600,x
                sta   $C700,x
                sta   $C800,x
                sta   $C900,x
                sta   $CA00,x
                sta   $CB00,x
                sta   $CC00,x
                sta   $CD00,x
                sta   $CE00,x
                sta   $CF00,x
                sta   $D000,x
                sta   $D100,x
                sta   $D1C0,x               ; offset to end on last char (w/ some overwrite)
                inx
                bne   :lp1
                rts


txt_intro_0 asc ' ',0D,0D,'    DreamOS v2.3 init !',0D,0D,00
        DO RELEASE
txt_intro_1 asc '       - decompressing snowflakes',0D,00
txt_intro_2 asc '       - wrapping presents',0D,00
txt_intro_3 asc '       - baking cookies',0D,00
        ELSE
txt_intro_1 asc '       - decompressing CLUT',0D,00
txt_intro_2 asc '       - decompressing PIXELS',0D,00
txt_intro_3 asc '       - start fade',0D,00
        FIN
txt_intro_clut_ok asc '! CLUT  ok',0D,00

bounce_table
  adr $012c00,$012ac0,$012980,$0125c0,$012200,$011d00,$0116c0,$010f40,$010680,$00fc80
  adr $00f280,$00e600,$00d980,$00cd00,$00be00,$00b040,$00a000,$008fc0,$007f80,$006e00
  adr $005c80,$0049c0,$003700,$002580,$0012c0,$000000,$000dc0,$001b80,$002940,$003700
  adr $0044c0,$005280,$005f00,$006b80,$007800,$008340,$008e80,$0099c0,$00a3c0,$00ac80
  adr $00b540,$00bcc0,$00c440,$00ca80,$00d0c0,$00d5c0,$00d980,$00dc00,$00de80,$00dfc0
  adr $00e100,$00dfc0,$00de80,$00dc00,$00d980,$00d5c0,$00d0c0,$00ca80,$00c440,$00bcc0
  adr $00b540,$00ac80,$00a3c0,$0099c0,$008e80,$008340,$007800,$006b80,$005f00,$005280
  adr $0044c0,$003700,$002940,$001b80,$000dc0,$000000,$000a00,$001400,$001e00,$002940
  adr $003340,$003c00,$004600,$004ec0,$005780,$006040,$0067c0,$006f40,$007580,$007bc0
  adr $0080c0,$0085c0,$008ac0,$008e80,$009100,$009380,$0094c0,$0094c0,$0094c0,$0094c0
  adr $009380,$009100,$008e80,$008ac0,$0085c0,$0080c0,$007bc0,$007580,$006f40,$0067c0
  adr $006040,$005780,$004ec0,$004600,$003c00,$003340,$002940,$001e00,$001400,$000a00
  adr $000000,$000500,$000b40,$001180,$001680,$001b80,$0021c0,$0026c0,$002bc0,$002f80
  adr $003480,$003840,$003c00,$003fc0,$004240,$0044c0,$004740,$004880,$0049c0,$0049c0
  adr $004b00,$0049c0,$0049c0,$004880,$004740,$0044c0,$004240,$003fc0,$003c00,$003840
  adr $003480,$002f80,$002bc0,$0026c0,$0021c0,$001b80,$001680,$001180,$000b40,$000500
  adr $000000,$FFFFFF

PIXEL_DATA_OFFSET_1SCREEN = PIXEL_DATA+320*240

** ZERO PAGE / DIRECT PAGE AREA
ptr0    = $20
ptr1    = $22
ptr2    = $24
ptr3    = $26
ptr4    = $28
ptr5    = $2A
ptr6    = $2C
ptr7    = $2E
ptr8    = $30
ptr9    = $32
ptr10   = $34
ptr11   = $36
ptr12   = $38
ptr13   = $3A
ptr14   = $3C
ptr15   = $3E

scratch = $80 ; to $8F?  I dunno.. just use ZP if ya like


galois16o
	lda seed+1
	tay ; store copy of high byte
	; compute seed+1 ($39>>1 = %11100)
	lsr ; shift to consume zeroes on left...
	lsr
	lsr
	sta seed+1 ; now recreate the remaining bits in reverse order... %111
	lsr
	eor seed+1
	lsr
	eor seed+1
	eor seed+0 ; recombine with original low byte
	sta seed+1
	; compute seed+0 ($39 = %111001)
	tya ; original high byte
	sta seed+0
	asl
	eor seed+0
	asl
	eor seed+0
	asl
	asl
	asl
	eor seed+0
	sta seed+0
	rts
seed    dw $1234
* SetFireFont     
*         lda $1
*         pha
*         lda #1
*         sta $1 ; font set 0 now at c000 - c7ff

*         ldy #FireFontLen
*         ldx #0
* :copy        lda FireFont,x
*         sta $c000,X
*         inx
*         dey
*         bpl :copy
*         pla
*         sta $1
*         rts
* FireFont 
* :0
*   db %00000000
*   db %00000000
*   db %00000000
*   db %00000000
*   db %00000000
*   db %00000000
*   db %00000000
*   db %00000000
* :1
*   db %00000000
*   db %00000000
*   db %00000000
*   db %00000000
*   db %00000000
*   db %00000000
*   db %00000100
*   db %00000000
* :2
*   db %01100000
*   db %00000011
*   db %00010001
*   db %00000010
*   db %00011000
*   db %00100000
*   db %00000000
*   db %00010001
* :3
*   db %00000010
*   db %00000100
*   db %00000100
*   db %00100000
*   db %00100000
*   db %00101010
*   db %00010010
*   db %00000000
* :4
*   db %01100011
*   db %00101010
*   db %00010000
*   db %00110100
*   db %00110010
*   db %01010011
*   db %00011000
*   db %01000000
* :5
*   db %10101001
*   db %10101010
*   db %11011000
*   db %10110011
*   db %11001000
*   db %00100001
*   db %10010010
*   db %00010010
* :6
*   db %10000000
*   db %01000001
*   db %11110111
*   db %11000001
*   db %11010101
*   db %10000010
*   db %00000000
*   db %11110010
* :7
*   db %11101010
*   db %10101101
*   db %11000000
*   db %10100101
*   db %10100000
*   db %00111100
*   db %00100110
*   db %01101011
* :8
*   db %10110111
*   db %10111101
*   db %11100100
*   db %11110111
*   db %01010011
*   db %11010001
*   db %10111001
*   db %01011100
* :9
*   db %11101000
*   db %10010011
*   db %11100000
*   db %10111101
*   db %11101110
*   db %11111111
*   db %11011101
*   db %11100100
* :A
*   db %10011101
*   db %11111011
*   db %11010100
*   db %11011111
*   db %11111111
*   db %11010110
*   db %10111011
*   db %11010111
* :B
*   db %10110011
*   db %11111111
*   db %10110111
*   db %10111111
*   db %01111111
*   db %11011111
*   db %11011111
*   db %11010011
* :C
*   db %11011110
*   db %11111111
*   db %11010111
*   db %01111111
*   db %11111111
*   db %01111111
*   db %11111111
*   db %11111111
* :D
*   db %11111111
*   db %11111111
*   db %01111111
*   db %10111111
*   db %11111111
*   db %11110111
*   db %11111111
*   db %11111111
* :E
*   db %11111111
*   db %11111111
*   db %11111111
*   db %11111111
*   db %11111111
*   db %11111111
*   db %11111111
*   db %11111111
* :F
*   db %11111111
*   db %11111111
*   db %11111111
*   db %11111111
*   db %11111111
*   db %11111111
*   db %11111111
*   db %11111111
* FireFontLen = *-FireFont        ; fits in a byte for 16chars*8bytes 