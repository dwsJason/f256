
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

;------------------------------------------------------------------------------

		use macros.i
		use mixer.i

;------------------------------------------------------------------------------

		mx %11
		org $0
		dsk xmas.pgz
		db	'Z'   			; PGZ header upper case Z means 24 bit size/length fields

;------------------------------------------------------------------------------

; Segment 0
		org $0
		adr main_code_start 			 	; Address to load into memory
		adr main_code_end-main_code_start   ; Length of data to load into their

		org $200
main_code_start
		put xmas.s
		put intro.s
		put term.s
		put mmu.s
		put lzsa2.s
		put file256.s
		put spritefont.s
		put irq.s
		put mod.s
		put mixer.s
		put version.s   ; hardware version checker
main_code_end

;------------------------------------------------------------------------------

		org $0
		adr song_start
		adr song_end-song_start
		org $040000
song_start
mod_xmas putbin data\xmas_remix.mod
song_end

;------------------------------------------------------------------------------

		org $0
		adr image1_start
		adr image1_end-image1_start  ; labels only work here, if data below is less than 64K
		org $060000
image1_start
pic1	putbin data\fireplace_big.256
image1_end

;------------------------------------------------------------------------------

		org $0
		adr image2_start
		adr image2_end-image2_start  ; labels only work here, if data below is less than 64K
		org $077000
image2_start
pic2    putbin data\introtall.256
f6font  putbin data\32x32-F6.256     ; decompresses on top of the fireplace, and introtall
image2_end

;------------------------------------------------------------------------------

; Launch Address
		adr start
		adr 0		; 0 length, tells the loader that this is where to run the code

;------------------------------------------------------------------------------

