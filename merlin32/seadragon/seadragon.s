;
; Merlin32 Line draw example for Jr
;
; To Assemble "merlin32 -v . link.s"
;
		mx %11

; System Bus Pointer's
;pSource  equ $10
;pDest    equ pSource+4
; Do not use anything below $20, the mmu module owns it

	dum $20
temp0 ds 4
temp1 ds 4
temp2 ds 4
temp3 ds 4
temp4 ds 4
temp5 ds 4
temp6 ds 4
temp7 ds 4

line_color ds 1
line_x0 ds 2
line_y0 ds 1
line_x1 ds 2
line_y1 ds 1

wave_addr ds 2

	dend

psg_r = VKY_PSG0
psg_l = VKY_PSG1


PIXEL_DATA = $010000

start
		sei

; This will copy the color table into memory, then set the video registers
; to display the bitmap

		jsr init320x240

		jsr initColors

		jsr TermInit

		lda #<txt_title
		ldx #>txt_title
		jsr TermPUTS

		jsr mmu_unlock ; just being lazy here, don't use the mmu functions
					   ; $6000 is both read and write block


		lda #2  	; Fill Color
		jsr DmaClear

		do 1
;------------------------------------------------------------------------------
; 
; Put audio in Stereo mode
;
		stz <io_ctrl

		lda #SYS_SID_ST+SYS_PSG_ST
		tsb |VKY_SYS1

;		jsr make_noise

		ldx #{sea_wave/8192}
		stx <mmu4
		inx
		stx <mmu5

		; our wave it at $8000, and is 10,349 bytes long

WAVE_LEN = wave_end-wave_start

		lda #$80
		sta <wave_addr+1
		stz <wave_addr

CPU_FREQ = 6290000

; carrier freq (should be too high to hear)
;AUDIO_FREQ = 111563/48000
AUDIO_FREQ = 0
END_ADDR = $8000+WAVE_LEN


		lda #$90
		sta |psg_l
		sta |psg_r

		lda #{AUDIO_FREQ&$F}
		ora #$80
		sta |psg_l
		sta |psg_r

		lda #{AUDIO_FREQ/16}
		and #$3F
		sta |psg_l
		sta |psg_r

; CPU_FREQ / 11025 ~ 570 clocks per sample

]loop
		; wait 500 clocks
		jsr wait500cyc

		lda (wave_addr) ; 5
		eor #$FF		; 2
		lsr				; 2
		lsr 			; 2
		lsr 			; 2
		lsr 			; 2   ; 15

		ora #$90		; 2
		sta |psg_l  	; 4   ; 21
		sta |psg_r  	; 4   ; 21


		clc	              ; 2
		lda <wave_addr    ; 3
		adc #1  		  ; 2 
		sta <wave_addr    ; 3  ; 31
		lda <wave_addr+1  ; 3
		adc #0  		  ; 2
		sta <wave_addr+1  ; 3  ; 39


:result_lo = temp0
:result_hi = temp0+1

		lda <wave_addr    ; 3  ; 42
		eor #<END_ADDR    ; 2  ; 44
		bne ]loop

		lda <wave_addr+1  ; 3  ; 47
		eor #>END_ADDR    ; 2  ; 49

		bne ]loop   	  ; 3  ; 56

		lda #$80
		sta <wave_addr+1
		stz <wave_addr

;		jmp ]loop

		lda #$9F  	; quiet
		sta |psg_l

		lda #2
		sta <io_ctrl
		fin

;------------------------------------------------------------------------------

		lda #$B
		sta line_color
