MEMTEXT_CTRL_REG        = $D300 
MEMTEXT_Enable            = $01        ; 1 = Enable (The Master Control needs to be on as well)
MEMTEXT_Size             = $02        ; 0 = 8x8, 1 = 8x16 
MEMTEXT_CURSOR_CTRL_REG = $D301      ; Cursor Control Register 
MEMTEXT_Cursor_Enable    = $01         ; Cursor On 
MEMText_Crsr_FlashRate0    = $02         ;
MEMText_Crsr_FlashRate1    = $04         ;
MEMText_FONT_Bank0        = $08        ;
MEMText_FONT_Bank1        = $10        ;
MEMText_FONT_Size        = $20        ; 
MEMText_CURSOR_X_POS    = $D302 
MEMText_CURSOR_Y_POS    = $D303     
MEMTEXT_MEMCHAR_PTR_LO    = $D304
MEMTEXT_MEMCHAR_PTR_MD    = $D305
MEMTEXT_MEMCHAR_PTR_HI    = $D306
MEMTEXT_PRECHARGE        = $D307     ; Reserved
MEMTEXT_MEMCOLOR_PTR_LO    = $D308
MEMTEXT_MEMCOLOR_PTR_MD    = $D309
MEMTEXT_MEMCOLOR_PTR_HI    = $D30A

MEMTEXT_CURSOR_COLOR_B    = $D30D
MEMTEXT_CURSOR_COLOR_G    = $D30E
MEMTEXT_CURSOR_COLOR_R    = $D30F
MEMTEXT_CURSOR_GRAPH    = $D310        ; $D310..D317 for 8x8, $D310..D31F for 8x16

IOBANK4_FG_LUT            = $C000
IOBANK4_BG_LUT           = $C800 
IOBANK4_FONT             = $D000    

init_memtext:
                
                ; We are done with LUT Init, So, let's init everything else
                jsr SetIOPage0
                
                lda #MEMTEXT_Enable
                sta MEMTEXT_CTRL_REG
                lda #$05
                sta MEMTEXT_CURSOR_CTRL_REG

                ; lets locate the Source Address for the Text + Attribute @ $00_2000 (now that mode uses 9600 Bytes in 80x60(2 bytes))
                lda #$00
                sta MEMTEXT_MEMCHAR_PTR_LO
                lda #$20                
                sta MEMTEXT_MEMCHAR_PTR_MD
                lda #$00
                sta MEMTEXT_MEMCHAR_PTR_HI
                ; lets locate the Source Address for the Color @ $00_5000
                lda #$00
                sta MEMTEXT_MEMCOLOR_PTR_LO
                lda #$50
                sta MEMTEXT_MEMCOLOR_PTR_MD
                lda #$00
                sta MEMTEXT_MEMCOLOR_PTR_HI
                
                lda #%00011000
                sta MEMTEXT_CURSOR_GRAPH
                sta MEMTEXT_CURSOR_GRAPH+1
                sta MEMTEXT_CURSOR_GRAPH+2
                sta MEMTEXT_CURSOR_GRAPH+3
                sta MEMTEXT_CURSOR_GRAPH+4
                sta MEMTEXT_CURSOR_GRAPH+5
                sta MEMTEXT_CURSOR_GRAPH+6
                sta MEMTEXT_CURSOR_GRAPH+7
                
                lda #$10
                sta MEMText_CURSOR_X_POS
                lda #$8
                sta MEMText_CURSOR_Y_POS
                
                lda #$0A
                sta MEMTEXT_PRECHARGE
                rts 
