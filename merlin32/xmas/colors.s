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
		sta |VKY_BKG_COL_B,x
		sta |VKY_BRDR_COL_B,x
		dex
		bpl ]lp

		; copy the first 16 colors up into the normal graphics luts

		inc io_ctrl	; io_ctrl = 1

		ldx #{16*4}-1       ; 16 colors
]lp
		lda |gs_colors,x
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
;		lda #$F0	; white on transparent
;		lda #0
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
	adrl $ffff0033
	;adrl $ffdd0033	;1 Deep Red
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

;------------------------------------------------------------------------------
; Pump Bar colors
vu_colors_off
	adrl $ff0B0000
	adrl $ff0B0100
	adrl $ff0B0200
	adrl $ff0C0300
	adrl $ff0C0400
	adrl $ff0C0500
	adrl $ff0D0600
	adrl $ff0D0800
	adrl $ff0D0900
	adrl $ff0E0A00
	adrl $ff0E0B00
	adrl $ff0E0C00
	adrl $ff0F0D00
	adrl $ff0F0E00
	adrl $ff0F0F00

vu_colors_on
	adrl $ffB00202
	adrl $ffB61402
	adrl $ffBB2602
	adrl $ffC13802
	adrl $ffC74A01
	adrl $ffCC5C01
	adrl $ffD26E01
	adrl $ffD88001
	adrl $ffDD9301
	adrl $ffE3A501
	adrl $ffE8B701
	adrl $ffEEC900 
	adrl $ffF4DB00 
	adrl $ffF9ED00 
	adrl $ffFFFF00 

vu_colors_peak
	adrl $ff080808
	adrl $ff080808
	adrl $ff080808
	adrl $ff080808
	adrl $ff080808

	adrl $ff080808
	adrl $ff080808
	adrl $ff080808
	adrl $ff080808
	adrl $ff080808
			 
	adrl $ff080808
	adrl $ff080808
	adrl $ff080808
	adrl $ff080808
	adrl $ff080808

;------------------------------------------------------------------------------

