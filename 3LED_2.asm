;*********************************************************************************
;**	3-Värisen LED-nauhan ohjain PIC16F628					**
;**	VERSIO: 1.0-0	10.02.2015						**
;**										**
;**	- RB7 (13)								**
;**	- RB6 (12)								**
;**	- RB5 (11) Oikea SININEN						**
;**	- RB4 (10) Oikea VIHREÄ							**
;**	- RB3 ( 9) Oikea PUNAINEN						**
;**	- RB2 ( 8) Vasen SININEN						**
;**	- RB1 ( 7) Vasen VIHREÄ							**
;**	- RB0 ( 6) Vasen PUNAINEN						**
;**										**
;**	- RA0 (17) 								**
;**	- RA1 (18) 								**
;**	- RA2 ( 1) 								**
;**	- RA3 ( 2)  								**
;**	- RA4 ( 3) 								**
;**										**
;**										**
;*********************************************************************************


	LIST p=16F628
	include <P16F628.inc>



START

; Muistipaikat

DELAY_LSB	equ	0x20	; Vähemmän merkitsevä viivelaskuri
DELAY_MSB	equ	0x21	; Enemmän merkitsevä viivelaskuri
time_ON		equ	0x22	; PWM ylhäällä
time_OFF	equ	0x23	; PWM alhalla
time0		equ	0x24	; apumuuttuja time_ON:lle
time1		equ	0x25	; apumuuttuja time_OFF:lle
LEDs		equ	0x26	; Sytytettävät ledit
LED_delay	equ	0x27	; Ledien viive
lightUP		equ	0x28
lightDOWN	equ	0x29

; Rekisterit BANK-0

status		equ	0x03	; STATUS-rekisteri
porta		equ	0x05	; PORTA-rekisteri
portb		equ	0x06	; PORTB-rekisteri
cmcon		equ	0x1F	; PIC16F628

; Rekisterit BANK-1

trisa		equ	0x85	; TRISA-rekisteri
trisb		equ	0x86	; TRISB-rekisteri

; Liput

carry		equ	0x00	; STATUS/C-bitti
zero		equ	0x02	; STATUS/Z-bitti
pank		equ	0x05	; STATUS/RP0 (register bank select bit)

LRED		equ	0x00	; Vasen PUNAINEN
LGREEN		equ	0x01	; Vasen VIHREÄ
LBLUE		equ	0x02	; Vasen SININEN
RRED		equ	0x03	; Oikea PUNAINEN
RGREEN		equ	0x04	; Oikea VIHREÄ
RBLUE		equ	0x05	; Oikea SININEN



	ORG 0000		; Asetetaan reset-osoite
	goto INIT

	ORG 0004		; Asetetaan keskeytys-osoite
	goto INIT

	ORG 0008		; Ohjelmakoodi alkaa




;*********************************************************************************
;** INIT alustaa PIC:n rekisterit ja muistipaikat				**
;*********************************************************************************


INIT

	movlw 0x07		; PIC16F628
	movwf cmcon		; PIC16F628

	clrf porta		; Nollaa portin A
	clrf portb		; Nollaa portin B
		
	bsf status,pank		; Bank 1
	
	movlw b'11111'		
	movwf trisa		; RA4 tulo
				; RA3 tulo
				; RA2 tulo
				; RA1 tulo
				; RA0 tulo
					
	movlw b'11000000'
	movwf trisb		; RB7 tulo
				; RB6 tulo
				; RB5 lähtö
				; RB4 lähtö
				; RB3 lähtö
				; RB2 lähtö
				; RB1 lähtö
				; RB0 lähtö
					
	bcf status,pank		; Bank 0
	
	movlw 0xFF		; 
	movwf LED_delay		; FFh -> LED_delay

	goto MAIN


;*********************************************************************************
;**	VIIVE aliohjelma, jossa viive muodostetaan DELAY_MSB ja DELAY_LSB       **
;**	loopeilla.								**
;**										**
;**	Kuluva aika kellojaksoina: DELAY_MSB x ((DELAY_LSB x 2TCy) + 4)		**
;**	Sisäinen kellotaajuus: OSC1 / 4 (4MHz ulkoinen -> 1MHz sisäinen)	**
;**										**
;**	LED_delay tuo aliohjelmaan sisemmän loopin kierrosten määrän		**
;*********************************************************************************


