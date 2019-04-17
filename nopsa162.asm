;*********************************************************************************
;**	Nopeudens‰‰din 20MHz:n PIC16F628:lle (PWM 2kHz)				**
;**	VERSIO: 1.6-1	27.6.2015						**
;**										**
;**	Kaikki FUSET OFF ( Paitsi WDT ja tarvittaessa CP )			**
;**	Oskillaattoriksi valitaan HS						**
;**										**
;**	- RB0 ottaa sis‰‰n servopulssin						**
;**	- RB1 oikosulkupalikka "0"= palikka paikalla, "1"= ei palikkaa		**
;**	- RB5 ledien katodi							**
;**	- RB6 ledin anodi							**
;**	- RB7 ledin anodi							**
;**	- RA0 ohjaa H-silta p‰‰teasteen 1 ja 3 fetti‰				**
;**	- RA1 ohjaa H-silta p‰‰teasteen 2 ja 4 fetti‰				**
;**										**
;**	- Askelia 90 + 90							**
;**	- Pyykeli paikalla, max pwm 100%					**
;**	- Pyykeli‰ ei paikalla, max pwm 90%					**
;**										**
;**	Ledien toiminta:							**
;**	- S‰hkˆjen kytkenn‰n j‰lkeen molemmat palaa = Ei servopulssia		**
;**	- Kumpikaan ei pala = Moottori SEIS					**
;**	- Toinen palaa = ETEEN/TAAKSE kierrosalueella				**
;**	- Toinen vilkkuu = T‰ysi ETEEN/TAAKSE					**
;**										**
;**	Ohjauksen jyrkkyytt‰ lis‰tty suhteessa ohjauspulssiin, koska sauvan	**
;**	liikealue ei riit‰ t‰yteen kaasuun. Muutetut rivit merkitty *****	**
;**										**
;**	1.6-0 Muutettu koodi toimimaan uudemmassa 16F628 piiriss‰.		**
;**	Muutokset merkitty: *** ver 1.6-0					**
;**										**
;**	1.6-1 Poistettu turhana ulkopuolinen suunnank‰‰nt‰j‰ kytkin		**
;**	Korjattu frame alustus bugi, joka oli tullut jyrkennyksen muutoksessa	**
;**	List‰tty pyykelin vaikutus PWM:‰‰n.					**
;*********************************************************************************

	LIST p=16F628	   	; M‰‰ritell‰‰n k‰‰nt‰j‰lle prosessori
	include <P16F628.inc>	; M‰‰ritet‰‰n kaikki rekisterit ja bitit 
	
START

; Muistipaikat *** ver 1.6-0 alkuos. 0Ch -> 20h

pwm_frame	equ	0x20	; PWM:n kehysrakenteen laskuri
pwm_out		equ	0x21	; l‰htev‰n PWM:n apulaskuri
pwm		equ	0x22	; servopulssin poikkeama keskikohdasta (0-90)
direction	equ	0x23	; Moottorin pyˆrimissuunta
counter		equ	0x24	; Viivelaskuri
down_cnt	equ	0x25	; Alaslaskuri pulssinpituudelle 0-0.5ms
up_cnt		equ	0x26	; Ylˆslaskuri pulssinpituudelle 0.5-1.0ms
up_aux		equ	0x27	; Ylˆslaskurin apulaskuri (laskee alas)
neutral		equ	0x28	; Sauvan keskiasennon viivelaskuri
blink		equ	0x29	; Laskuri ledien vilkuttamiselle
wait_up		equ	0x2A	; Ohjelman aloitusviivelaskuri
frame_le	equ	0x2B	; Talletettu kehyksen pituus

; Rekisterit

status		equ	0x03	; STATUS-rekisteri
porta		equ	0x05	; PORTA-rekisteri
portb		equ	0x06	; PORTB-rekisteri
trisa		equ	0x85	; TRISA-rekisteri
trisb		equ	0x86	; TRISB-rekisteri
opreg		equ	0x81	; OPTION_REG rekisteri 
intcon		equ	0x0B	; INTCON-rekisteri
cmcon		equ	0x1F	; CMCON-rekisteri *** ver 1.6-0

; Bitit

pank		equ	0x05	; REGISTER BANK SELECT BIT
int		equ	0x06	; INTEDG bitti OPTION_REG rekisteriss‰
inte		equ	0x04	; INTE-bitti INTCON-rekisteriss‰
intf		equ	0x01	; INTF-bitti INTCON-rekisteriss‰
gie		equ	0x07	; GIE-bitti INTCON-rekisteriss‰
zero		equ	0x02	; STATUS-rekisterin ZERO-bitti
pwm_forw	equ	0x00	; RA0 PWM eteenp‰in
pwm_back	equ	0x01	; RA1 PWM taaksep‰in 
led_forw	equ	0x07	; RB7 Eteenp‰in led
led_back	equ	0x06	; RB6 Taaksep‰in led
led_comm	equ	0x05	; RB5 Ledien yhteinen karva
forw		equ	0x00	; "0" servopulssi alueella 1-1.5ms (taakse)
				; "1" servopulssi alueella 1.5-2ms (eteen)
