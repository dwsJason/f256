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
CLUT_DATA  = $030000

;
; This will copy the color table into memory, then set the video registers
; to display the bitmap
;

start
		sei

; We're going to load compressed picture data at $04/0000, since currently
; Jr Vicky can't see above this



; Going to image at $01/0000
; Going to put palette at $03/0000 
]wait bra ]wait

; memory bus addresses
:pic_table_low
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
:pic_Table_h
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
		; copy CLUT
		do 0
		ldy #0  ; 256 total colors to copy
]lp
		ldx #2    ; copy 1 color

src		lda $2000,x
dst		sta VKY_GR_CLUT_0,x
		dex
		bpl src

		clc
		lda src+1
		adc #3
		sta src+1
		bcc :next
		inc src+2
		clc
:next
		lda dst+1
		adc #4
		sta dst+1
		bcc :next2
		inc dst+2
:next2  
		dey
		bne ]lp
		fin

		lda #<$2000
		sta temp0
		lda #>$2000
		sta temp0+1

		lda #<VKY_GR_CLUT_0
		sta temp0+2
		lda #>VKY_GR_CLUT_0
		sta temp0+3

		ldx #0
]lp
		jsr ReadColor
		jsr WriteColor
		dex
		bne ]lp

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
		lda #<image_start
		sta $D101
		lda #>image_start
		sta $D102
		lda #^image_start
		sta $D103

		lda #1
		sta $D100  ; bitmap enable, use clut 0
		stz $D108  ; disable
		stz $D110  ; disable



; this stops the program from exiting back into DOS or SuperBASIC 
; so we can see
:wait   bra :wait  
		rts
; Read a color
ReadColor
:pSrc = temp0
:pDst = temp0+2

:r = temp1
:g = temp1+1
:b = temp1+2

:p = temp2

		clc
		lda <:pSrc
		adc :x3table_lo,x
		sta <:p
		lda <:pSrc+1
		adc :x3table_hi,x
		sta <:p+1

		ldy #0
		lda (:p),y
		sta <:r
		iny
		lda (:p),y
		sta <:g
		iny
		lda (:p),y
		sta <:b

		rts

:x3table_lo
]v = 0
	lup 256
	db ]v
]v = ]v+3
	--^
:x3table_hi
]v = 0
	lup 256
	db ]v/256
]v = ]v+3
	--^

WriteColor
:b = temp1+2
:g = temp1+1
:r = temp1

:pSrc = temp0
:pDst = temp0+2

:p = temp2

		clc
		lda <:pDst
		adc :x4table_lo,x
		sta <:p
		lda <:pDst+1
		adc :x4table_hi,x
		sta <:p+1

		ldy #0
		lda :b
		sta (:p),y
		iny
		lda :g
		sta (:p),y
		iny
		lda :r
		sta (:p),y
		iny
		lda #$FF
		sta (:p),y ; A

		rts


:x4table_lo
]v = 0
	lup 256
	db ]v
]v = ]v+4
	--^

:x4table_hi
]v = 0
	lup 256
	db ]v/256
]v = ]v+4
	--^

