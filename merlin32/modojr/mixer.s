;
;
;  PCM Mixer Code
;
;
;------------------------------------------------------------------------------
		mx %11

psg_r = VKY_PSG0
psg_l = VKY_PSG1

MixerInit
		rts

;------------------------------------------------------------------------------

VOICE0 = mixer_voices+{sizeof_osc*0}
VOICE1 = mixer_voices+{sizeof_osc*1}
VOICE2 = mixer_voices+{sizeof_osc*2}
VOICE3 = mixer_voices+{sizeof_osc*3}

MixVoice mac
		lda ]1+osc_state
		beq next_osc		; osc stopped, so skip it

		lda ]1+osc_pWave+3  ; block number
		sta mmu3			; using block 3, $6000

		lda (]1+osc_pWave+1) ; fetch sample data
		sta ]1+osc_sample	; catched sample, for next interrupt

		; increment sample pointer
		; c=0
		lda ]1+osc_frequency		; fractional pointer
		adc ]1+osc_pWave
		sta ]1+osc_pWave

		lda ]1+osc_frequency+1  	; low byte
		adc ]1+osc_pWave+1
		sta ]1+osc_pWave+1

		bcc check_loop				; skipping as much work as possible

		lda ]1+osc_pWave+2  		; c=1
		adc #0						; 2 clocks, same as inc, but does clc
		bpl no_wrap 				; c=0

		lda #>READ_BLOCK			; wrap to the beginning of the block
		inc ]1+osc_pWave+3          ; block number moves forward

no_wrap sta ]1+osc_pWave+2

check_loop 

		; check for the end
		lda ]1+osc_pWave+3
		cmp ]1+osc_pWaveEnd+2
		bcc next_osc

		; we might be at the end
		lda ]1+osc_pWave+2
		cmp ]1+osc_pWaveEnd+1
		bcc next_osc

		lda ]1+osc_pWave+1
		cmp ]1+osc_pWaveEnd
		bcc next_osc

		; we are at the end - reset
		lda ]1+osc_state
		lsr
		bcc loop_the_wave

		; single shot
		stz ]1+osc_state  ; stop the osc
		clc
		jmp next_osc

loop_the_wave

		; I want the fraction to carry through here
		; $$TODO - fix the fraction here

		lda ]1+osc_pWaveLoop+2  		; block copies
		sta ]1+osc_pWave+3

		lda ]1+osc_pWaveLoop+1
		sta ]1+osc_pWave+2

		lda ]1+osc_pWaveLoop
		sta ]1+osc_pWave+1

		stz ]1+osc_pWave   ; wipe the fraction

next_osc
		<<<

;------------------------------------------------------------------------------

MixerMix mx %11
;
; We do this to reduce jitter, since we don't have a FIFO, we want to minimize
; the time between the IRQ and stuffing samples, and even more important
; this time should be as consistent as possible
;
		lda VOICE0+osc_sample
		ora #$80.$10			; Tone 1 - Left
		sta psg_l

		lda VOICE1+osc_sample
		ora #$80.$10			; Tone 1 - Right
		sta psg_r

		lda VOICE2+osc_sample
		ora #$80.$30			; Tone 2 - Right
		sta psg_r

		lda VOICE3+osc_sample
		ora #$80.$30			; Tone 2 - Left
		sta psg_l

; we could probably add 2 more channels, if we lower the mixer rate to 11Khz

; now that timing isn't as big of a deal, go ahead and fetch the next samples

		clc  ;  each mix below, keeps c=0

		MixVoice VOICE0
		MixVoice VOICE1
		MixVoice VOICE2
		MixVoice VOICE3

		rts

;------------------------------------------------------------------------------