wow_loop

]x = 0
]y = 0

		lda #150+]x
		sta <line_x0
		sta <line_x1

		lda #150+]y
		sta <line_y0
		sta <line_y1

		;jsr plot_line

		ldx #160+]x
		ldy #150+]y
		jsr text_plot_too

		ldx #170+]x
		ldy #145+]y
		jsr text_plot_too

		ldx #180+]x
		ldy #135+]y
		jsr text_plot_too

		ldx #185+]x
		ldy #125+]y
		jsr text_plot_too

		ldx #185+]x 
		ldy #115+]y
		jsr text_plot_too

		ldx #180+]x 
		ldy #105+]y
		jsr text_plot_too

		ldx #170+]x
		ldy #95+]y
		jsr text_plot_too

		ldx #160+]x
		ldy #90+]y 
		jsr text_plot_too

		ldx #150+]x
		ldy #90+]y 
		jsr text_plot_too

		ldx #140+]x
		ldy #95+]y 
		jsr text_plot_too

		ldx #130+]x
		ldy #105+]y 
		jsr text_plot_too

		ldx #125+]x
		ldy #115+]y 
		jsr text_plot_too

		ldx #125+]x
		ldy #125+]y 
		jsr text_plot_too

		ldx #130+]x
		ldy #135+]y 
		jsr text_plot_too

		ldx #140+]x
		ldy #145+]y 
		jsr text_plot_too

		ldx #150+]x
		ldy #150+]y 
		jsr text_plot_too

		lda line_color
		inc
		and #$F
		sta line_color

		jmp wow_loop



		do 0 ; this doesn't work on my Jr.
]clamp
		lda #15
]speed
		pha
		jsr DmaClear

		pla
		pha

		jsr TermPrintAH
		jsr TermCR

		ldx #0
		ldy #0
]wait
		dex
		bne ]wait
		dey
		bne ]wait

		pla
		dec
		bpl ]speed
		bra ]clamp
		fin


]wait bra ]wait


		do 0
		; set access to vicky CLUTs
		lda #1
		sta io_ctrl
		; copy the clut up there
		ldx #0
]lp		lda CLUT_DATA,x
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

		lda #<txt_copy_clut
		ldx #>txt_copy_clut
		jsr TermPUTS
		fin

;------------------------------------------------------------------------------

init320x240
		php
		sei

		; Access to vicky generate registers
		stz io_ctrl

		; enable the graphics mode
;;		lda #%00001111	; gamma + bitmap + graphics + overlay + text
;		lda #%00000001	; text
		lda #%01111111  ; all the things
		sta VKY_MSTR_CTRL_0
		;lda #%110       ; text in 40 column when it's enabled
		;sta $D001
		;lda #6
		;lda #1 ; clock_70
		lda #0
		sta VKY_MSTR_CTRL_1

		; layer stuff - take from Jr manual
;		lda #$54
		lda #$10
		sta VKY_LAYER_CTRL_0  ; tile map layers
;		lda #$06
		lda #$02
		sta VKY_LAYER_CTRL_1  ; tile map layers

		; Tile Map 0
		lda #$11
		sta $D200 ; tile size 8x8 + enable

		; Tile Map Disable
		stz VKY_TM0_CTRL
		stz VKY_TM1_CTRL
		stz VKY_TM2_CTRL

		; bitmap disables
		lda #1
		sta VKY_BM0_CTRL  ; enable
		stz VKY_BM1_CTRL  ; disable
		stz $D110  ; disable

		; set address of image, since image uncompressed, we just display it
		; where we loaded it.
		lda #<PIXEL_DATA
		sta VKY_BM0_ADDR_L
		lda #>PIXEL_DATA
		sta VKY_BM0_ADDR_M
		lda #^PIXEL_DATA
		sta VKY_BM0_ADDR_H

		lda #2
		sta io_ctrl
		plp

		rts
;------------------------------------------------------------------------------

txt_title asc 'Line Draw Example'
		db 13,0

txt_plot asc 'Plot ('
		db 0
txt_too asc ') to ('
		db 0