full		equ	0x01	; T‰yskaasu "1"
mid		equ	0x02	; Kaasun keskikohta "1"
input		equ	0x00	; RB0 servopulssi sis‰‰n
switch		equ	0x01	; RB1 pyykelipalikka

	ORG 0000		; Reset vektori
	goto INIT

	ORG 0004		; Keskeytys vektori
	goto PULSE

	ORG 0008		; Ohjelmakoodi alkaa

;*********************************************************************************
;** INIT alustaa PIC:n rekisterit ja muistipaikat				**
;*********************************************************************************

INIT
	movlw 0x07		; Komparaattorit OFF *** ver 1.6-0
	movwf cmcon		; Komparaattorit OFF *** ver 1.6-0
	
	clrf porta		; Nollaa portin A
	clrf portb		; Nollaa portin B
	bsf status,pank		; Bank 1
	movlw b'0000'		
	movwf trisa		; RA0-3 l‰htˆj‰
	movlw b'00001111'
	movwf trisb		; RB0-3 tuloja, RB4-7 l‰htˆj‰
	movlw b'1010'
	movwf opreg		; WDT-jakaja k‰yttˆˆn
	bsf opreg,int		; RB0 keskeytys nousevalla reunalla
	bcf status,pank		; Bank 0

	bcf porta,pwm_forw	; PWM_FORW  = "0"
	bcf porta,pwm_back	; PWM_BACK  = "0"	

	bcf portb,led_comm	; LED_COMM  = "0"
	
	movlw 0x00
	movwf pwm		; Alustetaan 'servopulssi' 1.5ms
	movlw 0x00
	movwf pwm_out		; Alustetaan l‰htev‰ PWM
	movlw 0x00
	movwf direction		; Alustetaan suunta taakse
	movlw 0x08
	movwf blink		; Alustetaan ledien vilkutus

	bsf portb,led_forw
	bsf portb,led_back

SW_FR				; Pyykeli paikalla frame = 90D, ei pyykeli‰ frame = 100D
	movlw 0x64		; Ei pyykeli‰ arvo
	btfsc portb,switch
	goto SW_F		; Hyppy, jos kytkin on auki (ei pyykeli‰)	
	movlw 0x5A		; Pyykeli paikallaan arvo	
SW_F
	movwf frame_le
	movwf pwm_frame
	
	movlw 0x32		; Odotetaan riitt‰v‰ m‰‰r‰ servopulsseja
	movwf wait_up
EDGE_0
	clrwdt
	btfss portb,input
	goto EDGE_0
EDGE_1
	clrwdt
	btfsc portb,input
	goto EDGE_1
	
	decfsz wait_up, 1
	goto EDGE_0

	bcf portb,led_forw
	bcf portb,led_back	

	bsf intcon,gie		; Aktivoidaan keskeytykset
	bsf intcon,inte		; Aktivoidaan RB0-keskeytys
	
;*********************************************************************************
;**	MAIN on silmukka, jossa pyˆrit‰‰n kun servopulssia ei mitata.           **
;**	Silmukan pituus 11-kellojaksoa.						**
;*********************************************************************************

MAIN
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	call PWM
	goto MAIN	

;*********************************************************************************
;** PWM muodostaa l‰htev‰n PWM-signaalin. Aliohjelmassa kuluva aika on aina     **
;** haarautumisista riippumatta 14 kellojaksoa.					**
;*********************************************************************************

PWM
	btfss direction,forw	; Tarkistetaan, onko suunta eteen vai taakse
	goto BACKWARD

FORWARD
	decfsz pwm_frame, 1	; PWM_FRAME = PWM_FRAME - 1
	goto PWM_OUT_0		; Hyppy PWM_OUT_0 jos PWM_FRAME > 0 
	movf frame_le, 0	; W = frame_le
	movwf pwm_frame		; pwm_frame = W (pwm erottelutarkkuus)
	movf pwm, 0		; PWM -> W
	movwf pwm_out		; W -> PWM_OUT
	bcf porta,pwm_back	; PWM_BACK  = "0"
	nop
	nop
	nop
	return

PWM_OUT_0	
	movf pwm_out, 1		; PWM_OUT = PWM_OUT (Z)
	btfsc status,zero
	goto END_PWM_0		; Hyppy END_PWM_0 jos PWM_OUT = 0
	decf pwm_out, 1		; PWM_OUT = PWM_OUT - 1	
	bsf porta,pwm_forw	; PWM_FORW  = "1"
	nop
	nop
	return

END_PWM_0
	bcf porta,pwm_forw	; PWM_FORW  = "0"
	nop
	nop
	return
	
