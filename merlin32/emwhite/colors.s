;------------------------------------------------------------------------------
;
; Colors - Predefined Color Tables, and helper functions for dealing with color
;

;------------------------------------------------------------------------------

initColors
		php
		sei
		lda io_ctrl
		pha

		; Copy the colors up into the text luts

		stz io_ctrl

		ldx #{16*4}-1       ; 16 colors
]lp
		lda |gs_colors,x
		sta |VKY_TXT_FGLUT,x
		sta |VKY_TXT_BGLUT,x
		dex
		bpl ]lp

		; Set the background color, and the border color

		ldx #2
]lp
		lda |gs_colors+{4*2},x ; Dark Blue index 2
		stz |VKY_BKG_COL_B,x
		stz |VKY_BRDR_COL_B,x  ; <--- zero background on purpose
		dex
		bpl ]lp

		; setup border?
		stz |VKY_BRDR_CTRL
		stz VKY_BRDR_VERT
		stz VKY_BRDR_HORI


		; copy the first 16 colors up into the normal graphics luts

		inc io_ctrl	; io_ctrl = 1

		ldx #{16*4}-1       ; 16 colors
]lp
		lda |game_colors,x
		sta |VKY_GR_CLUT_0,x
		sta |VKY_GR_CLUT_1,x
		sta |VKY_GR_CLUT_2,x
		sta |VKY_GR_CLUT_3,x
		dex
		bpl ]lp

		; clear the text color matrix to white

		lda #3
		sta io_ctrl

		ldx #0
		lda #$F2	; white on blue
]lp
		sta $C000,x
		sta $C100,x
		sta $C200,x
		sta $C300,x
		sta $C400,x
		sta $C500,x
		sta $C600,x
		sta $C700,x
		sta $C800,x
		sta $C900,x
		sta $CA00,x
		sta $CB00,x
		sta $CC00,x
		sta $CD00,x
		sta $CE00,x
		sta $CF00,x
		dex
		bne ]lp

		pla
		sta io_ctrl
		plp
		rts

;------------------------------------------------------------------------------
;GS Border Colors
border_colors
 dw $0,$d03,$9,$d2d,$72,$555,$22f,$6af ; Border Colors
 dw $850,$f60,$aaa,$f98,$d0,$ff0,$5f9,$fff
;------------------------------------------------------------------------------
gs_colors
	adrl $ff000000  ;0 Black
	adrl $ffdd0033	;1 Deep Red
	adrl $ff000099	;2 Dark Blue
	adrl $ffdd22dd	;3 Purple
	adrl $ff007722	;4 Dark Green
	adrl $ff555555	;5 Dark Gray
	adrl $ff2222ff	;6 Medium Blue
	adrl $ff66aaff	;7 Light Blue
	adrl $ff885500	;8 Brown
	adrl $ffff6600	;9 Orange
	adrl $ffaaaaaa	;A Light Gray
	adrl $ffff9988	;B Pink
	adrl $ff00dd00	;C Light Green
	adrl $ffffff00	;D Yellow
	adrl $ff55ff99	;E Aquamarine
	adrl $ffffffff	;F White

game_colors
	adrl $ff000000
	adrl $ff2121FF
	adrl $ff00FF00
	adrl $ff00FFFF
	adrl $ff47B7AE
	adrl $ff47B7FF
	adrl $ffFF0000
	adrl $ffDE9751
	adrl $ffFFB751
	adrl $ffFFFF00
	adrl $ffFFB7AE
	adrl $ffFFB7FF
	adrl $ffDEDEFF
	adrl $ffffff00	;D Yellow
	adrl $ff55ff99	;E Aquamarine
	adrl $ffffffff	;F White





;------------------------------------------------------------------------------