;------------------------------------------------------------------------------
;
; A = Fill Color
;
; Clear 320x240 buffer PIXEL_DATA with A
;
DmaClear
		php
		sei

		ldy io_ctrl
		phy

		stz io_ctrl

		ldx #DMA_CTRL_ENABLE+DMA_CTRL_FILL
		stx |DMA_CTRL

		sta |DMA_FILL_VAL

		lda #<PIXEL_DATA
		sta |DMA_DST_ADDR
		lda #>PIXEL_DATA
		sta |DMA_DST_ADDR+1
		lda #^PIXEL_DATA
		sta |DMA_DST_ADDR+2

]size = {320*240}

		lda #<]size
		sta |DMA_COUNT
		lda #>]size
		sta |DMA_COUNT+1
		lda #^]size
		sta |DMA_COUNT+2

		lda #DMA_CTRL_START
		tsb |DMA_CTRL

]busy
		lda |DMA_STATUS
		bmi ]busy

		stz |DMA_CTRL

		pla
		sta io_ctrl

		plp
		rts

;------------------------------------------------------------------------------
plot_line
		jmp plot_line_8x8y
		rts


;------------------------------------------------------------------------------
;
; no real regard given to performance, just make it work
;
plot_line_8x8y

:x0 = temp0
:y0 = temp0+1
:x1 = temp1
:y1 = temp1+1
:dx = temp2
:dy = temp2+1
:sx = temp3
:sy = temp3+1

:err  = temp4
:err2 = temp4+2

:temp0 = temp5

;----- copy inputs
		ldx <line_x0
		ldy <line_y0
		stx <:x0
		sty <:y0

		ldx <line_x1
		ldy <line_y1
		stx <:x1
		sty <:y1

;----- calulate dx + sx (delta x, and step x)
; dx = abs(x1 - x0)
; sx = x0 < x1 ? 1: -1  ; I'm doing 1 or 0
		cpx <:x0
		bcs :x_good

		sec
		lda <:x0
		sbc <:x1

		stz <:sx  ; indicate negative step
		bra :st_dx
:x_good
		lda #1
		sta <:sx  ; positive step
		txa
		sbc <:x0
:st_dx	sta <:dx

;----- calculate dy + sy (delta y, and step y)
; dy = -abs(y1 - y0)      ; I'm keeping this positive
; sy = y0 < y1 ? 1 : -1   ; I'm doing 1 or 0
:now_y
		cpy <:y0
		bcs :y_good

		sec
		lda <:y0
		sbc <:y1

		stz <:sy ; indicate negative step
		bra :st_dy
:y_good
		lda #1
		sta <:sy ; positive step
		tya
		sbc <:y0
:st_dy  sta <:dy

;----- calculate initial error
; error = dx + dy
		sec
		lda <:dx
		sbc <:dy
		sta <:err
		lda #0		; both dx and dy are only 8 bit, for now
		sbc #0
		sta <:err+1
]loop
		jsr PlotXY

; if x0==x1 && y0==y1 - done
		lda <:x0
		eor <:x1
		bne :go_go

		lda <:y0
		eor <:y1
		beq :done_done
:go_go
;----- calc e2
		lda <:err
		asl
		sta <:err2
		lda <:err+1
		rol
		sta <:err2+1
; if e2 >= (-dy)   (in original code dy is always negative)
;               (in our code dy is always positive)
		bpl :e2_ge_dy ; when error is positive, it's always greater=

		; if e2 is negative - 
		eor #$FF
		sta <:temp0+1

		lda <:err2
		eor #$FF
		inc
		sta <:temp0
		bne :kk
		inc <:temp0+1
:kk
		; temp0 is now a positive version of e2
		; now check to see if e2 <= dy

		lda <:temp0+1
		bne :next_thing

		lda <:temp0
		cmp <:dy
		bcc :e2_ge_dy
		beq :e2_ge_dy
		bcs :next_thing
