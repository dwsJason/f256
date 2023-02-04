; Calculating ZIP CRC-32 in 6502
; ==============================
		mx %11

		dum $f2
crc      ds 4
crc_num  ds 3
crc_count ds 3
		dend

; Calculate a ZIP 32-bit CRC from data in memory. This code is as
; tight and as fast as it can be, moving as much code out of inner
; loops as possible.
;
; On entry, crc..crc+3   =  incoming CRC
;           addr..addr+1 => start of data
;           num..num+1   =  number of bytes
; On exit,  crc..crc+3   =  updated CRC
;           addr..addr+1 => end of data+1
;           num..num+1   =  0
;
; Multiple passes over data in memory can be made to update the CRC.
; For ZIP, initial CRC must be &FFFFFFFF, and the final CRC must
; be EORed with &FFFFFFFF before being stored in the ZIP file.
;
; Extra CRC optimisation by Mike Cook, extra loop optimisation by JGH.
; Total 63 bytes.
;
calc_crc32
		stz crc_count
		stz crc_count+1
		stz crc_count+2
]bytelp
		LDX #8                       ; Prepare to rotate CRC 8 bits
		;LDA (crc_addr-8,x)       ; Fetch byte from memory
		jsr readbyte

; The following code updates the CRC with the byte in A ---------+
; If used in isolation, requires LDX #8 here                     |
		EOR crc+0             ; EOR byte into CRC bottom byte    |
]rotlp                        ;                                  |
		LSR crc+3             ;                                  | 
		ROR crc+2             ; Rotate CRC clearing bit 31       |
		ROR crc+1             ;                                  | 
		ROR                   ;                                  |
		BCC :clear            ; b0 was zero                      |
		TAY                   ; Hold CRC low byte in Y for a bit |
		LDA crc+3             ;                                  | 
		EOR #$ED              ;                                  | 
		STA crc+3             ; CRC=CRC EOR &EDB88320, ZIP polynomic
		LDA crc+2             ;                                  | 
		EOR #$B8              ;                                  | 
		STA crc+2             ;                                  |
		LDA crc+1             ;                                  | 
		EOR #$83              ;                                  | 
		STA crc+1             ;                                  |
		TYA                   ;                                  | 
		EOR #$20              ; Get CRC low byte back into A     |
:clear                        ;                                  |
		DEX                   ;                                  | 
		BNE ]rotlp            ; Loop for 8 bits                  |
; If used in isolation, requires STA crc+0 here                  |
; ---------------------------------------------------------------+
;
;		INC crc_addr
;		BNE :next
;		INC crc_addr+1      ; Step to next byte
;:next
;		STA crc+0           ; Store CRC low byte
                            ; Now do a 24-bit decrement
;		LDA crc_num+0
;		BNE :skip           ; num.lo<>0, not wrapping from 00 to FF
;		DEC crc_num+1       ; Wrapping from 00 to FF, dec. high byte
;:skip
;		DEC crc_num+0
;		BNE ]bytelp         ; Dec. low byte, loop until num.lo=0
;		LDA crc_num+1
;		BNE ]bytelp         ; Loop until num=0

		inc crc_count
		bne :check
		inc crc_count+1
		bne :check
		inc crc_count+2
:check
		lda crc_count
		cmp crc_num
		bne ]bytelp
		lda crc_count+1
		cmp crc_num+1
		bne ]bytelp
		lda crc_count+2
		cmp crc_num+2
		bne ]bytelp
		RTS

;------------------------------------------------------------------------------

