;╦══════════════════════════════════════════════════════════════════════
;║ LEVEL MANAGER
;╬══════════════════════════════════════════════════════════════════════
;║ level_manager.asm - Wyhrm for GameBoy
;║	Owns: entity_manager
;║	      physics_system, input_system, camera_system, collision_system
;║

;┬───────────────────────────────────────────────────────────────────────
;│ INCLUDES
;└ 
	INCLUDE     "./inc/HARDWARE.INC"   ; Include with useful memory position tags and more. Check file...

;┬───────────────────────────────────────────────────────────────────────
;│ CONSTANTS
;└  
	INCLUDE     "./inc/definitions/constants_def.asm"

;EXPORT MAX_LEVEL_SIZE

;┬───────────────────────────────────────────────────────────────────────
;│ MACROS
;└ 

;┬───────────────────────────────────────────────────────────────────────
;│ RAM VARIABLES
;└  
SECTION "LevelmanRAM", WRAM0
_DEATHS: 	DW 	; Death counter for current level
_CAM_Y::		DB 	; Píxel Y position of the visible area . !! No deberia ser global
_CAM_X::		DB 	; Píxel X position of the visible area . !! No deberia ser global
_PLY_INIT_Y:: DB 	; !! No deberia ser global
_PLY_INIT_X:: DB 	; !! No deberia ser global
_CAM_INIT_Y:: DB 	; !! No deberia ser global
_CAM_INIT_X:: DB 	; !! No deberia ser global

;┬───────────────────────────────────────────────────────────────────────
;│ DATA AREA
;└  
SECTION "LevelmanData", ROM0

;┬───────────────────────────────────────────────────────────────────────
;│ FUNCTIONS
;└  
SECTION "LevelmanFun", ROM0
LEVELMAN_INIT::
; ---- Initializes all managers and systems owned.
; DESTROYS: A, HL, BC
;
	; Init owned MANAGERS
	CALL    ENTITYMAN_INIT
	CALL 	STATEMAN_INIT
	; Init owned SYSTEMS
	CALL 	COLLISIONSYS_INIT	
	CALL 	INPUTSYS_INIT
	CALL 	PHYSICSSYS_INIT
	CALL 	CAMERASYS_INIT
	CALL 	ANIMATIONMAN_INIT
	RET

LEVELMAN_UPDATE::
; ---- Updates all systems owned.
; DESTROYS: A, HL, DE, BC
;
	; ----- EVENTMAN UPDATE
	CALL 	EVENTMAN_UPDATE

	; ---- INPUTSYS UPDATE
	CALL 	ENTITYMAN_GET_PHY_VEL
	CALL 	INPUTSYS_UPDATE

	; ---- STATEMAN UPDATE
	CALL 	ENTITYMAN_GET_PHY_TYP
	LD 		D, H 	; ┐
	LD 		E, L 	; ┴─> Save PHY_POS array mempos into DE
	CALL 	ENTITYMAN_GET_NUMENTITIES
	CALL 	STATEMAN_UPDATE

	; ---- COLLISIONSYS UPDATE
	CALL 	ENTITYMAN_GET_PHY_POS
	LD 		D, H 	; ┐
	LD 		E, L 	; ┴─> Save PHY_POS array mempos into DE
	CALL 	ENTITYMAN_GET_NUMENTITIES
	CALL 	COLLISIONSYS_UPDATE

	; ---- PHYSICSSYS UPDATE
	CALL 	ENTITYMAN_GET_PHY_VEL
	LD 		D, H 	; ┐
	LD 		E, L 	; ┴─> Save PHY_VEL array mempos into DE
	CALL 	ENTITYMAN_GET_PHY_POS
	CALL 	ENTITYMAN_GET_NUMENTITIES
	CALL 	PHYSICSSYS_UPDATE

	; ---- COLLISIONSYS UPDATE EXE
	CALL 	ENTITYMAN_GET_PHY_POS
	LD 		D, H 	; ┐
	LD 		E, L 	; ┴─> Save PHY_VEL array mempos into DE
	CALL 	ENTITYMAN_GET_PHY_POS
	CALL 	ENTITYMAN_GET_NUMENTITIES
	CALL 	COLLISIONSYS_UPDATE_EXE

	; ----- CAMERASYS UPDATE
	CALL 	ENTITYMAN_GET_PHY_VEL
	LD 		D, H 	; ┐
	LD 		E, L 	; ┴─> Save PHY_VEL array mempos into DE
	CALL 	LEVELMAN_GET_CAM
	CALL 	CAMERASYS_UPDATE_CAMERA	; Update camera position
	; --
	CALL 	LEVELMAN_GET_CAM
	LD 		B, H 	; ┐
	LD 		C, L 	; ┴─> Save Cam poistion into BC
	CALL 	ENTITYMAN_GET_PHY_POS
	LD 		D, H 	; ┐
	LD 		E, L 	; ┴─> Save PHY_POS array mempos into DE
	CALL  	ENTITYMAN_GET_SOAM
	CALL 	ENTITYMAN_GET_NUMENTITIES
	CALL 	CAMERASYS_UPDATE

	; ----- ANIMATIONMAN UPDATE
	CALL 	ENTITYMAN_GET_PHY_STA
	LD 		D, H 	; ┐
	LD 		E, L 	; ┴─> Save PHY_POS array mempos into DE
	CALL 	ANIMATIONMAN_UPDATE

	RET

