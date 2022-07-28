;╦══════════════════════════════════════════════════════════════════════
;║ ANIMATION MANAGER
;╬══════════════════════════════════════════════════════════════════════
;║ animation_manager.asm - Wyhrm for GameBoy
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
; 	1 = Corresponding entity size
; 	2 = Array offset
; 	3 = Register (L or E)
; DESROYS: A, HL, DE
;
	LD 		A, \1 - (\2)			; [8] ┐
	ADD 	\3 						; [4] ┼─> A = LOW(Entity(N).X + (ENT_SIZE-1))
	LD 		\3, A 					; [4] ┴─> L = LOW(Entity(N+1).Y)
ENDM
MACRO POINT_INI
; ---- Points to the start position of the corresponding array.
; PARAMETERS:
; 	1 = Corresponding entity size
; 	2 = Array offset
; 	3 = Register (L or E)
; DESTROYS: A, HL, DE
;
	LD 		A, -(\1 + \2)			; [8] ┐
	ADD 	\3 						; [4] ┼─> A = LOW(Entity(N).X + (ENT_SIZE-1))
	LD 		\3, A 					; [4] ┴─> L = LOW(Entity(N+1).Y)
ENDM

;┬───────────────────────────────────────────────────────────────────────
;│ DATA AREA
;└  
SECTION "AnimationmanData", ROM0
; ==== SPRITES BY STATE
; ----
PLAYER_SPRITES:
; --
.STATIC:
DB 	$00							; Sprite 0 + X (IDLE, WALK1, WALK2, JUMPDOWN)
.DEAD:
DB 	$60							; Sprite 0 + X (DEAD)
; -- 
.JUMP:
DB 	$30							; Sprite 0 + X (JUMPUP)
; --
.DASH_L:
DB 	$50							; Sprite 0 + X (DASH)
; --
.DASH_R:
DB 	$50							; Sprite 0 + X (DASH)
; --
.WALL_L:
DB 	$30							; Sprite 0 + X (JUMPUP)
; --
.WALL_R:
DB 	$30							; Sprite 0 + X (JUMPUP)
; --
.RBND_ONE:
DB 	$00							; Sprite 0 + X (NOTHING)
; --
.RBND_TWO:
DB 	$30							; Sprite 0 + X (JUMPUP)

;┬───────────────────────────────────────────────────────────────────────
;│ RAM VARIABLES
;└  
SECTION "AnimationmanRAM", WRAM0
; ---- MOVEMENT VALUE BY STATE
;_CURRENT_SPRITE: 	DB
_LF_PREV:			DB
_SATIC_CT:			DB

;┬───────────────────────────────────────────────────────────────────────
;│ FUNCTIONS
;└ 
SECTION "AnimationmanFun", ROM0
ANIMATIONMAN_INIT::
; ---- Routine to initialize AnimationManager.
; DESTROYS: 
;	-
;	
	;LD 		A, HIGH(_VRAM)			; HIGH(TILE_DATA)
	;LD 		[_CURRENT_SPRITE], A
	LD 		A, LF_LEFT
	LD 		[_LF_PREV], A
	XOR 	A
	LD 		[_SATIC_CT], A
    RET

ANIMATIONMAN_UPDATE::
; ---- Updates states and velocity (according to state) of entities.
; PARAMETERS: 
; 	DE = Pointer to first entity in the PHY entity array (State).
; DESTROYS: 
;	A, HL, DE, BC
;
	;LD 		C, A 			; C = Number of entities to update

.UPDATE_LOOP:
	;PUSH 	BC 				; Save entities counter

	LD 		H, $C0 
	LD 		L, $00 			;!! $C000 siempre es posicion de player en sOAM
	
.FLIP_LEFT:
	LD 		A, [_LF_PREV]
	CP 		LF_LEFT
	JP 		Z, .END_FLIP_LEFT

	POINT_NEXT		2, 0, L

	LD 		A, [HL]
	LD  	B, A

	INC 	HL 				; (3)
	LD 		A, [HL]			; Mirror
	RES 	5, A 			; OAMF_XFLIP
	LD 		[HL], A

	POINT_NEXT		2+4, 3, L

	LD 		A, [HL]
	LD 		C, A
	LD 		A, B
	LD 		[HL], A
	
	INC 	HL 				; (3)
	LD 		A, [HL]			; Mirror
	RES 	5, A 			; OAMF_XFLIP
	LD 		[HL], A

	POINT_NEXT		2, 3+4, L

	LD 		A, C
	LD 		[HL], A

	POINT_NEXT		2+8, 2, L

	LD 		A, [HL]
	LD  	B, A

	INC 	HL 				; (3)
	LD 		A, [HL]			; Mirror
	RES 	5, A 			; OAMF_XFLIP
	LD 		[HL], A

	POINT_NEXT		2+12, 3+8, L

	LD 		A, [HL]
	LD 		C, A
	LD 		A, B
	LD 		[HL], A
	
	INC 	HL 				; (3)
	LD 		A, [HL]			; Mirror
	RES 	5, A 			; OAMF_XFLIP
	LD 		[HL], A

	POINT_NEXT		2+8, 3+12, L

	LD 		A, C
	LD 		[HL], A

	LD 		A, LF_LEFT
	LD 		[_LF_PREV], A
