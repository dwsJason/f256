;
; Merlin32 Compressed Bitmap example for Jr
;
; To Assemble "merlin32 -v . link.s"
;
		mx %11


; System Bus Pointer's
;pSource  equ $10
;pDest    equ pSource+4
; Do not use anything below $20, the mmu module owns it

	dum $20
temp0 ds 4
temp1 ds 4
temp2 ds 4
temp3 ds 4
temp4 ds 4
temp5 ds 4
temp6 ds 4
temp7 ds 4

xpos ds 2
ping ds 2

frame_number ds 1

jiffy ds 2		; 60hz jiffy timer
;
; mixer - variables - I'm hogging up like 64 bytes here
; if need be, we could give mixer it's own DP (by using the mmu)
;
mixer_voices ds sizeof_osc*VOICES

; mod player - variables
mod_start ds 3
mod_sig   ds 4   ; M.K. most common

mod_num_tracks   ds 1  ; expects 4
mod_pattern_size ds 2  ; expects 1024 (for 4 tracks)
mod_row_size     ds 1  ; expects 4*4
mod_bpm          ds 1  ; expects 125
mod_speed        ds 1  ; default speed is 6

mod_num_instruments ds 1 ; expected 31

mod_song_length       ds 1     ; length in patterns
mod_p_current_pattern ds 3     ; pointer to the current pattern
mod_p_pattern_dir     ds 3	   ; pointer to directory of patterns (local ptr, and mmu block number)
mod_current_row       ds 1     ; current row #
mod_pattern_index     ds 1     ; current index into pattern directory
mod_num_patterns      ds 1     ; total number of patterns

mod_jiffy_rate        ds 2
mod_jiffy_countdown   ds 2
mod_jiffy             ds 2     ; mod player jiffy

mod_temp0			ds 4
mod_temp1           ds 4
mod_temp2			ds 4
mod_temp3			ds 4
mod_temp4			ds 4
mod_temp5			ds 4

irq_num ds 2


SongIsPlaying ds 1 ; flag for if a song is playing

	dend

; Jiffy Alias
dpJiffy = jiffy


;
; Let's do some memory management
;
; Frame Buffer at $01/0000 - 320x240 = 76,800, end address 02/2C00
;
; 2k gap at 02/2C00
; Pump Bars, 2 pump bar sprites.
;
; 44*33*2 = 3k 2,904 bytes
; Map Data for 8x8 tile-map, need 3k for the static screen
; $02/3400 -> $02/4000 - 3k
;
; $02/0000->$02/3FFF = 256 8x8 tiles
;
; $02/0000 -> $07/DFFF - space for songs 385,024 (max song size) $5/E000

MAP_DATA0 = $010000

PUMPBAR_SPRITE0 = $014000
PUMPBAR_SPRITE1 = $014400

TILE_DATA0 = $020000

; tiles are 16k for 256 in 8x8 mode
TILE_SIZE = {8*8*256}
TILE_DATA1 = TILE_DATA0+TILE_SIZE
TILE_DATA2 = TILE_DATA1+TILE_SIZE
TILE_DATA3 = TILE_DATA2+TILE_SIZE
TILE_DATA4 = TILE_DATA3+TILE_SIZE
TILE_DATA5 = TILE_DATA4+TILE_SIZE
TILE_DATA6 = TILE_DATA5+TILE_SIZE
TILE_DATA7 = TILE_DATA6+TILE_SIZE
TILE_DATA8 = TILE_DATA7+TILE_SIZE

CLUT_DATA  = $006000

;------------------------------------------------------------------------------
;
; Some Kernel Stuff
;

; arguments
args_buf ds 2
args_buflen ds 1

; Event Buffer, at org address
event_type ds 1
event_buf  ds 1
event_ext  ds 14

event_file_data_read  = event_type+kernel_event_event_t_file_data_read
event_file_data_wrote = event_type+kernel_event_event_t_file_wrote_wrote 

;------------------------------------------------------------------------------
;
; This is where it all begins
;
start
		sei
; save off stuff we need to get at the arguments
		; store argument list, but skip over first argument (us)
		lda	kernel_args_ext
		sta	args_buf
		lda	kernel_args_ext+1
		sta	args_buf+1

		lda	kernel_args_extlen
		sta	args_buflen

		jsr mmu_unlock

		jsr HasGoodHardware
;		bcc :HardwareGood
;		rts
;:HardwareGood


		jsr init320x240_video

		jsr initColors    	; copy GS colors over into the font LUT, and the LUT0 for the bitmap

		jsr initFont

		jsr initBackground
		jsr initPumpBars

		jsr TermInit

		lda #<txt_modo
		ldx #>txt_modo
		jsr TermPUTS

;------------------------------------------------------------------------------
;
; Deal With CLI and Loading
;
;------------------------------------------------------------------------------

		jsr LoadSong

;------------------------------------------------------------------------------

		ldx #68
		ldy #0
		jsr TermSetXY

		ldax #txt_sampler
		jsr TermPUTS

;------------------------------------------------------------------------------
;
; Setup a Jiffy Timer, using Kernel Jump Table
; Trying to be friendly, in case we can friendly exit
;

		jsr MixerInit   ; init those OSCilattors

		; hey needs to start on an 8k boundary
		ldaxy #mod_song
		jsr ModInit

		; All in wonder interrupt
		; - SOF timer, for dpJiffy
		; - 50hz timer, for the Mod Sequencer
		; - 16Khz timer, for the PCM player
		jsr InstallIRQ

		cli
		jsr ModPlay		;; Are you Crazy ?#@!


TEST_VOICE equ VOICE3 ; all 4 voices work

		do 0

:pInst = temp0

		lda #1
		asl
		tax
		lda |inst_address_table,x
		sta <:pInst
		lda |inst_address_table+1,x
		sta <:pInst+1

		stz TEST_VOICE+osc_pWave
		ldy #i_sample_start_badr
		lda (:pInst),y
		sta TEST_VOICE+osc_pWave+1
		iny
		lda (:pInst),y
		sta TEST_VOICE+osc_pWave+2
		iny
		lda (:pInst),y
		sta TEST_VOICE+osc_pWave+3

;		ldax #$100
; 8363.42*256/16000
;
		ldax #134
		stax TEST_VOICE+osc_frequency

		ldy #i_sample_loop_bend
		lda (:pInst),y
		sta TEST_VOICE+osc_pWaveEnd
		iny
		lda (:pInst),y
		sta TEST_VOICE+osc_pWaveEnd+1
		iny
		lda (:pInst),y
		sta TEST_VOICE+osc_pWaveEnd+2

;		; tell the oscillator to go!
;		lda #os_playing_singleshot
;		sta VOICE0+osc_state
		fin

		do 0
		; This actually works, and sounds ok
seadragon_test

:pInst     = temp0
:pStart    = temp1
:iLength   = temp2

		ldaxy #sfx_waves_start
		jsr set_read_address
		ldaxy #sfx_waves_start
		jsr set_write_address

		ldaxy #sfx_waves_end-sfx_waves_start
		sta <:iLength

		ldx <:iLength
		ldy <:iLength+1

]mloop
		jsr readbyte
		eor #$FF
		lsr
		lsr
		lsr
		lsr
		jsr writebyte

		dex
		bne ]mloop

		dey
		bpl ]mloop

		ldaxy #sfx_waves_start
		jsr set_read_address

		; start of wave to play
		ldax pSource
		stax TEST_VOICE+osc_pWave+1
		lda READ_MMU
		sta TEST_VOICE+osc_pWave+3

		ldaxy #sfx_waves_end
		jsr set_read_address

		; end of wave to play
		ldax pSource
		stac TEST_VOICE+osc_pWaveEnd
		lda READ_MMU
		sta TEST_VOICE+osc_pWaveEnd+2

		;ldax #{11025*256/16000}		 ; why not try for 11khz
		ldax #176		 ; why not try for 11khz
		stax TEST_VOICE+osc_frequency

;		lda #os_playing_singleshot
;		sta TEST_VOICE+osc_state

		fin


		do 0
