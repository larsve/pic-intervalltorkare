;**********************************************************************
; Description:
;   Program main. Define what parts should be used and in what order
;   they are initialized and called.
;   
;**********************************************************************
; Notes:
;
;
;**********************************************************************

    #include    "MCU_Defines.inc"
    #include    "Defines.inc"
    ;<editor-fold defaultstate="collapsed" desc="PIC 16F886 CONFIG">
#ifdef __16F886
#if OSC == 20
    __CONFIG    _CONFIG1, _LVP_OFF & _PWRTE_ON & _WDT_OFF & _FOSC_HS
#else
    __CONFIG    _CONFIG1, _LVP_OFF & _PWRTE_ON & _WDT_OFF & _INTOSCIO
#endif
    __CONFIG    _CONFIG2, _WRT_OFF & _BOR40V
#endif
;</editor-fold>
    ;<editor-fold defaultstate="collapsed" desc="PIC 16F1713 CONFIG">
#ifdef __16F1713
    __CONFIG _CONFIG1, _FOSC_INTOSC & _WDTE_SWDTEN & _PWRTE_ON & _MCLRE_ON & _CP_OFF & _BOREN_ON & _CLKOUTEN_OFF & _IESO_OFF & _FCMEN_ON
    __CONFIG _CONFIG2, _WRT_OFF & _PPS1WAY_OFF & _ZCDDIS_ON & _PLLEN_OFF & _STVREN_ON & _BORV_LO & _LPBOR_ON & _LVP_OFF
#endif
;</editor-fold>
    #include    "Constants.inc"
    #include    "InputOutput.inc"
    #include    "ISR_Timer.inc"

;***** Global declarations ********************************************
    
    Global  Main
    
;***** Extern declarations ********************************************

    ; From Startup_*.asm
    Extern  Do_Startup
    
    ; From ISR_Main.asm
    Extern  Init_MainISR
    Extern  Do_MainISR

    ; From ISR_Timer.asm
    Extern  Init_Timer
    Extern  Do_Timer
    Extern  Timer_Tick

    ; From InputOutput.asm
    Extern  Init_IO
    Extern  Do_Input
    Extern  Do_Output
    Extern  Output

    ; From Logic.asm
    Extern  Init_Logic
    Extern  Do_Logic

    ; From ADC.asm
    Extern  Init_ADC
    Extern  Do_ADC

;***** Startup ********************************************************
RES_VECT  CODE    0x0000        ; processor reset vector
    pagesel Do_Startup          ; ensure page bits are cleared
    goto Do_Startup             ; go to beginning of program

;***** Main program ***************************************************
PROG0 CODE

;**********************************************************************
; Main program loop
;**********************************************************************
Main
    pagesel Init_IO
    call    Init_IO
    call    Init_Timer
    call    Init_ADC
    call    Init_Logic

    ; Run Do_Input once to initialize Input, so that InputD will be correct in the first iteration
    call    Do_Input
    call    Init_MainISR        ; Enable interrupts

Main_Loop
    call    Do_Timer
    call    Do_Input
    call    Do_ADC
    call    Do_Logic
    call    Do_Output
    goto    Main_Loop

    END

