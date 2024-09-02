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

	dend

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

		stz io_ctrl  ; access sprite registers

;]spr_size = %00000001 ; 32x32
;]spr_size = %00100001  ; 24x24
;]spr_size = %01000001  ; 16x16
]spr_size = %01100001  ; 8x8

:x = temp0
:y = temp1
:sprite_frame = temp2
:pSprite = temp3

		lda #32
		sta <:x
		stz <:x+1

		sta <:y
		stz <:y+1
		

		lda #<sprite_sheet32
		lda #<sprite_sheet24
		lda #<sprite_sheet16
		lda #<sprite_sheet8
		sta <:sprite_frame+0

		lda #>sprite_sheet32
		lda #>sprite_sheet24
		lda #>sprite_sheet8
		sta <:sprite_frame+1

		lda #^sprite_sheet32
		lda #^sprite_sheet24
		lda #^sprite_sheet8
		sta <:sprite_frame+2

		lda #<VKY_SP0_CTRL
		sta <:pSprite
		lda #>VKY_SP0_CTRL
		sta <:pSprite+1

		ldx #8
		ldy #8
]lp
		; plot sprite frame a :x,:y
		lda #]spr_size
		jsr :store
		lda :sprite_frame
		jsr :store
		lda :sprite_frame+1
		jsr :store
		lda :sprite_frame+2
		jsr :store

		lda :x
		jsr :store
		lda :x+1
		jsr :store

		lda :y
		jsr :store
		lda :y+1
		jsr :store

		; sprite_frame increment
		clc
		;32x32
		;lda <:sprite_frame+1
		;adc #$04
		;sta <:sprite_frame+1

		;24x24
		;lda <:sprite_frame
		;adc #$40
		;sta <:sprite_frame
		;lda <:sprite_frame+1
		;adc #$02
		;sta <:sprite_frame+1

		;16x16
		;inc <:sprite_frame+1

		;8x8
		lda <:sprite_frame
		adc #64
		sta <:sprite_frame
		lda <:sprite_frame+1
		adc #0
		sta <:sprite_frame+1

		clc
		lda <:x
		adc #32
		sta <:x
		lda <:x+1
		adc #0
		sta <:x+1

		dex
		bne ]lp

		; next line
		ldx #8

		clc
		lda <:y
		adc #32  	; inc y
		sta <:y

		lda #32
		sta <:x  	; reset x
		stz <:x+1

		dey
		bne ]lp

]wait
		bra ]wait

:store
		sta (:pSprite)
		inc :pSprite
		bne :rts
		inc :pSprite+1
:rts	rts



;------------------------------------------------------------------------------
;
; Some Kernel Stuff here
;
		;ldax #event_data
		;stax kernel_args_events
main_loop

		;jsr kernel_NextEvent
		;bcs :no_events
		;jsr DoKernelEvent
:no_events

		bra main_loop

;------------------------------------------------------------------------------

init320x240
		php
		sei

		; Access to vicky generate registers
		stz io_ctrl

		; enable the graphics mode
		; X GAMMA SPRITE TILE BITMAP GRAPH OVRLY TEXT

		lda #%00100111  ; sprite + graph + overlay + text
		sta VKY_MSTR_CTRL_0

		lda #0
		sta VKY_MSTR_CTRL_1

		; layer stuff - take from Jr manual
		;lda #$10
		;sta VKY_LAYER_CTRL_0  ; tile map layers
		;lda #$02
		;sta VKY_LAYER_CTRL_1  ; tile map layers

		; Tile Map Disable
		stz VKY_TM0_CTRL
		stz VKY_TM1_CTRL
		stz VKY_TM2_CTRL

		; bitmap disables
		stz VKY_BM0_CTRL  ; disable
		stz VKY_BM1_CTRL  ; disable
		stz VKY_BM2_CTRL  ; disable

		stz VKY_BRDR_CTRL

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

