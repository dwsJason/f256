;
;  File Abstraction Routines, since Kernel level stuff is all async
;
		mx %11

		dum $B0
file_handle     ds 1
file_bytes_req  ds 3
file_bytes_read ds 3
		dend

		dum $100
file_buffer ds 128
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
		stz kernel_args_file_open_drive

		sta kernel_args_file_open_fname
		stx kernel_args_file_open_fname+1

		; Set the Filename length (why?)
		ldy #0
]len    lda (kernel_args_file_open_fname),y
		beq :got_len
		iny
		bne ]len
:got_len
		iny ; try including the nil
		sty kernel_args_file_open_fname_len

		; Set the mode, and open
		lda #kernel_args_file_open_READ
		sta kernel_args_file_open_mode
:try_again
		jsr kernel_File_Open
		sta file_handle
		bcc :it_opened
:error
		rts

:it_opened
]loop
        jsr kernel_Yield    ; Not required; but good while waiting.
        jsr kernel_NextEvent
        bcs ]loop

		lda event_type
		cmp #kernel_event_file_CLOSED
		beq :error
        cmp #kernel_event_file_NOT_FOUND
        bne :error
		cmp #kernel_event_file_OPENED
		beq :success
		cmp #kernel_event_file_ERROR
		bne :error
		bra ]loop

:success
		;lda event_file_stream
		;sta file_handle
		lda file_handle
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

		; Set the stream
		lda file_handle
		sta kernel_args_file_read_stream
]loop
		lda file_bytes_req+2
		bne :do255
		lda file_bytes_req+1
		beq :small_read
:do255	lda #128
		bra :try255
:small_read
		lda file_bytes_req
		beq :done_done
:try255
		sta kernel_args_file_read_buflen

		sec
		lda file_bytes_req
		sbc kernel_args_file_read_buflen
		sta file_bytes_req
		lda file_bytes_req+1
		sbc #0
		sta file_bytes_req+1
		lda file_bytes_req+2
		sbc #0
		sta file_bytes_req+2

		jsr kernel_File_Read
]eloop
        jsr kernel_Yield    ; Not required; but good while waiting.
        jsr kernel_NextEvent
        bcs ]loop

        cmp #kernel_event_file_EOF
		beq :done_done
        cmp #kernel_event_file_ERROR
		beq :done_done
		cmp #kernel_event_file_DATA
		bne ]eloop

		clc
		lda file_bytes_read
		adc event_file_data_read
		sta file_bytes_read
		bcc :get_data
		inc file_bytes_read+1
		bne :get_data
		inc file_bytes_read+2

:get_data
		lda event_file_data_read
		sta kernel_args_recv_buflen

		lda #<file_buffer
		sta kernel_args_recv_buf
		lda #>file_buffer
		sta kernel_args_recv_buf+1

		jsr kernel_ReadData

		ldx #0
]lp		lda file_buffer,x
		jsr writebyte
		inx
		cpx event_file_data_read
		bcc ]lp
				 
		bra ]loop				 


:done_done
		lda file_bytes_read
		ldx file_bytes_read+1
		ldy file_bytes_read+2

		rts

fclose
		lda file_handle
		sta kernel_args_file_close_stream
		jmp kernel_File_Close


