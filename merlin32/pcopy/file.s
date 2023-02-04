;
;  File Abstraction Routines, since Kernel level stuff is all async
;
		mx %11

DEBUG_FILE = 0

		dum $B0
file_handle     ds 1
file_bytes_req  ds 3

file_bytes_wrote ds 0
file_bytes_read ds 3
		dend

		dum $200
file_buffer ds 128
		dend

;
; AX = pFileName (CString)
;
; c = 0 - no error
;		A = filehandle
; c = 1 - error
;		A = error #
fcreate
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
		sty kernel_args_file_open_fname_len

		; Set the mode, and open
		lda #kernel_args_file_open_WRITE
		sta kernel_args_file_open_mode
:try_again
		jsr kernel_File_Open
		sta file_handle
		bcc :it_opened

:error
		sec
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
        beq :error
		cmp #kernel_event_file_OPENED
		beq :success
		cmp #kernel_event_file_ERROR
		bne :error
		bra ]loop

:success
		lda file_handle
		clc
		rts

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
;		iny ; try including the nil
		sty kernel_args_file_open_fname_len

		; Set the mode, and open
		lda #kernel_args_file_open_READ
		sta kernel_args_file_open_mode
:try_again
		jsr kernel_File_Open
		sta file_handle
		bcc :it_opened

;		lda #<txt_error
;		ldx #>txt_error
;		jsr TermPUTS
:error
		sec
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
        beq :error
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

		do DEBUG_FILE
		jsr TermCR
		lda file_bytes_req+2
		jsr TermPrintAH
		lda file_bytes_req
		ldx file_bytes_req+1
		jsr TermPrintAXH
		jsr TermCR
		fin

		stz file_bytes_read
		stz file_bytes_read+1
		stz file_bytes_read+2

		; Set the stream
		lda file_handle
		sta kernel_args_file_read_stream

		; make sure event output is still set
		lda #<event_type
		sta kernel_args_events
		lda #>event_type
		sta kernel_args_events+1

]loop
		lda file_bytes_req+2
		bne :do128  			  ; a lot of data left to read
		lda file_bytes_req+1      
		bne :do128
		lda file_bytes_req
		cmp #128
		bcc :small_read
:do128	lda #128
		bra :try128
:small_read
		lda file_bytes_req
		do DEBUG_FILE
		bne :try128
		jmp :done_done
		else
		beq :done_done  	   	; zero bytes left
		fin
:try128
		sta kernel_args_file_read_buflen

		do DEBUG_FILE
		jsr TermCR
		ldx #$EA
		lda kernel_args_file_read_buflen
		jsr TermPrintAXH
		jsr TermCR
		fin

		; subtract request from the total request
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

	    ; wait for data to appear, or error, or EOF
]event_loop
		do DEBUG_FILE
		; make sure event output is still set
		lda #<event_type
		sta kernel_args_events
		lda #>event_type
		sta kernel_args_events+1
		fin

        jsr kernel_Yield    ; Not required; but good while waiting.
        jsr kernel_NextEvent
        bcs ]event_loop

		lda event_type

		do DEBUG_FILE
		pha
		jsr TermPrintAH
		lda #'x'
		jsr TermCOUT
		pla
		fin

        cmp #kernel_event_file_EOF
		beq :done_done
        cmp #kernel_event_file_ERROR
		beq :done_done
		cmp #kernel_event_file_DATA
		bne ]event_loop

		do DEBUG_FILE
		jsr TermCR
		lda event_file_data_read
		jsr TermPrintAH
		jsr TermCR
		fin

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

		do DEBUG_FILE
		lda #<txt_data_read
		ldx #>txt_data_read
		jsr TermPUTS
		lda event_file_data_read
		jsr TermPrintAH
		jsr TermCR
		fin

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
		bne ]lp
		
		do DEBUG_FILE				 
		jmp ]loop
		else
		bra ]loop
		fin


:done_done
		lda file_bytes_read
		ldx file_bytes_read+1
		ldy file_bytes_read+2

		rts

fclose
		lda file_handle
		sta kernel_args_file_close_stream
		jmp kernel_File_Close

txt_data_read asc 'Data Read:'
		db 0

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
;		iny ; try including the nil
		sty kernel_args_file_open_fname_len

		; Set the mode, and open
		lda #kernel_args_file_open_READ
		sta kernel_args_file_open_mode
:try_again
		jsr kernel_File_Open
		sta file_handle
		bcc :it_opened

;		lda #<txt_error
;		ldx #>txt_error
;		jsr TermPUTS
:error
		sec
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
        beq :error
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
; mmu read address is the address
; AXY - Num Bytes to write
;
; Return
; AXY - num Bytes actually wrote
;
fwrite
		sta file_bytes_req
		stx file_bytes_req+1
		sty file_bytes_req+2

		stz file_bytes_wrote
		stz file_bytes_wrote+1
		stz file_bytes_wrote+2

		; Set the stream
		lda file_handle
		sta kernel_args_file_read_stream

		; make sure event output is still set
		lda #<event_type
		sta kernel_args_events
		lda #>event_type
		sta kernel_args_events+1

]loop
		lda file_bytes_req+2
		bne :do128  			  ; a lot of data left to read
		lda file_bytes_req+1      
		bne :do128
		lda file_bytes_req
		cmp #128
		bcc :small_read
:do128	lda #128
		bra :try128
:small_read
		lda file_bytes_req
		do DEBUG_FILE
		bne :try128
		jmp :done_done
		else
		beq :done_done  	   	; zero bytes left
		fin
:try128
		sta kernel_args_file_read_buflen

		do DEBUG_FILE
		jsr TermCR
		ldx #$EA
		lda kernel_args_file_read_buflen
		jsr TermPrintAXH
		jsr TermCR
		fin

		; subtract request from the total request
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

	    ; wait for data to appear, or error, or EOF
]event_loop
		do DEBUG_FILE
		; make sure event output is still set
		lda #<event_type
		sta kernel_args_events
		lda #>event_type
		sta kernel_args_events+1
		fin

        jsr kernel_Yield    ; Not required; but good while waiting.
        jsr kernel_NextEvent
        bcs ]event_loop

		lda event_type

		do DEBUG_FILE
		pha
		jsr TermPrintAH
		lda #'x'
		jsr TermCOUT
		pla
		fin

        cmp #kernel_event_file_EOF
		beq :done_done
        cmp #kernel_event_file_ERROR
		beq :done_done
		cmp #kernel_event_file_DATA
		bne ]event_loop

		do DEBUG_FILE
		jsr TermCR
		lda event_file_data_read
		jsr TermPrintAH
		jsr TermCR
		fin

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

		do DEBUG_FILE
		lda #<txt_data_read
		ldx #>txt_data_read
		jsr TermPUTS
		lda event_file_data_read
		jsr TermPrintAH
		jsr TermCR
		fin

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
		bne ]lp
		
		do DEBUG_FILE				 
		jmp ]loop
		else
		bra ]loop
		fin


:done_done
		lda file_bytes_read
		ldx file_bytes_read+1
		ldy file_bytes_read+2

		rts