VIIVE
	movlw 0xFF		;
	movwf DELAY_MSB		; FFh -> DELAY_MSB
MSB	
	movf LED_delay, 0	; LED_delay -> W
	movwf DELAY_LSB		; W -> DELAY_LSB
LSB	
	nop			; Kulutetaan yhteensä 10 kellojaksoa
	nop			;
	nop			;	
	nop			;
	nop			;
	nop			;
	nop			;
	nop			;
	nop			;
	nop			;
	
	decfsz DELAY_LSB, 1	; DELAY_LSB = DELAY_LSB - 1
	goto LSB

	decfsz DELAY_MSB, 1	; DELAY_MSB = DELAY_MSB - 1
	goto MSB

	return


;*********************************************************************************
;** PWM_ON sytyttää LEDit hitaasti						**
;**										**
;** LEDs muuttujassa tuodaan hitaasti sytytettävät ledit			**
;**										**
;** MSB	0	Ei kytketty							**
;** 	0	Ei kytketty							**
;**	x	Oikea SININEN							**
;**	x	Oikea VIHREÄ							**
;**	x	Oikea PUNAINEN							**
;**	x	Vasen SININEN							**
;**	x	Vasen VIHREÄ							**
;** LSB	x	Vasen PUNAINEN							**	
;**										**
;*********************************************************************************

PWM_ON

	movlw 0x01		;
	movwf time_ON		; 01h -> time_ON

	movlw 0xFF		;
	movwf time_OFF		; FFh -> time_OFF	
	movwf lightUP		; FFh -> lightUP		
	
LIGHT_UP

	movf time_ON, 0		; 
	movwf time1		; time_ON -> time1
	
	movf time_OFF, 0	; 
	movwf time0		; time_OFF -> time0

ON_LOOP

	movf portb, 0		; portb -> W
	iorwf LEDs, 0		; W OR LEDs -> W
	movwf portb		; W -> portb

LED_ON	

	nop
	nop
	nop
	nop
	nop
	
	decfsz time1, 1		; time1 = time1 - 1			
	goto LED_ON

OFF_LOOP

	movf portb, 0		; portb -> W
	xorwf LEDs, 0		; W XOR LEDs -> W
	movwf portb		; W -> portb

LED_OFF	
	
	nop
	nop
	nop
	nop
	nop
	
	decfsz time0, 1		; time0 = time0 - 1	
	goto LED_OFF

	incf time_ON, 1		; time_ON = time_ON + 1
	decf time_OFF, 1	; time_OFF = time_OFF - 1

	decfsz lightUP
	goto LIGHT_UP

	movf portb, 0		; portb -> W
	iorwf LEDs, 0		; W OR LEDs -> W
	movwf portb		; W -> portb

	
	return


;*********************************************************************************
;** PWM_OFF sammuttaa LEDit hitaasti						**
;*********************************************************************************


PWM_OFF

	movlw 0x01		;
	movwf time_OFF		; 01h -> time_OFF

	movlw 0xFF		;
	movwf time_ON		; FFh -> time_ON	
	movwf lightDOWN		; FFh -> lightDOWN		
	
LIGHT_DOWN

	movf time_ON, 0		; 
	movwf time1		; time_ON -> time1
	
	movf time_OFF, 0	; 
	movwf time0		; time_OFF -> time0

OFF_LOOP_2

	movf portb, 0		; portb -> W
	xorwf LEDs, 0		; W XOR LEDs -> W
	movwf portb		; W -> portb

LED_OFF_2	

	nop
	nop
	nop
	nop
	nop
	
	decfsz time0, 1		; time0 = time0 - 1			
	goto LED_OFF_2

ON_LOOP_2

	movf portb, 0		; portb -> W
	iorwf LEDs, 0		; W OR LEDs -> W
	movwf portb		; W -> portb

