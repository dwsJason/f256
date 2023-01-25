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
		put mmu.s
		put lzsa2.s
		put bitmap.s
main_code_end

		org $0
		adr image_start
		adr image_end-image_start  ; labels only work here, if data below is less than 64K

		org $040000
image_start
pic0
		putbin data\phoenix-rising.256
image_end

		org $0
		adr image2_start
		adr image2_end-image2_start  ; labels only work here, if data below is less than 64K
		org $050000

image2_start
pic1	putbin data\timefont.256
pic2    putbin data\tlb1r.256
pic3    putbin data\to1_font.256
pic4    putbin data\transfnt.256
pic5    putbin data\tristarf.256
pic6    putbin data\unknown1r.256
pic7    putbin data\woodfont.256
pic8    putbin data\xlcolfnt.256
image2_end

; Launch Address
		adr start
		adr 0		; 0 length, tells the loader that this is where to run the code

