#include "msp430.h"
;-------------------------------------------------------------------------------------------------------------------
;		Define menu items
;-------------------------------------------------------------------------------------------------------------------
		ORG  	0F800h
WELCOME		DB	'   WELCOME to' ;13
CharacterHERO	DB	' Character HERO';15
SCORE		DB	'SCORE:';6
YOUWIN		DB	'YOU WIN!';8
GAMEOVER	DB	'GAME OVER!';10
SEQUENCE	DB	'               ABC B A C  A  B   A BACB CAB BA C AC C A B B A  ABCACB        ';62 times

VALUEOFA	DB	'A'
VALUEOFB	DB	'B'
VALUEOFC	DB	'C'




;-------------------------------------------------------------------------------------------------------------------
		ORG		0C000h 				;Program start
;-------------------------------------------------------------------------------------------------------------------
;		Housekeeping
;-------------------------------------------------------------------------------------------------------------------
RESET		mov		#0400h,SP			;Initialize stackpointer
StopWDT		mov		#WDTPW + WDTHOLD, &WDTCTL	;Stop WDT
SetupP1		bis.b		#0xFF,&P1DIR			;Set P1.0,P1.1,P1.2,P1.3,P1.4,P1.5,P1.6,P1.7 as output ports
SetupP2		bis.b		#0xF8,&P2DIR			;Set P2.0,P2.1,P2.2 as input ports
;-------------------------------------------------------------------------------------------------------------------
;		MACROS
;-------------------------------------------------------------------------------------------------------------------
WRITELCD	MACRO		PALABRA,TIMES		;Writing in the LCD MACRO where PALABRA is the LABEL of the location where is 
							;stored the caracters that wants to be WRITTEN and TIMES is the number of characters
							;defined
		LOCAL		OTRA			;initialize MACRO labels being used
		push		R4
		push		R5
		push		R6
		call		#DELAY
		mov		#PALABRA,R4		;Move PALABRA to R4
		mov.b		#TIMES,R5		;Move TIMES to R5
OTRA:		mov.b		@R4+,R6			;Move first Character to R6 and move R4 to next character
		call		#DELAY	
		bis.b		#00010000b,&P1OUT	;Enable	R/S
		
		call		#COMMAND		;Command subroutine
		call		#DELAY	
		bic.b		#00010000b,&P1OUT	;Disable R/S
	
		dec		R5			;Decrement TIMES
		jnz		OTRA			;Do it AGAIN
		
		pop		R6
		pop		R5
		pop		R4
		
		ENDM					;End MACRO 
;-------------------------------------------------------------------------------------------------------------------
;		PROGRAM
;-------------------------------------------------------------------------------------------------------------------
Main		;Set up internal resistance 
		bic.b		#7,&P2SEL		;selectP2.0 & P2.1
		bis.b		#7,&P2REN		;set P2.0 & P2.1 as pull-up resistor
		bis.b		#7,&P2OUT		;set P2.0 & P2.1 as pull-up resistor	
		
		call		#INITIALIZELCD		;4bit LCD initialization
		call		#WRITEWELCOME		;Write welcome message
		;Clear LCD
		call		#CLEARLCD		;Clear LCD
		mov.b		#0xC0,R6		;move cursor to second line
		call		#COMMAND
		WRITELCD	SCORE,6			;Write score
		mov		#0,R8			;Clear R8
		mov		#0,R12			;button not pressed
		mov		#0,R9			;initialize good answers counter
		mov		#12,R13
		mov.b		#33h,R8			;Score
		call		#WRITESCORE
		call		#GAMESEQUENCE		;Write game sequence
		
		call		#CLEARLCD		;clear LCD
		WRITELCD	GAMEOVER,10		;Game over message
		
		
		
		jmp		$	
