;**********************************************************************
; Description:
;   Initialize I/O and handle any digital input/output.
;   
;**********************************************************************
; Notes:
;
;
;**********************************************************************

    #include    "MCU_Defines.inc"
    #include    "Defines.inc"
    #include    "Constants.inc"
    #include    "InputOutput.inc"
    #include    "ISR_Timer.inc"

;***** Global declarations ********************************************
    ; Methods
    GLOBAL Init_IO
    GLOBAL Do_Input
    GLOBAL Do_Output
    
    ; Variables
    GLOBAL Input
    GLOBAL InputD
    GLOBAL Output


;***** Extern declarations ********************************************

;***** Variables ******************************************************
; Allocate RAM addresses in unbanked memory
Shared_Data udata_shr
Input       res 1
InputD      res 1
Output      res 1

Temp_Data   udata_ovr   0x6e
Temp        res 1

;***** Code Section ***************************************************
PROG0   code

;**********************************************************************
; Initialize MCU Input and Output
;   Initializes input and output ports.
;**********************************************************************
;<editor-fold defaultstate="collapsed" desc="PIC16F886">
#ifdef __16F886
Init_IO
    ; Clear variables in unbamked memory
    clrf    Input
    clrf    InputD
    clrf    Output

    ; Setup I/O ports
    banksel PORTA
    clrf    PORTA               ; Clear port A output latches
    clrf    PORTB               ; Clear port B output latches
    clrf    PORTC               ; Clear port C output latches
    clrf    PORTE               ; Clear port E output latches

    BANKSEL TRISA               ; Set bank for TRIS registers
    movlw   PortA_TRIS          ; Port A IO bits
    movwf   TRISA               ; Set Port A IO register
    
    movlw   PortB_TRIS          ; Port B IO bits
    movwf   TRISB               ; Set Port B IO register
    
    movlw   PortC_TRIS          ; Port C IO bits
    movwf   TRISC               ; Set Port C IO register

    ; Port B weak pullup
    movlw   PortB_WPU           ; Port B Weak Pullups
    movwf   WPUB
    bcf     OPTION_REG, NOT_RBPU; Enable weak pullup's

    ; Analog
    banksel ANSEL
    movlw   PortA_ADC           ; A/D / I/O select bits
    movwf   ANSEL

    movlw   PortB_ADC           ; A/D / I/O select bits
    movwf   ANSELH

    return
#endif    
;</editor-fold>
;<editor-fold defaultstate="collapsed" desc="PIC16F1713">
#ifdef __16F1713
Init_IO
    ; Clear variables in unmabed memory
    clrf    Input
    clrf    InputD
    clrf    Output

    ; Setup I/O ports
    banksel PORTA
    clrf    PORTA               ; Clear port A output latches
    clrf    PORTB               ; Clear port B output latches
    clrf    PORTC               ; Clear port C output latches

    banksel ANSELA              ; Set Analog/digital select bits
    movlw   PortA_ADC
    movwf   ANSELA
    movlw   PortB_ADC
    movwf   ANSELB
    movlw   PortC_ADC
    movwf   ANSELC
    
    banksel WPUA                ; Configure weak pull-up
    movlw   PortA_WPU
    movwf   WPUA
    movlw   PortB_WPU
    movwf   WPUB
    movlw   PortC_WPU
    movwf   WPUC
    #if PortA_WPU || PortB_WPU || PortC_WPU != 0
    banksel OPTION_REG
    bcf     OPTION_REG, NOT_WPUEN; Enable weak pullup's 
    #endif
    
    banksel ODCONA              ; Disable Open-drain output
    clrf    ODCONA
    clrf    ODCONB
    clrf    ODCONC
    
    banksel SLRCONA             ; Set slew rate to max
    clrf    SLRCONA
    clrf    SLRCONB
    clrf    SLRCONC

    banksel IOCAF               ; Disable Interrupt on change
    clrf    IOCAF
    clrf    IOCAN
    clrf    IOCAP
    clrf    IOCBF
    clrf    IOCBN
    clrf    IOCBP
    clrf    IOCCF
    clrf    IOCCN
    clrf    IOCCP
    
    banksel TRISA               ; Set Data Direction Registers
    movlw   PortA_TRIS
    movwf   TRISA
    movlw   PortB_TRIS
    movwf   TRISB
    movlw   PortC_TRIS
    movwf   TRISC
    
#ifdef I2C
    ; Setup I2C peripheral..
    banksel PPSLOCK
    movlw   0x55                ; Issue the Lock/Unlock sequence..
    movwf   PPSLOCK
    movlw   0xaa
    movwf   PPSLOCK
    bcf     PPSLOCK, PPSLOCKED  ; Unlock periheral registers
    
    banksel RC3PPS
    movlw   B'00010000'         ; Set RC3 as SCL output pin
    movwf   RC3PPS
    movlw   B'00010001'         ; Set RC4 as SDA output pin
    movwf   RC4PPS
    
    banksel SSPCLKPPS
    movlw   B'00010011'         ; Set SSP CLK (I2C SCL) input to PORTC, Bit 3 (RC3)
    movwf   SSPCLKPPS
    movlw   B'00010100'         ; Set SSP DAT (I2C SDA) input to PORTC, Bit 4 (RC4)
    movwf   SSPDATPPS
    
    movlw   0x55                ; Issue the Lock/Unlock sequence..
    movwf   PPSLOCK
    movlw   0xaa
    movwf   PPSLOCK
    bsf     PPSLOCK, PPSLOCKED  ; Lock periheral registers
#endif    
    return
#endif
;</editor-fold>

;**********************************************************************
; Do Input
;   Scan input I/O ports.
;**********************************************************************
Do_Input
    banksel PORTA
    clrf    Temp                ; Clear Temp Input

    ; Read inputs and set matching bits in Temp

    ; Right home pulse (active low)
    btfsc   RhpPin
    bsf     Temp, inRhp

    ; Left home pulse (active low)
    btfsc   LhpPin
    bsf     Temp, inLhp

    ; Set InputD by doing a XOR on Temp and the previous Input to get inputs
    ; that have change state since last time.
    movfw   Temp
    xorwf   Input, W
    movwf   InputD

    ; Set Input to the current input states
    movfw   Temp
    movwf   Input

    return

;**********************************************************************
; Do Output
;   Set output I/O ports.
;**********************************************************************
Do_Output
    banksel PORTA
#ifdef RunLed
    ; Run LED
    btfss   Output, outRunLed
    bcf     RunLedPin
    btfsc   Output, outRunLed
    bsf     RunLedPin
#endif

    ; Left LED
    btfss   Output, outLeftLed
    bcf     LeftLedPin
    btfsc   Output, outLeftLed
    bsf     LeftLedPin
    
    ; Right LED
    btfss   Output, outRightLed
    bcf     RightLedPin
    btfsc   Output, outRightLed
    bsf     RightLedPin
    
    ; Run Left
    btfss   Output, outRunLeft
    bcf     RunLeftPin
    btfsc   Output, outRunLeft
    bsf     RunLeftPin
    
    ; Run Right
    btfss   Output, outRunRight
    bcf     RunRightPin
    btfsc   Output, outRunRight
    bsf     RunRightPin
    
    return

    END
