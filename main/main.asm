;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
            
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer


;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------
	mov.b #0xFF, &P1DIR ; Set all P1 pins as outputs
	mov.b #0xFF, &P2DIR ; Set all P2 pins as outputs

	;for the leds
	bic.b #00000001b, &P1SEL  ; Select Digital I/O for P1.0
	bic.b #00000010b, &P2SEL  ; Select Digital I/O for P2.1
	bic.b #00000001b, &P1SEL2 ; Select Digital I/O for P1.0
	bic.b #00000010b, &P2SEL2 ; Select Digital I/O for P2.1

	;for the leds
	bis.b #00000001b, &P1DIR ; Make P1.0 Output
	bis.b #00000010b, &P2DIR ; Make P2.1 Output

	; Set P2.3 and P1.3 as inputs for buttons
	bic.b #BIT3, &P2DIR   ; Clear P2.3 as input
	bic.b #BIT3, &P1DIR   ; Clear P1.3 as input

; Enable pull-up resistors for P2.3 and P1.3 for buttons
	bis.b #BIT3, &P2REN   ; Enable pull-up resistor for P2.3
	bis.b #BIT3, &P1REN   ; Enable pull-up resistor for P1.3

; Configure pull-up resistors as HIGH for buttons
	bis.b #BIT3, &P2OUT   ; Set pull-up resistor for P2.3 to HIGH
	bis.b #BIT3, &P1OUT   ; Set pull-up resistor for P1.3 to HIGH

	; P1.0 ve P2.1'i  (LOW)
	bic.b #00000001b, &P1OUT ; Turn off LED on P1.0
	bic.b #00000010b, &P2OUT ; Turn off LED on P2.1

	;arraning interrupts for two buttons
	bis.w #GIE, SR ; enable interrupts
	bis.b #00001000b, &P1IES ; P1.3
	bis.b #00001000b, &P1IE ; enable P

	bis.b #00001000b, &P2IES ; P2.3
	bis.b #00001000b, &P2IE ; enable P

main_loop:


	mov #12, R6 ; Initialize delay counter for long delay
	mov #4, R7 ; We count this to detect the moment when it is dash
	mov #1, R8 ; flag to find early button press
	mov #0, R9 ; flag for restart status control

		; Clear previous segment outputs, exclude P1.0 and P2.1
	mov.b #0xFE, &P1OUT ; Clear all P1 pins except P1.0
	mov.b #0xFD, &P2OUT ; Clear all P2 pins except P2.1
	call #call_3  ;printing 3 on the 7 segment
	call #delay  ;delay function
	dec R7       ; decrement the dash counter

	call #delay  ;delays between 3 and 2
	call #delay
	call #delay

    CMP #3, R9  ; Check if the Game Reset condition is triggered
    jge restart_



	tst R8       ; Check if early press exist
    jz wait

	mov.b #0xFE, &P1OUT ; Clear all P1 pins except P1.0
	mov.b #0xFD, &P2OUT ; Clear all P2 pins except P2.1
	call #call_2  ; printing 2 on the 7 segment
	call #delay  ; delay function
	dec R7       ; decrement the dash counter

	call #delay  ; delays between 2 and 1
	call #delay
	call #delay

	CMP #3, R9   ;Check if the Game Reset condition is triggered
    jge restart_

	tst R8       ; Check if early press exist
    jz wait

	mov.b #0xFE, &P1OUT ; Clear all P1 pins except P1.0
	mov.b #0xFD, &P2OUT ; Clear all P2 pins except P2.1
	call #call_1 ; printing 1 on the 7 segment
	call #delay  ; delay function
	dec R7       ; decrement the dash counter

	call #delay  ; delays between 1 and 0
	call #delay
	call #delay

	CMP #3, R9   ;Check if the Game Reset condition is triggered
    jge restart_

	tst R8       ; Check if early press exist
    jz wait

	mov.b #0xFE, &P1OUT ; Clear all P1 pins except P1.0
	mov.b #0xFD, &P2OUT ; Clear all P2 pins except P2.1
	call #call_0 ; printing 0 on the 7 segment
	call #delay  ; delay function
	dec R7       ; decrement the dash counter

	call #delay  ; delays between 0 and dash
	call #delay
	call #delay

	CMP #3, R9   ;Check if the Game Reset condition is triggered
    jge restart_

	tst R8       ; Check if early press exist
    jz wait

	mov.b #0xFE, &P1OUT ; Clear all P1 pins except P1.0
	mov.b #0xFD, &P2OUT ; Clear all P2 pins except P2.1
	call #call_dash ;printing dash on the 7 segment
	dec R7          ; decrement the dash counter

	call #delay  ; delays between dash and beginning of the new game
	call #delay
	call #delay

	CMP #3, R9   ;Check if the Game Reset condition is triggered
    jge restart_

wait:
    mov #0, R9   ; refresh the Game Reset condition
	call #delay_3s  ; delay for new game

    jmp main_loop  ; jump main for restarting the game

