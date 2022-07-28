;╦══════════════════════════════════════════════════════════════════════
;║ EVENT MANAGER
;╬══════════════════════════════════════════════════════════════════════
;║ event_manager.asm - Wyhrm for GameBoy
;║

;┬───────────────────────────────────────────────────────────────────────
;│ INCLUDES
;└  
    INCLUDE     "./inc/HARDWARE.INC"   ; Include with useful memory position tags and more. Check file...

;┬───────────────────────────────────────────────────────────────────────
;│ CONSTANTS
;└  
    INCLUDE     "./inc/definitions/constants_def.asm"

;┬───────────────────────────────────────────────────────────────────────
;│ MACROS
;└ 
MACRO POINT_NEXT
; ---- Points to next entity in corresponding array.
; PARAMETERS:
;   1 = Corresponding entity size
;   2 = Array offset
;   3 = Register (L or E)
; DESROYS: A, HL, DE
;
    LD      A, \1 - (\2)            ; [8] ┐
    ADD     \3                      ; [4] ┼─> A = LOW(Entity(N).X + (ENT_SIZE-1))
    LD      \3, A                   ; [4] ┴─> L = LOW(Entity(N+1).Y)
ENDM
MACRO POINT_INI
; ---- Points to the start position of the corresponding array.
; PARAMETERS:
;   1 = Corresponding entity size
;   2 = Array offset
;   3 = Register (L or E)
; DESTROYS: A, HL, DE
;
    LD      A, -(\1 + \2)           ; [8] ┐
    ADD     \3                      ; [4] ┼─> A = LOW(Entity(N).X + (ENT_SIZE-1))
    LD      \3, A                   ; [4] ┴─> L = LOW(Entity(N+1).Y)
ENDM

;┬───────────────────────────────────────────────────────────────────────
;│ DATA AREA
;└  
SECTION "EventmanData", ROM0

;┬───────────────────────────────────────────────────────────────────────
;│ RAM VARIABLES
;└  
SECTION "EventmanRAM", WRAM0
; ---- MOVEMENT VALUE BY STATE
;_CURRENT_SPRITE:   DB
_LVL_END::          DB
_LVL_LOADED::       DB

;┬───────────────────────────────────────────────────────────────────────
;│ FUNCTIONS
;└ 
SECTION "EventmanFun", ROM0
EVENTMAN_INIT::
; ---- Routine to initialize EventManager.
; DESTROYS: 
;   -
;   
    XOR     A
    LD      [_LVL_END], A
    LD      [_LVL_LOADED], A
    RET

EVENTMAN_UPDATE::
; ---- .
; PARAMETERS: 
;   DE = .
; DESTROYS: 
;   A, HL, DE, BC
; 
    LD      A, [_LVL_END]
    CP      0
    RET     Z
    CP      2
    JR      Z, .HIDE_WINDOW
    LD      A, [_LVL_LOADED]
    CP      1
    RET     Z
    CALL    muestra_ventana
    RET
.HIDE_WINDOW:
    CALL    muestra_ventana.anim_ocul_vent
    RET

;┬───────────────────────────────────────────────────────────────────────
;│ LOCAL FUNCTIONS
;└ 
muestra_ventana:
; ---- Windows screen that appears between levels.
    ld      a, 7
    ld      [rWX], a
 
    ld      a, 144
    ld      [rWY], a
 
    ;activamos la ventana y desactivamos los sprites
    ld      a, [rLCDC]
    or      LCDCF_WINON
    res     1, a
    ld      [rLCDC], a
 
    DI                      ; Disable interruptions

    ; b - posicion x
    ; c - posición y
    ; l - numero a imprimir (0-9)
    LD      B, $0E
    LD      C, $04
    LD      A, [_ACTUAL_LVL]
    INC     A
    LD      L, A
    CALL    ImprimeNumero

    ; b - posicion x
    ; c - posición y
    ; l - numero a imprimir (0-9)
    LD      B, $0E
    LD      C, $08
    LD      A, [_DEATHS_TOT]
    LD      L, A
    CALL    ImprimeNumero

        ; b - posicion x
    ; c - posición y
    ; l - numero a imprimir (0-9)
    LD      B, $0D
    LD      C, $08
    LD      A, [_DEATHS_TOT+1]
    LD      L, A
    CALL    ImprimeNumero

    ; animacion
    ld      a, 144
