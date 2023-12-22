;
; fnxMas 2023 - LET IT SNOW!!
;
; Each Snow Canvas is 960x1216, the top 16 pixels is the catalog
;                     992x1248, with padding
;
; 60 tiles wide x 76 tiles tall, I've added a 1 tile border for the vicky hardware
;
; 62 tiles wide x 78 tiles tall.
;
; It's 3 screens wide, repeating pattern, the idea is X position for center
; should be used by default, then you can scroll indefinitely / left / right
; and by adjusting coordinates we get wrapping
;
; the top 480 pixels (ignoring the first 32, because dummy row + catalog)
; are setup to repeat, so that as we scroll off the top we just add 240 to the
; vertical scroll register to get it to repeat indefinitely
;
		mx %11

;------------------------------------------------------------------------------
SnowInit
		rts

;------------------------------------------------------------------------------

SnowPump
		rts

;------------------------------------------------------------------------------

