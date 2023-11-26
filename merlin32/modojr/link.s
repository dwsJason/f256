;
; Generally a Merlin32 link file either produces several binary outputs
; or an OMF
;
; This one attempts to produce a PGZ executable
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
		use mixer.i

;------------------------------------------------------------------------------

		mx %11
		org $0
		dsk modojr.pgz
		db	'Z'   			; PGZ header upper case Z means 24 bit size/length fields

; Segment 0
		org $0
		adr main_code_start 			 	; Address to load into memory
		adr main_code_end-main_code_start   ; Length of data to load into their

		org $2000

main_code_start
		put modojr.s
		put mod.s
		put mmu.s
		put irq.s
main_code_end

		; $6000->$7FFF reserved for memory hole
		ERR    *-1/$6000      ; Error if PC > $6000

		org $0
		adr code2_start
		adr code2_end-code2_start

		org $A000
code2_start
		put term.s
		put lzsa2.s
		put file256.s
		put colors.s
		put mixer.s
code2_end

		ERR    *-1/$C000      ; Error if PC > $C000

		org $0
		adr sfx_waves_start
		adr sfx_waves_end-sfx_waves_start

		org $30000
sfx_waves_start
sea_wave putbin data/seadragon11k.raw
sfx_waves_end

		org $0
		adr mod_data_start
		adr mod_data_end-mod_data_start ; 72144      ;mod_end-mod_start  ; labels only work here, if data below is less than 64K
;		org $100000 - expansion RAM  (this works!)
		org $40000
mod_data_start
mod_song
	   putbin data/dru.mod
;       putbin data/tomsdine.mod
mod_data_end



		org $0
		adr image2_start
		adr image2_end-image2_start  ; labels only work here, if data below is less than 64K
		org $70000

;;		put data0.s
image2_start
pic1	;putbin data\fireplace.256
image2_end


; Launch Address
		adr start
		adr 0		; 0 length, tells the loader that this is where to run the code