LEVELMAN_RENDER::
; ---- Updates entities in the screen (OAM).
; DESTROYS: A, HL, DE, BC
;
	; -- RENDER CAMERA
	CALL 	LEVELMAN_GET_CAM
	CALL 	RENDERSYS_UPDATE_CAMERA
	; -- RENDER ENTITIES
	CALL 	ENTITYMAN_GET_SOAM
	CALL 	RENDERSYS_UPDATE
	RET

LEVELMAN_LOAD_MAP::
; ---- Loads TileMap for passed level.
; PARAMETERS:
;	HL = Pointer to TileMap
; DESTROYS: A, HL, BC, DE
;
	CALL 	READ_PTR_B 				; HL = ROM mempos of actual level TileMap
	PUSH 	HL						; Save Pointer to Tilemap for collmap call
	CALL 	RENDERSYS_LOAD_TILEMAP	; Load Background Tilemap into VRAM.
	POP 	HL 						; Retrieve Pointer to Tilemap for collmap call
	CALL 	COLLISIONSYS_LOAD_COLLMAP	; Load Collision map into WRAM.
	RET

LEVELMAN_LOAD_META::
; ---- Reads current level MetaData and creates its entities.
; PARAMETERS:
;	HL = Pointer to MetaData
; DESTROYS: 
; 	A, HL, BC, DE
;
	CALL 	READ_PTR_B 			; HL = ROM mempos of actual level MetaData
	
	LD 		A, [HL+]			; ┐
	LD 		[_CAM_X], A 		; │
	LD 		[_CAM_INIT_X], A 		; │ !!
	LD 		A, [HL+] 			; │
	LD  	[_CAM_Y], A 		; ┴─> Load Camera initial position
	LD 		[_CAM_INIT_Y], A 		; │ !!

	LD      A, [HL+]     		; Load first MetaData byte in A and increase HL
	LD  	E, A  				; E = Number of entities to create
	; BC = Entities total size
	LD 		B, 0
	LD  	C, ENTITY_OAM_SIZE + ENTITY_PHY_SIZE
.CREATE_ENTITIES_LOOP:
    PUSH 	HL 					; Save HL before CREATE call
    PUSH  	BC					; Save BC before CREATE call
    PUSH 	DE 					; Save DE before CREATE call
    CALL  	ENTITYMAN_CREATE  	; Create Entity with the manager
    POP 	DE  				; Retrieve DE after CREATE call
    POP  	BC 					; Retrieve BC after CREATE call
    POP 	HL 					; Retrieve HL after CREATE call
    DEC 	E 					; One less entity to create
    JR 		Z, .SAVE_AND_END;!!RET 	Z 					; Entities pending creation ?

    ADD		HL, BC 				; HL = Mempos of next entity to create
    JR .CREATE_ENTITIES_LOOP

.SAVE_AND_END:
	LD 		A, [$C100]
	LD  	[_PLY_INIT_Y], A 	; !! Save player intial Y and X
	LD 		A, [$C101]
	LD  	[_PLY_INIT_X], A	; !! Save player intial Y and X
	RET

LEVELMAN_TERMINATE::
; ---- Terminates all managers owned.
; DESTROYS: A, HL, DE, BC
;
	CALL 	ENTITYMAN_TERMINATE
	RET

;┬───────────────────────────────────────────────────────────────────────
;│ LOCAL FUNCTIONS
;└  
LEVELMAN_GET_CAM:
; ---- Camera Y position Getter into HL.
; DESTROYS: HL
; RETURNS:
;	HL = Camera Y position. Next byte is X position.
;
 	LD 	HL, _CAM_Y
 	RET

;║ EOF
;╚══════════════════════════════════════════════════════════════════════    