; before we single shot
; print some debug info


		ldaxy TEST_VOICE+osc_pWave+1
		stax pSource
		sty  READ_MMU

		jsr TermPrintAXYH
		lda #' '
		jsr TermCOUT

		ldaxy TEST_VOICE+osc_pWaveEnd
		stax pDest
		sty WRITE_MMU

		jsr TermPrintAXYH
		jsr TermCR

		jsr get_read_address
		jsr TermPrintAXYH
		lda #' '
		jsr TermCOUT

		jsr get_write_address
		jsr TermPrintAXYH
		jsr TermCR

		ldax TEST_VOICE+osc_frequency
		jsr TermPrintAXH
		jsr TermCR


; before we single shot
; lets print some stuff out, for my own sanity

		lda #os_playing_singleshot
		sta TEST_VOICE+osc_state
		fin

		do 0 ; glyph test
		ldax #:txt
		jsr TermPUTS

		jmp forward
:txt    db 13,13
        db $C0,$C1,$C2,$C3,$C4,$C5,$C6,$C7,$C8,$C9,$CA,$CB,$CC,$CD,$CE,$CF,
		db $D0,$D1,$D2,$D3,$D4,$D5,$D6,$D7,$D8,$D9,$DA,$DB,$DC,$DD,$DE,$DF,13
		db $E0,$E1,$E2,$E3,$E4,$E5,$E6,$E7,$E8,$E9,$EA,$EB,$EC,$ED,$EE,$EF,
		db $F0,$F1,$F2,$F3,$F4,$F5,$F6,$F7,$F8,$F9,$FA,$FB,$FC,$FD,$FE,$FF,13
		db 0

forward
		fin

;------------------------------------------------------------------------------

; Setup the LED HUD

		ldx #40
		ldy #26
		jsr TermSetXY
		ldax #txt_video_jiffy
		jsr TermPUTS

		ldx #40
		ldy #28
		jsr TermSetXY
		ldax #txt_audio_jiffy
		jsr TermPUTS

		ldx #48
		ldy #30
		jsr TermSetXY
		ldax #txt_bpm
		jsr TermPUTS

		ldx #46
		ldy #32
		jsr TermSetXY
		ldax #txt_speed
		jsr TermPUTS



		ldx #20
		ldy #32
		jsr TermSetXY
		ldax #txt_repeat_enabled
		jsr TermPUTS


		ldx #18
		ldy #26
		jsr TermSetXY
		ldax #txt_position
		jsr TermPUTS

		ldx #19
		ldy #28
		jsr TermSetXY
		ldax #txt_pattern
		jsr TermPUTS

		ldx #23
		ldy #30
		jsr TermSetXY
		ldax #txt_row
		jsr TermPUTS



;------------------------------------------------------------------------------

		; So the pattern has colors
		jsr PatternRenderInit

]main_loop
		jsr WaitVBL

		jsr SpeakerAnim

		jsr PumpBarRender
  
		jsr UpdateMarker

		jsr PatternRender

		;; Display Jiffy Timers
		ldx #53
		ldy #26
		jsr TermSetXY

		;ldax jiffy
		;jsr TermPrintAXH
		lda jiffy
		lsr
		lsr
		lsr
		lsr
		tax
		lda |tbl_hex,x
		sta (term_ptr)
		lda jiffy
		and #$F
		tax
		lda |tbl_hex,x
		ldy #1
		sta (term_ptr),y

		ldx #53
		ldy #28
		jsr TermSetXY

		;ldax mod_jiffy
		;jsr TermPrintAXH
		lda mod_jiffy
		lsr
		lsr
		lsr
		lsr
		tax
		lda |tbl_hex,x
		sta (term_ptr)
		lda mod_jiffy
		and #$F
		tax
		lda |tbl_hex,x
		ldy #1
		sta (term_ptr),y
		;; End JIffy

		;; BPM
		ldx #53
		ldy #30
		jsr TermSetXY

		ldx mod_bpm
		jsr PrintLEDAI
		;; END BPM

		;; Speed
		ldx #53
		ldy #32
		jsr TermSetXY

		ldx mod_speed
		jsr PrintLEDAI

		;; END Speed

		ldx #28
		ldy #26
		jsr TermSetXY

		;; Song position
		ldx mod_pattern_index
		jsr PrintLEDAI
		;; END SONG Position

		;; Pattern Number

		ldx #28
		ldy #28
		jsr TermSetXY

		lda mod_p_pattern_dir+2
		sta mmu3
		ldy mod_pattern_index
		lda (mod_p_pattern_dir),y
		tax
		jsr PrintLEDAI

		;; END Pattern Number

		;; ROW
		ldx #28
		ldy #30
		jsr TermSetXY

		ldx mod_current_row
		lda tbl_dec99_hi,x
		sta (term_ptr)
		ldy #1
		lda tbl_dec99_lo,x
		sta (term_ptr),y
		;; END ROW


		jmp ]main_loop
;
; Setup the Display with color regions for the text
;
PatternRenderInit

		lda io_ctrl
		pha

		lda #3     	; have term write to color
		sta io_ctrl

; player hud area

		ldx #16
		ldy #25
]lp		phy
		jsr TermSetXY

		ldy #47
]inloop lda |:hud_colors,y
		sta (term_ptr),y
		dey
		bpl ]inloop

		ply
		iny
		cpy #33
		bcc ]lp

; pattern data area

		; colors
		ldx #16
		ldy #33
]lp		phy 			 	; 1 line loop
		jsr TermSetXY

		ldy #47
]inlp	lda |:colors,y   	; stash colors
		sta (term_ptr),y
		dey
		bpl ]inlp

		ply
		iny
		cpy #60
		bcc ]lp

		pla 		  	 ; restore io_ctrl bank
		sta io_ctrl

		rts

:colors ; Row Number
		db 0,$10,$10

		lup 4
		db $70,$70,$70 ; Note Color
		db $D0,$D0     ; Instrument # 1-31
		db $C0,$C0,$C0 ; Volume v00-v64
		db $90,$90,$90 ; Effect
		--^

		db 0

; 48 columns
:hud_colors
		db $E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0
		db $B0,$B0,$B0,$B0,$B0,$B0,$B0,$B0,$B0,$B0,$B0,$B0
		db $E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0
		db $B0,$B0,$B0,$B0,$B0,$B0,$B0,$B0,$B0,$B0,$B0,$B0

;------------------------------------------------------------------------------

SpeakerAnim

		stz io_ctrl

		lda speaker_twang
		dec
		bmi :ha
		sta speaker_twang

		inc :time

		lda :time
		lsr
		bcc :who
		; ha
:ha
		; default
		ldax #32
		sei 					; reduce chance of interrupt causing bad position
		stax VKY_TM0_POS_Y_L	; store not atomic
		cli


		lda #2
		sta io_ctrl
		rts
:who
		ldax #32+480
		sei 					; reduce chance of interrupt causing bad position
		stax VKY_TM0_POS_Y_L	; store not atomic
		cli

		lda #2
		sta io_ctrl
		rts

:time  db 0
speaker_twang db 0


;------------------------------------------------------------------------------

PatternRender

:pPattern = temp0
:row_num  = temp0+2
:raw      = temp1
:track    = temp2
:screen_y = temp2+1

		sei
		; snap shot data, with interrupt off
		ldaxy mod_p_current_pattern
		sta :pPattern
		lda mod_current_row
		cli
		sta :row_num
		stx :pPattern+1
		sty mmu3

		cmp |:last_row
		bne :render

		rts
:render
		sta |:last_row

		lda #35
		;lda #50
		sta :screen_y

;
; 1 idea is to have a strike line in the middle, but it's easier to have it
; up-top
;
]row_loop
		stz :track

		; move the cursor to where we want to write stuff
		ldx #17
		ldy :screen_y
		jsr TermSetXY
; Current Row
		;lda :row_num
		;jsr TermPrintAH

		; Row Number
		ldx :row_num
		lda tbl_dec99_hi,x
		sta (term_ptr)

		ldy #1
		lda tbl_dec99_lo,x
		sta (term_ptr),y
]track_loop
		; get the note info for track 0
		jsr :get_byte
		sta :raw
		jsr :get_byte
		sta :raw+1
		jsr :get_byte
		sta :raw+2
		jsr :get_byte
		sta :raw+3

