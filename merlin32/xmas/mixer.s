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
		; default no oscillators running
		stz VOICE0+osc_state
		stz VOICE1+osc_state
		stz VOICE2+osc_state
		stz VOICE3+osc_state

		; even when not running they output samples
		; so setup some silence
		lda #$08 ; middle of the wave?
		sta VOICE0+osc_sample
		sta VOICE1+osc_sample
		sta VOICE2+osc_sample
		sta VOICE3+osc_sample

		; default volume - not used
		lda #$7f
		sta VOICE0+osc_left_vol
		sta VOICE1+osc_left_vol
		sta VOICE2+osc_left_vol
		sta VOICE3+osc_left_vol

		sta VOICE0+osc_right_vol
		sta VOICE1+osc_right_vol
		sta VOICE2+osc_right_vol
		sta VOICE3+osc_right_vol

		lda #1 ; default frequency is 16khz, or 1.00
		stz VOICE0+osc_frequency+0
		sta VOICE0+osc_frequency+1
		stz VOICE1+osc_frequency+0
		sta VOICE1+osc_frequency+1
		stz VOICE2+osc_frequency+0
		sta VOICE2+osc_frequency+1
		stz VOICE3+osc_frequency+0
		sta VOICE3+osc_frequency+1

		lda <io_ctrl
		pha

		stz <io_ctrl

		; force the PSG outputs to be stereo
		lda #SYS_SID_ST+SYS_PSG_ST
		tsb |VKY_SYS1

; set carrier frequency as high as it can go
AUDIO_FREQ = 0

		; tone 1, fast carrier
		lda #{AUDIO_FREQ&$F}
		ora #$80
		sta |psg_l
		sta |psg_r

		lda #{AUDIO_FREQ/16}
		and #$3F
		sta |psg_l
		sta |psg_r

		; tone 2, fast carrier
		lda #{AUDIO_FREQ&$F}
		ora #$80.$20
		sta |psg_l
		sta |psg_r

		lda #{AUDIO_FREQ/16}
		and #$3F
		sta |psg_l
		sta |psg_r

		; Stop playing the note tone 1
		lda #$80.$10.$0f
		sta psg_l
		sta psg_r

		; Stop playing the note tone 2
		lda #$80.$30.$0f
		sta psg_l
		sta psg_r

		; Stop playing the note tone 3
		lda #$80.$50.$0f
		sta psg_l
		sta psg_r


		pla
		sta <io_ctrl

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
		ora #$80.]2
		sta ]3

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

; we could probably add 2 more channels, if we lower the mixer rate to 11Khz

; now that timing isn't as big of a deal, go ahead and fetch the next samples

		clc  ;  each mix below, keeps c=0

		MixVoice VOICE0;$10;psg_l
		MixVoice VOICE1;$10;psg_r
		MixVoice VOICE2;$30;psg_r
		MixVoice VOICE3;$30;psg_l

		rts

;------------------------------------------------------------------------------



