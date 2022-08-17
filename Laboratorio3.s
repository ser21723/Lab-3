;*******************************************************************************
; Universidad del Valle de Guatemala	
; IE2023 ProgramaciÛn de microcontroladores
; Autor: Michelle Serrano 
; Compilador: PIC-AS (v2.36), MPLAB X IDE (v6.00)
; Proyecto: lab 3
; Hardware: PIC16F887 
; Creado: 09/08/2022
; ⁄ltima modificaciÛn: 15/08/2022
;*******************************************************************************
PROCESSOR 16F887
#include <xc.inc> 
;*******************************************************************************
; Palabra configuraciÛn
;*******************************************************************************
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT 
  CONFIG  WDTE = OFF            
  CONFIG  PWRTE = ON           
  CONFIG  MCLRE = OFF           
  CONFIG  CP = OFF              
  CONFIG  CPD = OFF             
  CONFIG  BOREN = OFF           
  CONFIG  IESO = OFF            
  CONFIG  FCMEN = OFF           
  CONFIG  LVP = OFF             

; CONFIG2
  CONFIG  BOR4V = BOR40V        
  CONFIG  WRT = OFF    
;*******************************************************************************
;Variables
;*******************************************************************************
 
PSECT udata_bank0 
    cont_auto:		DS 1
    cont_auto2:		DS 1
    cont_timer0:	DS 1
    cont_timer00:	DS 1
    w_temp:	 DS 1
    status_temp: DS 1
    
;*******************************************************************************
; Vector reset 
;*******************************************************************************

 PSECT CODE, abs, delta=2
 ORG 00h	    ; posici√≥n 0000h para el reset
 resetVector:
    goto main
 
;*******************************************************************************
;Interrupciones
;*******************************************************************************

PSECT CODE,abs, delta=2
ORG 04h
push:
    movwf w_temp	;guardado del valor de W
    swapf STATUS, w	;guardado del valor del STATUS
    movwf status_temp

isr:
    btfsc RBIF		;interrupci√≥n pushbuttons
    call  int_OCB
    btfsc T0IF		;interrupci√≥n Timer0
    call  int_tm0
    //call int_tm00
  
pop:
    swapf status_temp, w
    movwf STATUS
    swapf w_temp, f
    swapf w_temp, w
    retfie
 
;*******************************************************************************
;CÛdigo principal
;*******************************************************************************
PSECT code, delta=2, abs
ORG 100h
display:
    clrf    PCLATH
    bsf	    PCLATH, 0
    andlw   0Fh
    addwf   PCL, F
    retlw   3Fh		    ; 0
    retlw   06h		    ; 1
    retlw   5Bh		    ; 2
    retlw   4Fh		    ; 3
    retlw   66h		    ; 4
    retlw   6Dh		    ; 5
    retlw   7Dh		    ; 6
    retlw   07h		    ; 7
    retlw   7Fh		    ; 8
    retlw   6Fh		    ; 9
    
main:
    call    config_IO	    ;inputs PORTB, outputs PORTA, C, D
    call    Tm0_config	    
    call    reloj_config    ;a 1MHz
    call    config_iocb	    ;para puertos 0 y 1 del PORTB
    call    config_interrup 
    banksel PORTA
    clrf    PORTA
    movlw   3Fh
    movwf   PORTC
    movwf   PORTD
    clrf    cont_auto
    clrf    cont_timer0
    clrf    cont_auto2
    clrf    cont_timer00

loop:
    call display_auto
    call display_auto2
    goto loop
    
;*******************************CONFIGURACIONES*********************************

config_IO: 
    banksel ANSEL
    clrf    ANSEL	    ; pines digitales
    clrf    ANSELH
    
    banksel TRISA
    bsf	    TRISB, 0	    ;PORTB, 0 y 1 como entreada
    bsf	    TRISB, 1
    clrf    TRISA	    ;PORT A, C y D como salidas
    clrf    TRISC   
    clrf    TRISD
    bcf	    OPTION_REG, 7   ;habilita pull-ups
    bsf	    WPUB, 0	    ;pushbutton incrementar
    bsf	    WPUB, 1	    ;pushbutton decrementar
    return

Tm0_config:
    banksel TRISA
    bcf	    T0CS	    ;selecci√≥n del reloj interno
    bcf	    PSA		    ;asignamos prescaler al Timer0
    bsf	    PS2
    bsf	    PS1
    bcf	    PS0		    ;prescaler a 128
    banksel PORTA
    movlw   217
    movwf   TMR0
    bcf	    T0IF
    return

reloj_config:
    banksel TRISA
    bsf	    IRCF2
    bcf	    IRCF1
    bcf	    IRCF0	    ; reloj a 1MHz 
    return

config_interrup:
    banksel TRISA
    bsf	    GIE
    
    bsf	    RBIE	    ;interrupci√≥n del puerto B
    bcf	    RBIF
    
    bsf	    T0IE	    ;interrupci√≥n del Timer0
    bcf	    T0IF   
    return

config_iocb:
    banksel TRISA
    bsf	    IOCB, 0	    ;habilitar los pull-ups en puertos de entrada
    bsf	    IOCB, 1
    
    banksel PORTA
    movf    PORTB, W	    
    bcf	    RBIF    
    return

;****************************RUTINAS DE INTERRUPCIONES**************************  

int_OCB:
    btfss   PORTB, 0	    ;pushbutton de incremento
    incf    PORTA
    btfss   PORTB, 1	    ;pushbutton de decremento
    decf    PORTA
    bcf	    RBIF	    ;limpieza de la bandera
    return

int_tm0:
    movlw   217
    movwf   TMR0	    ;reseteo del Timer0
    bcf	    T0IF	    ;limpieza de la bandera 
    incf    cont_timer0     ;incremento de nuestra variable para lograr 
    SUBLW 10
    //REVISAR STATUS QUE SE CUMPLI” LLEGAR A 10
                            ;que el display cambie cada segundo
    return
    
int_tm00:
    movlw   217
    movwf   TMR0	    ;reseteo del Timer0
    bcf	    T0IF	    ;limpieza de la bandera 
    incf    cont_timer00     ;incremento de nuestra variable para lograr 
    SUBLW 10
                            ;que el display cambie cada segundo
    return	

;***************************************************************
display_auto:
    movlw   50		    ;ya que el timer cuenta cada 20ms, debe contar 50
    subwf   cont_timer0, w  ;veces para llegar al segundo y hacer que el 7	
    btfsc   ZERO	    ;segmentos cambie
    call    aumento_contador_display
    return
    
display_auto2:
    movlw   500              ;ya que el timer cuenta cada 20ms, debe contar 50
    subwf   cont_timer00, w  ;veces para llegar al segundo y hacer que el 7	
    btfsc   ZERO	    ;segmentos cambie
    call    aumento_contador_display2
    return
    
aumento_contador_display:
    clrf    cont_timer0	    ;se resetea la variable
    incf    cont_auto	    ;se incrementa la varable que lleva el valor del
    movf    cont_auto, W    ;segundo, se llama la tabla para 
    call    display	    ;traducirla y pegarla en el PORTD
    movwf   PORTD
    return
    
aumento_contador_display2:
    clrf    cont_timer00    ;se resetea la variable
    incf    cont_auto2	    ;se incrementa la varable 
    movf    cont_auto2, W   ;segundo, se llama la tabla para 
    call    display	    ;traducirla y pegarla en el PORTD
    movwf   PORTC
    return
END



