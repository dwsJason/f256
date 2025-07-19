;
; Generally a Merlin32 link file either produces several binary outputs
; or an OMF
;
; This one attempts to produce a PGZ executable
;
; This file contains an uncompress 320x240 bitmap, and colors
; just copy the color table, and set video mode to display
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


		mx %11
		org $0
		dsk memory.pgz
		db	'Z'   			; PGZ header upper case Z means 24 bit size/length fields

; Segment 0
		org $0
		adr main_code_start 			 	; Address to load into memory
		adr main_code_end-main_code_start   ; Length of data to load into their

		org $300
main_code_start
		put memory.s
		put term.s
		put mmu.s
		put colors.s
main_code_end

		org $0
		adr section_start1
		adr section_end1-section_start1  ; labels only work here, if data below is less than 64K
		org $010000
section_start1
		asc 'Text at $010000',0D00
section_end1

		org $0
		adr section_start2
		adr section_end2-section_start2  ; labels only work here, if data below is less than 64K
		org $020000
section_start2
		asc 'Text at $020000',0D00
section_end2

		org $0
		adr section_start3
		adr section_end3-section_start3  ; labels only work here, if data below is less than 64K
		org $030000
section_start3
		asc 'Text at $030000',0D00
section_end3

		org $0
		adr section_start4
		adr section_end4-section_start4  ; labels only work here, if data below is less than 64K
		org $040000
section_start4
		asc 'Text at $040000',0D00
section_end4

		org $0
		adr section_start5
		adr section_end5-section_start5  ; labels only work here, if data below is less than 64K
		org $050000
section_start5
		asc 'Text at $050000',0D00
section_end5

		org $0
		adr section_start6
		adr section_end6-section_start6  ; labels only work here, if data below is less than 64K
		org $060000
section_start6
		asc 'Text at $060000',0D00
section_end6

		org $0
		adr section_start7
		adr section_end7-section_start7  ; labels only work here, if data below is less than 64K
		org $070000
section_start7
		asc 'Text at $070000',0D00
section_end7

		org $0
		adr section_start8
		adr section_end8-section_start8  ; labels only work here, if data below is less than 64K
		org $080000
section_start8
		asc 'Text at $080000',0D00
section_end8

		org $0
		adr section_start9
		adr section_end9-section_start9  ; labels only work here, if data below is less than 64K
		org $090000
section_start9
		asc 'Text at $090000',0D00
section_end9

		org $0
		adr section_startA
		adr section_endA-section_startA  ; labels only work here, if data below is less than 64K
		org $0A0000
section_startA
		asc 'Text at $0A0000',0D00
section_endA

		org $0
		adr section_startB
		adr section_endB-section_startB  ; labels only work here, if data below is less than 64K
		org $0B0000
section_startB
		asc 'Text at $0B0000',0D00
section_endB

		org $0
		adr section_startC
		adr section_endC-section_startC  ; labels only work here, if data below is less than 64K
		org $0C0000
section_startC
		asc 'Text at $0C0000',0D00
section_endC

		org $0
		adr section_startD
		adr section_endD-section_startD  ; labels only work here, if data below is less than 64K
		org $0D0000
section_startD
		asc 'Text at $0D0000',0D00
section_endD

		org $0
		adr section_startE
		adr section_endE-section_startE  ; labels only work here, if data below is less than 64K
		org $0D0000
section_startE
		asc 'Text at $0E0000',0D00
section_endE

		org $0
		adr section_startF
		adr section_endF-section_startF  ; labels only work here, if data below is less than 64K
		org $0F0000
section_startF
		asc 'Text at $0F0000',0D00
section_endF

;------------------------------------------------------------------------------

		org $0
		adr section_start10
		adr section_end10-section_start10  ; labels only work here, if data below is less than 64K
		org $100000
section_start10
		asc 'Text at $100000',0D00
section_end10

		org $0
		adr section_start11
		adr section_end11-section_start11  ; labels only work here, if data below is less than 64K
		org $110000
