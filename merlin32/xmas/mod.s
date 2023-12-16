;
; ModoJr Mod Player
;

DISPLAY_STUFF equ 0

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

i_sample_start_badr ds 3  	; Start, Loop, and End in Block MMU3 address format
i_sample_loop_badr  ds 3	;
i_sample_loop_bend  ds 3	;

sizeof_inst ds 0
		dend

;------------------------------------------------------------------------------
ModPlayerTick mx %11

;		inc mod_jiffy
;		bne :no_hi
;		inc mod_jiffy+1
;:no_hi
		lda <mod_jiffy
		inc
		cmp <mod_speed
		bcs :next_row
		sta <mod_jiffy
		rts
:next_row
		stz <mod_jiffy

		lda SongIsPlaying
		bne :play_song

		rts

:play_song

; interpret mod_p_current_pattern, for simple note events
; this is called during an interrupt, so I'm working with the idea
; that it's safe to modify the oscillators

:note_period = mod_temp0
:note_sample = mod_temp0+2
:effect_no   = mod_temp1
:effect_parm = mod_temp1+2
:break = mod_temp2
:break_row = mod_temp2+2
:osc_x = mod_temp3
:vol   = mod_temp3+2
:jump = mod_temp4
:jump_order = mod_temp4+2
:pInst = mod_temp5

		stz <:break
		stz <:jump

		ldx #mixer_voices
		stx <:osc_x

		; map
		lda mod_p_current_pattern+2
		sta mmu3	;
		inc  		; $$TODO NOTE, I COULD FIX THIS BY ALIGNING PATTERN DATA
		sta mmu4	;

		ldy #0
]lp
		; $$JGA TODO, add volume support, right now there is NONE!
		;lda |mod_channel_pan,y    ; left
		lda #64 				   ; for now, save some clocks
		sta <:vol
		;lda |mod_channel_pan+1,y  ; right
		;sta <:vol+1

		lda (mod_p_current_pattern),y
		iny
		sta <:note_sample
		and #$0F
		sta <:note_period+1

		lda (mod_p_current_pattern),y
		iny
		sta <:note_period

		lda #$0F
		trb <:note_sample		; :note_sample has the instrument index

		lda (mod_p_current_pattern),y
		iny
		sta <:effect_no

		lsr
		lsr
		lsr
		lsr
		and #$0F
		tsb <:note_sample

		lda (mod_p_current_pattern),y
		iny
		sta <:effect_parm


		lda #$F0
		trb <:effect_no
;----------------------------------- what can I do with this stuff?

;     if (SAMPLE > 0) then {
;	  LAST_INSTRUMENT[CHANNEL] = SAMPLE_NUMBER  (we store this for later)
;	  volume[CHANNEL] = default volume of sample SAMPLE_NUMBER
;     }

		lda <:note_sample
		beq :no_note_sample

		sta |mod_last_sample,y

:no_note_sample

