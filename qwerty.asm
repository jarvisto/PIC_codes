'';**************************************
;**	PIC16F84
;**	VERSIO: 1.5-0	15.4.2003
;**	
;**	OSC=HS, WDT=OFF, PWRT=OFF, CP=OFF
;**	
;** - RA0	4555 A	out
;** - RA1	4555 B	out
;** - RA2	4555 C	out
;** - RA3	row 4	in
;** - RA4	row 3	in
;**	- RB0
;**	- RB1	character bit 1	out
;**	- RB2	character bit 2	out
;**	- RB3	character bit 3 out
;**	- RB4	character bit 4 out
;**	- RB5	character bit 5 out
;**	- RB6	row 2	in
;**	- RB7	row 1	in
;**************************************

	LIST p=16F84	   	; M‰‰ritell‰‰n k‰‰nt‰j‰lle prosessori
	include <P16F84.inc>	; M‰‰ritet‰‰n kaikki rekisterit ja bitit 

START

; Muistipaikat

column		equ	0x0C	; 
pwm_out		equ	0x0D	; 
pwm		equ	0x0E	; 
direction	equ	0x0F	; 
counter		equ	0x10	; 
down_cnt	equ	0x11	; 
up_cnt		equ	0x12	; 
up_aux		equ	0x13	; 
neutral		equ	0x14	; 
blink		equ	0x15	; 
wait_up		equ	0x16	; 

; Rekisterit

status		equ	0x03	; STATUS-rekisteri
porta		equ	0x05	; PORTA-rekisteri
portb		equ	0x06	; PORTB-rekisteri
trisa		equ	0x85	; TRISA-rekisteri
trisb		equ	0x86	; TRISB-rekisteri
opreg		equ	0x81	; OPTION_REG rekisteri 
intcon		equ	0x0B	; INTCON rekisteri

; Bitit

pank		equ	0x05	; REGISTER BANK SELECT BIT
int		equ	0x06	; INTEDG bitti OPTION_REG rekisteriss‰
inte		equ	0x04	; INTE-bitti INTCON-rekisteriss‰
intf		equ	0x01	; INTF-bitti INTCON-rekisteriss‰
gie		equ	0x07	; GIE-bitti INTCON-rekisteriss‰
zero		equ	0x02	; STATUS-rekisterin ZERO-bitti
row1		equ	0x07	; RB7 rivi 1
row2		equ	0x06	; RB6 rivi 2 
row3		equ	0x04	; RA4 rivi 3
row4		equ	0x03	; RA3 rivi 4


	ORG 0000		; Reset vektori
	goto INIT

	ORG 0004		; Keskeytys vektori
	goto PULSE

	ORG 0008		; Ohjelmakoodi alkaa

;**************************************
;** INIT alustaa PIC:n rekisterit ja muistipaikat
;**************************************

INIT
	clrf porta		; Nollaa portin A
	clrf portb		; Nollaa portin B
	bsf status,pank		; Bank 1
	movlw b'11000'		
	movwf trisa		; RA0-2 output, RA4,RA5 input
	movlw b'11000001'
	movwf trisb		; RB0, RB6, RB7 input, RB1-5 output
	bcf status,pank		; Bank 0
	
;**************************************
;**	MAIN silmukka
;**************************************

MAIN
	
	goto MAIN	

;**************************************
;**
;**************************************

	movlw 0x00
	movwf column
COL
	movf column, 0		; column -> W
	movwf porta		; W -> portA
	
	btfsc portb, row1
	xorlw 0x07		; row 1 = "00"
	
	btfsc portb, row2
	iorlw 0x08		; row 2 = "01"
	
	btfsc porta, row3
	iorlw 0x10		; row 3 = "10"		
	
	btfsc porta, row4
	iorlw 0x18		; row 4 = "11"
	
	incf column, 1		; column = column + 1
	
	movf column, 0		; column -> W
	xorlw 0x06
	btfss status, zero
	goto COL

ROW1

	xorlw 0x07
	
ROW2

	iorlw 0x08
	
ROW3

	iorlw 0x10
	
