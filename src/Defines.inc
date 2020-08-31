;**********************************************************************
; Description:
;	Global defines that change some parts of the program so suite the
;	specific needs of the different types of hardware used.
;   
;**********************************************************************
; Notes:
;
;
;**********************************************************************

#define OSC 2           ; Select 2MHz clock
#define ADC_OS          ; Turn on ADC oversampling
#define RunLed          ; Enable "Program running" LED
#define WDT             ; Enable Watchdog timer

#define ResetCause
;#define ResetCounters

; Setup ADC input references to use Vdd as reference
#define AdcRef1	B'01000000'	; Use the 1V024 FVR as reference for AN0/RA0
#define AdcRef2	B'00000000'	; Set AN4/RA5,  AN8/RB2,  AN9/RB3,  AN10/RB1 to VDD as reference
#define AdcRef3	B'00000000'	; Set AN11/RB4, AN12/RB0, AN13/RB5, AN14/RC2 to VDD as reference
#define AdcRef4	B'00000000'	; Set AN15/RC3, AN16/RC4, AN17/RC5, AN18/RC6 to VDD as reference
#define AdcRef5	B'00000000'	; Set AN19/RC7, DAC2,     Temp,     DAC1     to VDD as reference
