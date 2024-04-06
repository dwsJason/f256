
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
		dsk frisbee.pgz
		db	'Z'   			; PGZ header upper case Z means 24 bit size/length fields

;------------------------------------------------------------------------------

; Segment 0
		org $0
		adr main_code_start 			 	; Address to load into memory
		adr main_code_end-main_code_start   ; Length of data to load into their

		org $300
main_code_start
		put frisbee.s
		put term.s
		put mmu.s
		put lzsa2.s
		put i256.s
		put colors.s
main_code_end

;------------------------------------------------------------------------------
;		org $0
;		adr more_data_start
;		adr more_data_end-more_data_start
;		org $6000
;more_data_start
;
;pump_bar_sprites putbin data\pumpbars.256
;snow_bg putbin data\SnowBackground.256
;snow_fg putbin data\SnowForeGround.256
;beep_start putbin data\beep16khz.raw
;beep_end
;
;more_data_end
;
;------------------------------------------------------------------------------
;		org $0
;		adr audio_data_start
;		adr audio_data_end-audio_data_start
;		org $35800		; right after double high pixel buffer
;audio_data_start
;
;hohoho putbin data\ho-ho-ho-11khz.raw
;
;audio_data_end
;
;------------------------------------------------------------------------------
;
;		org $0
;		adr song_start
;		adr song_end-song_start
;		org $040000
;song_start
;mod_xmas putbin data\xmas_remix.mod
;song_end
;
;------------------------------------------------------------------------------

		org $0
		adr image1_start
		adr image1_end-image1_start  ; labels only work here, if data below is less than 64K
		org $070000
image1_start
	;
	; The course map is 22x17 tiles
	;
img_court	  putbin data\JapanCourt.256

baller_sheet  putbin data\baller_sheet.256

image1_end

;------------------------------------------------------------------------------
;
;		org $0
;		adr image2_start
;		adr image2_end-image2_start  ; labels only work here, if data below is less than 64K
;		org $077000
;image2_start
;f6font  putbin data\32x32-F6.256     ; decompresses on top of the fireplace, and introtall
;pic2    putbin data\introtall.256
;image2_end
;
;------------------------------------------------------------------------------

; Launch Address
		adr start
		adr 0		; 0 length, tells the loader that this is where to run the code

;------------------------------------------------------------------------------