LED_ON_2	
	
	nop
	nop
	nop
	nop
	nop
	
	decfsz time1, 1		; time1 = time1 - 1	
	goto LED_ON_2

	incf time_OFF, 1	; time_OFF = time_OFF + 1
	decf time_ON, 1		; time_ON = time_ON - 1

	decfsz lightDOWN
	goto LIGHT_DOWN

	movf portb, 0		; portb -> W
	xorwf LEDs, 0		; W XOR LEDs -> W
	movwf portb		; W -> portb
	
	return

;*********************************************************************************
;**	MAIN silmukka, jossa sytytellään LEDejä			                **
;**										**
;**	bsf portb,LRED		; Vasen punainen syttyy				**
;**	bsf portb,LGREEN	; Vasen vihreä syttyy				**
;**	bsf portb,LBLUE		; Vasen sininen syttyy				**
;**										**
;**	bcf portb,LRED		; Vasen punainen sammuu				**
;**	bcf portb,LGREEN	; Vasen vihreä sammuu				**
;**	bcf portb,LBLUE		; Vasen sininen sammuu				**
;**										**
;**	bsf portb,RRED		; Oikea punainen syttyy				**
;**	bsf portb,RGREEN	; Oikea vihreä syttyy				**
;**	bsf portb,RBLUE		; Oikea sininen syttyy				**
;**										**
;**	bcf portb,RRED		; Oikea punainen sammuu				**
;**	bcf portb,RGREEN	; Oikea vihreä sammuu				**
;**	bcf portb,RBLUE		; Oikea sininen sammuu				**
;**										**
;*********************************************************************************

MAIN

	call VIIVE
	call VIIVE
	
	movlw 0x09
	movwf LEDs		; Punainen & Punainen

	call PWM_ON
	call VIIVE

	movlw 0x09
	movwf LEDs
	
	call PWM_OFF
	call VIIVE
	
	movlw 0x12
	movwf LEDs		; Vihreä & Vihreä

	call PWM_ON
	call VIIVE
	
	movlw 0x12
	movwf LEDs
	
	call PWM_OFF
	call VIIVE

	movlw 0x24
	movwf LEDs		; Sininen & Sininen
	
	call PWM_ON
	call VIIVE
		
	movlw 0x24
	movwf LEDs
		
	call PWM_OFF
	call VIIVE
		
; PUNAINEN & PUNAINEN

	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,RRED		; Oikea punainen syttyy

	call VIIVE

	movlw 0x24
	movwf LEDs		; Sininen & Sininen
	
	call PWM_ON

	call VIIVE
	call VIIVE
	
	movlw 0x24
	movwf LEDs
		
	call PWM_OFF
	
	call VIIVE
	
	bcf portb,LRED		; Vasen punainen sammuu
	bcf portb,RRED		; Oikea punainen sammuu

; KELTAINEN & pimeä

	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,LGREEN	; Vasen vihreä syttyy
	
	call VIIVE

	bcf portb,LGREEN	; Vasen vihreä sammuu

; LILA & pimeä
	
	bsf portb,LBLUE		; Vasen sininen syttyy

	call VIIVE
	
	bcf portb,LRED		; Vasen punainen sammuu

; TURKOOSI & pimeä

	bsf portb,LGREEN	; Vasen vihreä syttyy
	
	call VIIVE

	bcf portb,LGREEN	; Vasen vihreä sammuu
	bcf portb,LBLUE		; Vasen sininen sammuu
	
; VALKOINEN & pimeä

	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,LGREEN	; Vasen vihreä syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy
	
	call VIIVE
	
	bcf portb,LRED		; Vasen punainen sammuu
	bcf portb,LGREEN	; Vasen vihreä sammuu
	bcf portb,LBLUE		; Vasen sininen sammuu	

; pimeä & KELTAINEN

	bsf portb,RRED		; Oikea punainen syttyy
	bsf portb,RGREEN	; Oikea vihreä syttyy
	
	call VIIVE

	bcf portb,RGREEN	; Oikea vihreä sammuu	

; pimeä & LILA
	
	bsf portb,RBLUE		; Oikea sininen syttyy

	call VIIVE
	
	bcf portb,RRED		; Oikea punainen sammuu

; pimeä & TURKOOSI

	bsf portb,RGREEN	; Oikea vihreä syttyy
	
	call VIIVE

	bcf portb,RGREEN	; Oikea vihreä sammuu
	bcf portb,RBLUE		; Oikea sininen sammuu