;-------------------------------------------------------------------------------------------------------------------
;	Interrupt Service
;-------------------------------------------------------------------------------------------------------------------	
ButtonPressed:	call		#ONESECDELAY			;Delay to overcome bouncing problems
		call		#DECGS				
		bit.b		#1,&P2IFG		;Check if A was pressed
		jnc		NOT_A		
		
		bic.b		#7,&P2IFG		;A was pressed
		cmp.b		VALUEOFA,R7		;If A was pressed check that there was an A in cursor position
		jnz		NOT_C			;Wrong press
		mov		#1,R12			;BUTTON pressed: TRUE
		call		#INCREASECOUNTER	;Increase good answer counter
		jmp		CLEARIF			
		
NOT_A		bit.b		#2,&P2IFG		;Check if B was pressed
		jnc		NOT_B			
		bic.b		#7,&P2IFG		;B was pressed	
		cmp.b		VALUEOFB,R7		;If B was pressed check that there was an B in cursor position
		jnz		NOT_C			;Wrong press
		mov		#1,R12			;BUTTON pressed: TRUE
		call		#INCREASECOUNTER	;Increase good answer counter
		jmp		CLEARIF
		
NOT_B		bit.b		#4,&P2IFG		;Check if C was pressed
		jnc		NOT_C
		bic.b		#7,&P2IFG		;C was pressed
		cmp.b		VALUEOFC,R7		;If C was pressed check that there was an C in cursor position	
		jnz		NOT_C			;Wrong press
		mov		#1,R12			;BUTTON pressed: TRUE
		call		#INCREASECOUNTER	;Increase good answer counter
		jmp		CLEARIF
		
NOT_C		mov		#1,R12
		call		#RESETCOUNTER		;Reset good answer counter
		call		#DECREASESCORE		;Decrement score
		
CLEARIF		bic.b		#7,&P2IFG		
		call		#DELAY
		call		#DELAY
		reti
;-------------------------------------------------------------------------------------------------------------------
;	Subroutines
;-------------------------------------------------------------------------------------------------------------------
INITIALIZELCD:	bic.b		#0xFF,&P1OUT		;Clear ports	
		call		#DELAY
		bis.b		#03h,&P1OUT		;30
		call		#DELAY
		call		#NIBBLE
		call		#DELAY
		call		#NIBBLE
		call		#DELAY
		call		#NIBBLE
		call		#DELAY
		bic.b		#01h,&P1OUT		;20
		call		#NIBBLE
		call		#DELAY
		;Funtion set:4 bit/2-line
		mov.b		#28h,R6
		call		#COMMAND
		
		call		#DELAY
		;Set Cursor
		mov.b		#10h,R6
		call		#COMMAND
		
		call		#DELAY
		;Display ON; Blinking cursor
		mov.b		#0Fh,R6
		call		#COMMAND
		
		call		#DELAY
		;Entry Mode set
		mov.b		#06h,R6
		call		#COMMAND
		call		#DELAY
		;Clear LCD
		call		#CLEARLCD
		ret
;-------------------------------------------------------------------------------------------------------------------	
DECGS:		cmp		#2,R13		;Stop decrementing at 2
		jz		MINIMUM			
		sub		#2,R13		;Decrement delay outer loop
MINIMUM				
		ret
;-------------------------------------------------------------------------------------------------------------------	
DECREASESCORE:	dec		R8		;Decrement score
		
		call		#WRITESCORE	;Update score
		ret
;-------------------------------------------------------------------------------------------------------------------	
INCREASESCORE:	inc		R8		;Increment score
		call		#WRITESCORE	;Update score
		ret
;-------------------------------------------------------------------------------------------------------------------	
INCREASECOUNTER:
		push		R6		
		mov		#5,R6			;maximum number of rights to get a point
		bis.b		#01000000b,&P1OUT	;turn on green LED
		bic.b		#10000000b,&P1OUT	;turn off red LED
		inc		R9			;increment good answer counter
		cmp		R9,R6			;if good answer counter equals 5 add point
		jnz		NOT5
		mov		#0,R9			;reset counter
		call		#INCREASESCORE		;increase point