;     if (NOTE exists) then {
;	  if (VIBRATO_WAVE_CONTROL = retrig waveform) then {
;		vibrato_position[CHANNEL] = 0 (see SECTION 5.5 about this)
;	  if (TREMOLO_WAVE_CONTROL = retrig waveform) then {
;		tremolo_position[CHANNEL] = 0 (see SECTION 5.8 about this)
;
;	  if (EFFECT does NOT = 3 and EFFECT does NOT = 5) then
;	      frequency[CHANNEL] =
;			FREQ_TAB[NOTE + LAST_INSTRUMENT[CHANNEL]'s finetune]
;     }
;
;     if (EFFECT = 0 and EFFECT_PARAMETER = 0) then goto to SKIP_EFFECTS label
;									    |
;     ....                                                                   ³
;     PROCESS THE NON TICK BASED EFFECTS (see section 5 how to do this)      ³
;     ALSO GRAB PARAMETERS FOR TICK BASED EFFECTS (like porta, vibrato etc)  ³
;     ....                                                                   ³
;									    ³
;label SKIP_EFFECTS:     <-ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;
;     if (frequency[CHANNEL] > 0) then SetFrequency(frequency[CHANNEL])
;	 if (NOTE exists) then {
;	  PLAYVOICE (adding sample_offset[CHANNEL] to start address)
;     }
;     move note pointer to next note (ie go forward 4 bytes in pattern buffer)

;		lda <:note_period
;		beql :nothing

		; do some effect stuff here
		lda <:effect_no
		asl
		tax
		jmp (:effect_table,x)

:effect_table
		da :arpeggio		   ;0
		da :porta_up		   ;1
		da :porta_down  	   ;2
		da :porta_to_note      ;3
		da :vibrato 		   ;4
		da :porta_vol_slide    ;5
		da :vibrato_vol_slide  ;6
		da :tremolo 		   ;7
		da :pan 			   ;8
		da :sample_offset      ;9
		da :vol_slide   	   ;A
		da :jump_to_pattern    ;B
		da :set_volume  	   ;C
		da :pattern_break      ;D
		da :E_things  	   	   ;E
		da :set_speed   	   ;F


:arpeggio
:porta_up
:porta_down
:porta_to_note
:vibrato
:porta_vol_slide
:vibrato_vol_slide
:tremolo
		bra :after_effect
:pan
; Dual Mod Player
;00 = far left
;40 = middle
;80 = far right
;A4 = surround *

; FT2 00 = far left, 80 = center, FF = far right

; how can you know?  (I guess I would analyze all the pan settings in the whole)
; tune, ahead of time, and see what the range is.  Yuck
		bra :after_effect
:sample_offset
:vol_slide
		bra :after_effect
:jump_to_pattern
		inc <:jump
		stz <:break_row    ; we always use this as the row
		lda <:effect_parm
		sta <:jump_order
		bra :after_effect  ; if a break is encountered after this in the row, it change the the jump_row, which is the same as the break row
:set_volume
;		ldax <:vol
;		phax		   ; temp save left,right vol on stack
;
		lda <:effect_parm ; 0-$40
		sta <:vol
;		lsr
;		cmp #$20
;		bcc :vol_range_ok
;		lda #$20   ; clamp
;:vol_range_ok
;		sta <:vol     ; left
;		sta <:vol+1   ; right (until we take into account pan)
;
;		plax
;		cmpax #$0820
;		beq :dim_right
;
;		; dim_left
;		lsr <:vol
;		lsr <:vol
;
;		bra :not_right
;:dim_right
;
;		lsr <:vol+1
;		lsr <:vol+1
;
;:not_right
;
;		ldx <:osc_x
;		lda <:vol  		; left/right volume (3f max)
;		sta <osc_left_vol,x
;		lda <:vol+1
;		sta <osc_right_vol,x
		bra :after_effect

:pattern_break
		inc <:break 	  			; need to break
		lda <:effect_parm
		sta <:break_row 			; skip to this row, with the break
		bra :after_effect
:E_things
		bra :after_effect
:set_speed
		lda <:effect_parm
		cmp #$20
		bcs :BPM  ; this needs to alter the 50hz timer, Beats Per Minute
		sta <mod_speed
		bra :after_effect

:BPM
		; needs to alter timer, skip for now
		phx
		sta <mod_bpm  			    ; for the visualizer
		tax
		lda |bpm_tick_table_l,x    	; changing from 50hz to, who knows what
		sei
		sta <mod_jiffy_rate
		lda |bpm_tick_table_h,x
		sta <mod_jiffy_rate+1
		cli
		plx

:after_effect

;NSTC:  (7159090.5  / (:note_period * 2))/16000 into 8.8 fixed result
;        (3579545.25 / :note_period) / 16000

;223.721578125 / :note_period
;57273 / :note_period
		ldax <:note_period
		cmpax #0
		beql :nothing

		stax |DIVU_DEN_L

		ldax #57273
		stax |DIVU_NUM_L

		; frequency
		ldx <:osc_x
		lda |QUOU_LL
		sei
		sta <osc_frequency,x
		lda |QUOU_LH
		sta <osc_frequency+1,x
		cli

		lda <:vol  		; left/right volume (3f max)
		;sta <osc_left_vol,x  ; save some clocks since we don't use this
		;lda <:vol+1
		;sta <osc_right_vol,x

		;---- start - this might be a good spot to update the pumpbar out

		sta |mod_pump_vol,y

		;---- end - this might be a good spot to update the pumpbar out

		phy  ; need to preserve

		lda |mod_last_sample,y
		and #$1F
		beq :no_sample

		dec
		asl
		tay
		lda |inst_address_table,y
		sta <:pInst
		lda |inst_address_table+1,y
		sta <:pInst+1

		; skip playing empty samples
		ldy #i_sample_length
		lda (:pInst),y
		iny
		ora (:pInst),y
		beq :no_sample

		;$$TODO
		;lda |i_fine_tune,y
		;lda |i_volume,y

		stz <osc_state,x ; stop the oscillator, while we futz with it

		; Instrument Definitions have their pointers in system
		; use pre-converted versions of the information
		; into block + offset address mmu format, to save some cpu
		; cycles here

		; wave pointer 24.8
		stz <osc_pWave,x		; zero out the fraction

		ldy #i_sample_start_badr
		lda (:pInst),y
		sta <osc_pWave+1,x
		iny
		lda (:pInst),y
		sta <osc_pWave+2,x
		iny
		lda (:pInst),y
		sta <osc_pWave+3,x

		; loop address 24
		ldy #i_sample_loop_badr
		lda (:pInst),y
		sta <osc_pWaveLoop,x
		iny
		lda (:pInst),y
		sta <osc_pWaveLoop+1,x
		iny
		lda (:pInst),y
		sta <osc_pWaveLoop+2,x

		; wave end address 24
		ldy #i_sample_loop_bend
		lda (:pInst),y
		sta <osc_pWaveEnd,x
		iny
		lda (:pInst),y
		sta <osc_pWaveEnd+1,x
		iny
		lda (:pInst),y
		sta <osc_pWaveEnd+2,x

		ldy #i_loop
		lda (:pInst),y
		inc 					; 1=single shot, 2=loop
		sta <osc_state,x		; re-enable the osc

:no_sample
		ply ; restore y

:nothing
		; c=?
		ldx <:osc_x
		clc
		txa
		adc #sizeof_osc  ; next oscillator, for the next track
		tax
		stx <:osc_x
		cpy <mod_row_size ; 4*4 or 8*4 or 6*4 or 7*4
		bccl ]lp

; check for jump
		lda <:jump
		bne :perform_jump  ; if we jump, we don't break

; check for break
		lda <:break
		bne :perform_break

; next row, and so on
		lda <mod_current_row
		inc
		cmp #64 ; number of rows in the pattern
		bcs :next_pattern
		sta <mod_current_row
		;c=0
		lda <mod_p_current_pattern
		adc <mod_row_size ;#4*4 or #8*4
		sta <mod_p_current_pattern
		bcc :no_carry
		inc <mod_p_current_pattern+1
:no_carry
		rts

:next_pattern
		stz <mod_current_row
:nxtp_leave_row
		lda <mod_pattern_index
		inc
		cmp <mod_song_length
		bcs :song_done
		sta <mod_pattern_index

		bra ModSetPatternPtr

:song_done
		;stz <SongIsPlaying
		; restart the song, song looping in demo
		jmp ModPlay 
		rts

:perform_jump
		; the next pattern is <:jump_order
		lda <:jump_order
		sta <mod_pattern_index

		lda <:break_row
		sta <mod_current_row

		bra ModSetPatternPtr

:perform_break

		lda <:break_row
		sta <mod_current_row

		bra :nxtp_leave_row

;------------------------------------------------------------------------------
; ModPlay (play the current Mod)
;
ModPlay mx %11
; stop existing song
	stz <SongIsPlaying

; Initialize song stuff

	lda #6  ; default speed
	sta <mod_speed
	stz <mod_jiffy

	stz <mod_current_row
	stz <mod_pattern_index
	jsr ModSetPatternPtr

	lda #1
	sta <SongIsPlaying
	rts

;------------------------------------------------------------------------------
;
; Map in the current pattern
;
ModSetPatternPtr mx %11
	ldy <mod_pattern_index

	lda <mod_p_pattern_dir+2  ; map in pattern block
	sta <mmu3

	lda (mod_p_pattern_dir),y
	and #$7F
	tax

	lda |mod_patterns_l,x
	sta <mod_p_current_pattern
	lda |mod_patterns_m,x
	sta <mod_p_current_pattern+1
	lda |mod_patterns_b,x
	sta <mod_p_current_pattern+2
	;sta <mmu3
	;inc
	;sta <mmu4

	rts

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
:pCurInst = temp4
:iLen = temp5
:temp = temp6
:iEnd = temp7

		staxy <mod_start
		jsr set_read_address

		do DISPLAY_STUFF
		lda #2
		sta io_ctrl         ; swap in the text memory
		fin

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
		
		do 0					    ; needs to happen after the memory is zero below
		lda #$40				 	; default volumes 
		sta |mod_channel_pan
		sta |mod_channel_pan+{4*1}
		sta |mod_channel_pan+{4*2}
		sta |mod_channel_pan+{4*3}
		fin

		; check to see if we support his kind of mod
		jsr ModIsSupported
		bcc :yes

		ldax #txt_unsupported
		jsr TermPUTS

		lda #13
		sta mod_sig+4
		stz mod_sig+5

		do DISPLAY_STUFF
		ldax #mod_sig
		jsr TermPUTS
		fin

		sec
		rts
:yes
;----------- Display the Mod Signature ---------
		do DISPLAY_STUFF
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

		fin

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

		;$$JGA FIXME
		ldax :pSourceInst
		stax mod_p_pattern_dir

		lda <mmu3
		sta mod_p_pattern_dir+2

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

		lda <:num_patterns
		sta <mod_num_patterns

;-------------------- print out the pattern indexes

; top of screen stats
		do DISPLAY_STUFF
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
		fin
	   
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
		sta <:pCurPattern+2

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
		adc #>1024  ; 4 	(16*64)
		bpl :pat_adr_ok

		inc <:pCurPattern+2
		sbc #31 		   ; c=0, -=$2000

:pat_adr_ok
		sta <:pCurPattern+1

		iny
		;cpy #128
		cpy mod_num_patterns 
		bcc ]pat_loop

; At this point :pCurPattern is the start of the instrument block

		; convert in to system memory pointer
		lda <:pCurPattern
		sta <:pCurInst
		lda <:pCurPattern+1
		and #$1f
		sta <:pCurInst+1

		lda <:pCurPattern+2
		lsr
		lsr
		lsr
		sta <:pCurInst+2

		lda <:pCurPattern+2
		asl
		asl
		asl
		asl
		asl
		tsb <:pCurInst+1

		do 0
		; test junk
		ldx #0
		ldy #25
		jsr TermSetXY

		ldaxy <:pCurPattern
		jsr TermPrintAXYH

		lda #' '
		jsr TermCOUT

		ldaxy <:pCurInst
		jsr TermPrintAXYH

]wait   bra ]wait
		fin

