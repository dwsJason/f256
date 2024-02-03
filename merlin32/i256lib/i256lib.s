;
; Merlin32 Cross Dev Library, to support I256 Images, in mos-llvm
;
; https://llvm-mos.org/wiki/C_calling_convention
;
; To Assemble "merlin32 -v i256lib.s"
;


		mx %11

; These addresses are configured in the linker script



; MMU modules needs 0-1F

; Caller Saved
; A, X, Y, RS1->RS9 (RC2->RC19)
; everything else we have to preserve

; Virtual mos-llvm registers
	dum $10
rs0  ds 2      	; RS0 16 bit pointer register composed of RC0 and RC1
rs1  ds 2   	; x
rs2  ds 2   	; x
rs3  ds 2   	; x
rs4  ds 2       ; x
rs5  ds 2       ; x
rs6  ds 2       ; x
rs7  ds 2       ; x
rs8  ds 2       ; x
rs9  ds 2       ; x
rs10 ds 2
rs11 ds 2
rs12 ds 2
rs13 ds 2
rs14 ds 2
rs15 ds 2
	dend

	dum $10
rc0  ds 1
rc1  ds 1
rc2  ds 1
rc3  ds 1
rc4  ds 1
rc5  ds 1
rc6  ds 1
rc7  ds 1
rc8  ds 1
rc9  ds 1
rc10 ds 1
rc11 ds 1
rc12 ds 1
rc13 ds 1
rc14 ds 1
rc15 ds 1
rc16 ds 1
rc17 ds 1
rc18 ds 1
rc19 ds 1
rc20 ds 1
rc21 ds 1
rc22 ds 1
rc23 ds 1
rc24 ds 1
rc25 ds 1
rc26 ds 1
rc27 ds 1
rc28 ds 1
rc29 ds 1
rc30 ds 1
rc31 ds 1
	dend

; Zero Page usage for the ASM library

	dum $80
temp0 ds 4			; used by MMU functions
temp1 ds 4
temp2 ds 4
temp3 ds 4
	dend

MMU_MEM = $90
LZSA_MEM = $A0
I256_MEM = $B0
LBM_MEM = $B0

; 8k Library Program, so it can be stored anywheren and mapped in

		org $A000
		dsk i256.flib

sig		db $f1,$1B		; signature   FLIB/$F11B
		db $c1			; tool #$c1 -> Image Picture Tool
		db 0            ; tool version
		db 1			; 1 8k block (really, always 1)
		db %100000 		; mount slot (means org $A000), if set to %110000, could mount at $A000, or even $8000

		jmp mosGetClut
		jmp mosGetClutIO
		jmp mosGetMap
		jmp mosGetPixels
		jmp mosGetMapWH
		jmp mosGetPixWidth
		jmp mosGetPixHeight
		jmp mosLzsa2Decompress


;
; mos llvm C compiler compliant function calls
;
;------------------------------------------------------------------------------
;
; u16 i256DecompressCLUT(u24 pTarget, u24 pI256);
;
; Input pDestination = AX RC2
; Input pSourceI256  = RC3 RC4 RC5
;
; Return: AX = Number of bytes decompressed
;
mosGetClut
		jsr lib_startup

		ldy rc2
		jsr set_write_address

		lda rc3
		ldx rc4
		ldy rc5
		jsr set_read_address

		jsr decompress_clut

		lda i256_colorCount
		asl
		rol i256_colorCount+1
		asl
		rol i256_colorCount+1
		ldx i256_colorCount+1

		jsr lib_shutdown
		rts

;------------------------------------------------------------------------------
;
; u16 i256DecompressClutIO(u8* pTarget, u24 pI256);
;
; Input pDestination = RC2 RC3   ; Destination Address in IO RAM
; Input pSourceI256  = AX RC4
;
; Return: AX = Number of bytes decompressed
;
mosGetClutIO
		jsr lib_startup

		ldy rc4
		jsr set_read_address

		lda #<temp_clut
		ldx #>temp_clut
		ldy #0
		jsr set_write_address

		jsr decompress_clut

		; here we need to copy the LUT

		lda #1
		sta io_ctrl

		ldx i256_colorCount
		ldy #0

		; reset the self modded code
		lda #>temp_clut
		sta :lp+2
		sta :lp1+2
		sta :lp2+2
		sta :lp3+2

