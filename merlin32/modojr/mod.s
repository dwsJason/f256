;
; ModoJr Mod Player
;

; Instrument Definition Structure
		dum 0
i_name              ds 32   ; this should be 0 terminated, so max len is 31char
i_sample_rate       ds 3    ; sample rate of original wave, maps to i_key_center
i_key_center        ds 2
i_percussion        ds 1    ; 1 for percussion (this means note # does not matter)
i_fine_tune         ds 1
i_volume            ds 2
i_percussion_freq   ds 2    ; freq to play percussion note at
i_loop              ds 2    ; 1 for loop, 0 for single shot
i_sample_start_addr ds 3    ; ram start address for sample
i_sample_length     ds 3    ; length in bytes
i_sample_loop_start ds 3    ; address
i_sample_loop_end   ds 3    ; address

sizeof_inst ds 0
		dend


;------------------------------------------------------------------------------
;
; ModInit
;
; AXY -> system memory address of MOD
; needs to be on an 8k boundary, aligned to a multiple of $2000
;
ModInit

:pSourceInst = temp0
:loopCount   = temp0+2
:pInst       = temp1
:num_patterns = temp1+2
:pPatterns    = temp2
:pCurPattern = temp3
:pCurInst = temp3

		staxy <mod_start
		jsr set_read_address

		stz SongIsPlaying           ; default not playing

		lda #4  					; default 4 tracks
		sta mod_num_tracks

		ldax #1024
		stax mod_pattern_size   	; default 1024 byte pattern

		lda #4*4
		sta mod_row_size		    ; default 16 byte row

		lda #125
		sta mod_bpm					; default 125 bpm

		ldy #31					; most common MOD
		sty <mod_num_instruments

		lda #6						; default 6
		sta <mod_speed

		; check to see if we support his kind of mod
		jsr ModIsSupported
		bcc :yes

		ldax #txt_unsupported
		jsr TermPUTS

		lda #13
		sta mod_sig+4
		stz mod_sig+5

		ldax #mod_sig
		jsr TermPUTS

		sec
		rts
:yes
;----------- Display the Mod Signature ---------
		ldx #7
		ldy #0
		jsr TermSetXY

		lda mod_sig
		jsr TermCOUT
		lda mod_sig+1
		jsr TermCOUT
		lda mod_sig+2
		jsr TermCOUT
		lda mod_sig+3
		jsr TermCOUT
;		jsr TermCR

;----------- Display the Mod Name ---------------

		ldx #3
		ldy #2
		jsr TermSetXY

		ldx #0
]name_loop
		lda |READ_BLOCK,x
		beq :done_name
		jsr TermCOUT
		inx
		cpx #20
		bcc ]name_loop
:done_name

;----------- Display the Number of Instruments -------

		ldx #14
		ldy #0
		jsr TermSetXY

		lda mod_num_instruments
		jsr TermPrintAI
		
		ldax #txt_instruments
		jsr TermPUTS

;----------- Display the Number of Tracks -------

		ldx #30
		ldy #0
		jsr TermSetXY

		lda mod_num_tracks
		jsr TermPrintAI
		
		ldax #txt_tracks
		jsr TermPUTS

; line accross the bottom of pattern list

		ldx #0
		ldy #24
		jsr TermSetXY

		ldx #79
]lp 	lda #173
		jsr TermCOUT
		dex
		bpl ]lp


; line accross the bottom of instrument block

		ldx #0
		ldy #18
		jsr TermSetXY

		ldx #79
]lp 	lda #173
		jsr TermCOUT
		dex
		bpl ]lp


; line accross the top

		ldx #0
		ldy #1
		jsr TermSetXY


		ldx #79
]lp 	lda #173
		jsr TermCOUT
		dex
		bpl ]lp

;---------- Copy the instrument definition block, into a local instruments
; Lucky this is in the first 8k

		; wait zero out the mod local memory
		ldax #mod_local_start
]loop
		stax :stz+1