; lets print out the note

		lda :raw+0
		lsr
		ror :raw+1
		lsr
		ror :raw+1

		; now :raw+1 is the period value / 4 (so it fits in a table less than 256 entries)

		iny
		ldx :raw+1

		lda tbl_note_letter,x  	; B  ;ha period plots as spaces if it's zero!
		sta (term_ptr),y

		iny
		lda tbl_note_mid,x  	; -
		sta (term_ptr),y

		iny
		lda tbl_octave,x	    ; 6
		sta (term_ptr),y

		; now 2 digit instrument number, in decimal
		lda :raw+0
		and #$F0
		sta :raw+0

		lda :raw+2
		lsr
		lsr
		lsr
		lsr
		ora :raw+0
		bne :digit
		lda #' '	   		; place spaces if inst is 0
		iny
		sta (term_ptr),y 
		iny
		sta (term_ptr),y 
		iny
		sta (term_ptr),y 
		iny
		sta (term_ptr),y 
		iny
		sta (term_ptr),y 
		bra :keep_going_brother
:digit
		tax
		lda tbl_dec99_hi,x
		iny
		sta (term_ptr),y
		lda tbl_dec99_lo,x
		iny
		sta (term_ptr),y

		; volume
		lda #'V'+$A0
		iny
		sta (term_ptr),y
		lda #'6'+$A0
		iny
		sta (term_ptr),y
		lda #'3'+$A0
		iny
		sta (term_ptr),y

:keep_going_brother

		; time to plot effect, or spaces if its 000

		lda :raw+2
		and #$0f
		ora :raw+3
		bne :plot_it

		lda #' '
		iny
		sta (term_ptr),y
		iny
		sta (term_ptr),y
		iny
		sta (term_ptr),y

		bra :done_draw
:plot_it
		lda :raw+2
		and #$0F
		tax
		lda :effect,x
		iny
		sta (term_ptr),y
		lda :raw+3
		lsr
		lsr
		lsr
		lsr
		tax
		lda :effect,x
		iny
		sta (term_ptr),y
		lda :raw+3
		and #$0F
		tax
		lda :effect,x
		iny
		sta (term_ptr),y

:done_draw
;		iny
		lda :track
		inc
		sta :track
		;cmp mod_num_tracks
		cmp #4
		bccl ]track_loop

		lda :screen_y
		inc 
		sta :screen_y
		cmp #59
		bcs :no_more_screen

		lda :row_num
		inc
		sta :row_num
		cmp #64
		bccl ]row_loop

:erase_row

		ldx #17
		ldy :screen_y
		jsr TermSetXY

		ldy #47
		lda #' '
]clear  sta (term_ptr),y
		dey
		bpl ]clear

:no_more_screen

		rts

:last_row ds 2

]A = $A0

:effect db '0'+]A,'1'+]A,'2'+]A,'3'+]A
		db '4'+]A,'5'+]A,'6'+]A,'7'+]A
		db '8'+]A,'9'+]A,'A'+]A,'B'+]A
		db 'C'+]A,'D'+]A,'E'+]A,'F'+]A

;:test_this
;		asc 'C#606V64D00C#606V64D00......................'
;		db 13
;		db 0



:get_byte
		lda (:pPattern)
		inc :pPattern
		bne :rts
		inc :pPattern+1
		bpl :rts
		lda #>READ_BLOCK
		sta :pPattern+1
		inc mmu3
:rts
		rts

UpdateMarker

:pColor = temp0
:color = temp1

		ldx |:current
	    cpx <mod_pattern_index
		bne :update
		rts
:update
		lda #3
		sta io_ctrl		; color matrix

		; block # in x

		;lda #$F2		; white on, blue for erase
		lda #$F0		; white on transparent
		sta <:color

		jsr :draw_color

		ldx <mod_pattern_index
		stx |:current

		;lda #$F1        ; white on red
		lda #$C1         ; green on red - FON_OVLY doesn't work
		sta <:color

		jsr :draw_color

		lda #2
		sta <io_ctrl	; text matrix
		rts


:draw_color
		lda :table_l,x
		sta :pColor
		lda :table_h,x
		sta :pColor+1

		ldy #3
		lda <:color
]lp		sta (:pColor),y
		dey
		bpl ]lp

		rts

]base = $C000+{19*80}

:table_l
]ct = 0
		lup 26
		db <{]base+{]ct*3}}
]ct = ]ct+1
		--^
]base = ]base+80
]ct = 0
		lup 26
		db <{]base+{]ct*3}}
]ct = ]ct+1
		--^
]base = ]base+80
]ct = 0
		lup 26
		db <{]base+{]ct*3}}
]ct = ]ct+1
		--^
]base = ]base+80
]ct = 0
		lup 26
		db <{]base+{]ct*3}}
]ct = ]ct+1
		--^


]base = $C000+{19*80}
:table_h
]ct = 0
		lup 26
		db >{]base+{]ct*3}}
]ct = ]ct+1
		--^
]base = ]base+80
]ct = 0
		lup 26
		db >{]base+{]ct*3}}
]ct = ]ct+1
		--^
]base = ]base+80
]ct = 0
		lup 26
		db >{]base+{]ct*3}}
]ct = ]ct+1
		--^
]base = ]base+80
]ct = 0
		lup 26
		db >{]base+{]ct*3}}
]ct = ]ct+1
		--^

:current db $7f


;----------------------------------------------------------------------------
;
; Decompress the Background onto TileMap0
; use CLUT 1
;
initBackground

; Decompress the CLUT
		ldaxy #CLUT_DATA
		jsr set_write_address

		ldaxy #background
		jsr set_read_address

		jsr decompress_clut

; Copy CLUT into Color Memory
		php
		sei

		lda io_ctrl
		pha

		lda #1
		sta io_ctrl ; access LUT data

		; copy the clut up there
		ldx #0
]lp		lda WRITE_BLOCK,x
		sta VKY_GR_CLUT_3,x
		lda WRITE_BLOCK+$100,x
		sta VKY_GR_CLUT_3+$100,x
		lda WRITE_BLOCK+$200,x
		sta VKY_GR_CLUT_3+$200,x
		lda WRITE_BLOCK+$300,x
		sta VKY_GR_CLUT_3+$300,x
		dex
		bne ]lp

		pla
		sta io_ctrl
		plp

		; Decompress the tile data
		ldaxy #TILE_DATA0
		jsr set_write_address

		ldaxy #background
		jsr set_read_address

		jsr decompress_pixels

		; Decompress the map data
		lda #<MAP_DATA0
		ldx #>MAP_DATA0
		ldy #^MAP_DATA0
		jsr set_write_address

		ldaxy #background
		jsr set_read_address

		jsr decompress_map

		do 1
		; map is 44x64
		
		ldaxy #MAP_DATA0
		jsr set_read_address
		jsr get_read_address
		jsr set_write_address

		ldxy #2816 ;{44*64}
]loop
		jsr readbyte
		jsr writebyte

		jsr readbyte
		ora #{8*3}		; remap to palette index 3
		jsr writebyte

		dexy
		bne ]loop
		fin

		rts

;------------------------------------------------------------------------------

initPumpBars

		; Decompress the tile data
		ldaxy #PUMPBAR_SPRITE0
		jsr set_write_address

		ldaxy #pump_bars
		jsr set_read_address

		jsr decompress_pixels

		php
		sei

		lda io_ctrl
		pha

		stz io_ctrl

		lda #%00000101  	; LUT#2
		sta VKY_SP0_CTRL	; vu 1-2, right
		sta VKY_SP1_CTRL	; vu 3-4, right
		sta VKY_SP2_CTRL	; vu 1-2, left
		sta VKY_SP3_CTRL	; vu 3-4, left

		ldaxy #PUMPBAR_SPRITE0
		staxy VKY_SP0_AD_L
		staxy VKY_SP2_AD_L

