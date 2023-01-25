;
; Merlin32 Cross Dev Stub for the Jr Micro Kernel
;
; To Assemble "merlin32 -v xdev.s"
;
		mx %11

; Will try $13E000, trying to put this some place that we won't depend on
; expansion RAM seems like a good try

		org $A000
		dsk xdev.bin
sig		db $f2,$56		; signature
		db 1            ; 1 8k block
		db 5            ; mount at $a000
		da start		; start here
		dw 0			; version
		dw 0			; kernel
		asc 'XDEV'
		db 0

start
		stz sig
		jmp start

