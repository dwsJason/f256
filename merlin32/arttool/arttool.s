;
; Merlin32 ArtTool.PGX program, for Jr
;
; To Assemble "merlin32 -v arttool.s"
;

;------------------------------------------------------------------------------
; Include the hardware defs, from PJW

		put ..\jr\f256jr.asm
		put ..\jr\f256_dma.asm
		put ..\jr\f256_irq.asm
		put ..\jr\f256_rtc.asm
		put ..\jr\f256_sprites.asm
		put ..\jr\f256_tiles.asm
		put ..\jr\f256_timers.asm
		put ..\jr\f256_via.asm
		put ..\jr\f256_intmath.asm

;------------------------------------------------------------------------------

		use macros.i

;------------------------------------------------------------------------------

; Shared constants with the pc side

COMMANDLIST_START = $2000     ; need some commmon ground here
PIXEL_DATA        = $10000
CLUT_DATA         = $A000

;------------------------------------------------------------------------------

		mx %11

;PGX_CPU_65816 = $01
;PGX_CPU_680X0 = $02
PGX_CPU_65C02 = $03

		org $0
		dsk arttool.pgx
		db 'P','G','X' 		; PGX header
		db PGX_CPU_65C02    ; CPU - 65c02
		adrl start

		org $300   ;; reserve $200->$2FF for Command Line
             


;
; Zero Page
;
	dum $20
pCommands ds 2  ; current address in the command list
pTarget   ds 2  ; current target address for the current command
iLength   ds 2  ; current length of data to copy

temp0 ds 4
temp1 ds 4
temp2 ds 4
temp3 ds 4
temp4 ds 4
temp5 ds 4
temp6 ds 4
temp7 ds 4

	dend


;------------------------------------------------------------------------------
;
; I want to make this as small as possible, and as flexible as possible
; For now, it's just going to parse a command structure
;
;------------------------------------------------------------------------------
		dum 0
cmd_end		ds 2
cmd_io_ctrl ds 2    		; set io_ctrl, to next immediate value

cmd_mov_8	ds 2    		; copy the next immediate 8 bit value to following 2 byte address
cmd_mov_16  ds 2    		; copy the next immediate 16 bit value to the following 2 byte address
cmd_mov_24  ds 2   			; copy the next immediate 24 bit value to the following 2 byte address
cmd_mov_32  ds 2    		; copy the next immediate 32 bit value to the following 2 byte address

cmd_block_move_8    ds 2 	; copy variable data, small, length 8 bit, address 16 bit, length_num_bytes
cmd_block_move_16   ds 2 	; copy variable data, large, length 16 bit, address 16 bit, length_num_bytes

		dend

start
		sei
;------------------------------------------------------------------------------
		jsr default_hardware_init   ; sets the default video mode, etc

		jsr TermInit
		jsr initColors
		jsr mmu_unlock

		lda #2
		sta io_ctrl

		_TermPuts txt_version


]idle   wai
		bra ]idle
		bra ]idle
		bra ]idle
		bra ]idle
		bra ]idle
		bra ]idle
		bra ]idle
		bra ]idle
		
;------------------------------------------------------------------------------
		lda #<COMMANDLIST_START
		ldx #>COMMANDLIST_START
		sta pCommands
		stx pCommands+1
;------------------------------------------------------------------------------

		ldy #0
]loop
		lda (pCommands),y
		iny
		and #$F1!$FF		; safety feature, filter invalid commands
		tax
		jsr (:command,x)

		cpy #$F0
		bcc ]loop

		; when we're close to the end of a page, let's update the pCommands pointer
		tya
		ldy #0
		clc
		adc pCommands
		sta pCommands
		bcc ]loop

		inc pCommands+1

		bra ]loop

:command
		da command_end
		da command_io_ctrl
		da command_move_8
		da command_move_16
		da command_move_24
		da command_move_32
		da command_block_move_8
		da command_block_move_16

;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
command_end
		wai
;------------------------------------------------------------------------------
command_io_ctrl
		lda (pCommands),y
		iny
		sta io_ctrl
		rts
;------------------------------------------------------------------------------
command_move_8
		lda (pCommands),y    	; fetch target address
		iny
		sta pTarget
		lda (pCommands),y
		iny
		sta pTarget+1

		lda (pCommands),y   	; immediate data
		iny
		sta (pTarget)
		rts