.END_FLIP_LEFT:

	LD 		A, [DE]
	LD 		C, A
	LD 		B, $00
	LD 		HL, PLAYER_SPRITES
	ADD 	HL, BC
	LD 		A, [HL]
	LD 		B, A

	LD 		A, C
	CP 		PLY_STATIC
	JR 		NZ, .NO_STATIC
	POINT_NEXT		PHY_VX, PHY_ST, E
	LD 		A, [DE]
	CP 		0
	JR 		Z, .PURE_STATIC
	LD 		A, [_SATIC_CT] 
	ADD 	B
	LD 		B, A
.PURE_STATIC:
	POINT_NEXT		PHY_ST, PHY_VX, E
.NO_STATIC:
	LD 		H, $C0 
	LD 		L, $00 			;!! $C000 siempre es posicion de player en sOAM

	POINT_NEXT		2, 0, L
	LD 		[HL], B
	INC 	B

	POINT_NEXT		2+4, 2, L
	LD 		[HL], B
	INC 	B

	POINT_NEXT		2+8, 2+4, L
	LD 		[HL], B
	INC 	B

	POINT_NEXT		2+12, 2+8, L
	LD 		[HL], B
.END_SPRITE_UPDATE:
	
	LD 		H, $C0 
	LD 		L, $00 			;!! $C000 siempre es posicion de player en sOAM
	
	POINT_NEXT		PHY_LF, PHY_ST, E
	LD 		A, [DE]
	CP 		LF_RIGHT
	JR 		NZ, .END_FLIP
.FLIP_RIGHT:
	LD 		A, [_LF_PREV]
	CP 		LF_RIGHT
	JP 		Z, .END_FLIP

	POINT_NEXT		2, 0, L

	LD 		A, [HL]
	LD  	B, A

	INC 	HL 				; (3)
	LD 		A, [HL]			; Mirror
	SET 	5, A 			; OAMF_XFLIP
	LD 		[HL], A

	POINT_NEXT		2+4, 3, L

	LD 		A, [HL]
	LD 		C, A
	LD 		A, B
	LD 		[HL], A
	
	INC 	HL 				; (3)
	LD 		A, [HL]			; Mirror
	SET 	5, A 			; OAMF_XFLIP
	LD 		[HL], A

	POINT_NEXT		2, 3+4, L

	LD 		A, C
	LD 		[HL], A

	POINT_NEXT		2+8, 2, L

	LD 		A, [HL]
	LD  	B, A

	INC 	HL 				; (3)
	LD 		A, [HL]			; Mirror
	SET 	5, A 			; OAMF_XFLIP
	LD 		[HL], A

	POINT_NEXT		2+12, 3+8, L

	LD 		A, [HL]
	LD 		C, A
	LD 		A, B
	LD 		[HL], A
	
	INC 	HL 				; (3)
	LD 		A, [HL]			; Mirror
	SET 	5, A 			; OAMF_XFLIP
	LD 		[HL], A

	POINT_NEXT		2+8, 3+12, L

	LD 		A, C
	LD 		[HL], A

	LD 		A, LF_RIGHT
	LD 		[_LF_PREV], A
.END_FLIP:

.END_ITERATION:
	; COUNTER CHECKS
	;POP 	BC 				; Retrieve entities counter
	;DEC  	C 				; One less entity to update
	
	; POINT TO NEXT ENTITY TYPE
	; POINT_NEXT
	CALL 	UPDATE_CT; !! PROVISIONAL 
	RET ; !! PROVISIONAL
	JP  	.UPDATE_LOOP

;┬───────────────────────────────────────────────────────────────────────
;│ LOCAL FUNCTIONS
;└ 
UPDATE_CT:
	LD  	A, [_SATIC_CT]
	CP 		0
	JR 		Z, .RESTART
	SUB 	$10
	LD  	[_SATIC_CT], A
	RET
.RESTART:
	ADD 	$10
	LD  	[_SATIC_CT], A
	RET

;║ EOF
;╚══════════════════════════════════════════════════════════════════════