; pimeä & VALKOINEN

	bsf portb,RRED		; Oikea punainen syttyy
	bsf portb,RGREEN	; Oikea vihreä syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE
	
	bcf portb,RRED		; Oikea punainen sammuu
	bcf portb,RGREEN	; Oikea vihreä sammuu
	bcf portb,RBLUE		; Oikea sininen sammuu	

; PUNAINEN & PUNAINEN

	movlw 0x60		; 
	movwf LED_delay		; 60h -> LED_delay

	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,RRED		; Oikea punainen syttyy
	
	call VIIVE

	bcf portb,LRED		; Vasen punainen sammuu
	bcf portb,RRED		; Oikea punainen sammuu

; VALKOINEN & VALKOINEN

	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,LGREEN	; Vasen vihreä syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy
	
	bsf portb,RRED		; Oikea punainen syttyy
	bsf portb,RGREEN	; Oikea vihreä syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE
	
	bcf portb,LRED		; Vasen punainen sammuu
	bcf portb,LGREEN	; Vasen vihreä sammuu
	bcf portb,LBLUE		; Vasen sininen sammuu	
	
	bcf portb,RRED		; Oikea punainen sammuu
	bcf portb,RGREEN	; Oikea vihreä sammuu
	bcf portb,RBLUE		; Oikea sininen sammuu	

; PUNAINEN & PUNAINEN

	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,RRED		; Oikea punainen syttyy
	
	call VIIVE

	bcf portb,LRED		; Vasen punainen sammuu
	bcf portb,RRED		; Oikea punainen sammuu

; VALKOINEN & VALKOINEN

	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,LGREEN	; Vasen vihreä syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy
	
	bsf portb,RRED		; Oikea punainen syttyy
	bsf portb,RGREEN	; Oikea vihreä syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE
	
	bcf portb,LRED		; Vasen punainen sammuu
	bcf portb,LGREEN	; Vasen vihreä sammuu
	bcf portb,LBLUE		; Vasen sininen sammuu	
	
	bcf portb,RRED		; Oikea punainen sammuu
	bcf portb,RGREEN	; Oikea vihreä sammuu
	bcf portb,RBLUE		; Oikea sininen sammuu	

; PUNAINEN & PUNAINEN

	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,RRED		; Oikea punainen syttyy
	
	call VIIVE

	bcf portb,LRED		; Vasen punainen sammuu
	bcf portb,RRED		; Oikea punainen sammuu

; VALKOINEN & VALKOINEN

	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,LGREEN	; Vasen vihreä syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy
	
	bsf portb,RRED		; Oikea punainen syttyy
	bsf portb,RGREEN	; Oikea vihreä syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE
	
	bcf portb,LRED		; Vasen punainen sammuu
	bcf portb,LGREEN	; Vasen vihreä sammuu
	bcf portb,LBLUE		; Vasen sininen sammuu	
	
	bcf portb,RRED		; Oikea punainen sammuu
	bcf portb,RGREEN	; Oikea vihreä sammuu
	bcf portb,RBLUE		; Oikea sininen sammuu	

; PUNAINEN & PUNAINEN

	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,RRED		; Oikea punainen syttyy
	
	call VIIVE

	bcf portb,LRED		; Vasen punainen sammuu
	bcf portb,RRED		; Oikea punainen sammuu

; VALKOINEN & VALKOINEN

	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,LGREEN	; Vasen vihreä syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy
	
	bsf portb,RRED		; Oikea punainen syttyy
	bsf portb,RGREEN	; Oikea vihreä syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE
	
	bcf portb,LRED		; Vasen punainen sammuu
	bcf portb,LGREEN	; Vasen vihreä sammuu
	bcf portb,LBLUE		; Vasen sininen sammuu	
	
	bcf portb,RRED		; Oikea punainen sammuu
	bcf portb,RGREEN	; Oikea vihreä sammuu
	bcf portb,RBLUE		; Oikea sininen sammuu
	
; PUNAINEN & PUNAINEN

	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,RRED		; Oikea punainen syttyy
	
	call VIIVE

	bcf portb,LRED		; Vasen punainen sammuu
	bcf portb,RRED		; Oikea punainen sammuu