:lp 	lda temp_clut,y
		sta (rc2),y
		iny
:lp1	lda temp_clut,y 
		sta (rc2),y
		iny
:lp2	lda temp_clut,y 
		sta (rc2),y
		iny
:lp3	lda temp_clut,y 
		sta (rc2),y
		iny
		bne :kk
		inc rc3

		lda :lp+2
		inc
		sta :lp+2
		sta :lp1+2
		sta :lp2+2
		sta :lp3+2
:kk
		dex
		bne :lp


; return bytes decompressed
		lda i256_colorCount
		asl
		rol i256_colorCount+1
		asl
		rol i256_colorCount+1
		ldx i256_colorCount+1

		jsr lib_shutdown
		rts

;------------------------------------------------------------------------------
;
;u24 i256DecompressMAP(u24 pTarget, u16 nameAdjust, u24 pI256);
;
; Input pDestination = AX RC2
; Input nameAdjust   = RC3 RC4
; Input pSource      = RC5 RC6 RC7
;
; Output: AX RC2 = Number of bytes decompressed
;
;
mosGetMap
		jsr lib_startup

		ldy rc2

		sta <temp1  			; temp1 holds the original write_address
		stx <temp1+1
		sty <temp1+2

		jsr set_write_address

		lda rc5
		ldx rc6
		ldy rc7
		jsr set_read_address

		jsr decompress_map

		jsr get_write_address
		sta <temp2
		stx <temp2+1
		sty <temp2+2

		; I want to get the length

		sec
		lda <temp2
		sbc <temp1
		sta <temp3
		lda <temp2+1
		sbc <temp1+1
		sta <temp3+1
		lda <temp2+2
		sbc <temp1+2
		sta <temp3+2

		sta <rc2 ; for return value

		ora <temp3+1
		ora <temp3
		bne :there_is_length

		; no length

		stz rc2
		lda #0
		tax
		bra :done

:there_is_length		
		; temp1 is the start address
		; temp2 is the end address
		; and temp3 is the length

		lda <temp1
		ldx <temp1+1
		ldy <temp1+2
		jsr set_write_address

; counter
		stz temp1+3
		stz temp2+3
		stz temp3+3
		ldy #1
]lp
		clc
		lda (pDest)
		adc rc3 	 			; modify the map data (offset tile, adjust clut)
		sta (pDest)
		lda (pDest),y
		adc rc4 				; modify the map data
		sta (pDest),y

		inc pDest
		bne :ok1
		inc pDest+1
		bpl :ok1
		inc WRITE_MMU
		lda #>WRITE_BLOCK
		sta pDest+1
:ok1
		inc pDest
		bne :ok2
		inc pDest+1
		bpl :ok2
		inc WRITE_MMU
		lda #>WRITE_BLOCK
		sta pDest+1
:ok2
		inc temp1+3
		bne :nxt
		inc temp2+3
		bne :nxt
		inc temp3+3
:nxt
		lda temp1+3
		cmp temp2
		bne :ii
		lda temp2+3
		cmp temp2+1
		bne :ii
		lda temp3+3
		cmp temp2+2
		beq :real
:ii
		inc temp1+3
		bne :nxt2
		inc temp2+3
		bne :nxt2
		inc temp3+3
:nxt2
		lda temp1+3
		cmp temp2
		bne ]lp
		lda temp2+3
		cmp temp2+1
		bne ]lp
		lda temp3+3
		cmp temp2+2
		bne ]lp

:real
		lda <temp3  	; return length
		ldx <temp3+1

:done
		jsr lib_shutdown
		rts

