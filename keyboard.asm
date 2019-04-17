;**************************************
;**	PIC16F84 12MHz
;**	VERSIO: 1.0-0  30.9.2017
;**	
;**	OSC=HS, WDT=OFF, PWRT=OFF, CP=OFF
;**	
;** 	- RA0	4555 A	out
;** 	- RA1	4555 B	out
;** 	- RA2	4555 C	out
;** 	- RA3	row 4	in
;** 	- RA4	row 3	in
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

column		equ	0x0C	; Sarakelaskuri
char		equ	0x0D	; Painike tieto = viisi alinta bitti‰
char_out	equ	0x0E	;  
push		equ	0x0F	; 
counterA	equ	0x10	; 
counterB	equ	0x11	; 
flags		equ	0x12	; Ohjausbittej‰ sis‰lt‰v‰ muistipaikka

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
send		equ 0x00	; L‰hetys k‰ynniss‰ "1"


	ORG 0000		; Reset vektori
	goto INIT

	ORG 0004		; Keskeytys vektori
	goto INIT

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
	
	clrf intcon
	clrf char
	clrf char_out
	clrf column
	
	movlw 0x0A
	movwf push
	movwf hold
	
;**************************************
;**	MAIN silmukka
;**************************************

MAIN
	call SCAN		; Skannaa n‰pp‰imistˆ‰
	call MODI		; N‰pp‰imistˆlt‰ tuleva koodi -> haluttu koodi
	call WR_OUT		; Kirjoitetaan n‰pp‰indata ulos
	call HOLD_BT	; Yksi merkki yhdell‰ painalluksella
	
	goto MAIN	

;**************************************
;** SCAN aliohjelma skannaa n‰pp‰imistˆ‰
;**************************************

SCAN
	
	movf column, 0
	movwf porta		; Asetetaan sarake
	
	nop			; 5us viive, jotta CMOS 4555 ehtii asettaa
	nop			; sarakeosoitteen oikein.
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	
	btfsc portb, row1
	goto ROW1		; row 1 = "00"
	
	btfsc portb, row2
	goto ROW2		; row 2 = "01"
	
	btfsc porta, row3
	goto ROW3		; row 3 = "10"		
	
	btfsc porta, row4
	goto ROW4		; row 4 = "11"
	
	incf column, 1		; column = column + 1
	
	movf column, 0		; column -> W
	xorlw 0x06
	btfss status, zero
	goto SCAN
	
	clrf column
	
	return

ROW1
	decfsz push, 1		; push = push - 1
	return

	movf column, 0
	movwf char		; W -> char
	
	clrf column
	
	return
	
ROW2
	decfsz push, 1		; push = push - 1
	return
	
	iorlw 0x08
	movwf char
	
	clrf column
	
	return
	
ROW3
	decfsz push, 1		; push = push - 1
	return
	
	iorlw 0x10
	movwf char
	
	clrf column
	
	return
	
ROW4
	decfsz push, 1		; push = push - 1
	return
	
	iorlw 0x18
	movwf char
	
	clrf column
	
	return
	

;**************************************
;** MODI aliohjelma n‰pp‰imistˆlt‰ tuleva koodi -> haluttu koodi
;** 
;**************************************

MODI

	movf push, 1		; push -> push (Z)
	btfss status, zero	; onko push "00" -> suoritetaan aliohjelma
	return

	btfsc flags, send	; Tarkistetaan onko l‰hetys jo k‰ynniss‰	
	return

	movlw 0x0A
	movwf push			; Alustetaan push-muuttuja

	bsf flags, send		; l‰hetys k‰ynniss‰	

ASTERISK_L

	movf char, 1		; char -> char (Z)
	btfss status, zero
	goto ZERO_L
	
	movlw 0xBC		; "1x11110x" '*'
	movwf char_out
	
	return

ZERO_L	
	movf char, 0
	xorlw 0x01
	btfss status, zero
	goto HASH_L
	
	movlw 0x80		; "1x00000x" '0'
	movwf char_out
	
	return
	
HASH_L
	movf char, 0
	xorlw 0x02
	btfss status, zero
	goto ASTERISK_R
	
	movlw 0xBC		; "1x11110x" '#'
	movwf char_out
	
	return

ASTERISK_R

	movf char, 0
	xorlw 0x03
	btfss status, zero
	goto ZERO_R
	
	movlw 0xBC		; "1x11110x" '*'
	movwf char_out
	
	return

ZERO_R
	movf char, 0
	xorlw 0x04
	btfss status, zero
	goto HASH_R
	
	movlw 0xBC		; "1x11110x" '0'
	movwf char_out
	
	return
	
HASH_R
	movf char, 0
	xorlw 0x05
	btfss status, zero
	goto SEVEN_L
	
	movlw 0xBC		; "1x11110x" '#'
	movwf char_out
	
	return

SEVEN_L
	movf char, 0
	xorlw 0x08
	btfss status, zero
	goto EIGHT_L
	
	movlw 0x8E		; "1x00111x" '7'
	movwf char_out
	
	return
	
