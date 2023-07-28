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
		dsk lbm.pgz
		db	'Z'   			; PGZ header upper case Z means 24 bit size/length fields

; Segment 0
		org $0
		adr main_code_start 			 	; Address to load into memory
		adr main_code_end-main_code_start   ; Length of data to load into their

		org $200
main_code_start
		put main.s
		put term.s
		put mmu.s
		put lbm.s
main_code_end

		org $0
		adr image2_start
		adr image2_end-image2_start  ; labels only work here, if data below is less than 64K
		org $070000

image2_start
pic0    putbin data\CAT.LBM
pic1    putbin data\CAT2.LBM
pic2    putbin data\CRATE.LBM
pic3    putbin data\CRATE2.LBM
pic4    putbin data\CUBES.LBM
pic5    putbin data\DRIP.LBM
pic6    putbin data\FRED.LBM
image2_end

		org $0
		adr image3_start
		adr image3_end-image3_start  ; labels only work here, if data below is less than 64K
		org $060000

image3_start
pic7    putbin data\GOPHER.LBM
pic8    putbin data\GOPHER2.LBM
pic9    putbin data\HEART.LBM
pic10   putbin data\LIGHTENI.LBM
pic11   putbin data\PEGUIN.LBM
pic12   putbin data\SAM.LBM
image3_end

		org $0
		adr image4_start
		adr image4_end-image4_start  ; labels only work here, if data below is less than 64K
		org $050000

image4_start
pic13   putbin data\SNAIL.LBM
pic14   putbin data\SNOWB.LBM
pic15   putbin data\SON.LBM
image4_end

; Launch Address
		adr start
		adr 0		; 0 length, tells the loader that this is where to run the code

