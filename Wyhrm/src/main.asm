;╦══════════════════════════════════════════════════════════════════════
;║ MAIN FILE
;╬══════════════════════════════════════════════════════════════════════
;║ main.asm - Wyhrm for GameBoy
;║

;┬───────────────────────────────────────────────────────────────────────
;│ INCLUDES
;└  
    INCLUDE     "./inc/HARDWARE.INC"   ; Include with useful memory position tags and more. Check file...

;┬───────────────────────────────────────────────────────────────────────
;│ CARTRIDGE HEADER
;└
SECTION "Cabecera", ROM0[$0100]
    INCLUDE "./inc/header.asm"    ; Cartridge header data file

;┬───────────────────────────────────────────────────────────────────────
;│ INTERRUPTIONS
;└
SECTION "VBLANKInterrupt",ROM0[$0040]
    RETI

SECTION "STATInterrupt",ROM0[$0048]
    RETI

;┬───────────────────────────────────────────────────────────────────────
;│ Program START
;└
SECTION "Start", ROM0[$0150]
MAIN:
    DI                      ; Disable interruptions

    LD      SP, $FFFF       ; Point STACK to memory's last position

MAIN.INIT:
    CALL    GAMEMAN_INIT

    ; Set up Interruptions
    LD      A,STATF_MODE00  ; ┐
    LDH     [rSTAT],A       ; ┴─> Set up the lcdc interrupt
    LD      A, IEF_LCDC     ; ┐
    LDH     [rIE], A        ; ┴─> Enable STAT interrupt
    EI                      ; Enable interruptions
    XOR     A               ; ┐
    LDH     [rIF], A        ; ┴─> Reset Interrupt flag

MAIN.GAMELOOP:
    HALT    ; Stop system clock
            ; return from halt when interrupted
    ; NOP 	; No Operation (NOP is necessary to avoid HALT skipping)
            ; └─> no need with RGBDS (already adds a NOP after HALT)
    
    LD      A, [rLY]        ;
    CP      143             ; Last line HBLANK ?
    JR      NZ, .GAMELOOP   ; No, some other line

    CALL    GAMEMAN_RENDER  ; Render Game
    CALL    GAMEMAN_UPDATE  ; Update Game

    JR .GAMELOOP

;║ EOF
;╚══════════════════════════════════════════════════════════════════════