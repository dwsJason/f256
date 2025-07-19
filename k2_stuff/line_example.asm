LINEDRAW_CONFIG_REG        = $D180        ;
; LINE_DRAWING_REG[0][7:0]
; bit[0] = Enable Line Drawing
; bit[1] = Write Line
; bit[2] = BM_Starting_Addy0 // 0 = BM0_ADDY, 1 = BM1_ADDY, 0 = BM2_ADDY
; bit[3] = BM_Starting_Addy1 // 0 = BM0_ADDY, 0 = BM1_ADDY, 1 = BM2_ADDY
; bit[4] = RESET PIXEL FIFO
; bit[5] = Reserved
; bit[6] = Reserved
; bit[7] = BUSY_DRAWING
LINEDRAW_COLOR_REG        = $D181
LINEDRAW_X0_LOW            = $D182 
LINEDRAW_X0_HI            = $D183 
LINEDRAW_X1_LOW            = $D184 
LINEDRAW_X1_HI            = $D185
LINEDRAW_Y0                = $D186 
LINEDRAW_Y1                = $D187 
LINEDRAW_FIFO_LO        = $D182
LINEDRAW_FIFO_HI        = $D183
 

RNG_SEED_LO                = $D6A4
RNG_VALUE_LO            = $D6A4
RNG_SEED_HI                = $D6A5
RNG_VALUE_HI             = $D6A5 
RNG_CONFIG_REG            = $D6A6
RNG_CONFIG_STAT            = $D6A6

; One Line

LineDraw:
                jsr SetIOPage0
                lda #$01
                sta MASTER_CTRL_REG3    ; Master Enable the Line Drawing 
                lda #$0
                sta LINEDRAW_X0_LOW        ; From 0,0
                sta LINEDRAW_X0_HI
                sta LINEDRAW_Y0
                lda #$01
                sta LINEDRAW_X1_HI        ; To 320, 200
                lda #$3F
                sta LINEDRAW_X1_LOW
                lda #$EF
                sta LINEDRAW_Y1
                lda #$01
                sta LINEDRAW_COLOR_REG
                lda #$3
                sta LINEDRAW_CONFIG_REG
StillDrawing:
                lda LINEDRAW_CONFIG_REG
                and #$80
                cmp #$80    ; Wait for the State Complete in the Drawing Algorithm
                bne StillDrawing
                
                lda #$01
                sta LINEDRAW_CONFIG_REG                
                rts


; many line

Random_Setup    lda #$00
                sta RNG_SEED_LO
                lda #$11
                sta RNG_SEED_HI
                lda #$03
                sta RNG_CONFIG_REG
                nop
                nop 
                lda #$01
                sta RNG_CONFIG_REG
                rts 
                
;The BCC & BCS instructions instructions are sometimes known as BLT (branch less than) and BGE (branch greater or equal), respectively.
DrawLineRandom:

                setaxl ;16bits all
                ldx #$0000
DrawlineLoop:    
                ; Begin Reading Random Value to Set x0,y0 : x1, y1
                lda RNG_VALUE_LO    ; Get a RND Value for X0 
                and #$01FF
                cmp #$0140
                bcc Within240X0
                and #$013F
Within240X0:    sta LINEDRAW_X0_LOW
                
                lda RNG_VALUE_LO    ; Get a RND Value for X0 
                and #$01FF
                cmp #$0140
                bcc Within240X1
                and #$013F
Within240X1:    sta LINEDRAW_X1_LOW
                
                setas ;8bits

                lda RNG_VALUE_LO    ; Get a RND Value for Y0 
                cmp #$F0
                bcc Within240Y0
                lda #$ef
Within240Y0:    sta LINEDRAW_Y0


                lda RNG_VALUE_LO    ; Get a RND Value for Y0 
                cmp #$F0
                bcc Within240Y1
                lda #$ef
Within240Y1:    sta LINEDRAW_Y1


                lda RNG_VALUE_LO    ; Just reading the LSB for the Color Register
                sta LINEDRAW_COLOR_REG
                
                lda #$03            ; Enable + Go Draw
                sta LINEDRAW_CONFIG_REG
                
StillDrawingRNG:
                ; For the Line to be Completely Finished computing
                lda LINEDRAW_CONFIG_REG
                and #$80
                cmp #$80
                bne StillDrawingRNG
                
                lda #$01                 ; In order to begin a new line, you need to bring back the Go bit back to zero
                sta LINEDRAW_CONFIG_REG  ; Always keep the Line Drawing Enabled for it to finish drawing
            
                setal
                inx 
                cpx #$4000
                bne DrawlineLoop
                
                setaxs 
                rts