:stz 	stz |$1234

		inc
		bne :ss
		inx
:ss
		cmpax #mod_local_end
		bcc ]loop

		stz <:loopCount

		ldax #$6014 ;READ_BLOCK+20
		stax :pSourceInst

]inst_fetch_loop

		; Pointer to the destination Instrument
		lda <:loopCount
		asl
		tax
		lda |inst_address_table,x
		sta <:pInst
		lda |inst_address_table+1,x
		sta <:pInst+1

; copy the sample name
		ldy #21
]lp 	lda (:pSourceInst),y
		sta (:pInst),y
		dey
		bpl ]lp

		lda #22
		jsr :add_to_pSource

; get the sample length

		ldy #i_sample_length+1

		lda (:pSourceInst)
		sta (:pInst),y
		dey
		jsr :inc_pSource
		lda (:pSourceInst)
		sta (:pInst),y

; fine tune
		jsr :inc_pSource 

		lda (:pSourceInst)
		ldy #i_fine_tune
		sta (:pInst),y
; volume
		jsr :inc_pSource

		lda (:pSourceInst)
		ldy #i_volume
		sta (:pInst),y

; loop start
		jsr :inc_pSource
		ldy #i_sample_loop_start+1
		lda (:pSourceInst)
		sta (:pInst),y
		dey
		jsr :inc_pSource
		lda (:pSourceInst)
		sta (:pInst),y

; loop len
		jsr :inc_pSource
		ldy #i_sample_loop_end+1
		lda (:pSourceInst)
		sta (:pInst),y
		dey
		jsr :inc_pSource
		lda (:pSourceInst)
		sta (:pInst),y

		jsr :inc_pSource


		lda <:loopCount
		inc
		sta <:loopCount
		cmp mod_num_instruments

		bcc ]inst_fetch_loop

;------------------------------------------------------------------------------

		jsr :get_byte
		sta mod_song_length

		jsr :inc_pSource

		ldax :pSourceInst
		stax mod_p_pattern_dir

		lda <mmu3
		sta mod_p_pattern_dir+1

		; initialize pattern index
		stz <mod_pattern_index

		; Scan the pattern directory, to find out how many patterns are
		; actually referenced in this file

		ldy #0
		stz <:num_patterns
]lp
		lda (:pSourceInst),y
		cmp <:num_patterns
		bcc :no_update
		sta <:num_patterns
:no_update
		iny
		;cpy mode_song_length
		cpy #128
		bcc ]lp

		inc <:num_patterns

;-------------------- print out the pattern indexes

; top of screen stats

		ldy #0
		ldx #41
		jsr TermSetXY
		ldax #txt_song_length
		jsr TermPUTS

		lda mod_song_length
		jsr TermPrintAI

		lda #' '
		jsr TermCOUT

		ldax #txt_patterns
		jsr TermPUTS

		lda <:num_patterns
		jsr TermPrintAI

; pattern indexes

		ldx #0
		ldy #19
		jsr TermSetXY

		ldx #26
		ldy #0
]lp		
		lda #' '
		jsr TermCOUT

		lda (:pSourceInst),y
		phx
		jsr TermPrintAH
		plx

		dex
		bne :no_cr
		ldx #26
		jsr TermCR
:no_cr
		iny
		cpy #128
		bcc ]lp

		jsr TermCR
	   
;------------------------------------------------------------------------------
	   
		lda #128
		jsr :add_to_pSource
		
; now at position 1080 / M.K.
		; READ_BLOCK+1084
		ldax #$6000+1084 ; modern mod
	   
		ldy <mod_num_instruments
		cpy #15
		bne :mkmod

		; old school mod
		; READ_BLOCK+1080
		ldax #$6000+1080-{16*30}
:mkmod			   
		stax <:pPatterns
		stax <:pCurPattern

		lda mmu3
		sta <:pPatterns+2
		sta <:pCurPattern

