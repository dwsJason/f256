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
		put macros.i.s
;------------------------------------------------------------------------------

sprite_sheet32 = $010000
sprite_sheet24 = $020000
sprite_sheet16 = $030000
sprite_sheet8  = $038000

		mx %11
		org $0
		dsk game.pgz
		db	'Z'   			; PGZ header upper case Z means 24 bit size/length fields

; Segment 0
		org $0
		adr main_code_start 			 	; Address to load into memory
		adr main_code_end-main_code_start   ; Length of data to load into their

		org $2000
main_code_start
		put game.s
		put term.s
		put colors.s
main_code_end


; place raw sprite data into upper 192k
		org $0
		adr bank1_start
		adr bank1_end-bank1_start
		org $010000
bank1_start
		putbin data\tiles32.raw
bank1_end

		org $0
		adr bank2_start
		adr bank2_end-bank2_start
		org $020000
bank2_start
		putbin data\tiles24.raw
bank2_end

		org $0
		adr bank3_start
		adr bank3_end-bank3_start
		org $030000
bank3_start
		putbin data\tiles16.raw
bank3_end

		org $0
		adr bank4_start
		adr bank4_end-bank4_start
		org $038000
bank4_start
		putbin data\tiles8.raw
bank4_end

; Launch Address
		adr start
		adr 0		; 0 length, tells the loader that this is where to run the code

