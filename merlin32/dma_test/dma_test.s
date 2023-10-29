;
; Merlin32 Line draw example for Jr
;
; To Assemble "merlin32 -v . link.s"
;
		mx %11

; System Bus Pointer's
;pSource  equ $10
;pDest    equ pSource+4
; Do not use anything below $20, the mmu module owns it

	dum $20
temp0 ds 4
temp1 ds 4
temp2 ds 4
temp3 ds 4
temp4 ds 4
temp5 ds 4
temp6 ds 4
temp7 ds 4
	dend

PIXEL_DATA = $010000

start

; This will copy the color table into memory, then set the video registers
; to display the bitmap

		jsr init320x240

		jsr initColors

		jsr TermInit

		lda #<txt_title
		ldx #>txt_title
		jsr TermPUTS

		jsr mmu_unlock ; just being lazy here, don't use the mmu functions
					   ; $6000 is both read and write block


		lda #2  	; Fill Color
		jsr DmaClear

;------------------------------------------------------------------------------
;
; Color Cycle Loop for the clears
;
]clamp
		lda #1
]speed
		pha
		jsr DmaClearWithSmallDMA

		pla
		dec
		bpl ]speed

		bra ]clamp


]wait bra ]wait

;------------------------------------------------------------------------------
;
; A = Fill Color
;
; Clear 320x240 buffer PIXEL_DATA with A, but do it 1 pixel at a time.
;
DmaClearWithSmallDMA
:color = temp1
:pPixelData = temp0
]size = {320*240}
]DONE_ADDRESS = PIXEL_DATA+]size

		sta <:color

		lda #<PIXEL_DATA
		sta <:pPixelData
		lda #>PIXEL_DATA
		sta <:pPixelData+1
		lda #^PIXEL_DATA
		sta <:pPixelData+2

		php
		sei

		ldy io_ctrl
		phy

		stz io_ctrl

]loop
		ldx #DMA_CTRL_ENABLE+DMA_CTRL_FILL
		stx |DMA_CTRL

		lda <:color
		sta |DMA_FILL_VAL

		lda <:pPixelData
		sta |DMA_DST_ADDR
		lda <:pPixelData+1
		sta |DMA_DST_ADDR+1
		lda <:pPixelData+2
		sta |DMA_DST_ADDR+2

		lda #1
		sta |DMA_COUNT
		stz |DMA_COUNT+1
		stz |DMA_COUNT+2

		lda #DMA_CTRL_START
		tsb |DMA_CTRL

]busy
		lda |DMA_STATUS
		bmi ]busy

		stz |DMA_CTRL


		inc <:pPixelData
		bne :check_done

		inc <:pPixelData+1
		bne :check_done

		inc <:pPixelData+2

:check_done

		lda <:pPixelData+2
		cmp #^]DONE_ADDRESS
		bne ]loop

		lda <:pPixelData+1
		cmp #>]DONE_ADDRESS
		bne ]loop

		lda <:pPixelData+0
		cmp #<]DONE_ADDRESS
		bne ]loop

		pla
		sta io_ctrl

		plp
		rts

;------------------------------------------------------------------------------



;------------------------------------------------------------------------------

init320x240
		php
		sei

		; Access to vicky generate registers
		stz io_ctrl

		; enable the graphics mode
;;		lda #%00001111	; gamma + bitmap + graphics + overlay + text
;		lda #%00000001	; text
		lda #%01111111  ; all the things
		sta VKY_MSTR_CTRL_0
		;lda #%110       ; text in 40 column when it's enabled
		;sta $D001
		lda #6
		stz VKY_MSTR_CTRL_1

		; layer stuff - take from Jr manual
;		lda #$54
		lda #$10
		sta VKY_LAYER_CTRL_0  ; tile map layers
;		lda #$06
		lda #$02
		sta VKY_LAYER_CTRL_1  ; tile map layers

		; Tile Map 0
		lda #$11
		sta $D200 ; tile size 8x8 + enable

		; Tile Map Disable
		stz VKY_TM0_CTRL
		stz VKY_TM1_CTRL
		stz VKY_TM2_CTRL

		; bitmap disables
		lda #1
		sta VKY_BM0_CTRL  ; enable
		stz VKY_BM1_CTRL  ; disable
		stz $D110  ; disable

		; set address of image, since image uncompressed, we just display it
		; where we loaded it.
		lda #<PIXEL_DATA
		sta VKY_BM0_ADDR_L
		lda #>PIXEL_DATA
		sta VKY_BM0_ADDR_M
		lda #^PIXEL_DATA
		sta VKY_BM0_ADDR_H

		; setup border - no border
		stz |VKY_BRDR_CTRL
		stz VKY_BRDR_VERT
		stz VKY_BRDR_HORI

		lda #2
		sta io_ctrl
		plp

		rts
;------------------------------------------------------------------------------

txt_title asc 'DMA Test'
		db 13,13,
		asc 'Fill the pixel buffer with 1 pixel size DMA requests.'
		db 13
		db 13
		asc 'Visualize the number of DMA transfer can happen in a single frame.'
		db 13,0


;------------------------------------------------------------------------------
;
; A = Fill Color
;
; Clear 320x240 buffer PIXEL_DATA with A
;
DmaClear
		php
		sei

		ldy io_ctrl
		phy

		stz io_ctrl

		ldx #DMA_CTRL_ENABLE+DMA_CTRL_FILL
		stx |DMA_CTRL

		sta |DMA_FILL_VAL

		lda #<PIXEL_DATA
		sta |DMA_DST_ADDR
		lda #>PIXEL_DATA
		sta |DMA_DST_ADDR+1
		lda #^PIXEL_DATA
		sta |DMA_DST_ADDR+2

]size = {320*240}

		lda #<]size
		sta |DMA_COUNT
		lda #>]size
		sta |DMA_COUNT+1
		lda #^]size
		sta |DMA_COUNT+2

		lda #DMA_CTRL_START
		tsb |DMA_CTRL

]busy
		lda |DMA_STATUS
		bmi ]busy

		stz |DMA_CTRL

		pla
		sta io_ctrl

		plp
		rts

;------------------------------------------------------------------------------


