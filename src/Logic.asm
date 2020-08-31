;**********************************************************************
; Description:
;	Main logic, this should be the router or switch that monitors and
;	controls the other parts and make them work with eachother.
;	Note. The A/D part should be moved to a separate unit.
;   
;**********************************************************************
; Notes:
;
;
;**********************************************************************

    #include	"MCU_Defines.inc"
    #include	"Constants.inc"
    #include	"ADC.inc"
    #include	"ISR_Timer.inc"

;    errorlevel  -207			; suppress message 207 from list file

;***** Script local defines *******************************************


;***** Global declarations ********************************************

    ; Methods
    GLOBAL	Init_Logic
    GLOBAL  Do_Logic
	
    ; Variables
;    GLOBAL	Uptime

;***** Extern declarations ********************************************

    ; From ADC_*.asm
    Extern AdcState
    Extern AN0
    
    ; From InputOutput.asm
    Extern Input
    Extern InputD
    Extern Output

    ; From ISR_Timer.asm
    Extern Timer_Tick

;***** Variables ******************************************************
; Allocate RAM addresses in unbanked memory
;Shared_Data	udata_shr
;LState		res 1			; Logic & ADC status bits

; Allocate RAM addresses in bank 0 memory
gprbank0	udata
LState		res 1			; Logic state
RhLed       res 1           ; Right LED counter (10ms ticks)
LhLed       res 1           ; Left LED counter (10ms ticks)
Delay       res 1           ; Delay counter (100ms ticks)
Pot         res 1
RLIdx       res 1
RLTime      res 1
RLCnt       res 1
        
; "Shared" temp variables..
Temp_Data	udata_ovr	0x6e
Temp		res 1
ISRTemp		res 1

;***** Constants ******************************************************
; Logic States
LS_Delay1s       EQU 0x00
LS_DelayInt      EQU 0x01
LS_AwaitHome     EQU 0x02
LS_FlipBit       EQU 0x07

;***** Code Section ***************************************************
PROG0		code

;**********************************************************************
; Init Logic
;   Initializes variables and read default values from EEprom.
;**********************************************************************
Init_Logic
    ; Clear/init variables
    banksel	LState
    clrf	LState
    clrf    RhLed
    clrf    LhLed
    clrf    Pot
    clrf    RLIdx
    clrf    RLTime
    clrf    RLCnt
    
    ; Set Delay to 10, to begin with the one second delay (10 * 100ms ticks)
    movlw   0x0a
    movwf   Delay
    
    ; Setup initial values for RunningLED times..
    movlw   0x0c 
    movwf   RLIdx               ; Start at 100% PWM output
    call    GetLedTime
    movwf   RLTime
    movwf   RLCnt
    
    return 

;**********************************************************************
; Do Logic
;   React to input changes and set output states.
;**********************************************************************
Do_Logic
    banksel LState
    btfsc	Timer_Tick, TimerTick_100ms
    clrwdt                      ; Clear Watchdog timer
    
    call    DelayTimer          ; Delay countdown
    call    CheckAdc            ; Check for new ADC value
    call    CheckInput          ; Any inputs changed?
    call    LightRightLED       ; Light Right LED?
    call    LightLeftLED        ; Light Left LED?
    call    RunningLed          ; Handle "Running LED" PWM(ish) output
    
    ; Specific state handlers..
    banksel LState
    movfw   LState
    andlw	0x03
    brw
    goto    DelayOneSecond      ; 0x00 - LS_Delay1s
    goto    DelayInterval       ; 0x01 - LS_DelayInt
    goto    AwaitHomePulse      ; 0x02 - LS_AwaitHome
                                ; 0x03 - Undefined, restart..
    clrf    LState
    clrf    Output
    movlw   0x0a
    movwf   Delay
    return
    
DelayOneSecond
    btfss	Timer_Tick, TimerTick_100ms
    return

    movfw   Delay
    skpz
    return                      ; Delay still > zero, bail..
    
    movfw   LState
    andlw   0xfc
    iorlw   LS_DelayInt
    movwf   LState
    decf    Delay, f            ; Wrap Delay around to 0xff to start intervall delay
    ; Continue into DelayInterval to check if we should start directly or hava a additional delay first
    
DelayInterval
    btfss	Timer_Tick, TimerTick_100ms
    return
    
    movfw   Delay
    subwf   Pot, w
    skpc
    return                      ; Delay > Pot, bail..
    
    movfw   LState
    andlw   0xfc
    iorlw   LS_AwaitHome
    movwf   LState
    bsf     Output, outRunLeft
    bsf     Output, outRunRight
    clrf    Delay
    return
    
AwaitHomePulse
    return

;**********************************************************************
; Local routines
;**********************************************************************

    ;<editor-fold defaultstate="collapsed" desc="CheckAdc">
