;
; Merlin32 Cross Dev Stub for the Jr Micro Kernel
;
; To Assemble "merlin32 -v kexec.s"
;
		mx %11

; some Kernel Stuff
		put ..\kernel\api.s

; Some Global Direct page stuff

; MMU modules needs 0-1F

	dum $20
temp0 ds 4
temp1 ds 4
temp2 ds 4
temp3 ds 4
	dend

; Event Buffer at $30
event_type = $30
event_buf  = $31
event_ext  = $32
;event_file_stream = $33
event_file_data_read = $33

args = $300


; File uses $B0-$BF
; Term uses $C0-$CF
; LZSA uses $E0-$EF
; Kernel uses $F0-FF
; I256 uses $F0-FF
; LBM uses $F0-FF

; 8k Kernel Program, so it can live anywhere

		org $A000
		dsk kexec.bin
sig		db $f2,$56		; signature
		db 1            ; 1 8k block
		db 5            ; mount at $a000
		da start		; start here
		dw 0			; version
		dw 0			; kernel
		asc '-' 		; This will require some discussion with Gadget
		db 0

start
		jsr TermInit

		jsr mmu_unlock

		lda #<txt_test
		ldx #>txt_test
		jsr TermPUTS

		lda #<args+2
		ldx #>args+2
		jsr TermPUTS
		jsr TermCR
;------------------------------------------------------------------------------
		; muy importante
		lda #<event_type
		sta kernel_args_events
		lda #>event_type
		sta kernel_args_events+1
				 
		; Set the drive
		; currently hard-coded to drive 0, since drive not passed
		;stz kernel_args_file_open_drive
		; Set the Filename
		lda #<args+2
		ldx #>args+2
		jsr fopen
		bcc :opened
		; failed

		jsr TermPrintAH
		jsr TermCR

		lda #<txt_error_open
		ldx #>txt_error_open
:err
		jsr TermPUTS
		lda #<args+2
		ldx #>args+2
		jsr TermPUTS
		jsr TermCR
		bra wait_for_key
:opened
		lda #<temp0
		ldx #>temp0
		ldy #0
		jsr set_write_address

		lda #4
		ldx #0
		ldy #0
		jsr fread

		pha

		jsr fclose

		pla

		cmp #4
		beq :got4

		stz temp1

		; at least for pics, this will tell me something
		lda #<temp0
		ldx #>temp0
		jsr TermPUTS
		jsr TermCR


		lda #<txt_error_reading
		ldx #>txt_error_reading
		bra :err
:got4



		; $$DO SOMETHING

wait_for_key
]loop
		lda #<event_type
		sta kernel_args_events
		lda #>event_type
		sta kernel_args_events+1
]wait
		jsr kernel_NextEvent
		bcs ]wait

		lda event_type
		cmp #kernel_event_key_PRESSED
		beq :done

		jsr TermPrintAH
		bra ]loop
:done
		jmp mmu_lock
		rts
txt_test asc 'KernelExec 0.0'
		db 13,0
txt_error_open asc 'ERROR: file open: '
		db 0
txt_error_notfound asc 'ERROR: file not found: '
		db 0
txt_error_reading asc 'ERROR: reading: '
		db 0

		put mmu.s
		put term.s
		put lbm.s
		put i256.s
		put lzsa2.s
		put file.s

; pad to the end
		ds $C000-*,$EA
; really pad to end, because merlin is buggy
		ds \