; fix up the instrument table
;
; i_sample_start_addr
; i_sample_length
; i_sample_loop_start
; i_sample_loop_end   ; contains the loop length
;

		; change out each pcm sample, to be unsigned
		; instead of signed  (eor #$80)

		; convert into SN76489 format
		; eor #$FF
		; lsr4


		stz <:loopCount
]iloop
		lda <:loopCount
		asl
		tax
		lda |inst_address_table,x
		sta <:pInst
		lda |inst_address_table+1,x
		sta <:pInst+1

		ldy #i_sample_start_addr

		; System Memory Start of the Instrument
		lda <:pCurInst
		sta (:pInst),y
		iny
		lda <:pCurInst+1
		sta (:pInst),y
		iny
		lda <:pCurInst+2
		sta (:pInst),y

		; Adjust the length from words to bytes
		; and update length
		ldy #i_sample_length
		lda (:pInst),y
		asl
		sta (:pInst),y
		sta <:iLen

		iny
		lda (:pInst),y
		rol
		sta (:pInst),y
		sta <:iLen+1

		iny
		lda #0
		rol
		sta (:pInst),y
		sta <:iLen+2

		; adjust the loop start - words to byte
		; and add to the pCurInst start

		ldy #i_sample_loop_end   ; really length

		lda (:pInst),y
		cmp #2
		bcs :it_loops
		iny
		lda (:pInst),y
		bne :it_loops

		; no loop
		lda #0
		sta (:pInst),y  	; i_sample_loop_end is now zero
		dey
		sta (:pInst),y

		ldy #i_loop			; zero loop flag
		sta (:pInst),y

		ldy #i_sample_loop_start   

		sta (:pInst),y
		iny
		sta (:pInst),y		; i_sample_loop_start is now zero 

		bra :no_loop