EIGHT_L
	movf char, 0
	xorlw 0x09
	btfss status, zero
	goto NINE_L
	
	movlw 0x90		; "1x01000x" '8'
	movwf char_out
	
	return
	
NINE_L
	movf char, 0
	xorlw 0x0A
	btfss status, zero
	goto SEVEN_R
	
	movlw 0x92		; "1x01001x" '9'
	movwf char_out
	
	return
	
SEVEN_R
	movf char, 0
	xorlw 0x0B
	btfss status, zero
	goto EIGHT_R
	
	movlw 0xBC		; "1x11110x" '7'
	movwf char_out
	
	return
	
EIGHT_R
	movf char, 0
	xorlw 0x0C
	btfss status, zero
	goto NINE_R
	
	movlw 0xBC		; "1x11110x" '8'
	movwf char_out
	
	return
	
NINE_R
	movf char, 0
	xorlw 0x0D
	btfss status, zero
	goto FOUR_L
	
	movlw 0xBC		; "1x11110x" '9'
	movwf char_out
	
	return
	
FOUR_L
	movf char, 0
	xorlw 0x10
	btfss status, zero
	goto FIVE_L
	
	movlw 0x88		; "1x00100x" '4'
	movwf char_out
	
	return
	
FIVE_L
	movf char, 0
	xorlw 0x11
	btfss status, zero
	goto SIX_L
	
	movlw 0x8A		; "1x00101x" '5'
	movwf char_out
	
	return
	
SIX_L
	movf char, 0
	xorlw 0x12
	btfss status, zero
	goto FOUR_R
	
	movlw 0x8C		; "1x00110x" '6'
	movwf char_out
	
	return
	
FOUR_R
	movf char, 0
	xorlw 0x13
	btfss status, zero
	goto FIVE_R
	
	movlw 0x9A		; "1x01101x" 'D'
	movwf char_out
	
	return
	
FIVE_R
	movf char, 0
	xorlw 0x14
	btfss status, zero
	goto SIX_R
	
	movlw 0x9C		; "1x01110x" 'E'
	movwf char_out
	
	return
	
SIX_R
	movf char, 0
	xorlw 0x15
	btfss status, zero
	goto ONE_L
	
	movlw 0x9E		; "1x01111x" 'F'
	movwf char_out

	return
	
ONE_L
	movf char, 0
	xorlw 0x18
	btfss status, zero
	goto TWO_L
	
	movlw 0x82		; "1x00001x" '1'
	movwf char_out
	
	return
	
TWO_L
	movf char, 0
	xorlw 0x19
	btfss status, zero
	goto THREE_L
	
	movlw 0x84		; "1x00010x" '2'
	movwf char_out
	
	return
	
THREE_L
	movf char, 0
	xorlw 0x1A
	btfss status, zero
	goto ONE_R
	
	movlw 0x86		; "1x00011x" '3'
	movwf char_out
	
	return
	
ONE_R
	movf char, 0
	xorlw 0x1B
	btfss status, zero
	goto TWO_R
	
	movlw 0x94		; "1x01010x" 'A'
	movwf char_out
	
	return
	
TWO_R
	movf char, 0
	xorlw 0x1C
	btfss status, zero
	goto THREE_R
	
	movlw 0x96		; "1x01011x" 'B'
	movwf char_out
	
	return
	
THREE_R
	movf char, 0
	xorlw 0x1D
	btfss status, zero
	goto BT_END
	
	movlw 0x98		; "1x01100x" 'C'
	movwf char_out
	
	return
	
BT_END
	
	return

;**************************************
;** WR_OUT aliohjelma ohjaa ulos l‰htev‰‰ dataa
;** char_out <> "00H" -> suoritetaan aliohjelma
;**************************************	

WR_OUT	
	
	movf char_out, 1	; char_out = char_out (Z)
	btfsc status, zero
	return
	
	movlw 0x3E
	movwf portb		; ready merkki l‰htˆˆn
	
RDY_D
	movlw 0xFF
	movwf counterA
A1	
	movlw 0xFF
	movwf counterB
A2	
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	
	decfsz counterB, 1
	goto A2
	decfsz counterA, 1
	goto A1
	
	movf char_out, 0
	movwf portb		; n‰pp‰indata l‰htˆˆn
	
DATA_D
	movlw 0xFF
	movwf counterA
A3	
	movlw 0xFF
	movwf counterB
A4
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	decfsz counterB, 1
	goto A4
	decfsz counterA, 1
	goto A3

	clrf portb
	clrf char
	clrf char_out

	return

HOLD_BT

	movf char_out, 1	; char_out = char_out (Z)
	btfss status, zero
	return
	
	decfsz hold, 1		; hold = hold - 1
	
	movf hold, 1		; hold -> hold (Z)
	btfss status, zero	
	return
	
	bcf flags, send		; l‰hetys loppunut
	
	movlw 0x0A
	movwf hold
	
	return
	
	
	END