; fill out the pattern address table
; yes, this could be nicer, since patterns are 1k in size
; we could relocate them to be aligned in the mmu, and reduce
; the window size.  We're going to try using a 16k window
; for now, and see if we can get away with using only 32k
; of mapped memory for our program

		ldy #0
		clc
]pat_loop
		ldax :pCurPattern
		sta |mod_patterns_l,y
		txa
		sta |mod_patterns_m,y
		lda :pCurPattern+2
		sta |mod_patterns_b,y

		lda <:pCurPattern+1
		adc #>1024  ; 4
		bpl :pat_adr_ok

		inc <:pCurPattern+2
		sbc #31 		   ; c=0, -=$2000

:pat_adr_ok
		sta <:pCurPattern+1

		iny
		cpy #128
		bcc ]pat_loop

; At this point :pCurPattern is the start of the instrument block



 

;------------------------------------------------------------------------------
; Dump the Instrument Data from the local instrument table

		stz <:loopCount
]print
		; Pointer to the destination Instrument
		lda <:loopCount
		asl
		tax
		lda |inst_address_table,x
		sta <:pInst
		lda |inst_address_table+1,x
		sta <:pInst+1

		; number
		ldx #0              ; x position on the screen
		lda <:loopCount
		inc
		cmp #10
		bcs :fine
		inx 		 		; 2 digits, so inc by 1
:fine
		cmp #16
		bcc :left
		sbc #16  			; adjust y for second column
		pha
		;clc
		txa
		adc #40				; tab the x over to the left
		tax
		pla
:left
		;clc
		adc #2
		tay

		jsr TermSetXY

		lda <:loopCount
		inc
		jsr TermPrintAI

		lda #' '
		jsr TermCOUT

		ldax <:pInst
		jsr TermPUTS

		lda <:loopCount
		inc
		sta <:loopCount
		cmp mod_num_instruments
		bcc ]print

;------------------------------------------------------------------------------

		rts
:get_byte
		lda (:pSourceInst)
:inc_pSource
		inc <:pSourceInst
		beq :inc_high
		rts

:add_to_pSource
		clc
		adc <:pSourceInst
		sta <:pSourceInst
		bcc :rts
:inc_high
		inc <:pSourceInst+1
:rts
		rts

ModIsSupported

		ldax READ_BLOCK+1080 ; magic offset
		stax mod_sig
		ldax READ_BLOCK+1080+2
		stax mod_sig+2

		cmpax #'K.'
		bne :next
		ldax mod_sig
		cmpax #'M.'
		bne :next

		clc			; default M.K. --> Good to go
		rts
:next
		; At least for now, I only care about old school mods here
		lda <mod_sig
		jsr :is_letter
		bcs :old_mod

		lda <mod_sig+1
		jsr :is_letter
		bcs :old_mod

		lda <mod_sig+2
		jsr :is_letter
		bcs :old_mod

		lda <mod_sig+3
		jsr :is_letter
		bcc :letters
:old_mod
		lda #15					; really old mod
		sta <mod_num_instruments

		; default - old school mod
		ldax #'mo'
		stax mod_sig
		ldax #'d '
		stax mod_sig+2

		clc
		rts

:letters
		sec ; not supported
		rts

:is_letter
		cmp #$20
		bcc :not_letter
		cmp #$7F
		bcs :not_letter
		; c=0 -> is letter
		rts
:not_letter
		sec
		rts


; Mod Other Local Variables
;------------------------------------------------------------------------------
inst_address_table
]index = 0
		lup 32
		da mod_instruments+{]index*sizeof_inst}
]index = ]index+1
		--^

mod_local_start



;
; Precomputed pointers to patterns
;
mod_patterns_l
	ds 128
mod_patterns_m
	ds 128
mod_patterns_b  ; block
	ds 128

mod_instruments ds sizeof_inst*32  ; Really a normal mod only has 31 of them

mod_last_sample ds 4*8 ; up to 8 channels
mod_channel_pan ds 4*8 ; up to 8 channels
mod_pump_vol    ds 4*8 ; up to 8 channels, pump bar data

mod_local_end
