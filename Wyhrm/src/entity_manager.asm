;╦══════════════════════════════════════════════════════════════════════
;║ ENTITY MANAGER
;╬══════════════════════════════════════════════════════════════════════
;║ entity_manager.asm - Wyhrm for GameBoy
;║

;┬───────────────────────────────────────────────────────────────────────
;│ INCLUDES
;└ 
	INCLUDE     "./inc/HARDWARE.INC"   ; Include with useful memory position tags and more. Check file...

;┬───────────────────────────────────────────────────────────────────────
;│ CONSTANTS
;└  
	INCLUDE     "./inc/definitions/constants_def.asm"

;EXPORT MAX_ENTITIES, ENTITY_OAM_SIZE, ENTITY_SCR_SIZE, ENTITY_PHY_SIZE, \
;       PHY_Y, PHY_X, PHY_VY, PHY_VX, ENTITY_H, ENTITY_W, \
;       MAX_ENTITY_W, MAX_ENTITY_H, ENTITY_H_AI, ENTITY_W_AI

;┬───────────────────────────────────────────────────────────────────────
;│ MACROS
;└ 
MACRO NEW_ENTITY
; ---- Reserves space for new Entity in then entity arrray (sOAM/PHY).
; PARAMETERS:
; 	1 = Last entity pointer
; 	2 = Sizeof entity
; DESTROYS: A, HL, DE, BC
; RETURNS:
; 	DE = Pointer to new blank entity
; 	BC = Sizeof Entity
;
	PUSH 	HL 		; Save mempos of the initialization data
	; Update Last Entity pointer
	LD 	HL, \1 + 1 	; ┐
	CALL  	READ_PTR 	; ┴─> Same as: LD HL, [_ENT_PEND]
	LD 	D, H		; ┐
	LD 	E, L 		; ┴─> DE = HL . DE => last entity mempos
	LD 	BC, \2		; ┐
	ADD 	HL, BC   	; ┴─> HL = last entity mempos updated
	LD 	A, H 		; ┐
	LD 	[\1], A  	; │
	LD 	A, L 		; │
	LD 	[\1 + 1], A 	; ┴─> Same as: LD [ENT_PEND], HL
	POP  	HL  		; Retrieve initialization data mempos
ENDM
MACRO CLEAN_ENTITY_ARRAY
; ---- Clean the entire ENTITY ARRAY.
; PARAMETERS:
; 	1 = Last entity pointer
; 	2 = Sizeof entity
; DESTROYS: A, HL, BC, DE
;
	LD 	HL, \1			; ENTITY ARRAY initial positon
	LD 	A, [_NUM_ENTITIES]	; ┐
	OR 	A                   	; │
	JR 	Z, .END_CLEAN\@	; ┼─> Exit if 0 entities 
	LD 	E, A  			; ┴─> E = Number of entities in array
 	XOR	A 			; A = 0 (Value to reset entity array)
.MAIN_LOOP\@:
	LD 	C, \2			; C = Total size of each entity
.ENTITY_COMP_LOOP\@:
 	LD  	[HL+], A  		; Load 0 and increment HL
 	
 	DEC  	C 			; Remaining components -1
 	JR  	NZ, .ENTITY_COMP_LOOP\@	; Are all components of current entity reseted ?
 	DEC	E 			; Remaining entities -1
 	JR 	Z, .END_CLEAN\@	; Entities remaining to reset ?	
 	JR  	.MAIN_LOOP\@
.END_CLEAN\@:
ENDM

;┬───────────────────────────────────────────────────────────────────────
;│ RAM VARIABLES
;└  
SECTION "EntitymanArrayOAM", WRAM0[$C000]
;ENTITY OAM ARRAY => $C000 (Shadow OAM / sOAM)
_ENTITY_OAM_ARRAY:	DS MAX_ENTITIES * ENTITY_OAM_SIZE
SECTION "EntitymanArrayPHY", WRAM0[$C100]			
;ENTITY PHY ARRAY => $C100 = sOAM + $0100
_ENTITY_PHY_ARRAY: 	DS MAX_ENTITIES * ENTITY_PHY_SIZE
SECTION "EntitymanRAM", WRAM0
_NUM_ENTITIES: 	DB
_ENT_OAM_PEND: 	DW
_ENT_PHY_PEND: 	DW

;┬───────────────────────────────────────────────────────────────────────
;│ FUNCTIONS
;└  
SECTION "EntitymanFun", ROM0
ENTITYMAN_INIT::
; ---- Initialize & Load ENTITY ARRAY location into LAST ENTITY POINTER.
; DESTROYS: A, HL, BC
;
	XOR	A 			; ┐
	LD  	[_NUM_ENTITIES], A 	; ┴─> Initialize NUM_ENTITIES as 0	

	CALL  	INIT_SOAM		; Initialize Shadow OAM array

	LD 	BC, _ENTITY_OAM_ARRAY 	; ┐
	LD 	HL, _ENT_OAM_PEND 		; │
	LD 	[HL], B 			; │
	INC 	HL        			; │
	LD 	[HL], C    			; ┴─> Initialize _ENT_OAM_PEND as the
	 					; initial mempos of _ENTITY_OAM_ARRAY  
	LD 	BC, _ENTITY_PHY_ARRAY  	; ┐
	LD 	HL, _ENT_PHY_PEND 		; │
	LD 	[HL], B 			; │
	INC 	HL        			; │
	LD 	[HL], C    			; ┴─> Initialize _ENT_PHY_PEND as the
	 					; initial mempos of _ENTITY_PHY_ARRAY  	 								
	RET