:e2_ge_dy
		; if x0 == x1 break, break the if?
		lda <:x0
		eor <:x1
		beq :next_thing
		; error = error + dy
		sec
		lda <:err
		sbc <:dy
		sta <:err
		lda <:err+1
		sbc #0
		sta <:err+1
		; x0 = x0 + sx
		lda <:sx
		beq :dec_x
		inc <:x0
		bra :next_thing
:dec_x
		dec <:x0

:next_thing
; if e2 <= dx
		lda <:err2+1
		bmi :kk2	  ; if e2 negative, it's automatically smaller
		bne ]loop     ; dx can be 255 at the biggest, so err2+1 has to be 0
					  ; for e2 to be <= dx
		lda <:dx
		cmp <:err2
		bcc ]loop

:kk2
		; if y0 == y1 break
		lda <:y0
		eor <:y1
		beq ]loop
		; error = error + dx
		clc
		lda <:err
		adc <:dx
		sta <:err
		lda <:err+1
		adc #0
		sta <:err+1
		; y0 = y0 + sy
		lda <:sy
		beq :dec_y
		inc <:y0
		bra ]loop
:dec_y
		dec <:y0
		bra ]loop

:done_done
		rts

		do 0
; plot a pixel at :x0,:y0, with line_color
; with no regards to efficiency
:plot
		ldx <:y0
		clc
		lda |:block_low_320,x   ; low byte of address in our mapped block
		adc <:x0
		sta |:p+1				; modify the store code, with abs address

		lda |:block_hi_320,x
		adc #0  				; Or adc x0+1 for 16-bit

		ldy |:block_num,x
		cmp #>{WRITE_BLOCK+$2000}
		bcc :good_to_go

		iny

		lda #>WRITE_BLOCK

:good_to_go
		sty <mmu5
		sta |:p+2
		lda line_color
:p		sta |WRITE_BLOCK

		rts
		fin

;------------------------------------------------------------------------------
;
; Version requires $6000 WRITE_BLOCK, so quicker detection of wrap
;
PlotXY
		ldx <:y0
		clc
		lda |:block_low_320,x   ; low byte of address in our mapped block
		adc <:x0
		sta |:p+1				; modify the store code, with abs address

		ldy |:block_num,x

		lda |:block_hi_320,x
		adc #0  				; Or adc x0+1 for 16-bit
		bpl :good_to_go 		; this check depends on block ending at 7FFF

		iny

		lda #>WRITE_BLOCK

:good_to_go
		sty <mmu3
		sta |:p+2
		lda line_color
:p		sta |WRITE_BLOCK

		rts


; I'm going to change this out to be an mmu+block + offset address
; simulating what the bitmap coordinate math block does



:block_low_320
]var = PIXEL_DATA
		lup 256
		db <]var
]var = ]var + 320
		--^

:block_hi_320
]var = PIXEL_DATA
		lup 256
		db >{{]var&$1FFF}+WRITE_BLOCK}
]var = ]var + 320
		--^

:block_num
]var = PIXEL_DATA
		lup 256
		db {]var/$2000}
]var = ]var + 320
		--^

;------------------------------------------------------------------------------

text_plot_too
		lda <line_x1
		sta <line_x0

		lda <line_y1
		sta <line_y0

		stx <line_x1
		sty <line_y1

;		jmp plot_line


		lda #<txt_plot
		ldx #>txt_plot
		jsr TermPUTS

		lda <line_x0
		jsr TermPrintAI  ; AI only goes to 99

		lda #$2C ; ','
		jsr TermCOUT

		lda <line_y0
		jsr TermPrintAI

		lda #<txt_too
		ldx #>txt_too
		jsr TermPUTS

		lda <line_x1
		jsr TermPrintAI

		lda #$2C ; ','
		jsr TermCOUT

		lda <line_y1
		jsr TermPrintAI

		lda #$29 ;')'
		jsr TermCOUT
		jsr TermCR

		;stz <io_ctrl

		jsr plot_line

		;lda #2
		;sta <io_ctrl
		rts



