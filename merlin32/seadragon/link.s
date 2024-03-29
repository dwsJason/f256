;
; Generally a Merlin32 link file either produces several binary outputs
; or an OMF
;
; This one attempts to produce a PGZ executable
;
; This file contains an uncompress 320x240 bitmap, and colors
; just copy the color table, and set video mode to display
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

;------------------------------------------------------------------------------


		mx %11
		org $0
		dsk seadragon.pgz
		db	'Z'   			; PGZ header upper case Z means 24 bit size/length fields

; Segment 0
		org $0
		adr main_code_start 			 	; Address to load into memory
		adr main_code_end-main_code_start   ; Length of data to load into their

		org $400
main_code_start
		put seadragon.s
		put term.s
		put mmu.s
		put colors.s
main_code_end

; Segment 1
		org $0
		adr wave_start
		adr wave_end-wave_start

		org $70000
wave_start
sea_wave putbin data/seadragon11k.raw
wave_end

		org $0
; Launch Address
		adr start
		adr 0		; 0 length, tells the loader that this is where to run the code

