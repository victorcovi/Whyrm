;╦══════════════════════════════════════════════════════════════════════
;║ GLOBAL ROUTINES
;╬══════════════════════════════════════════════════════════════════════
;║ global_routines.asm - Wyhrm for GameBoy
;║

;┬───────────────────────────────────────────────────────────────────────
;│ INCLUDES
;└	
 	INCLUDE     "./inc/HARDWARE.INC"   ; Include with useful memory position tags and more. Check file...

;┬───────────────────────────────────────────────────────────────────────
;│ FUNCTIONS
;└
SECTION "GloablRoutines", ROM0
LDIR::
; ---- Copies number of bytes especified by BC value from HL location to DE location.
; PARAMETERS:
; 	HL = Source location
; 	DE = Destined location
; 	BC = Number of bytes to copy
; DESTROYS: 
;	A, HL, DE, BC
;
    LD      A, [HL+]        ; Cargamos en A el dato a copiar
    LD      [DE], A         ; Copiamos en la direccion destino
    INC     DE              

    DEC     BC              ; Restamos 1 al total de datos a copiar
    LD      A, C            ;
    OR      B               ;
    JR      NZ, LDIR 		; Si B or C distinto de 0, BC !=0, bucle
    RET 

READ_PTR::
; ---- Read memory pointer in HL (ptr end position) to HL. 
;      When direction is saved in the pointer in order (HighByte first).
; PARAMETERS:
; 	HL = Location of pointer + 1
; DESTROYS: 
; 	A, HL
;
    LD      A, [HL-]
    LD      H, [HL]
    LD      L, A
    RET

READ_PTR_B::
; ---- Read memory pointer in HL (ptr start position) to HL.
;      When direction is saved in the pointer with LowByte first.
; PARAMETERS:
; 	HL = Location of pointer
; DESTROYS: 
; 	A, HL
;
    LD      A, [HL+]
    LD      H, [HL]
    LD      L, A
    RET

WAIT_VBLANK::
; ---- Wait for VBlank routine
; DESTROYS: 
;	A
;
    LD      A, [rLY]
    CP      144
    JR      NZ, WAIT_VBLANK
    RET

;║ EOF
;╚══════════════════════════════════════════════════════════════════════