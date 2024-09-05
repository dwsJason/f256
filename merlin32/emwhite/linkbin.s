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


; Best to make sure $1 is set to 0 before calling anything here

; jsr $2000  ; test harness -> chaos

; jsr $2003  ; Initialize Things (will load palette, initialize random hardware, change your video mode)
			 ; you may need to call this, then tweak the video mode again
			 ; this is also going to stomp on your color palettes for the text
			 ; destiend to be called once, and only once
			 ;
			 ; once this is called it is safe to call other functions
			 ; 
; jsr $2006  ; FramePump	 
;
; jsr $2009  ; SpawnEnemy    $41-42 -> X position 0->319
			 ;  			 $43    -> Load with the object you want - table below
			 ;  			 $44    -> size 0->3  (small to large)

; jsr $200C  ; CollideMissile  (even this needs 0 stored into $1 for the mmu)
			 ;
             ;
             ;  AX = X pixel position 0-319   (A is low, X is high)
             ;   Y = Y pixel position 0-240
             ;
             ; return    c=0    ; no collision
             ;           c=1    ; collision
             ;
             ;           A=number of collisions
             ;

; jsr $200F  ; WaitVBLPoll (this literally won't return until the raster is in the right place)
             ; in my code I call this, then I run the FramePump


; Spawn object numbers
;SPRITE_MSPAC_RIGHT  =  0
;SPRITE_MSPAC_LEFT   =  1
;SPRITE_PAC_RIGHT    =  2
;SPRITE_PAC_LEFT     =  3
;SPRITE_BLINKY_RIGHT =  4
;SPRITE_BLINKY_LEFT  =  5
;SPRITE_PINKY_RIGHT  =  6
;SPRITE_PINKY_LEFT   =  7
;SPRITE_INKY_RIGHT   =  8
;SPRITE_INKY_LEFT    =  9
;SPRITE_CLYDE_LEFT   =  10
;SPRITE_CLYDE_RIGHT  =  11
;SPRITE_GHOST_BLUE   =  12
;SPRITE_GHOST_WHITE  =  13
;SPRITE_CHERRY       =  14
;SPRITE_STRAWBERRY   =  15
;SPRITE_ORANGE       =  16
;SPRITE_PRETZEL      =  17
;SPRITE_APPLE        =  18
;SPRITE_PEAR         =  19
;SPRITE_BANANA       =  20
;SPRITE_HEART        =  21
;SPRITE_GRENADE      =  22
;SPRITE_SHIP         =  23
;SPRITE_BELL         =  24
;SPRITE_KEY          =  25

