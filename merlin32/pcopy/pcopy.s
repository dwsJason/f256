;
; Merlin32 Hello.PGX program, for Jr
;
; To Assemble "merlin32 -v hello.s"
;
		mx %11

; some Kernel Stuff
		put ..\kernel\api.s

;PGX_CPU_65816 = $01
;PGX_CPU_680X0 = $02
PGX_CPU_65C02 = $03

		org $0
		dsk pcopy.pgx
		db 'P','G','X' 		; PGX header
		db PGX_CPU_65C02    ; CPU - 65c02
		adrl start

;------------------------------------------------------------------------------
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

event_file_data_read  = event_type+kernel_event_event_t_file_data_read
event_file_data_wrote = event_type+kernel_event_event_t_file_wrote_wrote 

args = $300

; File uses $B0-$BF
; Term uses $C0-$CF
; Kernel uses $F0-FF

;
; $200-$3FF is currently ear-marked for args, and environment status shit
; Even if we don't care, we don't know if it will be placed in these locations
; before we're loaded, or after
;
		org $400
start
		jsr TermInit
		jsr mmu_unlock




		put mmu.s
		put term.s
		put file.s
		put crc32.s