;]ypos = 240
YPOS = 132

		ldax #320-24
		stax VKY_SP0_POS_X_L
		ldax #64-24
		stax VKY_SP2_POS_X_L

		ldax #YPOS
		stax VKY_SP0_POS_Y_L
		stax VKY_SP2_POS_Y_L

		ldaxy #PUMPBAR_SPRITE1
		staxy VKY_SP1_AD_L
		staxy VKY_SP3_AD_L

		ldax #320
		stax VKY_SP1_POS_X_L
		ldax #64
		stax VKY_SP3_POS_X_L
		ldax #YPOS
		stax VKY_SP1_POS_Y_L
		stax VKY_SP3_POS_Y_L

		; initialize some of those LUT Colors

		lda #1
		sta io_ctrl

		; verify the backdrop color
		ldaxy #0
		staxy VKY_GR_CLUT_2+{16*4}


		ldx #{15*4}-1       ; 15 colors
]lp		lda vu_colors_off,x
		sta VKY_GR_CLUT_2+{1*4},x		
		sta VKY_GR_CLUT_2+{17*4},x		
		sta VKY_GR_CLUT_2+{33*4},x		
		sta VKY_GR_CLUT_2+{49*4},x

		lda vu_colors_peak,x
		sta VKY_GR_CLUT_2+{65*4},x		
		sta VKY_GR_CLUT_2+{81*4},x		
		sta VKY_GR_CLUT_2+{97*4},x		
		sta VKY_GR_CLUT_2+{113*4},x

		dex
		bpl ]lp



		pla
		sta io_ctrl
		plp

		rts

;------------------------------------------------------------------------------
init320x240_video
		php
		sei

		; Access to vicky generate registers
		stz io_ctrl

		; enable the graphics mode
;;		lda #%00001111	; gamma + bitmap + graphics + overlay + text
;		lda #%00000001	; text
		lda #%01111111  ; all the things
		sta VKY_MSTR_CTRL_0
		;lda #%110       ; text in 40 column when it's enabled
		;lda #6
		;lda #1 ; clock_70
		lda #0
		;lda #%10000   ; Font Overlay Mode - BG color can be on top
		sta VKY_MSTR_CTRL_1

		; layer stuff - take from Jr manual
		; 0,1, and 2 are bitmap layers
		; 4,5, and 6 are tilemap layers

		lda #$40		      ; bitmap0 on top of tilemap 0
		sta VKY_LAYER_CTRL_0
		lda #$05
		sta VKY_LAYER_CTRL_1  ; tile map layer 2

		; Tile Map Enable/Disable
		lda #$11
		sta VKY_TM0_CTRL  ; enable 8x8
		stz VKY_TM1_CTRL  ; disable
		stz VKY_TM2_CTRL  ; disable

		; bitmap disables
		stz VKY_BM0_CTRL  ; disable
		stz VKY_BM1_CTRL  ; disable
		stz VKY_BM2_CTRL  ; disable
		stz $D110  ; disable

		;
		; Initialize Tile Map 0
		;
		ldaxy #MAP_DATA0
		staxy VKY_TM0_ADDR_L

		ldax #44
		stax VKY_TM0_SIZE_X
		ldax #64
		stax VKY_TM0_SIZE_Y

		ldax #8
		stax VKY_TM0_POS_X_L
		ldax #32
		stax VKY_TM0_POS_Y_L

		;
		; Catalog Address
		;
		ldaxy #TILE_DATA0
		staxy VKY_TS0_ADDR_L
		staxy VKY_TS1_ADDR_L
		staxy VKY_TS2_ADDR_L
		staxy VKY_TS3_ADDR_L
		staxy VKY_TS4_ADDR_L
		staxy VKY_TS5_ADDR_L
		staxy VKY_TS6_ADDR_L
		staxy VKY_TS7_ADDR_L

		;
		; Disable all the sprites
		;
		ldx #0
]lp		stz VKY_SP0_CTRL,x
		stz VKY_SP0_CTRL+$100,x
		dex
		bne ]lp


		lda #2
		sta io_ctrl
		plp

		rts

;------------------------------------------------------------------------------
;
; Actual Parse CLI, and Load Music
;
LoadSong
		php
		cli		; need the kernel to work


		ldx #0
		ldy #2
		jsr TermSetXY

		ldax #txt_about
		jsr TermPUTS

;
; We need to sanity check the arguments, in-case they are hot
; garbage, which can happen with FoenixMgr
;

		lda args_buflen
		and #1
		beq :@

		cmp #16            ; mod player only accepts 1 argument, here we're checking if you did more than 8
						   ; 128 would be "max", pexec can handle
		bcs :bad_args
:@
		; plausible length
		ldax args_buf
		cmpax #$280
		bcc :bad_args
		cmpax #$290
		bcc :argsok

:bad_args
		stz args_buflen
		ldax #$280		
		stax args_buf
:argsok

; argument stuff

		ldax args_buf
		stax kernel_args_ext

		lda args_buflen
		sta kernel_args_extlen
		beq :no_args
		cmp #4
		bcc :no_args

		ldax #txt_loading
		jsr TermPUTS

		lda #1    		; print out the first arg
		jsr get_arg
		jsr TermPUTS
		jsr TermCR

		lda #1  	    ; open the first arg
		jsr get_arg

		jsr fopen
		bcc :opened

		pha
		lda #<txt_error_open   ; fail to open, show error
		ldx #>txt_error_open
		jsr TermPUTS
		pla

		jsr TermPrintAH
		jsr TermCR

;		jsr fclose

		bra :wait_here

:opened
		ldaxy #mod_song  ; address where we're loading
		jsr set_write_address

		ldaxy #$58000 ; max song size
		jsr fread

		jsr fclose

		bra :check_memory

:play_song

		;ldax #txt_play
		;jsr TermPUTS

		plp

		; erase our crap
		jsr TermInit

		lda #<txt_modo
		ldx #>txt_modo
		jsr TermPUTS

		rts

:no_args
:check_memory

		ldax #txt_check_memory
		jsr TermPUTS

		ldaxy #mod_song
		jsr set_read_address

		ldax READ_BLOCK+1080
		cmpax #'M.'
		bne :derp
		ldax READ_BLOCK+1082
		cmpax #'K.'
		beq :play_song
:derp
		ldax #txt_derp
		jsr TermPUTS

:wait_here
		bra :wait_here






;------------------------------------------------------------------------------
; Get argument
; A - argument number
;
; Returns string in AX

get_arg
		asl
		tay
		iny
		lda (kernel_args_ext),y
		tax
		dey
		lda (kernel_args_ext),y
		rts


;------------------------------------------------------------------------------
;
; LED FONT STRINGS
;
txt_video_jiffy
		db 'V'+$A0,'I'+$A0,'D'+$A0,'E'+$A0,'O'+$A0
		db ' '+$A0,'J'+$A0,'I'+$A0,'F'+$A0,'F'+$A0,'Y'+$A0,':'+$A0
		db 0

txt_audio_jiffy
		db 'A'+$A0,'U'+$A0,'D'+$A0,'I'+$A0,'O'+$A0
		db ' '+$A0,'J'+$A0,'I'+$A0,'F'+$A0,'F'+$A0,'Y'+$A0,':'+$A0
		db 0
		db 0

txt_repeat_enabled
		db 'R'+$A0,'E'+$A0,'P'+$A0,'E'+$A0,'A'+$A0,'T'+$A0,':'+$A0
		db ' ','E'+$A0,'N'+$A0,'A'+$A0,'B'+$A0,'L'+$A0,'E'+$A0,'D'+$A0
		db 0

txt_position
		db 'P'+$A0,'O'+$A0,'S'+$A0,'I'+$A0,'T'+$A0,'I'+$A0,'O'+$A0,'N'+$A0
		db ':'+$A0,0

txt_pattern
		db 'P'+$A0,'A'+$A0,'T'+$A0,'T'+$A0,'E'+$A0,'R'+$A0,'N'+$A0
		db ':'+$A0,0

txt_row
		db 'R'+$A0,'O'+$A0,'W'+$A0 
		db ':'+$A0,0

txt_bpm
		db 'B'+$A0,'P'+$A0,'M'+$A0 
		db ':'+$A0,0

txt_speed
		db 'S'+$A0,'P'+$A0,'E'+$A0,'E'+$A0,'D'+$A0
		db ':'+$A0,0

;------------------------------------------------------------------------------


txt_modo asc 'ModoJr'
		db 13,0

txt_play
		asc 'PLAY!',00

txt_loading
		asc 'Loading: ',00

txt_error_open asc 'ERROR: file open $',00

