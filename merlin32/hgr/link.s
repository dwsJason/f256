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
		dsk hgr.pgz
		db	'Z'   			; PGZ header upper case Z means 24 bit size/length fields

; Segment 0
		org $0
		adr main_code_start 			 	; Address to load into memory
		adr main_code_end-main_code_start   ; Length of data to load into their

		org $400
main_code_start
		put hgr.s
		put mmu.s
main_code_end

		org $0
		adr images_start
		; $$TODO - There is a bug in merlin preventing me from using labels
		; because the binary data is larger than 64K
		adr images_end-images_start

		org $030000
images_start
blitz_image      putbin data\blitz.hgr
hardhat_image    putbin data\hardhat.hgr
starblazer_image putbin data\starblazer.hgr
images_end

; Launch Address
		adr start
		adr 0		; 0 length, tells the loader that this is where to run the code