section_start11
		asc 'Text at $110000',0D00
section_end11

		org $0
		adr section_start12
		adr section_end12-section_start12  ; labels only work here, if data below is less than 64K
		org $120000
section_start12
		asc 'Text at $120000',0D00
section_end12

		org $0
		adr section_start13
		adr section_end13-section_start13  ; labels only work here, if data below is less than 64K
		org $130000
section_start13
		asc 'Text at $130000',0D00
section_end13

		org $0
		adr section_start14
		adr section_end14-section_start14  ; labels only work here, if data below is less than 64K
		org $140000
section_start14
		asc 'Text at $140000',0D00
section_end14

		org $0
		adr section_start15
		adr section_end15-section_start15  ; labels only work here, if data below is less than 64K
		org $150000
section_start15
		asc 'Text at $150000',0D00
section_end15

		org $0
		adr section_start16
		adr section_end16-section_start16  ; labels only work here, if data below is less than 64K
		org $160000
section_start16
		asc 'Text at $160000',0D00
section_end16

		org $0
		adr section_start17
		adr section_end17-section_start17  ; labels only work here, if data below is less than 64K
		org $170000
section_start17
		asc 'Text at $170000',0D00
section_end17

		org $0
		adr section_start18
		adr section_end18-section_start18  ; labels only work here, if data below is less than 64K
		org $180000
section_start18
		asc 'Text at $180000',0D00
section_end18

		org $0
		adr section_start19
		adr section_end19-section_start19  ; labels only work here, if data below is less than 64K
		org $190000
section_start19
		asc 'Text at $190000',0D00
section_end19

		org $0
		adr section_start1A
		adr section_end1A-section_start1A  ; labels only work here, if data below is less than 64K
		org $1A0000
section_start1A
		asc 'Text at $1A0000',0D00
section_end1A

		org $0
		adr section_start1B
		adr section_end1B-section_start1B  ; labels only work here, if data below is less than 64K
		org $1B0000
section_start1B
		asc 'Text at $1B0000',0D00
section_end1B

		org $0
		adr section_start1C
		adr section_end1C-section_start1C  ; labels only work here, if data below is less than 64K
		org $1C0000
section_start1C
		asc 'Text at $1C0000',0D00
section_end1C

		org $0
		adr section_start1D
		adr section_end1D-section_start1D  ; labels only work here, if data below is less than 64K
		org $1D0000
section_start1D
		asc 'Text at $1D0000',0D00
section_end1D

		org $0
		adr section_start1E
		adr section_end1E-section_start1E  ; labels only work here, if data below is less than 64K
		org $1E0000
section_start1E
		asc 'Text at $1E0000',0D00
section_end1E

		org $0
		adr section_start1F
		adr section_end1F-section_start1F  ; labels only work here, if data below is less than 64K
		org $1F0000
section_start1F
		asc 'Text at $1F0000',0D00
section_end1F

; -- expansion ram banks -- what?

		org $0
		adr section_startF4
		adr section_endF4-section_startF4  ; labels only work here, if data below is less than 64K
		org $F40000
section_startF4
		asc 'Text at $F40000',0D00
section_endF4

		org $0
		adr section_startF5
		adr section_endF5-section_startF5  ; labels only work here, if data below is less than 64K
		org $F50000
section_startF5
		asc 'Text at $F50000',0D00
section_endF5

		org $0
		adr section_startF6
		adr section_endF6-section_startF6  ; labels only work here, if data below is less than 64K
		org $F60000
section_startF6
		asc 'Text at $F60000',0D00
section_endF6

		org $0
		adr section_startF7
		adr section_endF7-section_startF7  ; labels only work here, if data below is less than 64K
		org $F70000
section_startF7
		asc 'Text at $F70000',0D00
section_endF7

; Launch Address
		org $0
		adr start
		adr 0		; 0 length, tells the loader that this is where to run the code