txt_check_memory
		asc 'Bad Arguments - Check memory for preloaded Song',00

txt_about asc '   This is a very BASIC MOD player for the F256.',0D,0D
		asc 'Features:',0D,0D
		asc '       - 4 voice stereo PSG output L,R,R,L',0D
		asc '       - 4 bit audio, at 16khz',0D
		asc '       - M.K. style MOD files',0D
		asc '       - Load MODs from SDcard',0D
		asc '       - Detect and play preloaded MOD at $28000',0D,0D,00

txt_derp asc 0D,0D,'Unable to Load Song, or detect a Preloaded Song',0D,0D
		 asc 'Press RESET to exit.',00

txt_unlock asc 'mmu_unlock'
		db 13,0

txt_setaddr asc 'set_write_address'
		db 13,0

txt_setpicaddr asc 'set_pic_address'
		db 13,0

txt_decompress_clut asc 'decompress_clut'
		db 13,0

txt_copy_clut asc 'copy_clut'
		db 13,0

txt_decompress asc 'decompress_pixels'
		db 13,0

txt_decompress_map asc 'decompress_map'
		db 13,0

txt_unsupported db 13
		asc 'ERROR Unsupported Mod Type = '
		db 0

txt_instruments asc ' Instruments'
		db 13,0

txt_tracks asc ' Tracks'
		db 13,0

txt_song_length cstr 'Length:'
txt_patterns cstr 'Patterns:'
txt_sampler cstr 'Mixer:16khz'
txt_L cstr ' L'

txt_massage_wave asc 'Massage the instruments'
		db 13,0

;------------------------------------------------------------------------------
; WaitVBL
; Preserve all registers
;
WaitVBL
		pha
		lda <dpJiffy
]lp
		cmp <dpJiffy
		beq ]lp
		pla
		rts

;------------------------------------------------------------------------------

PumpBarRender mx %11

:levels = temp0
:max_lit = temp1

		php
		sei
		; grab samples
		lda |mod_pump_vol+{4*1}
		stz |mod_pump_vol+{4*1}
		sta <:levels+0
		lda |mod_pump_vol+{4*2}
		stz |mod_pump_vol+{4*2}
		sta <:levels+1
		lda |mod_pump_vol+{4*3}
		stz |mod_pump_vol+{4*3}
		sta <:levels+2
		lda |mod_pump_vol+{4*4}
		stz |mod_pump_vol+{4*4}
		sta <:levels+3
		plp

; for the speaker anim

		ora <:levels+2
		ora <:levels+1
		ora <:levels+0
		beq :no_speaker

		lda #15				; move speaker for about 1/4 second, when note played
		sta speaker_twang

:no_speaker

; end for speaker anim

]ct = 0
		lup 4
		lda <:levels+]ct 			; no value
		beq :no_new_value

		; here would be a good place to scale + clamp, if we want that
		lsr  ; this will make them move 2x speed (1/2 second to empty the bar)

		cmp |pump_bar_levels+]ct	; new value is less than what we have, so ignore
		bcc :no_new_value

		sta |pump_bar_levels+]ct    ; new level, since it's >=
		cmp |pump_bar_peaks+]ct     ; check to see if it's a new peak
		bcc :no_new_value

		sta |pump_bar_peaks+]ct		; set new peak
		lda #20	; hang time for new peak  (1/3) of a second
		sta |pump_bar_peak_timer+]ct

:no_new_value

		lda |pump_bar_peak_timer+]ct
		beq :skip_peak_timer
		dec
		sta |pump_bar_peak_timer+]ct
		bne :skip_peak_timer
		stz |pump_bar_peaks+]ct
:skip_peak_timer
		lda |pump_bar_levels+]ct
		beq :skip_level
		dec
		sta |pump_bar_levels+]ct
:skip_level
]ct = ]ct+1
		--^

		lda io_ctrl
		pha

		lda #1			; page in the palettes
		sta io_ctrl

	    do 1
; render the colors
]ct = 0
		lup 4

		lda |pump_bar_levels+]ct
		lsr
		cmp #15
		bcc :no_clamp
		lda #15
:no_clamp

		ldx #0

		asl
		asl
		sta :max_lit
		beq :colors_off
:colors_on
		lda |vu_colors_on,x
		sta VKY_GR_CLUT_2+{1*4}+{]ct*64},x
		inx
		cpx :max_lit
		bcc :colors_on
		bra :check_end
:colors_off
		lda |vu_colors_off,x
		sta VKY_GR_CLUT_2+{1*4}+{]ct*64},x
		inx
:check_end
		cpx #15*4
		bcc :colors_off
:done
]ct = ]ct+1
		--^
		fin

; Render the Peak Meters
		do 1

]ct = 0
		lup 4

		lda pump_bar_last_peak+]ct
		cmp pump_bar_peaks+]ct
		beq :next_peak				; no change, leave alone

		; erase old peak
		and #%11111110
		cmp #30
		bcc :eok
		lda #30
:eok
		asl
		tax

		lda #$10
		sta VKY_GR_CLUT_2+$100+{]ct*64}+0,x
		sta VKY_GR_CLUT_2+$100+{]ct*64}+1,x
		sta VKY_GR_CLUT_2+$100+{]ct*64}+2,x

		; draw new peak
		lda pump_bar_peaks+]ct
		sta pump_bar_last_peak+]ct


		and #%11111110
		cmp #30
		bcc :drawok
		lda #30
:drawok

		asl
		tax

		lda #$F0
		sta VKY_GR_CLUT_2+$100+{]ct*64}+0,x
		sta VKY_GR_CLUT_2+$100+{]ct*64}+1,x
		sta VKY_GR_CLUT_2+$100+{]ct*64}+2,x
:next_peak
]ct = ]ct+1
		--^

		fin

		pla
		sta io_ctrl

			 
		do 0   ; visual verify volume data coming through
		ldx #0
		ldy #49
		jsr TermSetXY

		ldx #0
]lp		phx
		lda |mod_pump_vol,x
		jsr TermPrintAH
		plx
		inx
		cpx #32
		bcc ]lp
		fin

		do 0   ; visual verify volume data coming through
		ldx #0
		ldy #50
		jsr TermSetXY

		ldx #0
]lp		phx
		lda |pump_bar_levels,x
		jsr TermPrintAH
		plx
		inx
		cpx #32
		bcc ]lp
		fin


		rts

;------------------------------------------------------------------------------

PrintLEDAI
		ldy #0
		cpx #100
		bcc :less_than_100

		txa
		sbc #100
		tax
		lda #'1'+$A0

		cpx #100
		bcc :less_than_200

		txa
		sbc #100
		tax

		lda #'2'+$A0

:less_than_200
		sta (term_ptr),y
		iny
		 
:less_than_100		 
		lda tbl_dec99_hi,x
		sta (term_ptr),y
		iny
		lda tbl_dec99_lo,x
		sta (term_ptr),y

		iny
		lda #' '
		sta (term_ptr),y

		rts

;------------------------------------------------------------------------------
tbl_hex
		db '0'+$A0,'1'+$A0,'2'+$A0,'3'+$A0,'4'+$A0,'5'+$A0,'6'+$A0,'7'+$A0
		db '8'+$A0,'9'+$A0,'A'+$A0,'B'+$A0,'C'+$A0,'D'+$A0,'E'+$A0,'F'+$A0

;------------------------------------------------------------------------------
;
; Fast ATOI, for 00-99
;
tbl_dec99_hi
]var = 0
		lup 100
		db {{]var/10}+'0'+$A0}
]var = ]var+1
		--^

tbl_dec99_lo
		lup 10
		db $D0,$D1,$D2,$D3,$D4,$D5,$D6,$D7,$D8,$D9
		--^

;------------------------------------------------------------------------------
;
; Fast pattern render tables
;
; C,C#,D,D#,E,F,F#,G,G#,A,A#,B
;
; Tuning 0, Normal
;	dc.w 856,808,762,720,678,640,604,570,538,508,480,453 ; C-1 to B-1
;	dc.w 428,404,381,360,339,320,302,285,269,254,240,226 ; C-2 to B-2
;	dc.w 214,202,190,180,170,160,151,143,135,127,120,113 ; C-3 to B-3

]A = $A0
tbl_note_letter

	db ' '
