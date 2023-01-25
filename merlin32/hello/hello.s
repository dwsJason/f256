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
		dsk hello.pgx
		db 'P','G','X' 		; PGX header
		db PGX_CPU_65C02    ; CPU - 65c02
		adrl start

		org $200
             
; Zero Page defines
mmu_ctrl equ 0
io_ctrl  equ 1
; reserved addresses 2-7 for future expansion, use at your own peril
mmu      equ 8
   
pSource = $F0

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


:wait   bra :wait
		rts

:text   ASC	'Hello World!'
		db  0


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

