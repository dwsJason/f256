
; Generic Merlin32 Link file set up to produce a PGZ executable
;

;------------------------------------------------------------------------------
; Include the hardware defs, from PJW

		put ..\jr\f256jr.asm
		put ..\jr\f256_dma.asm
		put ..\jr\f256_irq.asm
		put ..\jr\f256_rtc.asm
		put ..\jr\f256_sprites.asm
		put ..\jr\f256_tiles.asm
		put ..\jr\f256_timers.asm
		put ..\jr\f256_via.asm
		put ..\jr\f256_intmath.asm
		put ..\kernel\api.s

;------------------------------------------------------------------------------

		use macros.i

;------------------------------------------------------------------------------

		mx %11
		org $0
		dsk platform.pgz
		db	'Z'   			; PGZ header upper case Z means 24 bit size/length fields

;------------------------------------------------------------------------------

; Segment 0
		org $0
		adr main_code_start 			 	; Address to load into memory
		adr main_code_end-main_code_start   ; Length of data to load into their

		org $300
main_code_start
		put platform.s
		put term.s
		put mmu.s
		put lzsa2.s
		put i256.s
		put colors.s
main_code_end

;------------------------------------------------------------------------------
		org $0
		adr image1_start
		adr image1_end-image1_start  ; labels only work here, if data below is less than 64K
		org $070000
image1_start

img_court	  putbin data\maps\test.256

namco_font    putbin data\namco_font.font

image1_end

;------------------------------------------------------------------------------

; Launch Address
		adr start
		adr 0		; 0 length, tells the loader that this is where to run the code

;------------------------------------------------------------------------------