; VALKOINEN & VALKOINEN

	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,LGREEN	; Vasen vihreä syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy
	
	bsf portb,RRED		; Oikea punainen syttyy
	bsf portb,RGREEN	; Oikea vihreä syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE
	
	bcf portb,LRED		; Vasen punainen sammuu
	bcf portb,LGREEN	; Vasen vihreä sammuu
	bcf portb,LBLUE		; Vasen sininen sammuu	
	
	bcf portb,RRED		; Oikea punainen sammuu
	bcf portb,RGREEN	; Oikea vihreä sammuu
	bcf portb,RBLUE		; Oikea sininen sammuu
	
; LILA & TURKOOSI

	movlw 0x40		; 
	movwf LED_delay		; 40h -> LED_delay
	
	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy

	bsf portb,RGREEN	; Oikea vihreä syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE

	bcf portb,LRED		; Vasen punainen sammuu	
	bcf portb,LBLUE		; Vasen sininen sammuu
	
	bcf portb,RGREEN	; Oikea vihreä sammuu
	bcf portb,RBLUE		; Oikea sininen sammuu

; TURKOOSI & LILA
	
	bsf portb,RRED		; Oikea punainen syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy

	bsf portb,LGREEN	; Vasen vihreä syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy
	
	call VIIVE

	bcf portb,RRED		; Oikea punainen sammuu	
	bcf portb,RBLUE		; Oikea sininen sammuu
	
	bcf portb,LGREEN	; Vasen vihreä sammuu
	bcf portb,LBLUE		; Vasen sininen sammuu

; LILA & TURKOOSI
	
	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy

	bsf portb,RGREEN	; Oikea vihreä syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE

	bcf portb,LRED		; Vasen punainen sammuu	
	bcf portb,LBLUE		; Vasen sininen sammuu
	
	bcf portb,RGREEN	; Oikea vihreä sammuu
	bcf portb,RBLUE		; Oikea sininen sammuu	

; TURKOOSI & LILA
	
	bsf portb,RRED		; Oikea punainen syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy

	bsf portb,LGREEN	; Vasen vihreä syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy
	
	call VIIVE

	bcf portb,RRED		; Oikea punainen sammuu	
	bcf portb,RBLUE		; Oikea sininen sammuu
	
	bcf portb,LGREEN	; Vasen vihreä sammuu
	bcf portb,LBLUE		; Vasen sininen sammuu

; LILA & TURKOOSI
	
	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy

	bsf portb,RGREEN	; Oikea vihreä syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE

	bcf portb,LRED		; Vasen punainen sammuu	
	bcf portb,LBLUE		; Vasen sininen sammuu
	
	bcf portb,RGREEN	; Oikea vihreä sammuu
	bcf portb,RBLUE		; Oikea sininen sammuu	

; TURKOOSI & LILA
	
	bsf portb,RRED		; Oikea punainen syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy

	bsf portb,LGREEN	; Vasen vihreä syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy
	
	call VIIVE

	bcf portb,RRED		; Oikea punainen sammuu	
	bcf portb,RBLUE		; Oikea sininen sammuu
	
	bcf portb,LGREEN	; Vasen vihreä sammuu
	bcf portb,LBLUE		; Vasen sininen sammuu

; LILA & TURKOOSI
	
	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy

	bsf portb,RGREEN	; Oikea vihreä syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE

	bcf portb,LRED		; Vasen punainen sammuu	
	bcf portb,LBLUE		; Vasen sininen sammuu
	
	bcf portb,RGREEN	; Oikea vihreä sammuu
	bcf portb,RBLUE		; Oikea sininen sammuu	

; TURKOOSI & LILA
	
	bsf portb,RRED		; Oikea punainen syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy

	bsf portb,LGREEN	; Vasen vihreä syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy
	
	call VIIVE

	bcf portb,RRED		; Oikea punainen sammuu	
	bcf portb,RBLUE		; Oikea sininen sammuu
	
	bcf portb,LGREEN	; Vasen vihreä sammuu
	bcf portb,LBLUE		; Vasen sininen sammuu

