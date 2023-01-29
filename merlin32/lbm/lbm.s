;
; 65c02 Foenix LBM file format parser utils
; for F256 Jr
;
		mx %11

; error codes
		dum $0
lbm_no_error         ds 1   ; 0 = no error
lbm_error_notlbm     ds 1   ; 1 = not an LBM file
lbm_error_notpbm     ds 1   ; 2 = not an LBM with 8 bit packed pixels
lbm_error_noclut     ds 1   ; 3 = There's no CLUT in this file
lbm_error_nopixels   ds 1   ; 4 = There are no PIXL in this file
		dend


		dum $F0
lbm_ChunkLength ds 0
lbm_FileLength ds 0
lbm_pChunk     ds 0
lbm_temp0      ds 4

lbm_pTag       ds 0
lbm_colorCount ds 0
lbm_temp1      ds 2

lbm_FileStart  ds 3
lbm_Width      ds 2
lbm_Height     ds 2
lbm_EOF        ds 3
		dend

;------------------------------------------------------------------------------
;
; This works with the mmu utils
; Addresses are in System Memory BUS space
;
; set_read_address  - the source address for the image.lbm
; set_write_address - the destination address of the clut data
;
;  This will massage the LBM clut data into something that works on Jr
;
; if c=0, then operation success
; if c=1, then operation fail, error code in A
;
lbm_decompress_clut
		rts


;------------------------------------------------------------------------------
;
; This works with the mmu utils
; Addresses are in System Memory BUS space
;
; set_read_address  - the source address for the image.lbm
; set_write_address - the destination address of the pixel data
;
; if c=0, then operation success
; if c=1, then operation fail, error code in A
;
lbm_decompress_pixels
		jsr lbm_init
		bcc :good
		rts				; error, error code in A
:good
		rts

;------------------------------------------------------------------------------


CHNK_FORM asc 'FORM'
CHNK_PBM  asc 'PBM '
CHNK_BMHD asc 'BMHD'
CHNK_CMAP asc 'CMAP'
CHNK_BODY asc 'BODY'

;------------------------------------------------------------------------------

;
; This works with the mmu utils
; Addresses are in System Memory BUS space
;
; set_read_address  - the source address for the image.lbm
; set_write_address - the destination address of the pixel data
;
lbm_init
		lda #<CHNK_FORM
		ldx #>CHNK_FORM
		jsr lbm_CheckTag
		bcc :good
		lda #lbm_error_notlbm
		rts
:good
		jsr lbm_chunklength

		jsr get_read_address

		; Need to set EOF, so FindChunk knows where to stop
		clc
		adc lbm_ChunkLength
		sta lbm_EOF+0
		txa
		adc lbm_ChunkLength+1
		sta lbm_EOF+1
		tya
		adc lbm_ChunkLength+2
		sta lbm_EOF+2

		lda #<CHNK_PBM
		ldx #>CHNK_PBM
		jsr lbm_CheckTag
		bcc :pbm
:not_pbm
		lda #lbm_error_notpbm
		rts
:pbm
		lda #<CHNK_BMHD
		ldx #>CHNK_BMHD
		jsr lbm_CheckTag
		bcs :not_pbm

		jsr lbm_chunklength
		jsr lbm_nextchunk_address ; pChunk will hold next chunk address


		; Width
		jsr readbyte
		sta lbm_Width+1
		jsr readbyte
		sta lbm_Width

		;Height
		jsr readbyte
		sta lbm_Height+1
		jsr readbyte
		sta lbm_Height


		lda lbm_pChunk
		ldx lbm_pChunk+1
		ldy lbm_pChunk+2

		jsr set_read_address

		clc
		rts
;------------------------------------------------------------------------------
;
; AX = address of tag to check
;
; c=0 match
; c=1 does not match
;
lbm_CheckTag
		sta lbm_pTag
		stx lbm_pTag+1

		jsr readbyte
		sta lbm_temp0
		jsr readbyte
		sta lbm_temp0+1
		jsr readbyte
		sta lbm_temp0+2
		jsr readbyte
		sta lbm_temp0+3

		ldy #3
]lp		lda (lbm_pTag),y
		cmp lbm_temp0,y
		bne :error
		dey
		bpl ]lp
		clc
		rts

:error
		sec
		rts

;------------------------------------------------------------------------------
lbm_chunklength
		jsr readbyte
		sta lbm_ChunkLength+3
		jsr readbyte
		sta lbm_ChunkLength+2
		jsr readbyte
		sta lbm_ChunkLength+1
		jsr readbyte
		sta lbm_ChunkLength+0
		rts

;------------------------------------------------------------------------------
lbm_nextchunk_address
		jsr get_read_address
		clc
		adc lbm_pChunk
		sta lbm_pChunk
		txa
		adc lbm_pChunk+1
		sta lbm_pChunk+1
		tya
		adc lbm_pChunk+2
		sta lbm_pChunk+2
		rts
;------------------------------------------------------------------------------