;	db 'C'+]A ; index 0
	db 'B'+]A ; index 1
	db 'E'+]A ; index 2
	db 'B'+]A ; index 3
	db 'G'+]A ; index 4
	db 'E'+]A ; index 5
	db 'C'+]A ; index 6

	db 'A'+]A ; index 7
	db 'G'+]A ; index 8
	db 'F'+]A ; index 9
	db 'E'+]A ; index 10
	db 'D'+]A ; index 11
	db 'C'+]A ; index 12
	db 'C'+]A ; index 13

	db 'B'+]A ; index 14
	db 'A'+]A ; index 15
	db 'G'+]A ; index 16
	db 'G'+]A ; index 17
	db 'F'+]A ; index 18
	db 'F'+]A ; index 19
	db 'F'+]A ; index 20
	db 'E'+]A ; index 21
	db 'D'+]A ; index 22
	db 'D'+]A ; index 23
	db 'D'+]A ; index 24
	db 'C'+]A ; index 25
	db 'C'+]A ; index 26
	db 'C'+]A ; index 27

	db 'B'+]A ; index 28
	db 'B'+]A ; index 29
	db 'A'+]A ; index 30
	db 'A'+]A ; index 31
	db 'A'+]A ; index 32
	db 'G'+]A ; index 33
	db 'G'+]A ; index 34
	db 'G'+]A ; index 35
	db 'G'+]A ; index 36
	db 'F'+]A ; index 37
	db 'F'+]A ; index 38
	db 'F'+]A ; index 39
	db 'F'+]A ; index 40
	db 'E'+]A ; index 41
	db 'E'+]A ; index 42
	db 'E'+]A ; index 43
	db 'D'+]A ; index 44
	db 'D'+]A ; index 45
	db 'D'+]A ; index 46
	db 'D'+]A ; index 47
	db 'D'+]A ; index 48
	db 'C'+]A ; index 49
	db 'C'+]A ; index 50
	db 'C'+]A ; index 51
	db 'C'+]A ; index 52
	db 'C'+]A ; index 53
	db 'C'+]A ; index 54

	db 'B'+]A ; index 55
	db 'B'+]A ; index 56
	db 'B'+]A ; index 57
	db 'B'+]A ; index 58
	db 'A'+]A ; index 59
	db 'A'+]A ; index 60
	db 'A'+]A ; index 61
	db 'A'+]A ; index 62
	db 'A'+]A ; index 63
	db 'A'+]A ; index 64
	db 'A'+]A ; index 65
	db 'G'+]A ; index 66
	db 'G'+]A ; index 67
	db 'G'+]A ; index 68
	db 'G'+]A ; index 69
	db 'G'+]A ; index 70
	db 'G'+]A ; index 71
	db 'G'+]A ; index 72
	db 'G'+]A ; index 73
	db 'F'+]A ; index 74
	db 'F'+]A ; index 75
	db 'F'+]A ; index 76
	db 'F'+]A ; index 77
	db 'F'+]A ; index 78
	db 'F'+]A ; index 79
	db 'F'+]A ; index 80
	db 'F'+]A ; index 81
	db 'F'+]A ; index 82
	db 'E'+]A ; index 83
	db 'E'+]A ; index 84
	db 'E'+]A ; index 85
	db 'E'+]A ; index 86
	db 'E'+]A ; index 87
	db 'D'+]A ; index 88
	db 'D'+]A ; index 89
	db 'D'+]A ; index 90
	db 'D'+]A ; index 91
	db 'D'+]A ; index 92
	db 'D'+]A ; index 93
	db 'D'+]A ; index 94
	db 'D'+]A ; index 95
	db 'D'+]A ; index 96
	db 'D'+]A ; index 97
	db 'D'+]A ; index 98
	db 'C'+]A ; index 99
	db 'C'+]A ; index 100
	db 'C'+]A ; index 101
	db 'C'+]A ; index 102
	db 'C'+]A ; index 103
	db 'C'+]A ; index 104
	db 'C'+]A ; index 105
	db 'C'+]A ; index 106
	db 'C'+]A ; index 107
	db 'C'+]A ; index 108
	db 'C'+]A ; index 109
	db 'C'+]A ; index 110

	db 'B'+]A ; index 111
	db 'B'+]A ; index 112
	db 'B'+]A ; index 113 
	db 'B'+]A ; index 114 
	db 'B'+]A ; index 115 
	db 'B'+]A ; index 116 
	db 'A'+]A ; index 117
	db 'A'+]A ; index 118
	db 'A'+]A ; index 119
	db 'A'+]A ; index 120
	db 'A'+]A ; index 121
	db 'A'+]A ; index 122
	db 'A'+]A ; index 123
	db 'A'+]A ; index 124
	db 'A'+]A ; index 125
	db 'A'+]A ; index 126
	db 'A'+]A ; index 127
	db 'A'+]A ; index 128
	db 'A'+]A ; index 129
	db 'A'+]A ; index 130
	db 'G'+]A ; index 131
	db 'G'+]A ; index 132
	db 'G'+]A ; index 133
	db 'G'+]A ; index 134
	db 'G'+]A ; index 135
	db 'G'+]A ; index 136
	db 'G'+]A ; index 137
	db 'G'+]A ; index 138
	db 'G'+]A ; index 139
	db 'G'+]A ; index 140
	db 'G'+]A ; index 141
	db 'G'+]A ; index 142
	db 'G'+]A ; index 143
	db 'G'+]A ; index 144
	db 'G'+]A ; index 145
	db 'G'+]A ; index 146
	db 'G'+]A ; index 147
	db 'F'+]A ; index 148
	db 'F'+]A ; index 149
	db 'F'+]A ; index 150
	db 'F'+]A ; index 151
	db 'F'+]A ; index 160
	db 'F'+]A ; index 161
	db 'F'+]A ; index 162
	db 'F'+]A ; index 163
	db 'F'+]A ; index 164
	db 'F'+]A ; index 165
	db 'E'+]A ; index 166
	db 'E'+]A ; index 167
	db 'E'+]A ; index 168
	db 'E'+]A ; index 169
	db 'E'+]A ; index 170
	db 'E'+]A ; index 171
	db 'E'+]A ; index 172
	db 'E'+]A ; index 173
	db 'E'+]A ; index 174
	db 'E'+]A ; index 175
	db 'D'+]A ; index 176
	db 'D'+]A ; index 177
	db 'D'+]A ; index 178
	db 'D'+]A ; index 179
	db 'D'+]A ; index 180
	db 'D'+]A ; index 181
	db 'D'+]A ; index 182
	db 'D'+]A ; index 183
	db 'D'+]A ; index 184
	db 'D'+]A ; index 185
	db 'D'+]A ; index 186
	db 'D'+]A ; index 187
	db 'D'+]A ; index 188
	db 'D'+]A ; index 189
	db 'D'+]A ; index 190
	db 'D'+]A ; index 191
	db 'D'+]A ; index 192
	db 'D'+]A ; index 193
	db 'D'+]A ; index 194
	db 'D'+]A ; index 195
	db 'C'+]A ; index 196
	db 'C'+]A ; index 197
	db 'C'+]A ; index 198
	db 'C'+]A ; index 199
	db 'C'+]A ; index 200
	db 'C'+]A ; index 201
	db 'C'+]A ; index 202
	db 'C'+]A ; index 203
	db 'C'+]A ; index 204
	db 'C'+]A ; index 205
	db 'C'+]A ; index 206
	db 'C'+]A ; index 207
	db 'C'+]A ; index 208
	db 'C'+]A ; index 209
	db 'C'+]A ; index 210
	db 'C'+]A ; index 211
	db 'C'+]A ; index 212
	db 'C'+]A ; index 213
	db 'C'+]A ; index 214
	db 'C'+]A ; index 215
	db 'C'+]A ; index 216
	db 'C'+]A ; index 217
	db 'C'+]A ; index 218
	db 'C'+]A ; index 219
	db 'C'+]A ; index 220
	db 'C'+]A ; index 221
	db 'C'+]A ; index 222
	db 'C'+]A ; index 223
	db 'C'+]A ; index 224
	db 'C'+]A ; index 225

