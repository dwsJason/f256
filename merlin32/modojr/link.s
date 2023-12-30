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

;		put ..\jr\open_kernal.i.s

;------------------------------------------------------------------------------

		use macros.i
		use mixer.i
		use kernel_api.i

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
		put version.s
		put term.s
		put lzsa2.s
		put file256.s
		put mixer.s
		put colors.s
		put font.s
		put file.s
code2_end

		ERR    *-1/$C000      ; Error if PC > $C000


		org $0
		adr cdata_start
		adr cdata_end-cdata_start

		org $18000
cdata_start
led_font   putbin data/led_font.font
pump_bars  putbin data/pumpbars.256
background putbin data/background.256

sfx_waves_start
sea_wave putbin data/seadragon11k.raw
sfx_waves_end

cdata_end

		do 0
		org $0
		adr mod_data_start
		adr mod_data_end-mod_data_start ; 72144      ;mod_end-mod_start  ; labels only work here, if data below is less than 64K
;		org $100000 - expansion RAM  (this works!)
		org $28000
mod_data_start
mod_song
;		putbin data/dru.mod
;		putbin data/el_gondo.mod
;		putbin data/tomsdine.mod
;		putbin data/savage.mod
;		putbin data/bm1992.mod
;		putbin data/bizarrel.mod
;		putbin data/xmas/goto80-xmas.mod ;- crashes fast
;		putbin data/xmas/rush_-_xmas.mod  ; not bad
;		putbin data/xmas/xmas_1.mod
;		putbin data/xmas/nutcase_-_xmastune.mod  ; good, not particularly xmas-ee
;		putbin data/xmas/xmas_again.mod  ; good but 45 seconds
;		putbin data/xmas/xmas_orgy.mod  ; no
;		putbin data/xmas/estrayk_-_xmas.mod ; jingle bells, but a lot of static
;		putbin data/xmas/scott_cribbs_-_xmass.mod ; I like this one
;		putbin data/xmas/xmas1995.mod  ; fun
;		putbin data/xmas/xmas_93.mod ; I don't like it
;		putbin data/xmas/xmas.mod
;		putbin data/xmas/spirit_-_xmasmix.mod
		; this is the one
;		putbin data/xmas/xmas_remix.mod  ; contendor (up there)
;		putbin data/xmas/xmas_hit_collection.mod ; (maybe) becomes unpleasant
;		putbin data/xmas/tdk-xmas_spirits_2.mod  ; no
;		putbin data/xmas/amixmas.mod ; not terrible
;		putbin data/xmas/xmas_melondy.mod ; crashes
;		putbin data/xmas/xmas_mix_92.mod ; I dig it
;		putbin data/xmas/xmas_break.mod ; very cool, but crashes

;       putbin mods/bananasplit.mod
;       putbin mods/believe.mod
;       putbin mods/bizarrel.mod
;       putbin mods/bm1992.mod
;       putbin mods/DRU.MOD
;       putbin mods/EL_GONDO.MOD
;       putbin mods/GILLIGAN.MOD
       putbin mods/hymn_to_aurora.mod
;       putbin mods/knulla-kuk.mod
;       putbin mods/moby_-_dragonsfunk.mod
;       putbin mods/MOD.Majortom
;       putbin mods/SAVAGE.MOD
;       putbin mods/space_debris.mod
;       putbin mods/TOMSDINE.MOD

mod_data_end
		else
mod_song equ $28000
		fin

; Launch Address
		adr start
		adr 0		; 0 length, tells the loader that this is where to run the code