; LILA & TURKOOSI
	
	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy

	bsf portb,RGREEN	; Oikea vihreä syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE

	bcf portb,LRED		; Vasen punainen sammuu	
	bcf portb,LBLUE		; Vasen sininen sammuu
	
	bcf portb,RGREEN	; Oikea vihreä sammuu
	bcf portb,RBLUE		; Oikea sininen sammuu	

; TURKOOSI & LILA
	
	bsf portb,RRED		; Oikea punainen syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy

	bsf portb,LGREEN	; Vasen vihreä syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy
	
	call VIIVE

	bcf portb,RRED		; Oikea punainen sammuu	
	bcf portb,RBLUE		; Oikea sininen sammuu
	
	bcf portb,LGREEN	; Vasen vihreä sammuu
	bcf portb,LBLUE		; Vasen sininen sammuu
	
; LILA & TURKOOSI
	
	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy

	bsf portb,RGREEN	; Oikea vihreä syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE

	bcf portb,LRED		; Vasen punainen sammuu	
	bcf portb,LBLUE		; Vasen sininen sammuu
	
	bcf portb,RGREEN	; Oikea vihreä sammuu
	bcf portb,RBLUE		; Oikea sininen sammuu	

; TURKOOSI & LILA
	
	bsf portb,RRED		; Oikea punainen syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy

	bsf portb,LGREEN	; Vasen vihreä syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy
	
	call VIIVE

	bcf portb,RRED		; Oikea punainen sammuu	
	bcf portb,RBLUE		; Oikea sininen sammuu
	
	bcf portb,LGREEN	; Vasen vihreä sammuu
	bcf portb,LBLUE		; Vasen sininen sammuu

; SININEN & SININEN

	movlw 0xC0		;
	movwf LED_delay		; C0h -> LED_delay
	
	bsf portb,LBLUE		; Vasen sininen syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE

	bcf portb,LBLUE		; Vasen sininen sammuu	
	bcf portb,RBLUE		; Oikea sininen sammuu	
	
; VALKOINEN & VALKOINEN

	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,LGREEN	; Vasen vihreä syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy
	
	bsf portb,RRED		; Oikea punainen syttyy
	bsf portb,RGREEN	; Oikea vihreä syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE
	
	bcf portb,LRED		; Vasen punainen sammuu
	bcf portb,LGREEN	; Vasen vihreä sammuu
	bcf portb,LBLUE		; Vasen sininen sammuu	
	
	bcf portb,RRED		; Oikea punainen sammuu
	bcf portb,RGREEN	; Oikea vihreä sammuu
	bcf portb,RBLUE		; Oikea sininen sammuu

; SININEN & SININEN

	movlw 0xA0		;
	movwf LED_delay		; A0 -> LED_delay
	
	bsf portb,LBLUE		; Vasen sininen syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE

	bcf portb,LBLUE		; Vasen sininen sammuu	
	bcf portb,RBLUE		; Oikea sininen sammuu	

; VALKOINEN & VALKOINEN	

	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,LGREEN	; Vasen vihreä syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy
	
	bsf portb,RRED		; Oikea punainen syttyy
	bsf portb,RGREEN	; Oikea vihreä syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE
	
	bcf portb,LRED		; Vasen punainen sammuu
	bcf portb,LGREEN	; Vasen vihreä sammuu
	bcf portb,LBLUE		; Vasen sininen sammuu	
	
	bcf portb,RRED		; Oikea punainen sammuu
	bcf portb,RGREEN	; Oikea vihreä sammuu
	bcf portb,RBLUE		; Oikea sininen sammuu

; SININEN & SININEN

	movlw 0x80		;
	movwf LED_delay		; 80h -> LED_delay
	
	bsf portb,LBLUE		; Vasen sininen syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE

	bcf portb,LBLUE		; Vasen sininen sammuu	
	bcf portb,RBLUE		; Oikea sininen sammuu	