CheckAdc
    banksel AdcState
    btfss   AdcState, adcDone
    return
    
    ; AN0 is a 10-bit ADC value, oversampled 64 times, and stored in big endian
    ; format and since ADC_OS_AVG isn't turned on, we'll endup with a value
    ; between zero and 65472 (1023 x 64) = 0xffc0, but we're only intersted in
    ; the upper 8-bits (0-255) to use as our 0 to 25.5 second delay source..
    ; And since we are counting down, we invert the ADC value that we compare
    ; to the delay counter.
    movfw   AN0
    sublw   0xff
    banksel Pot
    movwf   Pot
    return
;</editor-fold>
    
    ;<editor-fold defaultstate="collapsed" desc="CheckInput">
CheckInput
    movfw   InputD
    skpnz
    return                      ; No inputs changed
    
    ; Check Right Home Pulse for a high-to-low transition..
    btfss   InputD, inRhp
    goto    CheckLeftInput      ; No change..
    btfsc   Input, inRhp
    goto    CheckLeftInput      ; Not low
    bcf     Output, outRunRight ; Stop right
    
    ; Setup LED counter to light the LED for a short period
    banksel RhLed
    movlw   .50
    movwf   RhLed
    
    ; Change LState?
    movfw   LState
    andlw   0x03
    xorlw   LS_AwaitHome
    skpz
    goto    CheckLeftInput
    movfw   LState
    andlw   0xfc
    iorlw   LS_Delay1s
    movwf   LState
    
    ; Reset delay timer
    movlw   0x0a
    movwf   Delay
    
CheckLeftInput
    ; Check Left Home Pulse for a high-to-low transition..
    btfss   InputD, inLhp
    return                      ; No change..
    btfsc   Input, inLhp
    return                      ; Not low
    bcf     Output, outRunLeft  ; Stop left
    
    ; Setup LED counter to light the LED for a short period
    banksel LhLed
    movlw   .50
    movwf   LhLed
    
    ; Change LState?
    movfw   LState
    andlw   0x03
    xorlw   LS_AwaitHome
    skpz
    return
    movfw   LState
    andlw   0xfc
    iorlw   LS_Delay1s
    movwf   LState
    
    ; Reset delay timer
    movlw   0x0a
    movwf   Delay
    return
;</editor-fold>
    
    ;<editor-fold defaultstate="collapsed" desc="DelayTimer">
DelayTimer
    btfss	Timer_Tick, TimerTick_100ms
    return

    banksel Delay
    movfw   Delay
    skpz
    decf    Delay, f
    return
;</editor-fold>
    
    ;<editor-fold defaultstate="collapsed" desc="LightLeftLED">
LightLeftLED
    banksel LhLed
    movfw   LhLed
    skpnz
    return
    bsf     Output, outLeftLed
    btfss	Timer_Tick, TimerTick_10ms
    return
    decfsz  LhLed, f
    return
    bcf     Output, outLeftLed
    return
;</editor-fold>

    ;<editor-fold defaultstate="collapsed" desc="LightRightLED">
LightRightLED
    banksel RhLed
    movfw   RhLed
    skpnz
    return
    bsf     Output, outRightLed
    btfss	Timer_Tick, TimerTick_10ms
    return
    decfsz  RhLed, f
    return
    bcf     Output, outRightLed
    return
;</editor-fold>

    ;<editor-fold defaultstate="collapsed" desc="RunningLed">
RunningLed
    banksel LState
    bsf     Output, outRunLed
    movfw   RLCnt
    skpnz
    bcf     Output, outRunLed
    
    ; On a 1ms tick?
    btfss   Timer_Tick, TimerTick_1ms
    return
    
    ; Dec RLCnt if > 0
    movfw   RLCnt
    skpz
    decf    RLCnt, f
    
    ; On a 10ms tick?
    btfss   Timer_Tick, TimerTick_10ms
    return
    
    ; Flip LS_FlipBit bit and check state to know if we should reload RLCnt.
    movlw   1 << LS_FlipBit
    xorwf   LState, f
    btfsc   LState, LS_FlipBit
    return

    ; Reload RLCnt
    movfw   RLTime
    movwf   RLCnt
    
    ; On a 100ms tick?
    btfss   Timer_Tick, TimerTick_100ms
    return
    
    ; Fetch next time from sin() table..
    call    GetLedTime
    movwf   RLTime
    return
    
GetLedTime
    incf    RLIdx, f
    movfw   RLIdx
    andlw   0x3f
    brw
    dt	    0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10, 0x10
    dt	    0x11, 0x12, 0x12, 0x13, 0x13, 0x14, 0x14, 0x14
    dt	    0x14, 0x14, 0x14, 0x14, 0x13, 0x13, 0x12, 0x12
    dt	    0x11, 0x10, 0x10, 0x0F, 0x0E, 0x0D, 0x0C, 0x0B
    dt	    0x0A, 0x09, 0x08, 0x07, 0x06, 0x05, 0x04, 0x04
    dt	    0x03, 0x02, 0x02, 0x01, 0x01, 0x00, 0x00, 0x00
    dt	    0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x02, 0x02
    dt	    0x03, 0x04, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09
;</editor-fold>

	END