ENTITYMAN_CREATE::
; ---- Creates and initializes new Entity.
; PARAMETERS:
; 	HL = New entity initialization data
; DESTROYS: A, HL, DE, BC
;
	; MAX ENTITIES control
	LD 	A, [_NUM_ENTITIES]
	CP	MAX_ENTITIES
	RET 	Z

	; -- ENTITY sOAM COMPONENTS	
	; Add new blank entity to the entity array
	NEW_ENTITY _ENT_OAM_PEND, ENTITY_OAM_SIZE
	; HL = new entity initialization sOAM data
	; DE = Pointer to the new entity space
	; BC = Siezof entity (sOAM)
	; Copy initialization values to new entity sOAM data reserved space
	CALL 	LDIR

	; -- ENTITY PHY COMPONENTS
	; Add new blank entity to the entity array
	NEW_ENTITY _ENT_PHY_PEND, ENTITY_PHY_SIZE	
	; HL = new entity initialization PHY data
	; DE = Pointer to the new entity space
	; BC = Siezof entity (PHY)
	; Copy initialization values to new entity PHY data reserved space
	CALL 	LDIR

	; Increment number of entities
	CALL 	NUM_ENTITIES_INC
	RET

ENTITYMAN_GET_NUMENTITIES::
; ---- Number of entities Getter into A.
; DESTROYS:	A
; RETURNS:
;	A  = Number of current entities
;
 	LD 	A, [_NUM_ENTITIES]
 	RET

ENTITYMAN_GET_SOAM::
; ---- sOAM EntityArray Getter into HL.
; DESTROYS: HL
; RETURNS:
;	HL = Start of the sOAM array mempos
;
 	LD 	HL, _ENTITY_OAM_ARRAY
 	RET

ENTITYMAN_GET_PHY_VEL::
; ---- PHY EntityArray Getter into HL.
; DESTROYS: HL
; RETURNS:
;	HL = Start of the PHY array mempos
;
 	LD 	HL, _ENTITY_PHY_ARRAY + PHY_VY
 	RET

ENTITYMAN_GET_PHY_POS::
; ---- PHY EntityArray Getter into HL.
; DESTROYS: HL
; RETURNS:
;	HL = Start of the PHY array mempos
;
 	LD 	HL, _ENTITY_PHY_ARRAY + PHY_Y
 	RET

ENTITYMAN_GET_PHY_TYP::
; ---- PHY EntityArray Getter into HL.
; DESTROYS: HL
; RETURNS:
;	HL = Start of the PHY array mempos
;
 	LD 	HL, _ENTITY_PHY_ARRAY + PHY_T
 	RET

ENTITYMAN_GET_PHY_STA::
; ---- PHY EntityArray Getter into HL.
; DESTROYS: HL
; RETURNS:
;	HL = Start of the PHY array mempos
;
 	LD 	HL, _ENTITY_PHY_ARRAY + PHY_ST
 	RET

ENTITYMAN_TERMINATE::
; ---- Terminate tasks.
; DESTROYS: HL
; RETURNS:
;	HL = Start of the PHY array mempos
;
 	CALL 	CLEAN_ENTITYARRAY
 	RET

;┬───────────────────────────────────────────────────────────────────────
;│ LOCAL FUNCTIONS
;└ 
INIT_SOAM:
; ---- Clean the entire ENTITY ARRAY.
; PARAMETERS:
; 	1 = Last entity pointer
; 	2 = Sizeof entity
; DESTROYS: A, HL, BC, DE
;
	LD 	A, OAM_SIZE 			; ┐
	LD 	C, A 				; ┴─> C = OAM size = $A0
	LD     HL, _ENTITY_OAM_ARRAY	; HL = sOAM array initial mempos
	XOR 	A 				; A = 0 (Value to initialize shadow OAM array)
.INIT_LOOP:
 	LD  	[HL+], A  			; Load 0 and increment HL
; COUNT CHECK
 	DEC  	C 				; 1 less byte to initialize
	JR  	NZ, .INIT_LOOP		; Bytes remaining ? 
 	RET  					; Exit if 0

NUM_ENTITIES_INC:
; ---- Increments number of reserved entities.
; DESTROYS: HL
;
	LD 	HL, _NUM_ENTITIES 		; ┐
	INC  	[HL]  				; ┴─> num_entities++
	RET

CLEAN_ENTITYARRAY::
; ---- Clean the entire ENTITY ARRAY.
; DESTROYS: A, HL, BC, DE
;
	; Clean Shadow OAM Entity array
	CLEAN_ENTITY_ARRAY _ENT_OAM_PEND, ENTITY_OAM_SIZE
	; Clean PHY Entity array
	CLEAN_ENTITY_ARRAY _ENT_PHY_PEND, ENTITY_PHY_SIZE
	RET

;║ EOF
;╚══════════════════════════════════════════════════════════════════════