BACKWARD			; Muodostaa PWM:‰‰ pulssialueella 1-1.5ms
	decfsz pwm_frame, 1	; PWM_FRAME = PWM_FRAME - 1
	goto PWM_OUT_1		; Hyppy PWM_OUT_1 jos PWM_FRAME > 0
	movf frame_le, 0	; W = frame_le
	movwf pwm_frame		; pwm_frame = W (pwm erottelutarkkuus)
	movf pwm, 0		; PWM -> W
	movwf pwm_out		; W -> PWM_OUT
	bcf porta,pwm_forw	; PWM_FORW  = "0"
	nop
	nop
	return

PWM_OUT_1	
	movf pwm_out, 1		; PWM_OUT = PWM_OUT (Z)
	btfsc status,zero	; Jos Z-lippu on "1" -> hyppy END_PWM_1
	goto END_PWM_1		; Hyppy END_PWM_1 jos PWM_OUT = 0
	decf pwm_out, 1		; PWM_OUT = PWM_OUT - 1
	bsf porta,pwm_back	; PWM_BACK  = "1"
	nop
	return
	
END_PWM_1
	bcf porta,pwm_back	; PWM_BACK  = "0"
	nop
	return

;*********************************************************************************
;**	PULSE laskee servopulssin pituuden RB0 tulosta				**
;**	- Aliohjelmaan tullaan servopulssin tekem‰ll‰ keskeytyksell‰		**
;**	- Ensin muodostetaan 1ms viive, jolla erotetaan tahdistusosa		**
;**	- Lasketaan 90->0, josta saadaan pulssinpituus jos alueella 1.0-1.5ms	**
;**	- Lasketaan 0->90, josta saadaan pulssinpituus jos alueella 1.5-2.0ms	**
;**										**
;**	Aliohjelman luovuttama data:						**
;**	  pwm  = laskettu ohjauspulssin pituus neutraalialueen reunasta (0-90)	**
;**	  forw = "0" servopulssi alueella 1.0-1.5ms				**
;**	  	 "1" servopulssi alueella 1.5-2.0ms				**
;*********************************************************************************		

PULSE

	movlw 0xCD		; ***** KASVATETTU ARVOA
	movwf counter		; Asetetaan 1ms viivekierrosten m‰‰r‰		 
	movlw 0x5A		; ***** PIENENNETTY ARVOA		
	movwf down_cnt		; DOWN_CNT = 90	
	movlw 0x00
	movwf up_cnt		; UP_CNT = 0
	movlw 0x5A		; ***** PIENENNETTY ARVOA
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
	
LOOP				; Muodostaa 1ms viiveen servopulssin alusta lukien
	call PWM		; K‰yd‰‰n PWM:ss‰ p‰ivitt‰m‰ss‰ l‰htˆj‰
	nop
	nop
	nop
	nop
	nop
	nop
	decfsz counter, 1	
	goto LOOP

COUNT_DOWN			; Mitataan onko servopulssi 1-1.5ms pitk‰
	btfss portb,input	; Tutkitaan RB0-tila (servopulssi sis‰‰n)
	goto PULSE_OFF_0	; Jos RB0-tulo "0" -> servopulssi loppunut -> PULSE_OFF_0		
	call PWM		; Kutsutaan PWM-aliohjelmaa
	bcf direction,full	; FULL-bitti "0"
	nop
	decfsz down_cnt, 1	; DOWN_CNT = DOWN_CNT - 1
	goto COUNT_DOWN		; Hyppy COUNT_DOWN, jos DOWN_CNT > 0

	bsf direction,mid	; MID-bitti "1"

MIDDLE
	decfsz neutral,1	; Looppi tekee sauvan keskialueelle 'tyhj‰‰' liikett‰
	goto MIDDLE		; (25D vastaa yht‰ steppi‰.)
	
COUNT_UP			; Mitataan servopulssia 1.5-2ms alueella
	btfss portb,input	; Tutkitaan RB0-tila (servopulssi sis‰‰n)
	goto PULSE_OFF_1	; Jos RB0-tulo "0" -> servopulssi loppunut -> PULSE_OFF_1
	call PWM		; Kutsutaan PWM-aliohjelmaa
	bcf direction,mid	; MID-bitti "0"
	incf up_cnt, 1		; UP_CNT = UP_CNT + 1
	decfsz up_aux, 1	; UP_AUX = UP_AUX - 1
	goto COUNT_UP		; Hyppy COUNT_UP, jos UP_AUX > 0

	bsf direction,full	; FULL-bitti "1"

PULSE_OFF_1
	bsf direction,forw	; Suuntabitti FORW = "1"
	movf up_cnt, 0		; UP_CNT -> W
	movwf pwm		; W -> PWM
	bcf intcon,intf		; Nollataan keskeytyksest‰ kertova INTF-bitti
	goto LED
	
PULSE_OFF_0
	bcf direction,forw	; Suuntabitti FORW = "0"
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