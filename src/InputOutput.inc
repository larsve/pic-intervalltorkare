;**********************************************************************
; Description:
;   Define all fysical input/output. No manipulation should be done
;   directly, all manipulation of pin input/output shold be done in the
;   Do_Input/Do_Output methods.
;   
;**********************************************************************
; Notes:
;
;
;**********************************************************************

    ;***** Port A I/O, 1 = Input, 0 = Output, A = Analog
    ; RA7 : 1 = Unused
    ; RA6 : 1 = Unused
    ; RA5 : 1 = Unused
    ; RA4 : 1 = Unused
    ; RA3 : 1 = Unused
    ; RA2 : 1 = Unused
    ; RA1 : 1 = Unused
    ; RA0 : A = Pot
    #define PortA_TRIS      B'11111111'     ; PORTA Data Direction Register
    #define PortA_ADC       B'00000001'     ; Analoga inputs
    #define PortA_WPU       B'00000000'     ; Pullup on PORT A

    ;***** Port B I/O, 1 = Input, 0 = Output, A = Analog
    ; RB7 : 1 = Unused
    ; RB6 : 1 = Unused
    ; RB5 : 1 = Right home pulse (active low, pullup)
    ; RB4 : 1 = Left home pulse (active low, pullup)
    ; RB3 : 1 = Unused
    ; RB2 : 1 = Unused
    ; RB1 : 1 = Unused
    ; RB0 : 1 = Unused
    #define PortB_TRIS      B'11111111'     ; PORTB Data Direction Register
    #define PortB_ADC       B'00000000'     ; Analog inputs
    #define PortB_WPU       B'00110000'     ; Pullup on PORT B
    #define RhpPin          PORTB, 0x05     ; Right home pulse (active low)
    #define LhpPin          PORTB, 0x04     ; Left home pulse (active low)
    
    ;***** Port C I/O, 1 = Input, 0 = Output, A = Analog
    ; RC7 : 0 = Right
    ; RC6 : 0 = Left
    ; RC5 : 1 = Unused
    ; RC4 : 1 = Unused
    ; RC3 : 1 = Unused
    ; RC2 : 0 = Right LED
    ; RC1 : 0 = Left LED
    ; RC0 : 0 = Running LED
    #define PortC_TRIS      B'00111000'     ; PORTC Data Direction Register
    #define PortC_ADC       B'00000000'     ; Analoga inputs
    #define PortC_WPU       B'00000000'     ; Pullup on PORT C
    #define RunRightPin     PORTC, 0x07     ; Run Right
    #define RunLeftPin      PORTC, 0x06     ; Run Left
    #define RightLedPin     PORTC, 0x02     ; Right LED pin
    #define LeftLedPin      PORTC, 0x01     ; Left LED pin
    #define RunLedPin       PORTC, 0x00     ; Running LED pin