ROW4

	iorlw 0x18

	
	
	;*********************************************************************************
;** PWM muodostaa l‰htev‰n PWM-signaalin. Aliohjelmassa kuluva aika on aina     **
;** haarautumisista riippumatta 14 kellojaksoa.					**
;*********************************************************************************

PWM
	btfss direction,forw	; Tarkistetaan, onko suunta eteen vai taakse
	goto BACKWARD
FORWARD
	decfsz pwm_frame, 1	; PWM_FRAME = PWM_FRAME - 1
	goto PWM_OUT_0		; Hyppy PWM_OUT_0 jos PWM_FRAME <> 0 
	movlw 0x64
	movwf pwm_frame		; PWM_FRAME = 100D (PWM:n erottelutarkkuus)
	movf pwm, 0		; PWM -> W
	movwf pwm_out		; W -> PWM_OUT
	bcf porta,pwm_back	; PWM_BACK  = "0"
	bsf porta,pwm_back2	; PWM_BACK2 = "1"
	nop
	nop
	return
PWM_OUT_0	
	movf pwm_out, 1		; PWM_OUT = PWM_OUT (Z)
	btfsc status,zero
	goto END_PWM_0		; Hyppy END_PWM_0 jos PWM_OUT = 0
	decf pwm_out, 1		; PWM_OUT = PWM_OUT - 1	
	bsf porta,pwm_forw	; PWM_FORW  = "1"
	bcf porta,pwm_forw2	; PWM_FORW2 = "0"
	nop
	return

END_PWM_0
	bcf porta,pwm_forw	; PWM_FORW  = "0"
	bsf porta,pwm_forw2	; PWM_FORW2 = "1"
	nop
	return
	
BACKWARD
	decfsz pwm_frame, 1	; PWM_FRAME = PWM_FRAME - 1
	goto PWM_OUT_1		; Hyppy PWM_OUT_1 jos PWM_FRAME <> 0
	movlw 0x64
	movwf pwm_frame		; PWM_FRAME = 100D (PWM:n erottelutarkkuus)
	movf pwm, 0		; PWM -> W
	movwf pwm_out		; W -> PWM_OUT
	bcf porta,pwm_forw	; PWM_FORW  = "0"
	bsf porta,pwm_forw2	; PWM_FORW2 = "1"
	nop
	return
PWM_OUT_1	
	movf pwm_out, 1		; PWM_OUT = PWM_OUT (Z)
	btfsc status,zero	; Jos Z-lippu on "1" -> hyppy END_PWM_1
	goto END_PWM_1		; Hyppy END_PWM_1 jos PWM_OUT = 0
	decf pwm_out, 1		; PWM_OUT = PWM_OUT -1
	bsf porta,pwm_back	; PWM_BACK  = "1"
	bcf porta,pwm_back2	; PWM_BACK2 = "0"
	return
	
END_PWM_1
	bcf porta,pwm_back	; PWM_BACK  = "0"
	bsf porta,pwm_back2	; PWM_BACK2 = "1"
	return

;*********************************************************************************
;**	PULSE ottaa servopulssin sis‰‰n ja laskee sen pituuden.			**
;**	- Aliohjelma, johon haaraudutaan servopulssin tekem‰ll‰ keskeytyksell‰	**
;**	- Ensin muodostetaan 1ms viive, jolla erotetaan tahdistusosa		**
;**	- Lasketaan 90->0, josta saadaan pulssinpituus jos alueella 1.0-1.5ms	**
;**	- Lasketaan 0->90, josta saadaan pulssinpituus jos alueella 1.5-2.0ms	**
;*********************************************************************************		


