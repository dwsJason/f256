;
; Merlin32 Cross Dev Stub for the Jr Micro Kernel
;
; To Assemble "merlin32 -v kexec.s"
;

; Platform-Exec
;
;         Load->Run PGX files
;         Load->Run PGZ files
;         Load-Display 256 Picture files
;         Load-Display LBM Picture files
;  

		mx %11

; some Kernel Stuff
		put ..\kernel\api.s

; Kernel uses MMU configurations 0 and 1
; User programs default to # 3
; I'm going to need 2 & 3, so that I can launch the PGX/PGZ with config #3
;
; and 0-BFFF mapped into 1:1
;

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
event_file_data_read = $36

args = $300


; File uses $B0-$BF
; Term uses $C0-$CF
; LZSA uses $E0-$EF
; Kernel uses $F0-FF
; I256 uses $F0-FF
; LBM uses $F0-FF

; 8k Kernel Program, so it can live anywhere

		org $A000
		dsk pexec.bin
sig		db $f2,$56		; signature
		db 1            ; 1 8k block
		db 5            ; mount at $a000
		da start		; start here
		dw 0			; version
		dw 0			; kernel
		asc '-' 		; This will require some discussion with Gadget
		db 0

start
		; Terminal Init
		jsr TermInit

		; mmu help functions are alive
		jsr mmu_unlock

		; Program Version
		lda #<txt_version
		ldx #>txt_version
		jsr TermPUTS

		; Display what we're trying to do
		lda #<txt_launch
		ldx #>txt_launch
		jsr TermPUTS

		; Display the arguments, hopefully there are some
		lda #<args+2
		ldx #>args+2
		jsr TermPUTS
		jsr TermCR

;------------------------------------------------------------------------------
		; Before receiving any Kernel events, we need to have a location
		; to receive them defined
		lda #<event_type
		sta kernel_args_events
		lda #>event_type
		sta kernel_args_events+1
				 
		; Set the drive
		; currently hard-coded to drive 0, since drive not passed
		; stz kernel_args_file_open_drive
		; Set the Filename
		lda #<args+2
		ldx #>args+2
		jsr fopen
		bcc :opened
		; failed

		pha
		lda #<txt_error_open
		ldx #>txt_error_open
		jsr TermPUTS
		pla

		jsr TermPrintAH
		jsr TermCR

		bra wait_for_key
:opened

		; set address, system memory, to read
		lda #<temp0
		ldx #>temp0
		ldy #0
		jsr set_write_address

		; request 4 bytes
		lda #4
		ldx #0
		ldy #0
		jsr fread

		pha

		jsr fclose

		pla

		cmp #4
		beq :got4

		pha

		lda #<txt_error_reading
		ldx #>txt_error_reading
		jsr TermPUTS

		jsr TermPrintAH
		jsr TermCR

		bra wait_for_key
:got4
		jsr execute_file

		; $$DO SOMETHING

wait_for_key
		lda #<txt_press_key
		ldx #>txt_press_key
		jsr TermPUTS

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

;------------------------------------------------------------------------------
;
execute_file
; we have the first 4 bytes, let's see if we can
; identify the file
		lda temp0
		cmp 'Z'
		beq :pgZ
		cmp 'P'
		beq :pgx
		cmp 'I'
		beq :256
		cmp 'F'
		beq :lbm
:done
		lda #<txt_unknown
		ldx #>txt_unknown
		jsr txt_unknown

		rts

;------------------------------------------------------------------------------
; Load / run pgZ Program
:pgZ
		rts
:pgx
		lda temp0+1
		cmp 'G'
		bne :done
		lda temp0+2
		cmp 'X'
		bne :done
		lda temp0+3
		cmp #3
		bne :done
;------------------------------------------------------------------------------
; Load / Run PGX Program
		rts

:256
		lda temp0+1
		cmp '2'
		bne :done
		lda temp0+2
		cmp '5'
		bne :done
		lda temp0+3
		bne :done
;------------------------------------------------------------------------------
; Load / Display 256 Image
;
:lbm
		lda temp0+1
		cmp 'O'
		bne :done
		lda temp0+2
		cmp 'R'
		bne :done
		lda temp0+3
		cmp 'M'
		bne :done
;------------------------------------------------------------------------------
; Load / Display LBM Image

		rts


;------------------------------------------------------------------------------
; Strings and other includes
txt_version asc 'Pexec 0.01'
		db 13,13,0

txt_press_key db 13
		asc '--- Press >ENTER< to continue ---'
		db 13,0
		
txt_unknown
		asc 'Unknown application type'
		db 13,13,0		

txt_launch asc 'launch: '
		db

txt_error_open asc 'ERROR: file open $'
		db 0
txt_error_notfound asc 'ERROR: file not found: '
		db 0
txt_error_reading asc 'ERROR: reading $'
		db 0
txt_error asc 'ERROR!'
		db 13
		db 0
txt_open asc 'Open Success!'
		db 13
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
