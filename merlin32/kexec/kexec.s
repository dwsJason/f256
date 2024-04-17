;
; Merlin32 Cross Dev Stub for the Jr Micro Kernel
;
; To Assemble "merlin32 -v kexec.s"
;

; Kernel-Exec
;
;   Load->Run PGX files from Flash
;   Load->Run PGZ files from Flash
;  

		mx %11

; Some Global Direct page stuff

; MMU modules needs 0-1F

	dum $20
temp0 ds 4
temp1 ds 4
temp2 ds 4
temp3 ds 4
	dend

	dum $20
PGz_z ds 1
PGz_addr ds 4
PGz_size ds 4
	dend

	dum $70
temp7 ds 4
temp8 ds 4
temp9 ds 4
temp10 ds 4
	dend


; copy of the mmu_lock function, down to zero page

mmu_lock_springboard = $80

; File uses $B0-$BF
; Term uses $C0-$CF
; Kernel uses $F0-FF

; 8k Kernel Program, so it can live anywhere

		org $A000
		dsk kexec.bin
sig		db $f2,$56		; signature
		db 6            ; 6 8k block
		db 5            ; mount at $a000
		da start		; start here
		db 1			; version
		db 0			; reserved
		db 0			; reserved
		db 0			; reserved
pname	asc 'test' 		; This will require some discussion with Gadget
		db 0
		asc ''	; argument list
		db 0
pdesc	asc 'test desc'	; description
		db 0

		ds \

start
		; Terminal Init
		jsr TermInit

		; mmu help functions are alive
		jsr mmu_unlock

		; Program Name

		lda #<pname
		ldx #>pname
		jsr TermPUTS

		lda #' '
		jsr TermCOUT

		lda #<pdesc
		ldx #>pdesc
		jsr TermPUTS

		jsr fopen		; sets us up to start parsing the file

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

		bra :done
:got4
		jsr execute_file

:done
		jmp mmu_lock   ; jsr+rts

;------------------------------------------------------------------------------
;
execute_file

; we have the first 4 bytes, let's see if we can
; identify the file
		lda temp0
		cmp #'Z'
		beq :pgZ
		cmp #'z'
		beq :pgz
		cmp #'P'
		beq :pgx
:done
		; we're screwed here
		rts

;------------------------------------------------------------------------------
; Load / run pgZ Program
:pgZ
		jmp LoadPGZ
:pgz
		jmp LoadPGz
:pgx
		lda temp0+1
		cmp #'G'
		bne :done
		lda temp0+2
		cmp #'X'
		bne :done
		lda temp0+3
		cmp #3
		bne :done
;------------------------------------------------------------------------------
; Load / Run PGX Program
;		jmp LoadPGX
;-----------------------------------------------------------------------------
LoadPGX
		lda #<temp0
		ldx #>temp0
		ldy #^temp0
		jsr set_write_address
		
		jsr fopen

		lda #8
		ldx #0
		ldy #0
		jsr fread
		
		lda temp1
		ldx temp1+1
		ldy temp1+2
		jsr set_write_address
		
		; Try to read 64k, which should load the whole file
		lda #0
		tax
		ldy #1
		jsr fread

launchProgram
		jsr fclose	; close PGX or PGZ
		
		lda #5
		sta old_mmu0+5	; when lock is called it will map $A000 to physcial $A000

		; need to place a copy of mmu_lock, where it won't be unmapped
		ldx #mmu_lock_end-mmu_lock
]lp		lda mmu_lock,x
		sta mmu_lock_springboard,x
		dex
		bpl ]lp

		; construct more stub code
		lda #$20   ; jsr mmu_lock_springboard
		sta temp0
		lda #<mmu_lock_springboard
		sta temp0+1
		lda #>mmu_lock_springboard
		sta temp0+2 

		lda #$4c
		sta temp1-1  ; same as temp0+3

		; temp1, and temp1+1 contain the start address
		
		jmp temp0	; will jsr mmu_lock, then jmp to the start

;-----------------------------------------------------------------------------
LoadPGz
		jsr fopen
		
		lda #<PGz_z
		ldx #>PGz_z
		ldy #^PGz_z
		jsr set_write_address
		
		lda #9
]loop
		ldx #0
		ldy #0
		jsr fread
		
		lda PGz_size
		ora PGz_size+1
		ora PGz_size+2
		ora PGz_size+3
		beq pgzDoneLoad
		
		lda PGz_addr
		ldx PGz_addr+1
		ldy PGz_addr+2
		jsr set_write_address

		lda PGz_size
		ldx PGz_size+1
		ldy PGz_size+2
		jsr fread
		
		lda #<PGz_addr
		ldx #>PGz_addr
		ldy #^PGz_addr
		jsr set_write_address
		lda #8
		bra ]loop

;-----------------------------------------------------------------------------
LoadPGZ
		; Open the File again (seek back to 0)
		jsr fopen
		
		lda #<temp0
		ldx #>temp0
		ldy #^temp0
		jsr set_write_address
		
		lda #7
]loop
		ldx #0
		ldy #0
		jsr fread
		
		lda temp1
		ora temp1+1
		ora temp1+2
		beq pgzDoneLoad
		
		lda temp0+1
		ldx temp0+2
		ldy temp0+3
		jsr set_write_address

		lda temp1
		ldx temp1+1
		ldy temp1+2
		jsr fread
		
		lda #<temp0+1
		ldx #>temp0+1
		ldy #^temp0+1
		jsr set_write_address
		lda #6
		bra ]loop

pgzDoneLoad

		; copy the start location, for the launch code fragment 
		lda temp0+1
		sta temp1
		lda temp0+2
		sta temp1+1

		jmp launchProgram  ; share cleanup with PGX launcher

;------------------------------------------------------------------------------
; other includes
;------------------------------------------------------------------------------
		put mmu.s
		put term.s
		put file.s

; could be either a PGX or a PGZ
		ds \

program_start
data_start
;		putbin xmas.pgz
;		putbin fm_b20pre1.pgZ

