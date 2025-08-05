;
; Only on K2 Hardware Draw
; in io bank 0
;

; VICKY MASTER CONTROL LINE ENABLE = $01
; FIFO is 4096 pixels in size

; LINE_DRAWING_REG[0][7:0]
; bit[0] = Enable Line Drawing
; bit[1] = Write Line
; bit[2] = BM_Starting_Addy0 // 0 = BM0_ADDY, 1 = BM1_ADDY, 0 = BM2_ADDY
; bit[3] = BM_Starting_Addy1 // 0 = BM0_ADDY, 0 = BM1_ADDY, 1 = BM2_ADDY
; bit[4] = RESET PIXEL FIFO
; bit[5] = Reserved
; bit[6] = Reserved
; bit[7] = BUSY_DRAWING


LINE_CTRL  = $D180
LINE_CTRL_ENABLE = $01
LINE_CTRL_WRITE  = $02
LINE_CTRL_BM     = $0C ; %11 = 0, 1, or 2
LINE_CTRL_FIFO_RESET = $10

LINE_CTRL_BUSY = $80  ; Line Draw Busy


LINE_COLOR = $D181

LINE_X0   = $D182
LINE_X0_L = $D182
LINE_X0_H = $D183

LINE_X1   = $D184
LINE_X1_L = $D184
LINE_X1_H = $D185

LINE_Y0   = $D186
LINE_Y0_L = $D186

LINE_Y1   = $D187
LINE_Y1_L = $D187

LINE_FIFO_LO = $D182
LINE_FIFO_HI = $D183

;This is for the Record, the Line Drawing Module works in a Differed way (so
;not to stall the CPU), when you push your Coordinates in and you set the Go
;bit and it reports the Busy is now Low, it doesn't mean the process is over,
;it only means that the line has been processed and recorded inside a FIFO then
;you can process another one but before you decide to switch BM planes or else,
;you need to make sure the FIFO is emptied to confirm that the Pixels have been
;written (in the right BM plane) which is really when the process is over.
;Now, the FIFO is big enough to process many lines while waiting to be written
;in memory but that FIFO needs to be monitored carefully. And if one wants to
;do double buffering or else, one needs to make sure the process is done. Also
;starting the process at the right time will help mitigate any FIFO overload
;since there is no writing to memory during the Vertical Blanking which last 45
;lines, but the Vicky Engines starts pulling stuff out Memory @ the line 43
;(The fetching of the Graphical Data is always 2 lines ahead).
;Just be mindful, so not to waste any time debugging... ;)
