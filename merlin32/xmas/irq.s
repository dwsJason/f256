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

		; High Res Timer0 
		stz |TM0_CTRL

		lda #INT00_VKY_SOF!$FF  ; clear mask for SOF
		sta |INT_MASK_0 	; enable some interrupts

		lda #$FF
		sta |INT_PEND_0 	; clear any pending interrupts
		sta |INT_PEND_1

		; polarity + edge
		sta |$D664
		sta |$D668

		pla
		sta io_ctrl

		stz jiffy
		stz jiffy+1

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


