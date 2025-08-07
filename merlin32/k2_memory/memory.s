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

line_color ds 1
line_x0 ds 2
line_y0 ds 1
line_x1 ds 2
line_y1 ds 1

target_x0 ds 2
target_y0 ds 1

target_x1 ds 2
target_y1 ds 1


cursor_x ds 2
cursor_y ds 2

	dend

PIXEL_DATA = $40000
DMA_CLEAR_ADDY = PIXEL_DATA
DMA_CLEAR_LEN  = 320*240

start 	mx %11
		sei 	; disable interrupts, since the uKernel will crash in native

		sec	
		xce 	; into native CPU mode!


; This will copy the color table into memory, then set the video registers
; to display the bitmap

		jsr init320x240

		jsr initColors

		jsr TermInit

		ldx #70
		ldy #1
		jsr TermSetXY

		lda #<txt_title
		ldx #>txt_title
		jsr TermPUTS

		jsr mmu_unlock ; just being lazy here, don't use the mmu functions
					   ; $6000 is both read and write block

;------------------------------------------------------------------------------

		lda #2  	; Fill Color
		jsr DmaClear

;------------------------------------------------------------------------------
;
; Random Seed Init

		stz io_ctrl

		lda #$12
		sta |VKY_SEEDL
		lda #$34
		sta |VKY_SEEDH
		lda #3
		sta |VKY_RND_CTRL
		lda #1
		sta |VKY_RND_CTRL

;------------------------------------------------------------------------------


		lda #2
		sta io_ctrl

		ldx #0
		ldy #0
		jsr TermSetXY

		lda #<:txt
		ldx #>:txt
		jsr TermPUTS


;------------------------------------------------------------------------------

:count = temp0
:pLongText = temp1

		rep #$30
		stz <:count
]loop
		rep #$30
		lda <:count
		asl
		asl
		tax

		lda text_table,x
		sta :pLongText
		lda text_table+2,x
		sta :pLongText+2

		ora <:pLongText
		beq	:finished

		sep #$30

		lda <:pLongText
		ldx <:pLongText+1
		ldy <:pLongText+2
		jsr TermPrintAXYH

		lda #$38
		tsb mmu_ctrl

		ldy #0
]lp
		lda [:pLongText],y
		sta scratch_ram,y
		beq :copy_done
		iny
		bra ]lp

:copy_done
		lda #$38
		trb mmu_ctrl

		lda #<scratch_ram
		ldx #>scratch_ram
		jsr TermPUTS

		inc <:count

		bra ]loop

:finished
		mx %11

:wait 	bra :wait

:txt	asc ' !"#$%&'27'()*+,-./',0D
		asc '0123456789:;<=>?',0D
		asc '@ABCDEFGHIJKLMNO'0D
		asc 'PQRSTUVWXYZ[\]^_'0D
		asc '`abcdefghijklmno'0D
		asc 'pqrstuvwxyz{|}~'0D
		db 0

;------------------------------------------------------------------------------

txt_title asc 'Vectors'
		db 13,0

; Long Text Table

text_table
		adrl section_start1
		adrl section_start2
		adrl section_start3
; we've cleared this with DMA
;		adrl section_start4
; we've cleared this with DMA
;		adrl section_start5
		adrl section_start6
		adrl section_start7
		adrl section_start8
		adrl section_start9
		adrl section_startA
		adrl section_startB
		adrl section_startC
		adrl section_startD
		adrl section_startE
		adrl section_startF
		adrl section_start10

		adrl section_start11
		adrl section_start12
		adrl section_start13
		adrl section_start14
		adrl section_start15
		adrl section_start16
		adrl section_start17
		adrl section_start18
		adrl section_start19
		adrl section_start1A
		adrl section_start1B
		adrl section_start1C
		adrl section_start1D
		adrl section_start1E
		adrl section_start1F
		;adrl 0

		adrl section_startF4
		adrl 0

		adrl section_startF5
		;adrl section_startF6
		;adrl section_startF7

		adrl 0

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
		;lda #6
		;lda #1 ; clock_70
		lda #0
		sta VKY_MSTR_CTRL_1

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
		stz VKY_BM0_CTRL  ; enable
		sta VKY_BM1_CTRL  ; disable
		stz $D110  ; disable

		; set address of image, since image uncompressed, we just display it
		; where we loaded it.
		lda #<PIXEL_DATA
		sta VKY_BM0_ADDR_L
		lda #>PIXEL_DATA
		sta VKY_BM0_ADDR_M
		lda #^PIXEL_DATA
		sta VKY_BM0_ADDR_H

		lda #<PIXEL_DATA
		sta VKY_BM1_ADDR_L
		lda #>PIXEL_DATA
		sta VKY_BM1_ADDR_M
		lda #^PIXEL_DATA
		sta VKY_BM1_ADDR_H

		lda #2
		sta io_ctrl
		plp

		rts


;------------------------------------------------------------------------------
;
; A = Fill Color
;
; Clear 320x240 buffer PIXEL_DATA with A
;
DmaClear
		php
		sei

;]size = {320*240}
]size = DMA_CLEAR_LEN
;]addr = PIXEL_DATA
]addr = DMA_CLEAR_ADDY


		ldy io_ctrl
		phy

		stz io_ctrl

		ldx #DMA_CTRL_ENABLE+DMA_CTRL_FILL
		stx |DMA_CTRL

		sta |DMA_FILL_VAL

		lda #<]addr
		sta |DMA_DST_ADDR
		lda #>]addr
		sta |DMA_DST_ADDR+1
		lda #^]addr
		sta |DMA_DST_ADDR+2


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

scratch_ram
