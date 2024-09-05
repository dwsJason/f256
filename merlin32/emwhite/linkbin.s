;
; Generate a bin file
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
;
; in theory you can change these addresses and the code should still work
; just need to be careful to not let the data overlap
;
sprite_sheet32 = $010000
sprite_sheet24 = $020000
sprite_sheet16 = $030000
sprite_sheet8  = $038000


		mx %11
		dsk game.2000    ; generate file called game.2000

		org $2000
		put game.s
		put term.s
		put colors.s

; some clever math, and some file concatenation could bring the data
; down to a single load, sorry I don't have time this morning
;
; tiles32.raw at $010000
; tiles24.raw at $020000
; tiles16.raw at $030000
; tiles8.raw  at $038000
;