; should go out to 225, since highest number in tuning table is 900
;------------------------------------------------------------------------------

tbl_note_mid
	db ' '
;	db '-'+]A ; index 0 
	db '#'+]A ; index 1 
	db '#'+]A ; index 2 
	db '-'+]A ; index 3 
	db '#'+]A ; index 4 
	db '#'+]A ; index 4 
	db '-'+]A ; index 5 
	db '#'+]A ; index 6

	db '-'+]A ; index 7 
	db '#'+]A ; index 8 
	db '#'+]A ; index 9 
	db '-'+]A ; index 10 
	db '#'+]A ; index 11 
	db '#'+]A ; index 12
	db '-'+]A ; index 13

	db '-'+]A ; index 14 
	db '#'+]A ; index 15 
	db '#'+]A ; index 16 
	db '-'+]A ; index 17 
	db '#'+]A ; index 18 
	db '#'+]A ; index 19
	db '-'+]A ; index 20 
	db '-'+]A ; index 21 
	db '#'+]A ; index 22 
	db '-'+]A ; index 23 
	db '-'+]A ; index 24 
	db '#'+]A ; index 25
	db '-'+]A ; index 26
	db '-'+]A ; index 27

	db '-'+]A ; index 28 
	db '-'+]A ; index 29 
	db '#'+]A ; index 30 
	db '-'+]A ; index 31 
	db '-'+]A ; index 32 
	db '#'+]A ; index 33 
	db '#'+]A ; index 34 
	db '-'+]A ; index 35 
	db '-'+]A ; index 36 
	db '#'+]A ; index 37 
	db '#'+]A ; index 38 
	db '-'+]A ; index 39 
	db '-'+]A ; index 40 
	db '-'+]A ; index 41 
	db '-'+]A ; index 42 
	db '-'+]A ; index 43 
	db '#'+]A ; index 44
	db '#'+]A ; index 45 
	db '#'+]A ; index 46 
	db '-'+]A ; index 47 
	db '-'+]A ; index 48 
	db '#'+]A ; index 49
	db '#'+]A ; index 50
	db '#'+]A ; index 51
	db '-'+]A ; index 52
	db '-'+]A ; index 53
	db '-'+]A ; index 54
	db '-'+]A ; index 55
	db '-'+]A ; index 56 
	db '-'+]A ; index 57 
	db '-'+]A ; index 58 
	db '#'+]A ; index 59 
	db '#'+]A ; index 60 
	db '#'+]A ; index 61 
	db '-'+]A ; index 62 
	db '-'+]A ; index 63 
	db '-'+]A ; index 64 
	db '-'+]A ; index 65
	db '#'+]A ; index 66 
	db '#'+]A ; index 67 
	db '#'+]A ; index 68 
	db '#'+]A ; index 69 
	db '-'+]A ; index 70 
	db '-'+]A ; index 71 
	db '-'+]A ; index 72 
	db '-'+]A ; index 73 
	db '#'+]A ; index 74 
	db '#'+]A ; index 75 
	db '#'+]A ; index 76 
	db '#'+]A ; index 77 
	db '-'+]A ; index 78
	db '-'+]A ; index 79
	db '-'+]A ; index 80 
	db '-'+]A ; index 81 
	db '-'+]A ; index 82 
	db '-'+]A ; index 83 
	db '-'+]A ; index 84 
	db '-'+]A ; index 85 
	db '-'+]A ; index 86
	db '-'+]A ; index 87
	db '#'+]A ; index 88
	db '#'+]A ; index 89
	db '#'+]A ; index 90 
	db '#'+]A ; index 91
	db '#'+]A ; index 92
	db '-'+]A ; index 93
	db '-'+]A ; index 94
	db '-'+]A ; index 95 
	db '-'+]A ; index 96 
	db '-'+]A ; index 97 
	db '-'+]A ; index 98 
	db '#'+]A ; index 99
	db '#'+]A ; index 100
	db '#'+]A ; index 101
	db '#'+]A ; index 102
	db '#'+]A ; index 103
	db '#'+]A ; index 104
	db '-'+]A ; index 105
	db '-'+]A ; index 106
	db '-'+]A ; index 107
	db '-'+]A ; index 108
	db '-'+]A ; index 109
	db '-'+]A ; index 110
	db '-'+]A ; index 111
	db '-'+]A ; index 112
	db '-'+]A ; index 113
	db '-'+]A ; index 114
	db '-'+]A ; index 115
	db '-'+]A ; index 116
	db '#'+]A ; index 117
	db '#'+]A ; index 118
	db '#'+]A ; index 119
	db '#'+]A ; index 120
	db '#'+]A ; index 121
	db '#'+]A ; index 122
	db '#'+]A ; index 123
	db '-'+]A ; index 124
	db '-'+]A ; index 125
	db '-'+]A ; index 126
	db '-'+]A ; index 127
	db '-'+]A ; index 128
	db '-'+]A ; index 129
	db '-'+]A ; index 130
	db '-'+]A ; index 131
	db '#'+]A ; index 132
	db '#'+]A ; index 133
	db '#'+]A ; index 134
	db '#'+]A ; index 135
	db '#'+]A ; index 136
	db '#'+]A ; index 137
	db '#'+]A ; index 138
	db '-'+]A ; index 139
	db '-'+]A ; index 140
	db '-'+]A ; index 141
	db '-'+]A ; index 142
	db '-'+]A ; index 143
	db '-'+]A ; index 144
	db '-'+]A ; index 145
	db '-'+]A ; index 147
	db '#'+]A ; index 148
	db '#'+]A ; index 149
	db '#'+]A ; index 150
	db '#'+]A ; index 151
	db '#'+]A ; index 152
	db '#'+]A ; index 153
	db '#'+]A ; index 154
	db '#'+]A ; index 155
	db '-'+]A ; index 156
	db '-'+]A ; index 157
	db '-'+]A ; index 158
	db '-'+]A ; index 159
	db '-'+]A ; index 160
	db '-'+]A ; index 161
	db '-'+]A ; index 162
	db '-'+]A ; index 163
	db '-'+]A ; index 164
	db '-'+]A ; index 165
	db '-'+]A ; index 166
	db '-'+]A ; index 167
	db '-'+]A ; index 168
	db '-'+]A ; index 169
	db '-'+]A ; index 170
	db '-'+]A ; index 171
	db '-'+]A ; index 172
	db '-'+]A ; index 173
	db '-'+]A ; index 174
	db '-'+]A ; index 175
	db '#'+]A ; index 176
	db '#'+]A ; index 177
	db '#'+]A ; index 178
	db '#'+]A ; index 179
	db '#'+]A ; index 180
	db '#'+]A ; index 181
	db '#'+]A ; index 182
	db '#'+]A ; index 183
	db '#'+]A ; index 184
	db '-'+]A ; index 185
	db '-'+]A ; index 186
	db '-'+]A ; index 187
	db '-'+]A ; index 188
	db '-'+]A ; index 189
	db '-'+]A ; index 190
	db '-'+]A ; index 191
	db '-'+]A ; index 192
	db '-'+]A ; index 193
	db '-'+]A ; index 194
	db '-'+]A ; index 195
	db '-'+]A ; index 196
	db '#'+]A ; index 197
	db '#'+]A ; index 198
	db '#'+]A ; index 199
	db '#'+]A ; index 200
	db '#'+]A ; index 201
	db '#'+]A ; index 202
	db '#'+]A ; index 203
	db '#'+]A ; index 204
	db '#'+]A ; index 205
	db '#'+]A ; index 206
	db '#'+]A ; index 207
	db '#'+]A ; index 208
	db '-'+]A ; index 209
	db '-'+]A ; index 210
	db '-'+]A ; index 211
	db '-'+]A ; index 212
	db '-'+]A ; index 213
	db '-'+]A ; index 214
	db '-'+]A ; index 215
	db '-'+]A ; index 216
	db '-'+]A ; index 217
	db '-'+]A ; index 218
	db '-'+]A ; index 219
	db '-'+]A ; index 220
	db '-'+]A ; index 221
	db '-'+]A ; index 222
	db '-'+]A ; index 223
	db '-'+]A ; index 224
	db '-'+]A ; index 225

; should go out to 225, since highest number in tuning table is 900
;------------------------------------------------------------------------------