;------------------------------------------------------------------------------
;
;u24 i256DecompressPIXELS(u24 pTarget, u24 pI256);
;
; Input pDestination = AX RC2
; Input pSourceI256  = RC3 RC4 RC5
;
; Output: AX RC2 = Number of bytes decompressed
;
mosGetPixels
		jsr lib_startup
		jsr lib_shutdown
		rts

;------------------------------------------------------------------------------
;
;u16 i256GetMapWidthHeight(u24 pI256);
;
; Input pSource = AX RC2
;
; Output: AX
;
mosGetMapWH
		jsr lib_startup
		jsr lib_shutdown
		rts

;------------------------------------------------------------------------------
;
;u16 i256GetPixelWidth(u24 pI256);
;
; Input pSource = AX RC2
;
; Output: AX
;
mosGetPixWidth
		jsr lib_startup
		jsr lib_shutdown
		rts

;------------------------------------------------------------------------------
;
;u16 i256GetPixelHeight(u24 pI256);
;
; Input pSource = AX RC2
;
; Output: AX
;
mosGetPixHeight
		jsr lib_startup
		jsr lib_shutdown
		rts

;------------------------------------------------------------------------------
;
;u16 lzsa2Decompress(u24 pTarget, u24 pSource);
;
; Input pDestination = AX RC2
; Input pSourceI256  = RC3 RC4 RC5
;
; Max return values is $10000
;
; Return: AX RC2 = Number of bytes decompressed
;
mosLzsa2Decompress
		jsr lib_startup
		jsr lib_shutdown
		rts

;------------------------------------------------------------------------------
;
; Preserve ZP space
; Configure MMU
;
lib_startup
		phx
		pha

		ldx #127
]save	lda <$80,x
		sta |zp_backup,x
		dex
		bpl ]save

		jsr mmu_unlock

		pla
		plx
		rts
;------------------------------------------------------------------------------
;
; Restore MMU
; Restore ZP space
;
lib_shutdown

		phx
		pha

		jsr mmu_lock

		ldx #127
]rest	lda |zp_backup,x
		sta <$80,x
		dex
		bpl ]rest

		pla
		plx

		rts

;------------------------------------------------------------------------------
; Load / Display 256 Image
		jsr set_srcdest_clut
		jsr decompress_clut
		jsr set_srcdest_pixels
		jsr decompress_pixels

;------------------------------------------------------------------------------
; Load / Display LBM Image


		; Now the LBM is in memory, let's try to decode and show it
		; set src to loaded image file, and dest to clut
		jsr set_srcdest_clut

		jsr lbm_decompress_clut


		; get the pixels
		; set src to loaded image file, dest to output pixels
		jsr set_srcdest_pixels
		jsr lbm_decompress_pixels

;-----------------------------------------------------------------------------
set_srcdest_clut
		; Address where we're going to load the file
		;lda #<IMAGE_FILE
		;ldx #>IMAGE_FILE
		;ldy #^IMAGE_FILE
		jsr set_read_address

		;lda #<CLUT_DATA
		;ldx #>CLUT_DATA
		;ldy #^CLUT_DATA
		jsr set_write_address
		rts
;-----------------------------------------------------------------------------
set_srcdest_pixels
		;lda #<IMAGE_FILE
		;ldx #>IMAGE_FILE
		;ldy #^IMAGE_FILE
		jsr set_read_address

		;lda #<PIXEL_DATA
		;ldx #>PIXEL_DATA
		;ldy #^PIXEL_DATA
		jsr set_write_address
		rts

;------------------------------------------------------------------------------
		put mmu.s
		put lbm.s
		put i256.s
		put lzsa2.s

		dum *
;------------------------------------------------------------------------------
; Zero Page Backup
zp_backup ds 256
;------------------------------------------------------------------------------
temp_clut ds 1024
;------------------------------------------------------------------------------
		dend

; pad to the end
;		ds $C000-*,$EA
; really pad to end, because merlin is buggy
;		ds \,$EA