; VALKOINEN & VALKOINEN	

	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,LGREEN	; Vasen vihreä syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy
	
	bsf portb,RRED		; Oikea punainen syttyy
	bsf portb,RGREEN	; Oikea vihreä syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE
	
	bcf portb,LRED		; Vasen punainen sammuu
	bcf portb,LGREEN	; Vasen vihreä sammuu
	bcf portb,LBLUE		; Vasen sininen sammuu	
	
	bcf portb,RRED		; Oikea punainen sammuu
	bcf portb,RGREEN	; Oikea vihreä sammuu
	bcf portb,RBLUE		; Oikea sininen sammuu

; SININEN & SININEN

	movlw 0x60		;
	movwf LED_delay		; 60h -> LED_delay
	
	bsf portb,LBLUE		; Vasen sininen syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE

	bcf portb,LBLUE		; Vasen sininen sammuu	
	bcf portb,RBLUE		; Oikea sininen sammuu	

; VALKOINEN & VALKOINEN	

	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,LGREEN	; Vasen vihreä syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy
	
	bsf portb,RRED		; Oikea punainen syttyy
	bsf portb,RGREEN	; Oikea vihreä syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE
	
	bcf portb,LRED		; Vasen punainen sammuu
	bcf portb,LGREEN	; Vasen vihreä sammuu
	bcf portb,LBLUE		; Vasen sininen sammuu	
	
	bcf portb,RRED		; Oikea punainen sammuu
	bcf portb,RGREEN	; Oikea vihreä sammuu
	bcf portb,RBLUE		; Oikea sininen sammuu

; SININEN & SININEN
	
	movlw 0x40		;
	movwf LED_delay		; 40h -> LED_delay
	
	bsf portb,LBLUE		; Vasen sininen syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE

	bcf portb,LBLUE		; Vasen sininen sammuu	
	bcf portb,RBLUE		; Oikea sininen sammuu	

; VALKOINEN & VALKOINEN	

	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,LGREEN	; Vasen vihreä syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy
	
	bsf portb,RRED		; Oikea punainen syttyy
	bsf portb,RGREEN	; Oikea vihreä syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE
	
	bcf portb,LRED		; Vasen punainen sammuu
	bcf portb,LGREEN	; Vasen vihreä sammuu
	bcf portb,LBLUE		; Vasen sininen sammuu	
	
	bcf portb,RRED		; Oikea punainen sammuu
	bcf portb,RGREEN	; Oikea vihreä sammuu
	bcf portb,RBLUE		; Oikea sininen sammuu	

; SININEN & SININEN

	movlw 0x20		;
	movwf LED_delay		; 20h -> LED_delay
	
	bsf portb,LBLUE		; Vasen sininen syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE

	bcf portb,LBLUE		; Vasen sininen sammuu	
	bcf portb,RBLUE		; Oikea sininen sammuu	

; VALKOINEN & VALKOINEN	

	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,LGREEN	; Vasen vihreä syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy
	
	bsf portb,RRED		; Oikea punainen syttyy
	bsf portb,RGREEN	; Oikea vihreä syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE
	
	bcf portb,LRED		; Vasen punainen sammuu
	bcf portb,LGREEN	; Vasen vihreä sammuu
	bcf portb,LBLUE		; Vasen sininen sammuu	
	
	bcf portb,RRED		; Oikea punainen sammuu
	bcf portb,RGREEN	; Oikea vihreä sammuu
	bcf portb,RBLUE		; Oikea sininen sammuu

; SININEN & SININEN

	movlw 0x40		;
	movwf LED_delay		; 40h -> LED_delay
	
	bsf portb,LBLUE		; Vasen sininen syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE

	bcf portb,LBLUE		; Vasen sininen sammuu	
	bcf portb,RBLUE		; Oikea sininen sammuu	

; VALKOINEN & VALKOINEN	

	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,LGREEN	; Vasen vihreä syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy
	
	bsf portb,RRED		; Oikea punainen syttyy
	bsf portb,RGREEN	; Oikea vihreä syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE
	
	bcf portb,LRED		; Vasen punainen sammuu
	bcf portb,LGREEN	; Vasen vihreä sammuu
	bcf portb,LBLUE		; Vasen sininen sammuu	
	
	bcf portb,RRED		; Oikea punainen sammuu
	bcf portb,RGREEN	; Oikea vihreä sammuu
	bcf portb,RBLUE		; Oikea sininen sammuu

