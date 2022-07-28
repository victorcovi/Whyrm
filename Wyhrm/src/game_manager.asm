;╦══════════════════════════════════════════════════════════════════════
;║ GAME MANAGER
;╬══════════════════════════════════════════════════════════════════════
;║ game_manager.asm - Wyhrm for GameBoy
;║	Owns: level_manager
;║		  render_system
;║

;┬───────────────────────────────────────────────────────────────────────
;│ INCLUDES
;└ 
	INCLUDE     "./inc/HARDWARE.INC"   ; Include with useful memory position tags and more. Check file...

;┬───────────────────────────────────────────────────────────────────────
;│ CONSTANTS
;└  
	INCLUDE     "./inc/definitions/constants_def.asm"
;DEF MAX_LEVELS  	EQU X 	; Possible maximun number of levels

;EXPORT MAX_LEVELS

;┬───────────────────────────────────────────────────────────────────────
;│ MACROS
;└  
; ---- MACROS FOR ENTITY DEFINITIOS BY TYPE 
	INCLUDE		"./inc/definitions/entities_def.asm"
	
;┬───────────────────────────────────────────────────────────────────────
;│ RAM VARIABLES
;└ 
SECTION "GamemanRAM", WRAM0
_ACTUAL_LVL:: DB				; Actual level number id . !! No deberia ser global
_DEATHS_TOT:: DW				; Total Death counter for current level . !! No deberia ser global
_DEATHS_ARR: DS NUM_LEVELS * 2	; Death counter by level array 

;┬───────────────────────────────────────────────────────────────────────
;│ DATA AREA
;└  
SECTION "GamemanData", ROM0
; ---- LEVELS DATA (TileMap + MetaData)
	INCLUDE		"./inc/definitions/levels_def.asm"

;┬───────────────────────────────────────────────────────────────────────
;│ FUNCTIONS
;└  
SECTION "GamemanFun", ROM0
GAMEMAN_INIT::
; ---- Initiates all managers and systems owned.
; DESTROYS: A, HL, DE, BC
;
    ; Init owned SYSTEMS
    CALL 	RENDERSYS_INIT
	; Init owned MANAGERS
	CALL    LEVELMAN_INIT
	CALL 	EVENTMAN_INIT

	; Load First Level
	XOR  	A 					; ┐
	LD 		[_ACTUAL_LVL], A  	; ┴─> Initialize ACTUAL_LVL as 0
	LD  	[_DEATHS_TOT], A
	LD  	[_DEATHS_TOT+1], A
	CALL 	GAMEMAN_LOAD_LEVEL
	RET

GAMEMAN_UPDATE::
; ---- Updates all managers and systems owned.
; DESTROYS: A, HL, DE, BC
;
	; Update owned MANAGERS
	CALL 	LEVELMAN_UPDATE
	; Update owned SYSTEMS
	; CALL ...
	RET

GAMEMAN_RENDER::
; ---- Updates entities in the screen (OAM)
; DESTROYS: A, HL, DE, BC
;
	; Update Render System through LevelManager
	CALL 	LEVELMAN_RENDER
	RET

GAMEMAN_LOAD_LEVEL::
; ---- Load current level.
; DESTROYS: A, HL, DE, BC
;
	CALL 	RENDERSYS_LCD_OFF 	; Turn off LCD before loading Level

	LD 		A, [_ACTUAL_LVL] 	; ┐
	SLA  	A 					; ├─> A = ACTUAL LEVEL * 2
	LD 		B, 0  				; │
	LD  	C, A 				; ┴─> BC = ACTUAL LEVEL * 2 (Ptr Ararys format)

	PUSH 	BC					; Save BC (Actual level in ptr ararys format)

	LD 		HL, MAP_PTR_ARRAY	; ┐
	ADD  	HL, BC   			; ┴─> HL = Pointer to actual level TileMap
	CALL 	LEVELMAN_LOAD_MAP	; Loads TileMap

	POP 	BC					; Retrieve BC (Actual level in ptr ararys format)

	LD 		HL, META_PTR_ARRAY	; ┐
	ADD  	HL, BC   			; ┴─> HL = Pointer to actual level MetaData
	CALL 	LEVELMAN_LOAD_META	; Loads TileMap

	CALL 	RENDERSYS_LCD_ON 	; Turn LCD back On

	RET

GAMEMAN_TERMINATE::
; ---- Terminates all managers owned.
; DESTROYS: A, HL, DE, BC
;
	CALL 	LEVELMAN_TERMINATE
	RET

;║ EOF
;╚══════════════════════════════════════════════════════════════════════