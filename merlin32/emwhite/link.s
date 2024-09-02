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
		put ..\jr\f256_xymath.asm

;------------------------------------------------------------------------------


		mx %11
		org $0
		dsk game.pgz
		db	'Z'   			; PGZ header upper case Z means 24 bit size/length fields

; Segment 0
		org $0
		adr main_code_start 			 	; Address to load into memory
		adr main_code_end-main_code_start   ; Length of data to load into their

		org $300
main_code_start
		put game.s
		put term.s
		put colors.s
main_code_end


; place raw sprite data into upper 192k
		org $0
		adr bank1_start
		adr $10000 ;length  bank1_end-bank1_start
		org $010000
bank1_start
sprite_sheet32 putbin data\sheet32.data
bank1_end

		org $0
		adr bank2_start
		adr $10000 ;length  bank2_end-bank2_start
		org $020000
bank2_start
sprite_sheet24 putbin data\sheet24.data
bank2_end

		org $0
		adr bank3_start
		adr $10000 ;length  bank3_end-bank3_start
		org $030000
bank3_start
sprite_sheet816 putbin data\sheet816.data
bank3_end

; Launch Address
		adr start
		adr 0		; 0 length, tells the loader that this is where to run the code