tbl_octave
	db ' '
;	db '6'+]A ; index 0
	db '6'+]A ; index 1
	db '6'+]A ; index 2

	db '5'+]A ; index 3 
	db '5'+]A ; index 4 
	db '5'+]A ; index 5 
	db '5'+]A ; index 6

	db '5'+]A ; index 7 
	db '5'+]A ; index 8 
	db '5'+]A ; index 9 
	db '5'+]A ; index 10 
	db '5'+]A ; index 11 
	db '5'+]A ; index 12
	db '5'+]A ; index 13

	db '4'+]A ; index 14 
	db '4'+]A ; index 15 
	db '4'+]A ; index 16 
	db '4'+]A ; index 17 
	db '4'+]A ; index 18 
	db '4'+]A ; index 19 
	db '4'+]A ; index 20 
	db '4'+]A ; index 21 
	db '4'+]A ; index 22 
	db '4'+]A ; index 23 
	db '4'+]A ; index 24 
	db '4'+]A ; index 25
	db '4'+]A ; index 26

	db '4'+]A ; index 27

	db '3'+]A ; index 28 
	db '3'+]A ; index 29 
	db '3'+]A ; index 30 
	db '3'+]A ; index 31 
	db '3'+]A ; index 32 
	db '3'+]A ; index 33 
	db '3'+]A ; index 34 
	db '3'+]A ; index 35 
	db '3'+]A ; index 36 
	db '3'+]A ; index 37 
	db '3'+]A ; index 38 
	db '3'+]A ; index 39 
	db '3'+]A ; index 40 
	db '3'+]A ; index 41 
	db '3'+]A ; index 42 
	db '3'+]A ; index 43 
	db '3'+]A ; index 44
	db '3'+]A ; index 45 
	db '3'+]A ; index 46 
	db '3'+]A ; index 47 
	db '3'+]A ; index 48 
	db '3'+]A ; index 49 
	db '3'+]A ; index 50
	db '3'+]A ; index 51
	db '3'+]A ; index 52
	db '3'+]A ; index 53

	db '3'+]A ; index 54
	db '2'+]A ; index 55

	db '2'+]A ; index 56 
	db '2'+]A ; index 57 
	db '2'+]A ; index 58 
	db '2'+]A ; index 59 
	db '2'+]A ; index 60 
	db '2'+]A ; index 61 
	db '2'+]A ; index 62 
	db '2'+]A ; index 63 
	db '2'+]A ; index 64 
	db '2'+]A ; index 65 
	db '2'+]A ; index 66 
	db '2'+]A ; index 67 
	db '2'+]A ; index 68 
	db '2'+]A ; index 69 
	db '2'+]A ; index 70 
	db '2'+]A ; index 71 
	db '2'+]A ; index 72 
	db '2'+]A ; index 73
	db '2'+]A ; index 74
	db '2'+]A ; index 75 
	db '2'+]A ; index 76 
	db '2'+]A ; index 77 
	db '2'+]A ; index 78
	db '2'+]A ; index 79 
	db '2'+]A ; index 80 
	db '2'+]A ; index 81
	db '2'+]A ; index 82
	db '2'+]A ; index 83
	db '2'+]A ; index 84
	db '2'+]A ; index 85 
	db '2'+]A ; index 86 
	db '2'+]A ; index 87 
	db '2'+]A ; index 88 
	db '2'+]A ; index 89 
	db '2'+]A ; index 90 
	db '2'+]A ; index 91 
	db '2'+]A ; index 92 
	db '2'+]A ; index 93 
	db '2'+]A ; index 94 
	db '2'+]A ; index 95 
	db '2'+]A ; index 96 
	db '2'+]A ; index 97 
	db '2'+]A ; index 98 
	db '2'+]A ; index 99 
	db '2'+]A ; index 100 
	db '2'+]A ; index 101
	db '2'+]A ; index 102
	db '2'+]A ; index 103
	db '2'+]A ; index 104
	db '2'+]A ; index 105
	db '2'+]A ; index 106
	db '2'+]A ; index 107

	db '2'+]A ; index 108
	db '2'+]A ; index 109
	db '2'+]A ; index 110
	db '1'+]A ; index 111
	db '1'+]A ; index 112

	db '1'+]A ; index 113
	db '1'+]A ; index 114
	db '1'+]A ; index 115
	db '1'+]A ; index 116
	db '1'+]A ; index 117
	db '1'+]A ; index 118
	db '1'+]A ; index 119
	db '1'+]A ; index 120
	db '1'+]A ; index 121
	db '1'+]A ; index 122
	db '1'+]A ; index 123
	db '1'+]A ; index 124
	db '1'+]A ; index 125
	db '1'+]A ; index 126
	db '1'+]A ; index 127
	db '1'+]A ; index 128
	db '1'+]A ; index 129
	db '1'+]A ; index 130
	db '1'+]A ; index 131
	db '1'+]A ; index 132
	db '1'+]A ; index 133
	db '1'+]A ; index 134
	db '1'+]A ; index 135
	db '1'+]A ; index 136
	db '1'+]A ; index 137
	db '1'+]A ; index 138
	db '1'+]A ; index 139
	db '1'+]A ; index 140
	db '1'+]A ; index 141
	db '1'+]A ; index 142
	db '1'+]A ; index 143
	db '1'+]A ; index 144
	db '1'+]A ; index 145
	db '1'+]A ; index 146
	db '1'+]A ; index 147
	db '1'+]A ; index 148
	db '1'+]A ; index 149
	db '1'+]A ; index 150
	db '1'+]A ; index 151
	db '1'+]A ; index 152
	db '1'+]A ; index 153
	db '1'+]A ; index 154
	db '1'+]A ; index 155
	db '1'+]A ; index 156
	db '1'+]A ; index 157
	db '1'+]A ; index 158
	db '1'+]A ; index 159
	db '1'+]A ; index 160
	db '1'+]A ; index 161
	db '1'+]A ; index 162
	db '1'+]A ; index 163
	db '1'+]A ; index 164
	db '1'+]A ; index 165
	db '1'+]A ; index 166
	db '1'+]A ; index 167
	db '1'+]A ; index 168
	db '1'+]A ; index 169
	db '1'+]A ; index 170
	db '1'+]A ; index 171
	db '1'+]A ; index 172
	db '1'+]A ; index 173
	db '1'+]A ; index 174
	db '1'+]A ; index 175
	db '1'+]A ; index 176
	db '1'+]A ; index 177
	db '1'+]A ; index 178
	db '1'+]A ; index 179
	db '1'+]A ; index 180
	db '1'+]A ; index 181
	db '1'+]A ; index 182
	db '1'+]A ; index 183
	db '1'+]A ; index 184
	db '1'+]A ; index 185
	db '1'+]A ; index 186
	db '1'+]A ; index 187
	db '1'+]A ; index 188
	db '1'+]A ; index 189
	db '1'+]A ; index 190
	db '1'+]A ; index 191
	db '1'+]A ; index 192
	db '1'+]A ; index 193
	db '1'+]A ; index 194
	db '1'+]A ; index 195
	db '1'+]A ; index 196
	db '1'+]A ; index 197
	db '1'+]A ; index 198
	db '1'+]A ; index 199
	db '1'+]A ; index 200
	db '1'+]A ; index 201
	db '1'+]A ; index 202
	db '1'+]A ; index 203
	db '1'+]A ; index 204
	db '1'+]A ; index 205
	db '1'+]A ; index 206
	db '1'+]A ; index 207
	db '1'+]A ; index 208
	db '1'+]A ; index 209
	db '1'+]A ; index 210
	db '1'+]A ; index 211
	db '1'+]A ; index 212
	db '1'+]A ; index 213
	db '1'+]A ; index 214

	db '1'+]A ; index 215
	db '1'+]A ; index 216
	db '1'+]A ; index 217
	db '1'+]A ; index 218
	db '1'+]A ; index 219
	db '1'+]A ; index 220
	db '1'+]A ; index 221
	db '1'+]A ; index 222
	db '1'+]A ; index 223
	db '1'+]A ; index 224
	db '1'+]A ; index 225

; should go out to 225, since highest number in tuning table is 900
;------------------------------------------------------------------------------
