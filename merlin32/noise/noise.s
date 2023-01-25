;
; Merlin32 Noise.PGX program, for Jr
;
; To Assemble "merlin32 -v . noise.s"
;
		mx %11

;PGX_CPU_65816 = $01
;PGX_CPU_680X0 = $02
PGX_CPU_65C02 = $03

		org $0
		dsk noise.pgx
		db 'P','G','X' 		; PGX header
		db PGX_CPU_65C02    ; CPU - 65c02
		adrl start

		org $200			; take all the RAM

; Zero Page defines
mmu_ctrl equ 0
io_ctrl  equ 1
; reserved addresses 2-7 for future expansion, use at your own peril
mmu      equ 8

; F0->FF are reserved for passing args / getting return values from the kernel
; so if not using a kernel call, then it can be temp space?
pSource = $F0
CHROUT = $ffd2

psg_l = $D600
psg_r = $D610



start
		; this also, sets the MMU io-page
		jsr ClearTextBuffer

		; this print, only prints to the upper left corner of the screen	

		lda #<:text   		; Text C String Address
        sta pSource+0       ; Pointer that the print function will use
		lda #>:text
		sta pSource+1

		jsr print

		stz io_ctrl  ; swap noise registers back into memory
		jsr make_noise


; this stops the program from exiting back into DOS or SuperBASIC 
; so we can see
:wait   bra :wait  
		rts

:text   ASC	'Hello Noise!'
		db  0

;------------------------------------------------------------------------------
;
; pSource (DP Location $FB) points to a 0 terminated string
; Function wrecks A, and Y (CHROUT might wreck X)
;
print
		ldy     #0
]loop   lda     (pSource),y
        beq     :done
        ;jsr     CHROUT
		sta		$C000,y
        iny
        bra     ]loop
:done   rts

ClearTextBuffer

		lda #2
		sta io_ctrl         ; swap in the text memory

		ldx #0
		lda #' '
]lp
		sta $C000,x
		sta $C100,x
		sta $C200,x
		sta $C300,x
		sta $C400,x
		sta $C500,x
		sta $C600,x
		sta $C700,x
		sta $C800,x
		sta $C900,x
		sta $CA00,x
		sta $CB00,x
		sta $CC00,x
		sta $CD00,x
		sta $CE00,x
		sta $CF00,x
		dex
		bne ]lp

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

            lda frequency,x         ; Get the low 4 bits of the frequency
            and #$0f
            ora #$80
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

            ; Start playing the note
            lda #$90
            sta psg_l
            sta psg_r

            ; Wait for the length of the note (1/2 second)
            ldx #3
            jsr wait_tens

            ; Stop playing the note
            lda #$9f
            sta psg_l
            sta psg_r

            ; Wait for the pause between notes (1/5 second)
            ldx #3
            jsr wait_tens

            ; Try the next note
            iny
            bra ]loop

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