;------------------------------------------------------------------------------
command_move_16

		lda (pCommands),y    	; fetch target address
		iny
		sta pTarget
		lda (pCommands),y
		iny
		sta pTarget+1

		lda (pCommands),y   	; immediate data
		iny
		sta (pTarget)

		pinc pTarget

		lda (pCommands),y   	; immediate data
		iny
		sta (pTarget)

		rts
;------------------------------------------------------------------------------
command_move_24

		lda (pCommands),y    	; fetch target address
		iny
		sta pTarget
		lda (pCommands),y
		iny
		sta pTarget+1

		lda (pCommands),y   	; immediate data
		iny
		sta (pTarget)

		pinc pTarget

		lda (pCommands),y   	; immediate data
		iny
		sta (pTarget)

		pinc pTarget

		lda (pCommands),y   	; immediate data
		iny
		sta (pTarget)

		rts
;------------------------------------------------------------------------------
command_move_32
		lda (pCommands),y    	; fetch target address
		iny
		sta pTarget
		lda (pCommands),y
		iny
		sta pTarget+1

		lda (pCommands),y   	; immediate data
		iny
		sta (pTarget)

		pinc pTarget

		lda (pCommands),y   	; immediate data
		iny
		sta (pTarget)

		pinc pTarget

		lda (pCommands),y   	; immediate data
		iny
		sta (pTarget)

		pinc pTarget

		lda (pCommands),y   	; immediate data
		iny
		sta (pTarget)

		rts
;------------------------------------------------------------------------------
command_block_move_8

		lda (pCommands),y    	; fetch target address
		iny
		sta pTarget
		lda (pCommands),y
		iny
		sta pTarget+1

		; get the length
		lda (pCommands),y
		tax  ; length
		iny
		;sta iLength
		;stz iLength+1
]loop
		lda (pCommands),y
		iny
		bne :y_ok
		inc pCommands+1
:y_ok
		sta (pTarget)
		pinc pTarget

		dex
		bne ]loop

		rts

;------------------------------------------------------------------------------
command_block_move_16

		lda (pCommands),y    	; fetch target address
		iny
		sta pTarget
		lda (pCommands),y
		iny
		sta pTarget+1

		; get the length
		lda (pCommands),y
		iny
		tax  ; iLength
;		sta iLength

		lda (pCommands),y
		iny
		sta iLength+1
]loop
		lda (pCommands),y
		iny
		bne :y_ok
		inc pCommands+1
:y_ok
		sta (pTarget)
		pinc pTarget

		dex
		bne ]loop

		lda iLength+1
		dec
		sta iLength+1
		cmp #$FF
		bne ]loop

		rts

;------------------------------------------------------------------------------
; Include the other modules

		put term.s
		put mmu.s
		put colors.s
;------------------------------------------------------------------------------

txt_version asc 0D,0D,'     Artist Download Tool Version 0.0',00

;------------------------------------------------------------------------------

default_hardware_init

		php
		sei

		; Access to vicky generate registers
		stz io_ctrl

		; enable the graphics mode
		lda #%00001111	; bitmap + graphics + overlay + text
		sta VKY_MSTR_CTRL_0
		stz VKY_MSTR_CTRL_1

		; layer stuff - take from Jr manual
		lda #$10
		sta VKY_LAYER_CTRL_0  ; bitmap layers
		lda #$02
		sta VKY_LAYER_CTRL_1  ; bitmap layers

		; Tile Map Disable
		stz VKY_TM0_CTRL
		stz VKY_TM1_CTRL
		stz VKY_TM2_CTRL

		; bitmap disables
		lda #1
		sta VKY_BM0_CTRL  ; enable
		stz VKY_BM1_CTRL  ; disable
		stz VKY_BM2_CTRL  ; disable

		; set address of image, since image uncompressed, we just display it
		; where we loaded it.
		lda #<PIXEL_DATA
		sta VKY_BM0_ADDR_L
		lda #>PIXEL_DATA
		sta VKY_BM0_ADDR_M
		lda #^PIXEL_DATA
		sta VKY_BM0_ADDR_H

;------------------------------------------------------------------------------
; copy your clut into LUT0
;

		lda CLUT_DATA
		sta VKY_BRDR_COL_B
		sta VKY_BKG_COL_B
		lda CLUT_DATA+1
		sta VKY_BRDR_COL_G
		sta VKY_BKG_COL_G
		lda CLUT_DATA+2
		sta VKY_BRDR_COL_R
		sta VKY_BKG_COL_R


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


;------------------------------------------------------------------------------

		; set access back to text buffer, for the text stuff
		lda #2
		sta io_ctrl

		plp

		rts


;------------------------------------------------------------------------------