NOT5
		pop		R6
		ret
;-------------------------------------------------------------------------------------------------------------------			
RESETCOUNTER:  	mov		#0,R9			;Reset counter
		bis.b		#10000000b,&P1OUT	;Turn on red LED
		bic.b		#01000000b,&P1OUT	;Turn off green LED
		ret
;-------------------------------------------------------------------------------------------------------------------	
CLEARLCD:	mov.b		#01,R6			;CLEAR LCD command
		call		#COMMAND
		call		#DELAY
		ret
;-------------------------------------------------------------------------------------------------------------------
DELAY:		push		R15			;DELAY
		mov		#10000,R15
DLOOP		dec		R15
		jnz		DLOOP
		pop		R15
		ret
;------------------------------------------------------------------------------------------------------------------		
DELAY1:		push		R15			;half delay 
		mov		#5000,R15
DLOOP1		dec		R15
		jnz		DLOOP1
		pop		R15
		ret
;-------------------------------------------------------------------------------------------------------------------
ONESECDELAY:	push		R14			;Halfsecond delay
		push		R15
		mov 		#2, R15
D1		mov		#43000, R14
D2		dec		R14
		jnz		D2
		dec		R15
		jnz		D1
		pop		R15
		pop		R14
		ret
;-------------------------------------------------------------------------------------------------------------------		
TWOSECDELAY:	push		R14			;GAMESPEED
		push		R15
		mov 		R13,R15
D3		mov		#43000, R14
D4		dec		R14
		jnz		D4
		dec		R15
		jnz		D3
		pop		R15
		pop		R14
		ret
;-------------------------------------------------------------------------------------------------------------------		
NIBBLE:		bis.b		#00100000b,&P1OUT
		call		#DELAY1
		bic.b		#00100000b,&P1OUT
		ret
;-------------------------------------------------------------------------------------------------------------------
GAMESEQUENCE:	push		R6
		push		R10
		push		R11
		push		R15
		
		mov		#0,R11			;pointer in sequence
MOVESEQUENCE	mov		R11,R10			; initialize second pointer
		mov		#16,R15			;counter of how many letters
		mov.b		#0x80,R6		;Set cursor to first position in first line
		call		#COMMAND
TIMES16		mov.b		SEQUENCE(R10),R6	;get characters from sequence
		bis.b		#00010000b,&P1OUT	;Enable	R/S
		call		#COMMAND		;Command subroutine	
		bic.b		#00010000b,&P1OUT	;Disable R/S
		cmp		#9,R15			;if R15 equals 9 store current value to be available to check when pressed
		jnz		DontStoreValue		;if its not zero do nothing
		mov.b		R6,R7			;if its zero store value
DontStoreValue	inc		R10			;increment inner counter
		dec		R15			;decrement times
		jnz		TIMES16			
			
		call		#DELAY			
		mov.b		#87h,R6			;move cursor to position wanted		
		call		#COMMAND			
		bis.b		#7,&P2IE		;enable BIT0 and BIT1 interrupts on	
		bic.b		#7,&P2IFG		;Clear interrupt flags(just in case)
		bis.b		#00001000b,SR		;Turn on global interrupt enable
		nop
		call		#TWOSECDELAY		;Time to press button
		bic.b		#7,&P2IE		;disable BIT0 and BIT1 interrupts on	
		bic.b		#00001000b,SR		;Turn off global interrupt enable
		nop
		inc		R11			;increment pointer
		;Check if score is 0 or 8
		call		#ButtonNOTPRESSED
		call		#CHECKSCORE
		
		cmp		#62,R11			;do this 41 times
		jnz		MOVESEQUENCE
		
		pop		R15
		pop		R11
		pop		R10
		pop		R6
		ret