.anim_most_vent:
    push    af
    ld      bc, 1000
    call    RETARDO
    pop     af
    dec     a
    ld      [rWY], a
    jr      nz, .anim_most_vent

    ; -- CARGA MAPA
    ; Load First Level
    LD      A, [_ACTUAL_LVL]    ; ┐
    INC     A
    LD      [_ACTUAL_LVL], A    ; ┴─> Initialize ACTUAL_LVL as 0
    CALL    LEVELMAN_INIT
    CALL    GAMEMAN_LOAD_LEVEL

    LD      A, 1
    LD      [_LVL_LOADED], A

    ; Set up Interruptions
    LD      A,STATF_MODE00  ; ┐
    LDH     [rSTAT],A       ; ┴─> Set up the lcdc interrupt
    LD      A, IEF_LCDC     ; ┐
    LDH     [rIE], A        ; ┴─> Enable STAT interrupt
    EI                      ; Enable interruptions
    XOR     A               ; ┐
    LDH     [rIF], A        ; ┴─> Reset Interrupt flag
 
    ; esperamos a que pulsen start para salir
.espera_salir:
;    call    LEE_PAD
;    ;SIMB  (%↓↑←→+-BA)
;    and     %00001000               ; Boton START
    RET;JR      .espera_salir;jr      z, .espera_salir;  

.anim_ocul_vent:
    push    af
    ld      bc, 1000
    call    RETARDO
    pop     af
    inc     a
    ld      [rWY], a
    cp      144
    jr      nz, .anim_ocul_vent
 
    ;desactivamos la ventana y activamos los sprites
    ld      a, [rLCDC]
    res     5, a
    or      LCDCF_OBJON
    ld      [rLCDC], a

    XOR     A
    LD      [_LVL_END], A
    LD      [_LVL_LOADED], A
 
    ret                     ; volvemos

; Imprime un numero (unidad)
; Parámetros
; b - posicion x
; c - posición y
; l - numero a imprimir (0-9)
ImprimeNumero:
    push    hl          ; guardamos hl pa luego
    ; vamos a usar hl ahora para los cálculos del destino
    ld      hl, _SCRN1
    ; vamos a la posición y
    ld      a, c
    cp      0
    jr      z, .fin_y   ; si es cero, vamos a por las x
.avz_y:
    ld      de, 32
    add     hl, de      ; avanzamos en las Y por lo tanto 32 tiles
    dec     a
    jr      nz, .avz_y
.fin_y:
; vamos a por las x
    ld      a, b
    cp      0
    jr      z, .fin_x   ; si es cero, terminamos
.avz_x:
    inc     hl
    dec     a
    jr      nz, .avz_x
.fin_x:
    push    hl
    pop     de          ; de = hl
; bien, tenemos en 'de' la posición de memoria donde escribir el numero
; vamos a ello
    pop     hl          ; rescatamos el número
    ld      a, l
    and     $0F         ; solo nos interesa la parte baja
 
    add     a, FONT_MASK       ; el primer caracter es 32 el espacio, el cero está a +16
    ld      [de], a
    ret

RETARDO:
; ---- Rutina de Retardo NO anidado

    LD      DE, 2470        ; Contador de ejecucion del bucle
.delay:
    DEC     DE              ; Decremento
    LD      A, D            ; 
    OR      E               ;
    JR      NZ, .delay      ; If DE != 0 , Bucle
    RET

;║ EOF
;╚══════════════════════════════════════════════════════════════════════