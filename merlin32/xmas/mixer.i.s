
VOICES   equ 4
DAC_RATE equ 16000

; Enum for Oscillator States
		dum 0
os_stopped            ds 1
os_playing_singleshot ds 1
os_playing_looped     ds 1
		dend


;
;
; Voice/Oscillator Structure
;
; 
		dum 0
osc_state      ds 1
;osc_sample     ds 1
osc_pWave      ds 4 ; 24.8 current wave pointer
;osc_pWaveLoop  ds 3 ; 24 location in the wave, to loop too
osc_pWaveEnd   ds 3 ; 24 end of wave
osc_frequency  ds 2 ; 8.8 frequency
;osc_left_vol   ds 1 ; Left Volume
;osc_right_vol  ds 1 ; Right Volume

sizeof_osc ds 0

		dend