restart_:         ; Bonus Game Reset case
    mov #0, R9    ; refresh the restart condition
    ; turn on all leds for representing the  Game Reset
    bis.b #00000001b, &P1OUT ; Turn on P1.0 (red on)
    bis.b #00000010b, &P2OUT ; Turn on P2.1 (green on)

    call #delay_3s           ; 3 seconds delay
    ; turn off all the leds
    bic.b #00000011b, &P1OUT ; Turn off P1.0 and P2.1
    bic.b #00000011b, &P2OUT

    jmp main_loop  ; and jump to main_loop for new game

P1_ISR:  ; bonus first interrupt function for player1's button
	bic.b #00001000b, &P1IFG ; clear IF for next interrupt
	ADD #1, R9     ; add 1 to R9 for game reset case, If it increases twice, the game is reset.

	tst R7             ; Check if it is dash or a number, to check for early button pressing
    jn Negative        ; if dash jump to negative
    ;If pressed before the time is up, turn on the opposing side's LED  (Lost)
    bic.b #00000001b, &P1OUT ; Turn off P1.0 (red off)
	bis.b #00000010b, &P2OUT ; Turn on P2.1 (green on)
	; Set the flag to 0 to finish the game
	mov #0, R8
    jmp Continue ; jump to Continue

Negative:
	;If player1 pressed it while it was dash, player1 won, turn on his/her own led (Won)
    bis.b #00000001b, &P1OUT ; Turn on P1.0
	bic.b #00000010b, &P2OUT ; Turn off P2.1
Continue:
	reti ; return from interrupt

P2_ISR: ; bonus second interrupt function for player2's button
	bic.b #00001000b, &P2IFG ; clear IF for P2.3

	tst R7            ; Check if it is dash or a number, to check for early button pressing
    jn Negative2      ; jump negative
    ;If pressed before the time is up, turn on the opposing side's LED  (Lost)
    bis.b #00000001b, &P1OUT ; Turn on P1.0
	bic.b #00000010b, &P2OUT ; Turn off P2.1
	; Set the flag to 0 to finish the game
	mov #0, R8
    jmp Continue2 ; jump to Continue2

Negative2:
	;If player2 pressed it while it was dash, player2 won, turn on his/her own led (Won)
	bic.b #00000001b, &P1OUT ; Turn off P1.0 (red off)
	bis.b #00000010b, &P2OUT ; Turn on P2.1 (green on)
Continue2:
	reti ; return from interrupt

;delay function
delay:
	mov.w #0xFFFF, r10
decrease:
	dec.w r10
	jnz decrease
	ret

; 3 second delay function
delay_3s:
    call #delay
	dec R6
	jnz delay_3s
	jmp main_loop

;printing dash
call_dash:
	bic.b #BIT2, &P2OUT ; Turn on g
	ret
;printing zero
call_0:
	bic.b #BIT1, &P1OUT ; Turn on a
	bic.b #BIT2, &P1OUT ; Turn on b
	bic.b #BIT4, &P1OUT ; Turn on c
	bic.b #BIT5, &P1OUT ; Turn on d
	bic.b #BIT7, &P1OUT ; Turn on e
	bic.b #BIT0, &P2OUT ; Turn on f
	; bic.b #BIT2, &P2OUT ; Turn on g
	ret

;printing one
call_1:
	; bic.b #BIT1, &P1OUT ; Turn on a
	bic.b #BIT2, &P1OUT ; Turn on b
	bic.b #BIT4, &P1OUT ; Turn on c
	; bic.b #BIT5, &P1OUT ; Turn on d
	; bic.b #BIT7, &P1OUT ; Turn on e
	; bic.b #BIT0, &P2OUT ; Turn on f
	; bic.b #BIT2, &P2OUT ; Turn on g
	ret

;printing two
call_2:
	bic.b #BIT1, &P1OUT ; Turn on a
	bic.b #BIT2, &P1OUT ; Turn on b
	; bic.b #BIT4, &P1OUT ; Turn on c
	bic.b #BIT5, &P1OUT ; Turn on d
	bic.b #BIT7, &P1OUT ; Turn on e
	; bic.b #BIT0, &P2OUT ; Turn on f
	bic.b #BIT2, &P2OUT ; Turn on g
	ret

;printing three
call_3:
	bic.b #BIT1, &P1OUT ; Turn on a
	bic.b #BIT2, &P1OUT ; Turn on b
	bic.b #BIT4, &P1OUT ; Turn on c
	bic.b #BIT5, &P1OUT ; Turn on d
	; bic.b #BIT7, &P1OUT ; Turn on e
	; bic.b #BIT0, &P2OUT ; Turn on f
	bic.b #BIT2, &P2OUT ; Turn on g
	ret


;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
		   .sect ".int02" ; Port 1 interrupt vector
		   .short P1_ISR
           .sect ".int03" ; Port 2 interrupt vector
		   .short P2_ISR
		   .sect ".reset" ; MSP430 RESET Vector
           .short RESET ; actually int15
           .end