:it_loops
		ldy #i_sample_loop_start
		jsr :get_add_store

		lda <:pCurInst		; save cur inst pointer
		pha
		lda <:pCurInst+1
		pha
		lda <:pCurInst+2
		pha

		lda <:temp     		; we want our length added to the loop address
		sta <:pCurInst
		lda <:temp+1
		sta <:pCurInst+1
		lda <:temp+2
		sta <:pCurInst+2

		ldy #i_sample_loop_end
		jsr :get_add_store

		pla 			   	; restore cur inst
		sta <:pCurInst+2
		pla
		sta <:pCurInst+1
		pla
		sta <:pCurInst

		ldy #i_loop
		lda #1
		sta (:pInst),y

:no_loop
		; next wave start location
		clc
		lda <:pCurInst
		adc <:iLen
		sta <:pCurInst
		lda <:pCurInst+1
		adc <:iLen+1
		sta <:pCurInst+1
		lda <:pCurInst+2
		adc <:iLen+2
		sta <:pCurInst+2

		; if the instrument is single shot, here's our chance to
		; set the i_sample_loop_end to the end of the single shot
		; to make the mod player note-on code a little more simple
		ldy #i_loop
		lda (:pInst),y
		bne :loops_ok

		; This is a single shot
		ldy #i_sample_loop_end
		lda <:pCurInst
		sta (:pInst),y
		iny
		lda <:pCurInst+1
		sta (:pInst),y
		iny
		lda <:pCurInst+2
		sta (:pInst),y
