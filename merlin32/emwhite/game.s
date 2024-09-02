;
; Merlin32 Line draw example for Jr
;
; To Assemble "merlin32 -v . link.s"
;
		mx %11

io_ctrl  equ 1

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

RAST_COL = $D018
RAST_ROW = $D01A

start

; This will copy the color table into memory, then set the video registers
; to display the bitmap

		jsr init320x240

		jsr initColors

		jsr TermInit

		ldx #60
		ldy #1
		jsr TermSetXY

		lda #<txt_title
		ldx #>txt_title
		jsr TermPUTS

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

main_loop

		bra main_loop

;------------------------------------------------------------------------------

init320x240
		php
		sei

		; Access to vicky generate registers
		stz io_ctrl

		; enable the graphics mode
		lda #%00100111  ; sprite + graph + +overlay + text
		sta VKY_MSTR_CTRL_0

		lda #0
		sta VKY_MSTR_CTRL_1

		; layer stuff - take from Jr manual
		lda #$10
		sta VKY_LAYER_CTRL_0  ; tile map layers
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
		stz VKY_BM0_ADDR_L
		stz VKY_BM0_ADDR_M
		lda #1
		sta VKY_BM0_ADDR_H

		stz VKY_BM1_ADDR_L
		stz VKY_BM1_ADDR_M
		sta VKY_BM1_ADDR_H

		lda #2
		sta io_ctrl
		plp

		rts
;------------------------------------------------------------------------------

txt_title asc 'game thing'
		db 13,0

;------------------------------------------------------------------------------

WaitVBLPoll
		lda $1
		pha
		stz $1
LINE_NO = 241*2
        lda #<LINE_NO
        ldx #>LINE_NO
:waitforlineAX		
]wait
        cpx $D01B
        beq ]wait
]wait
        cmp $D01A
        beq ]wait

]wait
        cpx $D01B
        bne ]wait
]wait
        cmp $D01A
        bne ]wait
		pla 
		sta $1
        rts

;------------------------------------------------------------------------------