PULSE

	movlw 0xCD		; *****> KASVATETTU ARVOA
	movwf counter		; Asetetaan 1ms viivekierrosten m‰‰r‰		 
	movlw 0x5A		; *****> PIENENNETTY ARVOA		
	movwf down_cnt		; DOWN_CNT = 90	
	movlw 0x00
	movwf up_cnt		; UP_CNT = 0
	movlw 0x5A		; *****> PIENENNETTY ARVOA
	movwf up_aux		; UP_AUX = 90

	clrwdt			; Watchdogin nollaus
	movlw b'010'
	movwf opreg		; WDT esijakajan asetus
	
	bsf direction,full	; FULL-bitti "1"
	bcf direction,mid	; MID-bitti "0"
	movlw 0x32		
	movwf neutral		; NEUTRAL = 50D (tyhj‰ liike sauvan keskialueella)
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	
LOOP
	call PWM		; K‰yd‰‰n PWM:ss‰ p‰ivitt‰m‰ss‰ l‰htˆj‰
	nop
	nop
	nop
	nop
	nop
	nop
	decfsz counter, 1	
	goto LOOP

COUNT_DOWN
	btfsc portb,input	; Tutkitaan RB0-tila (servopulssi sis‰‰n) *** 1.5-0 ***
	goto PULSE_OFF_0	; Jos RB0-tulo "0" -> hyppy		
	call PWM		; Kutsutaan PWM-aliohjelmaa
	bcf direction,full	; FULL-bitti "0"
	nop
	decfsz down_cnt, 1	; DOWN_CNT = DOWN_CNT - 1
	goto COUNT_DOWN		; Hyppy COUNT_DOWN, jos DOWN_CNT <> 0
	bsf direction,mid	; MID-bitti "1"

MIDDLE
	decfsz neutral,1	; Looppi tekee sauvan keskialueelle 'tyhj‰‰'
	goto MIDDLE		; liikett‰. 25D = yksi steppi.
	
COUNT_UP
	btfsc portb,input	; Tutkitaan RB0-tila (servopulssi sis‰‰n) *** 1.5-0 ***
	goto PULSE_OFF_1	; Jos RB0-tulo "0" -> hyppy
	call PWM		; Kutsutaan PWM-aliohjelmaa
	bcf direction,mid	; MID-bitti "0"
	incf up_cnt, 1		; UP_CNT = UP_CNT + 1
	decfsz up_aux, 1	; UP_AUX = UP_AUX - 1
	goto COUNT_UP		; Hyppy COUNT_UP, jos UP_AUX <> 0
	bsf direction,full	; FULL-bitti "1"

PULSE_OFF_1
	bsf direction,forw	; Suuntabitti FORW = "1"
	btfsc portb,reverse	; Jos RB1-tulo "0" ei reverse‰
	bcf direction,forw	; Suuntabitti FORW = "0" REVERSE
	movf up_cnt, 0		; UP_CNT -> W
	movwf pwm		; W -> PWM
	bcf intcon,intf		; Nollataan keskeytyksest‰ kertova INTF-bitti
	goto LED
	
PULSE_OFF_0
	bcf direction,forw	; Suuntabitti FORW = "0"
	btfsc portb,reverse	; Jos RB1-tulo "0" ei reverse‰
	bsf direction,forw	; Suuntabitti FORW = "1" REVERSE
	movf down_cnt, 0	; DOWN_CNT -> W
	movwf pwm		; W -> PWM
	bcf intcon,intf		; Nollataan keskeytyksest‰ kertova INTF-bitti

LED
	bcf portb,led_forw	; LED_FORW = "0"
	bcf portb,led_back	; LED_BACK = "0"
	btfsc direction,mid
	goto LED_0		; Hyppy, jos MID-bitti "1"
	btfsc direction,forw
	bsf portb,led_forw	; LED_FORW = "1"
	btfss direction,forw
	bsf portb,led_back	; LED_BACK = "1"
	btfss direction,full
	goto LED_0		; Hyppy, jos FULL-bitti "0"
	decfsz blink, 1
	retfie			; Paluu, kun vilkunta k‰ynniss‰
	movlw 0x08
	movwf blink		; Asetetaan ledien vilkkumisnopeus
	movlw 0x20		; W-rekisteriin "00100000"
	xorwf portb, 1		; W - XOR - PORTB -> PORTB
	retfie

LED_0
	bcf portb,led_comm	; LED_COMM = "0"
	retfie
	
	END