:loops_ok

		;
		; This is getting silly, but if I can pre-calcuate these
		; pointers for the mixer, the mod player interrupt can
		; be a bit shorter.
		;
		ldy #i_sample_start_addr
		ldx #i_sample_start_badr
		jsr :convert_to_baddr

		ldy #i_sample_loop_start
		ldx #i_sample_loop_badr
		jsr :convert_to_baddr

		ldy #i_sample_loop_end
		ldx #i_sample_loop_bend
		jsr :convert_to_baddr

		lda <:loopCount
		inc
		sta <:loopCount
		cmp <mod_num_instruments
		bccl ]iloop

		do DISPLAY_STUFF
		; dump out last address, so I can make sure it matches mod length
		ldx #73
		ldy #24
		jsr TermSetXY

		ldaxy <:pCurInst
		jsr TermPrintAXYH
		fin
 

;------------------------------------------------------------------------------
; Dump the Instrument Data from the local instrument table

		do DISPLAY_STUFF

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
		adc #39				; tab the x over to the right
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

		ldx term_x
		phx		; save, so we can put data next to the name


		lda #' '
		jsr TermCOUT

		ldax <:pInst
		jsr TermPUTS

		; jump cursor to right of name
		clc
		pla
		adc #23
		tax
		ldy term_y
		jsr TermSetXY

		ldy #i_sample_length
		lda (:pInst),y
		iny
		ora (:pInst),y
		beq :skip_this_one

		ldy #i_sample_start_addr
		jsr :show_address

		ldy #i_loop
		lda (:pInst),y
		beq :skip_this_one

		ldy #i_sample_loop_start
		jsr :show_address

		;ldax #txt_L
		;jsr TermPUTS
		;lda #'L'
		;jsr TermCOUT

:skip_this_one
		lda <:loopCount
		inc
		sta <:loopCount
		cmp mod_num_instruments
		bcc ]print

		fin

;------------------------------------------------------------------------------

		do DISPLAY_STUFF
		ldx #0
		ldy #25
		jsr TermSetXY
		;ldax #txt_massage_wave
		;jsr TermPUTS
		fin

		stz <:loopCount

]massage_loop

		; Pointer to the destination Instrument
		lda <:loopCount
		asl
		tax
		lda |inst_address_table,x
		sta <:pInst
		lda |inst_address_table+1,x
		sta <:pInst+1

		do 0     			; make me feel good, to see stuff happening
		lda <:loopCount
		jsr TermPrintAI

		ldy #i_sample_start_addr
		jsr :print_addr

		ldy #i_sample_loop_start
		jsr :print_addr

		ldy #i_sample_loop_end
		jsr :print_addr

		ldy #i_sample_start_badr
		jsr :print_addr

		ldy #i_sample_loop_badr
		jsr :print_addr

		ldy #i_sample_loop_bend
		jsr :print_addr

		jsr TermCR
		fin

