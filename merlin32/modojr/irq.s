;
; Jiffy, ModJiffy, and MixerJiffy IRQ handling
;

VIRQ = $FFFE

InstallIRQ
		php
		sei

		jsr CopyROM

; save the old IRQ version
		lda VIRQ
		sta original_irq
		lda VIRQ+1
		sta original_irq+1

; patch in my IRQ
		lda #<my_irq_handler
		sta VIRQ

		lda #>my_irq_handler
		sta VIRQ+1

;
; Here we just fuck over the kernel
;

		lda io_ctrl
		pha
		stz io_ctrl

		lda #$FF
		sta |INT_MASK_0 	; disable all these interrupts
		sta |INT_MASK_1		; disable all these interrupts
		sta |INT_PEND_0 	; clear any pending interrupts
		sta |INT_PEND_1
		
;
; Setup the Hi Rate Timer for 16Khz
; 
CPU_CLOCK_RATE equ 6293750  ; this is 1/4th clock rate
;RATE     equ 25175000/16000 ; system clock rate, timer is tied to this
RATE     equ CPU_CLOCK_RATE/4000
MODRATE  equ 16000/50

		stz <SongIsPlaying

		; MOD set to 50hz
		lda #<MODRATE
		sta <mod_jiffy_rate
		lda #>MODRATE
		sta <mod_jiffy_rate+1

		; High Res Timer0 
		do 1
		;lda #TM_CTRL_CLEAR.TM_CTRL_UP_DOWN.TM_CTRL_ENABLE.TM_CTRL_INTEN
		stz |TM0_CTRL

		lda #TM_CMP_CTRL_CLR
		sta |TM0_CMP_CTRL

		lda #<RATE
		sta |TM0_CMP_L
		lda #>RATE
		sta |TM0_CMP_M
		lda #^RATE
		sta |TM0_CMP_H

		stz |TM0_VALUE_L
		stz |TM0_VALUE_M
		stz |TM0_VALUE_H

		lda #TM_CTRL_UP_DOWN.TM_CTRL_ENABLE.TM_CTRL_INTEN
		sta |TM0_CTRL
  
		lda #{INT00_VKY_SOF.INT04_TIMER_0}!$FF  ; clear mask for SOF, and fast timer
		sta |INT_MASK_0 	; enable some interrupts

		lda #$FF
		sta |INT_PEND_0 	; clear any pending interrupts
		sta |INT_PEND_1

		; polarity + edge
		sta |$D664
		sta |$D668
		else

		lda #{INT00_VKY_SOF.INT01_VKY_SOL}!$FF  ; clear mask for SOF, and fast timer
		sta |INT_MASK_0 	; enable some interrupts

		lda #$FF
		sta |INT_PEND_0 	; clear any pending interrupts
		sta |INT_PEND_1


		fin

		stz VKY_LINE_NBR_L
		stz VKY_LINE_NBR_H
		stz irq_num
		stz irq_num+1

		lda #VKY_LINE_ENABLE
		sta |VKY_LINE_CTRL 	; enable line interrupts

		pla
		sta io_ctrl


		stz jiffy
		stz jiffy+1
		stz mod_jiffy
		stz mod_jiffy+1

		plp
		rts

my_irq_handler

		pha
		phx
		phy

		lda <MMU_IO_CTRL
		pha

		; Switch to I/O page 0 - so we can read the interrupt registers
		stz <MMU_IO_CTRL

		lda INT_PEND_0
		sta INT_PEND_0 			; clear all interrupts

		bit #INT04_TIMER_0.INT01_VKY_SOL
		beq :not_mixer

		pha  ; preserve the interrupts that happened

		; mixer / DAC service
		lda mmu3
		pha
		jsr MixerMix
		pla
		sta mmu3

		; stuff for the K
		do 0
;		inc irq_num
;		bne :no_hi_irq_num
;		inc irq_num+1
		lda irq_num
		inc
		cmp #$F0
		bcc :no_hi_irq_num
		lda #0
:no_hi_irq_num
		sta irq_num

;		lda irq_num
		asl
		sta VKY_LINE_NBR_L
		lda irq_num+1
		rol
		sta VKY_LINE_NBR_H
		fin
		; end stuff for the K

		; it's slow
		; we have to manually count off 16000/50 interrupts :(

		lda <mod_jiffy_countdown
		dec
		sta <mod_jiffy_countdown
		cmp #$FF
		bne :not_hi
		dec <mod_jiffy_countdown+1
:not_hi
		ora <mod_jiffy_countdown+1
		bne :not_mod

:do_mod_jiffy

		; reset the count
		lda <mod_jiffy_rate
		sta <mod_jiffy_countdown
		lda <mod_jiffy_rate+1
		sta <mod_jiffy_countdown+1

		cli
		jsr ModPlayerTick

:not_mod
		pla


:not_mixer
		bit #INT00_VKY_SOF
		beq :not_sof
		; SOF interrupt
		inc <jiffy
		bne :not_sof  	; we probably don't actually need 16 bit jiffy
		inc <jiffy+1
:not_sof

		pla
		sta <MMU_IO_CTRL

		ply
		plx

		pla
		rti

not_this
		jmp (original_irq) ; $$JGA, this might unmap our IRQ handler


; keep a copy, even though I guess we can always get another copy
original_irq ds 2



;
; Copy the ROM to RAM, so we can patch it, taking the end of memory
;
CopyROM
		php
		sei
	
		lda io_ctrl
		pha

		lda mmu_ctrl
		pha

		and #$3
		sta temp0 ; active MLUT

		asl
		asl
		asl
		asl

		ora temp0
		ora #$80
		sta mmu_ctrl

		; map the kernel ROM to $A000
		lda #$7f
		sta mmu5
		; map our RAM replacement
		lda #$3f
		sta mmu7

		; in case we get called more than 1 time
		lda #$A0
		sta :src+2
		lda #$E0
		sta :dst+2

		ldx #0
		ldy #32
]lp
:src	lda $A000,x
:dst	sta $E000,x
		dex
		bne ]lp

		inc :src+2
		inc :dst+2

		dey
		bne ]lp

		lda #5     		; map system RAM $A000 to $A000
		sta mmu5

		;lda #7
		;sta mmu7

		pla
		sta mmu_ctrl

		pla
		sta io_ctrl
		
		plp
		rts


