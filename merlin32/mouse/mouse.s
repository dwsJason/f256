;
; Merlin32 Hello.PGX program, for Jr
;
; To Assemble "merlin32 -v hello.s"
;
		mx %11

;PGX_CPU_65816 = $01
;PGX_CPU_680X0 = $02
PGX_CPU_65C02 = $03

		org $0
		dsk mouse.pgx
		db 'P','G','X' 		; PGX header
		db PGX_CPU_65C02    ; CPU - 65c02
		adrl start

; Kernel Funcion calls
		dum $ff00
kernel_NextEvent   ds   4   ; Copy the next event into user-space.
kernel_ReadData    ds   4   ; Copy primary bulk event data into user-space
kernel_ReadExt     ds   4   ; Copy secondary bolk event data into user-space
kernel_Yield       ds   4   ; Give unused time to the kernel.
kernel_Putch       ds   4   ; deprecated
kernel_Basic       ds   4   ; deprecated
		dend

; event name space
; define just enough from api.asm, to get some mouse action
		dum 0
				   ds 4 ; reserved
event_JOYSTICK     ds 2
event_DEVICE       ds 2 ; Device added/removed.
event_key_PRESSED  ds 2
event_key_RELEASED ds 2
event_mouse_DELTA  ds 2
event_mouse_CLICKS ds 2

		dend

event_type = $30
event_buf  = $31
event_ext  = $32
mouse_delta_x = $33
mouse_delta_y = $34
mouse_delta_z = $35
mouse_buttons = $36
mouse_clicks_inner  = $33
mouse_clicks_middle = $34
mouse_clicks_outer  = $35

		org $300
             
; Zero Page defines
mmu_ctrl equ 0
io_ctrl  equ 1
; reserved addresses 2-7 for future expansion, use at your own peril
mmu      equ 8
   
pScreen = $E0
pSource = $E0

start
		; this also, sets the MMU io-page
		jsr ClearTextBuffer


		ldx #0
]lp		lda :text,x
		beq :done
		sta $C000,x
		inx
		bra ]lp
:done

; Let the Kernel do it's thing, event loop

		lda #$30 ; tell kernel where to stick it
		sta <$F0
		stz <$F1

:loop
		;stz io_ctrl
		jsr kernel_NextEvent
		bcs :loop

		;lda #2
		;sta io_ctrl         ; swap in the text memory

		lda #$c0
		sta pScreen+1
		lda #80
		sta pScreen

		lda #'$'
		jsr myPUTC

		lda event_type
		jsr myPRINTAH

;		lda event_type
;		cmp #event_mouse_DELTA
;		bne :loop

		lda #' '
		jsr myPUTC

		lda #'$'
		jsr myPUTC

		lda mouse_delta_x
		jsr myPRINTAH

		lda #' '
		jsr myPUTC
		lda #'$'
		jsr myPUTC

		lda mouse_delta_y
		jsr myPRINTAH

		bra :loop

:text   ASC	'Hello Mouse'
		db  0

incScreen
		inc pScreen
		bne :rts
		inc pScreen+1
:rts 	
		rts


; myPUTC

myPUTC
		sta (pScreen)
		bra incScreen


myPRINTAH
		pha
		lsr
		lsr
		lsr
		lsr
		tax
		lda :chars,x
		jsr myPUTC
		pla
		and #$0F
		tax
		lda :chars,x
		bra myPUTC

:chars  ASC '0123456789ABCDEF'



; Fill Text Buffer with spaces

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

