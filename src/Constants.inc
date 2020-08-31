;**********************************************************************
; Description:
;   Define global constants used in various places in many modules.
;   
;**********************************************************************
; Notes:
;
;
;**********************************************************************


; *** Reset flags *****************************************************

rfPOR       EQU 0x07        ; Power On Reset
rfBOR       EQU 0x06        ; Brown-out Reset
rfWDT       EQU 0x05        ; Watchdog Timeout Rest
rfSTKOF     EQU 0x04        ; Stack overflow reset
rfSTKUF     EQU 0x03        ; Stack underflow reset
rfMCLR      EQU 0x02        ; MClear Reset
rfRI        EQU 0x01        ; Reset instruction
    

; *** Input/Output Constants ******************************************

; Input constants
inRhp           EQU 0x07	; Right Home Pulse
inLhp           EQU 0x06	; Left Home Pulse

; Output constants
outRunLed       EQU 0x07	; Program Running LED
outLeftLed      EQU 0x06	; 
outRightLed     EQU 0x05	; 
outRunLeft      EQU 0x04	; 
outRunRight     EQU 0x03	; 