;------------------------------------------------------------------------------
;
; PORT PJW's example to merlin32
;

make_noise
		ldy #0

        ; Get the note to play
]loop	lda score,y

        ; If we're at the end of the score, we're done
        bne :playnote
:done   nop
        bra :done

            ; Find the frequency for the note
:playnote   sec                     ; Convert the note character to an index
            sbc #'A'                ; Into the frequency table
            tax

			; tone 1
            lda frequency,x         ; Get the low 4 bits of the frequency
            and #$0f
            ora #$80.$00
            sta psg_l
            sta psg_r

            lda frequency,x         ; Get the upper bits of the frequency
            lsr a
            lsr a
            lsr a
            lsr a
            and #$3f
            sta psg_l
            sta psg_r

			; tone 2
            lda frequency,x         ; Get the low 4 bits of the frequency
			and #$0f
			ora #$80.$20
			sta psg_l
			sta psg_r

			lda frequency,x         ; Get the upper bits of the frequency
			lsr a
			lsr a
			lsr a
			lsr a
			and #$3f
			sta psg_l
			sta psg_r

			; tone 3
            lda frequency,x         ; Get the low 4 bits of the frequency
			and #$0f
			ora #$80.$40
			sta psg_l
			sta psg_r

			lda frequency,x         ; Get the upper bits of the frequency
			lsr a
			lsr a
			lsr a
			lsr a
			and #$3f
			sta psg_l
			sta psg_r


            ; Start playing the note - tone 1
            lda #$80.$10
            sta psg_l
            sta psg_r

            ; Start playing the note - tone 2
			;lda #$80.$30
            ;sta psg_l
            ;sta psg_r

            ; Start playing the note - tone 3
			;lda #$80.$50
            ;sta psg_l
            ;sta psg_r


            ; Wait for the length of the note (1/2 second)
            ldx #3
            jsr wait_tens

            ; Stop playing the note tone 1
            lda #$80.$10.$0f
            sta psg_l
            sta psg_r

            ; Stop playing the note tone 2
            lda #$80.$30.$0f
            sta psg_l
            sta psg_r

            ; Stop playing the note tone 3
            lda #$80.$50.$0f
            sta psg_l
            sta psg_r


            ; Wait for the pause between notes (1/5 second)
            ldx #3
            jsr wait_tens

            ; Try the next note
            iny
            jmp ]loop

;
; Wait for about 1ms
;
wait_1ms    phx
            phy

            ; Inner loop is 6 clocks per iteration or 1us
            ; Run the inner loop ~1000 times for 1ms

            ldx #3
wait_outr   ldy #$ff
wait_inner  nop
            dey
            bne wait_inner
            dex
            bne wait_outr

            ply
            plx
            rts

;
; Wait for 100ms
;
wait_100ms  phx
            ldx #100
wait100l    jsr wait_1ms
            dex
            bne wait100l
            plx
            rts

;
; Wait for some 10ths of seconds
;
; X = number of 10ths of a second to wait
;
wait_tens   jsr wait_100ms
            dex
            bne wait_tens
            rts
;
; Assignment of notes to frequency
; NOTE: in general, this table should support 10-bit values
;       we're using just one octave here, so we can get away with bytes
;       PSG system clock is 3.57MHz
;
frequency	db 127   ; A (Concert A)
            db 113   ; B
            db 212   ; C
            db 190   ; D
            db 169   ; E
            db 159   ; F
            db 142   ; G

;
; The notes to play
;
score       ASC 'CCGGAAG'
            ASC 'FFEEDDC'
            ASC 'GGFFEED'
            ASC 'GGFFEED'
            ASC 'CCGGAAG'
            ASC 'FFEEDDC'
			db 0

wait500cyc
			phx
			ldx #100
]wait
			dex 	 	; 2
			bne ]wait   ; 3

			plx
			rts

