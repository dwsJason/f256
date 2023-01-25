;
; Generally a Merlin32 link file either produces several binary outputs
; or an OMF
;
; This one attempts to produce a PGZ executable
;
; This file contains an uncompress 320x240 bitmap, and colors
; just copy the color table, and set video mode to display
;

		mx %11
		org $0
		dsk bitmap.pgz
		db	'Z'   			; PGZ header upper case Z means 24 bit size/length fields

; Segment 0
		org $0
		adr main_code_start 			 	; Address to load into memory
		adr main_code_end-main_code_start   ; Length of data to load into their

		org $200
main_code_start
		put bitmap.s
main_code_end

		org $0
		adr image_start
		; $$TODO - There is a bug in merlin preventing me from using labels
		; because the binary data is larger than 64K
		adr 320*240       ; image_end-image_start

		org $010000
image_start
		putbin data\phoenix-rising.raw   ; 320x240 pixels data  76800 bytes
;		putbin data\redimage.raw   ; 320x240 pixels data  76800 bytes
image_end

		org $0
		adr colors_start
		adr colors_end-colors_start

		org $030000
colors_start
		putbin data\phoenix-rising.pal
;		putbin data\redimage.pal
colors_end


; Launch Address
		adr start
		adr 0		; 0 length, tells the loader that this is where to run the code

