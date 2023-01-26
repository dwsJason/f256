;
; Merlin32 Compressed Bitmap example for Jr
;
; To Assemble "merlin32 -v . link.s"
;
		mx %11

; Zero Page defines
;mmu_ctrl equ 0
io_ctrl  equ 1
; reserved addresses 2-7 for future expansion, use at your own peril
;mmu      equ 8
;mmu0     equ 8
;mmu1     equ 9
;mmu2     equ 10
;mmu3     equ 11
;mmu4     equ 12
;mmu5     equ 13
;mmu6     equ 14
;mmu7     equ 15

; System Bus Pointer's
;pSource  equ $10
;pDest    equ pSource+4



temp0 = $F0
temp1 = $F4
temp2 = $F8
temp3 = $FC

VKY_GR_CLUT_0 = $D000

PIXEL_DATA = $010000
CLUT_DATA  = $008000

;
; This will copy the color table into memory, then set the video registers
; to display the bitmap
;

start
		sei

; We're going to load compressed picture data at $04/0000, since currently
; Jr Vicky can't see above this
		jsr init320x240

		jsr mmu_unlock

		lda #<CLUT_DATA
		ldx #>CLUT_DATA
		ldy #^CLUT_DATA
		jsr set_write_address

		ldx #0 ; picture #
		jsr set_pic_address

		jsr decompress_clut

		; set access to vicky CLUTs
		lda #1
		sta io_ctrl
		; copy the clut up there
		ldx #0
]lp		lda CLUT_DATA,x
		sta VKY_GR_CLUT_0,x
		lda CLUT_DATA+$100,x
		sta VKY_GR_CLUT_0+$100,x
		lda CLUT_DATA+$200,x
		sta VKY_GR_CLUT_0+$200,x
		lda CLUT_DATA+$300,x
		sta VKY_GR_CLUT_0+$300,x
		dex
		bne ]lp

		ldx #0
		jsr set_pic_address
		jsr decompress_pixels

; Going to image at $01/0000
; Going to put palette at $03/0000 
]wait bra ]wait

;
; X = offset to picture to set
; 
set_pic_address
		lda :pic_table_h,x
		tay
		lda :pic_table_m,x
		pha
		lda :pic_table_l,x
		plx

		jmp set_read_address

; memory bus addresses
:pic_table_l
		db <pic0
		db <pic1
		db <pic2
		db <pic3
		db <pic4
		db <pic5
		db <pic6
		db <pic7
		db <pic8
:pic_table_m
		db >pic0
		db >pic1
		db >pic2
		db >pic3
		db >pic4
		db >pic5
		db >pic6
		db >pic7
		db >pic8
:pic_table_h
		db ^pic0
		db ^pic1
		db ^pic2
		db ^pic3
		db ^pic4
		db ^pic5
		db ^pic6
		db ^pic7
		db ^pic8

		; set access to vicky CLUTs
		lda #1
		sta io_ctrl

		lda mmu_ctrl
		pha  		  ; save to restore when done
		and #$3
		sta temp0     ; active MLUT
		asl
		asl
		asl
		asl
		ora temp0     ; active MLUT, copied to the EDIT LUT
		ora #$80      ; Enable MMU edit - we are editing the active (spooky)
		sta mmu_ctrl

		; set access to the CLUT we loaded
		; map the color_ram into page 1 or address $2000
		lda #CLUT_DATA/8192
		sta mmu+1

;-----------------------------------------------------------------------------

;---------------------------------------------
; zero out a section of the bitmap
;		lda #image_start/8192
;		sta mmu+1
;
;		ldx #0
;:lp
;		stz |$2000,x
;		dex
;		bne :lp
;
;		lda :lp+2
;		inc
;		sta :lp+2
;		cmp #$40
;		bcc :lp
;---------------------------------------------


		; map 2000 back to 2000
		lda #1
		sta mmu+1

		pla
		sta mmu_ctrl
;-----------------------------------------------------------------------------

init320x240
		; Access to vicky generate registers
		stz io_ctrl

		; enable the graphics mode
		;lda #%01001110	; gamma + bitmap + graphics + overlay, text disabled
		lda #%00001100	; bitmap + graphics 
		sta $D000
		;lda #%110       ; text in 40 column when it's enabled
		;sta $D001
		stz $D001


		; layer stuff - take from Jr manual
		stz $D002  ; layer ctrl 0
		stz $D003  ; layer ctrl 3

		; set address of image, since image uncompressed, we just display it
		; where we loaded it.
		lda #<PIXEL_DATA
		sta $D101
		lda #>PIXEL_DATA
		sta $D102
		lda #^PIXEL_DATA
		sta $D103

		lda #1
		sta $D100  ; bitmap enable, use clut 0
		stz $D108  ; disable
		stz $D110  ; disable

		rts

