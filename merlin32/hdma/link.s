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
		put ..\jr\f256_xymath.asm

;------------------------------------------------------------------------------


		mx %11
		org $0
		dsk hdma.pgz
		db	'Z'   			; PGZ header upper case Z means 24 bit size/length fields

; Segment 0
		org $0
		adr main_code_start 			 	; Address to load into memory
		adr main_code_end-main_code_start   ; Length of data to load into their

		org $200
main_code_start
		put hdma.s
		put term.s
		put mmu.s
		put lzsa2.s
		put file256.s
main_code_end

		org $0
		adr image2_start
		adr image2_end-image2_start  ; labels only work here, if data below is less than 64K
		org $070000

image2_start
pic1	putbin data\ehonda_floor.256
pic2    putbin data\ehonda_bg.256
image2_end

; Launch Address
		adr start
		adr 0		; 0 length, tells the loader that this is where to run the code