;-------------------------------------------------------------------------------------------------------------------
ButtonNOTPRESSED:	
		cmp.b		VALUEOFA,R7		;Check if there was a letter in cursors position
		jz		CHECK
		cmp.b		VALUEOFB,R7
		jz		CHECK
		cmp.b		VALUEOFC,R7
		jz		CHECK
		jmp		PRESSED
		
CHECK		cmp		#0,R12			;If there was a letter check is BUtton pressed: true
		jnz		PRESSED			
		call		#RESETCOUNTER		;Reset good answer counter
		call		#DECREASESCORE		;Decrease score
PRESSED		mov		#0,R12			;Button pressed: false
		ret
;-------------------------------------------------------------------------------------------------------------------
CHECKSCORE:	push		R6
		mov		#38h,R6
		cmp		R8,R6			;Check if score equals zero
		jnz		SCORECERO		
		call		#WINMESSAGE		;Display win message
		jmp		L1
SCORECERO	cmp		#30h,R8			;Check if scoe equals zero
		jnz		L1		
		call		#LOSEMESSAGE		;Display lose message
L1		pop		R6
		ret
;-------------------------------------------------------------------------------------------------------------------
LOSEMESSAGE:	call		#CLEARLCD		
		mov		#0400h,SP		
		WRITELCD	GAMEOVER,10		;GAME OVER
NOPE		nop
		jmp		NOPE
		ret
;-------------------------------------------------------------------------------------------------------------------	
WINMESSAGE:	call		#CLEARLCD
		mov		#0400h,SP
		WRITELCD	YOUWIN,8		;YOU WIN
NOPE1		nop
		jmp		NOPE1
		ret
;-------------------------------------------------------------------------------------------------------------------		
WRITEWELCOME:	call		#DELAY
		WRITELCD	WELCOME,13		;Welcome message
		call		#DELAY
		mov		#11000000b,R6 		;Write in second line of the LCD command
		call		#COMMAND		;Send command
		call		#DELAY
		WRITELCD	CharacterHERO,15	;Write character hero
		call		#DELAY
		call		#ONESECDELAY
		ret
;------------------------------------------------------------------------------------------------------------------
WRITESCORE:	
		call		#DELAY
		mov.b		#0xC7,R6
		call		#COMMAND
		call		#DELAY
		bis.b		#00010000b,&P1OUT	;Enable	R/S
		mov.b		R8,R6
		call		#COMMAND
		bic.b		#00010000b,&P1OUT	;Enable	R/S
		call		#DELAY
		ret
;-------------------------------------------------------------------------------------------------------------------	
;Commands subroutine, used to enter commands to the LCD
COMMAND:	
		push		R6
		push		R7
		push		R15
		
		mov.b		R6,R7			;move R6 to R7
		and.b		#0xF0,R6		;Set least significant nybble to 0000.
				
		mov		#4,R15			;Rotate four times R6
AGAIN:		rra		R6			;Rotate right
		dec		R15			;decrement counter
		jnz		AGAIN			;Do it again
		bic.b		#0xF,&P1OUT		;Clear P1.0 to P1.3
		bis.b		R6,&P1OUT		;Send the Upper bits to LCD
		
		call		#NIBBLE
		
		and.b		#0x0F, R7		;Set nybble to 0000
         	bic.b		#0xF, &P1OUT		;Clear P1.0 to P1.3
         	bis.b		R7, &P1OUT              ;Send the Lower bits to LCD
         	
		call		#NIBBLE			; call Nibble
		bic.b		#0xF,&P1OUT		;Clear P1.0 to P1.3 (Just in case)
		
		pop		R15
		pop		R7
		pop		R6
		
		ret
;-------------------------------------------------------------------------------------------------------------------
;	Interrupt Vectors
;-------------------------------------------------------------------------------------------------------------------
		ORG		0FFFEh				;MSP430 RESET VECTOR
		DW		RESET
		ORG		0FFE6h				;Button pressed interrupt
		DW		ButtonPressed
		END