; SININEN & SININEN

	movlw 0x60		;
	movwf LED_delay		; 60h -> LED_delay
	
	bsf portb,LBLUE		; Vasen sininen syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE

	bcf portb,LBLUE		; Vasen sininen sammuu	
	bcf portb,RBLUE		; Oikea sininen sammuu	

; VALKOINEN & VALKOINEN	

	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,LGREEN	; Vasen vihreä syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy
	
	bsf portb,RRED		; Oikea punainen syttyy
	bsf portb,RGREEN	; Oikea vihreä syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE
	
	bcf portb,LRED		; Vasen punainen sammuu
	bcf portb,LGREEN	; Vasen vihreä sammuu
	bcf portb,LBLUE		; Vasen sininen sammuu	
	
	bcf portb,RRED		; Oikea punainen sammuu
	bcf portb,RGREEN	; Oikea vihreä sammuu
	bcf portb,RBLUE		; Oikea sininen sammuu	

; SININEN & SININEN

	movlw 0x80		;
	movwf LED_delay		; 80h -> LED_delay
	
	bsf portb,LBLUE		; Vasen sininen syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE

	bcf portb,LBLUE		; Vasen sininen sammuu	
	bcf portb,RBLUE		; Oikea sininen sammuu	
	
; VALKOINEN & VALKOINEN

	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,LGREEN	; Vasen vihreä syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy
	
	bsf portb,RRED		; Oikea punainen syttyy
	bsf portb,RGREEN	; Oikea vihreä syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE
	
	bcf portb,LRED		; Vasen punainen sammuu
	bcf portb,LGREEN	; Vasen vihreä sammuu
	bcf portb,LBLUE		; Vasen sininen sammuu	
	
	bcf portb,RRED		; Oikea punainen sammuu
	bcf portb,RGREEN	; Oikea vihreä sammuu
	bcf portb,RBLUE		; Oikea sininen sammuu
	
; SININEN & SININEN

	movlw 0xA0		;
	movwf LED_delay		; A0h -> LED_delay
	
	bsf portb,LBLUE		; Vasen sininen syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE

	bcf portb,LBLUE		; Vasen sininen sammuu	
	bcf portb,RBLUE		; Oikea sininen sammuu	

; VALKOINEN & VALKOINEN	

	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,LGREEN	; Vasen vihreä syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy
	
	bsf portb,RRED		; Oikea punainen syttyy
	bsf portb,RGREEN	; Oikea vihreä syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE
	
	bcf portb,LRED		; Vasen punainen sammuu
	bcf portb,LGREEN	; Vasen vihreä sammuu
	bcf portb,LBLUE		; Vasen sininen sammuu	
	
	bcf portb,RRED		; Oikea punainen sammuu
	bcf portb,RGREEN	; Oikea vihreä sammuu
	bcf portb,RBLUE		; Oikea sininen sammuu

; SININEN & SININEN

	movlw 0xC0		;
	movwf LED_delay		; C0h -> LED_delay
	
	bsf portb,LBLUE		; Vasen sininen syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE

	bcf portb,LBLUE		; Vasen sininen sammuu	
	bcf portb,RBLUE		; Oikea sininen sammuu	

; VALKOINEN & VALKOINEN	

	bsf portb,LRED		; Vasen punainen syttyy
	bsf portb,LGREEN	; Vasen vihreä syttyy
	bsf portb,LBLUE		; Vasen sininen syttyy
	
	bsf portb,RRED		; Oikea punainen syttyy
	bsf portb,RGREEN	; Oikea vihreä syttyy
	bsf portb,RBLUE		; Oikea sininen syttyy
	
	call VIIVE
	
	bcf portb,LRED		; Vasen punainen sammuu
	bcf portb,LGREEN	; Vasen vihreä sammuu
	bcf portb,LBLUE		; Vasen sininen sammuu	
	
	bcf portb,RRED		; Oikea punainen sammuu
	bcf portb,RGREEN	; Oikea vihreä sammuu
	bcf portb,RBLUE		; Oikea sininen sammuu
	
	
	
	movlw 0xFF		;
	movwf LED_delay		; FFh -> LED_delay
	
	goto MAIN


	END