;
; Do the actual sample massage so it's ready to stuff into the PSG
;
		ldy #i_sample_loop_bend
		jsr :get_temp

		lda :temp
		sta :iEnd
		lda :temp+1
		sta :iEnd+1
		lda :temp+2
		sta :iEnd+2

		ldy #i_sample_start_badr
		jsr :get_temp

		lda :temp+2
		sta <mmu3
]massage
		lda <:temp
		cmp <:iEnd
		bne :process_sample

		lda <:temp+1
		cmp <:iEnd+1
		bne :process_sample

		lda <mmu3
		cmp <:iEnd+2
		beq :done_sample

:process_sample

		lda (:temp)
		eor #$7F 		; eor #$80 + #$FF
		lsr
		lsr
		lsr
		lsr
		sta (:temp)

		inc <:temp
		bne ]massage
		inc <:temp+1
		bpl ]massage
		lda #>READ_BLOCK
		sta <:temp+1
		inc <mmu3
		bra ]massage

:done_sample

		lda <:loopCount
		inc
		sta <:loopCount
		cmp mod_num_instruments
		bccl ]massage_loop

		rts

:print_addr
		jsr :get_temp

		lda #' '
		jsr TermCOUT

		ldaxy :temp
		jsr TermPrintAXYH

		rts

:convert_to_baddr
		jsr :get_temp

		lda <:temp+1
		asl
		rol <:temp+2
		asl
		rol <:temp+2
		asl
		rol <:temp+2

		lda <:temp+1
		and #$1F
		ora #>READ_BLOCK
		sta <:temp+1

		txa
		tay
:set_temp
		lda <:temp
		sta (:pInst),y
		iny
		lda <:temp+1
		sta (:pInst),y
		iny
		lda <:temp+2
		sta (:pInst),y

		rts

:show_address
		jsr :get_temp
		;lda :temp+2
		;jsr TermPrintAN  ; Nybble
		;ldax :temp
		;jsr TermPrintAXH

		ldaxy :temp
		jsr TermPrintAXYH
		lda #' '
		jmp TermCOUT

:get_temp
		lda (:pInst),y
		sta <:temp
		iny
		lda (:pInst),y
		sta <:temp+1
		iny
		lda (:pInst),y
		sta <:temp+2
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

:get_add_store
		; fetch word offset, x2 into temp
		phy
		lda (:pInst),y
		asl
		sta <:temp

		iny
		lda (:pInst),y
		rol
		sta <:temp+1

		iny
		lda #0
		rol
		sta <:temp+2

	    ; add temp to current sample start
		clc
		lda <:temp
		adc <:pCurInst
		sta <:temp
		lda <:temp+1
		adc <:pCurInst+1
		sta <:temp+1
		lda <:temp+2
		adc <:pCurInst+2
		sta <:temp+2

		; save result back into instrument def
		;ldy #i_sample_loop_start
		ply
		lda <:temp
		sta (:pInst),y

		iny
		lda <:temp+1
		sta (:pInst),y

		iny
		lda <:temp+2
		sta (:pInst),y
		rts

;------------------------------------------------------------------------

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

;------------------------------------------------------------------------------
; tick rate table
;CPU_CLOCK_RATE equ 6293750
TIMER_TICK_RATE = 16000
bpm_tick_table_l
]bpm = 0
		lup 256
]hz = {{2*]bpm}/5}
		do ]hz
		db <{TIMER_TICK_RATE/]hz}
		else
		db 0
		fin
]bpm = ]bpm+1
		--^

bpm_tick_table_h
]bpm = 0
		lup 256
]hz = {{2*]bpm}/5}
		do ]hz
		db >{TIMER_TICK_RATE/]hz}
		else
		db 0
		fin
]bpm = ]bpm+1
		--^


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

mod_last_sample ds 4*16 ; up to 8 channels
mod_channel_pan ds 4*16 ; up to 8 channels
mod_pump_vol    ds 4*16 ; up to 8 channels, pump bar data

pump_bar_levels ds 2*8 	   ; for current rendering
pump_bar_peaks  ds 2*8 	   ; peaks hang on for 1 second
pump_bar_last_peak ds 2*8  ; only for peaks, make the draw code "smarter"
pump_bar_peak_timer ds 2*8 ; peak gets cleared to 0, when timer hits 0

mod_local_end
