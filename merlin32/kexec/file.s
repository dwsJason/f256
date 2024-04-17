;
;  Flash Abstraction Routines, read data from flash
;  by mimik file reader code
;
		mx %11

		dum $B0
file_handle     ds 1
file_bytes_req  ds 3

file_bytes_wrote ds 0
file_bytes_read ds 3

file_to_read ds 1
file_open_drive ds 1
		dend

;
; AX = pFileName (CString)
;
; c = 0 - no error
;		A = filehandle
; c = 1 - error
;		A = error #
;
fopen
		lda #<data_start
		sta pSource

		lda #{{data_start/256}&$1F}.{READ_BLOCK/256}
		sta pSource+1

		lda mmu5
		sta READ_MMU

		clc
		rts

;
; mmu write address is the address
; AXY - Num Bytes to Read
;
; Return
; AXY - num Bytes actually read in
;
fread
		sta file_bytes_req
		stx file_bytes_req+1
		sty file_bytes_req+2

		stz file_bytes_read
		stz file_bytes_read+1
		stz file_bytes_read+2


]loop
		lda file_bytes_req+2
		bne :do128  			  ; a lot of data left to read
		lda file_bytes_req+1      
		bne :do128
		lda file_bytes_req
		bne	:not_done
		jmp	:done_done
:not_done
		bpl :small_read
:do128	
		lda	#128
:small_read
		sta	file_to_read
		jsr	bytes_can_write ; Number of bytes left in the block
		cmp file_to_read
		bcs :read_len_ok
		sta file_to_read

:read_len_ok
		ldy #0
]read
		jsr readbyte
		sta (pDest),y
		iny
		cpy file_to_read
		bcc ]read

		lda file_to_read
		jsr increment_dest

		; subtract bytes read from the total request
		sec
		lda file_bytes_req
		sbc file_to_read
		sta file_bytes_req
		lda file_bytes_req+1
		sbc #0
		sta file_bytes_req+1
		lda file_bytes_req+2
		sbc #0
		sta file_bytes_req+2

		clc
		lda file_bytes_read
		adc file_to_read
		sta file_bytes_read
		bcc ]loop
;-----------------------------------------------------------------------------
; LAME PROGRESS INDICATOR
;-----------------------------------------------------------------------------

;		jsr ProgressIndicator

;-----------------------------------------------------------------------------
		inc file_bytes_read+1
		bne ]loop
		inc file_bytes_read+2

		bra ]loop


:done_done
		lda file_bytes_read
		ldx file_bytes_read+1
		ldy file_bytes_read+2
fclose
		rts
;-----------------------------------------------------------------------------

