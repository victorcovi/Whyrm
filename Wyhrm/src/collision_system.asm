;╦══════════════════════════════════════════════════════════════════════
;║ COLLISION SYSTEM
;╬══════════════════════════════════════════════════════════════════════
;║ collision_system.asm - Wyhrm for GameBoy
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
; DESTROYS: A, HL, DE
;
	LD 		A, \1 - \2				; [8] ┐
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
MACRO CONVERT_POSITION
; ---- Converts Pixel position into Tile position. Direction in X.
; PARAMETERS:
;	 1 = Added amount to Y
;	 2 = Added amount to X
; 	DE = Pointer to first entity in the PHY entity array (Position).
; 	 B = X ref. added amount
; DESTROYS: A, HL, DE
;
	; CALCULATE Y
							; [DE] = Entity(N).Y (World)
	LD 		A, [DE]			; A = Y (World)
	ADD		\1 				; A = Y + Added amount.

	CALL 	CONVERT_Y 		; Y Pixel -> Y Tile (VRAM format)
	; [HL] = Y_TILE (VRAM format)

	PUSH	BC				; Save Number of entities to update
	LD  	BC, _DYN_COLLMAP
	ADD		HL, BC 			; Y_TILE + 1st TILEMAP pos
	POP 	BC 				; C = Number of entities to update

	; CALCULATE X
	INC 	DE 				; [DE] = Entity(N).X (World)
	LD 		A, [DE]			; A = X (World)
	ADD		\2 				; A = X + Added amount.

	CALL 	CONVERT_X 		; X Pixel -> X Tile (VRAM format)
	; A = X_TILE (VRAM format)

	ADD  	A, L 			; ┐ HL = 1st TILEMAP pos + Y_TILE + X_TILE
	LD  	L, A 			; ┴─> HL = Desired TILE position for current Entity
ENDM
MACRO CHECK_COLLISION_PLAYER
; ---- Checks if calculated tile is collisionable.
; PARAMETERS:
; 	1 = Mempos to next routine when no collision is detected.
;	2 = Mempos to next routine when collision is detected.
;	3 = Axis we are working on (Y or X).
; 	4 = Velocity adjustment for collision detection
; DESTROYS: A, HL, DE
;
	POINT_NEXT  	PHY_\3, PHY_X, E
	; [DE] = Y | [DE] = X
	LD 		A, [HL]
	AND 	%11110000
	CP 		BLOCK_MASK		; Is tile we are moving onto collisionable ?
	JR 		NZ, .NO_COLLISION\@
.COLLISION\@:
	; Calculate velocity to stop player with
	LD 		A, [DE] 		; ┐
	LD  	L, A 			; ┴─> L = Y | X
	LD 		A, [_TILE_\3]
	CALL 	CONVERT_REVERSE
	SUB		L 				; A = Tile pixel pos - Player pixel pos
	SUB 	\4 				; A = new player velocity (adjusted)
	LD 		L, A 			; Save A into L
	POINT_NEXT  	PHY_V\3, PHY_\3, E
	; [DE] = VY | [DE] = VX
	LD 		A, L 			; Retrieve A from L
	LD 		[DE], A 		; VY | VX = new player velocity (adjusted) 

	POINT_NEXT  	PHY_C\3, PHY_V\3, E
	; [DE] = CY | [DE] = CX
	LD 		A, [_COL_T]
	LD 		B, BLOCK
	ADD 	B
	LD 		[DE], A 		; Update entity colision type (X or Y dep. \3)

	POINT_INI		PHY_C\3, 0, E
	; [DE] = Y (Entity first component)
	JP		\2
.NO_COLLISION\@:
	CP 		MORTAL_MASK		; Is tile we are moving onto mortal ?
	JR 		NZ, .NO_MORTAL_COLL\@
.MORTAL_COLL\@:
	; Calculate velocity to stop player with
	LD 		A, [DE] 		; ┐
	LD  	L, A 			; ┴─> L = Y | X
	LD 		A, [_TILE_\3]
	CALL 	CONVERT_REVERSE
	SUB		L 				; A = Tile pixel pos - Player pixel pos
	SUB 	\4 				; A = new player velocity (adjusted)
	LD 		L, A 			; Save A into L
	POINT_NEXT  	PHY_V\3, PHY_\3, E
	; [DE] = VY | [DE] = VX
	LD 		A, L 			; Retrieve A from L
	LD 		[DE], A 		; VY | VX = new player velocity (adjusted) 

	POINT_NEXT  	PHY_C\3, PHY_V\3, E
	; [DE] = CY | [DE] = CX
	LD 		A, [_COL_T]
	LD 		B, BLOCK
	ADD 	B
	LD 		[DE], A 		; Update entity colision type (X or Y dep. \3)

	POINT_NEXT 	PHY_T, PHY_C\3, E
	; [DE]  = Entity(N).Type
	LD 		A, PLY_DEAD 		
	CALL 	STATE_REQUEST		; ┴─> Request to change to DEAD state
	POINT_INI		PHY_ST, 0, E
	; [DE] = Y (Entity first component)
	JP 		\2
.NO_MORTAL_COLL\@:
	CP 		WIN_MASK		; Is tile we are moving onto mortal ?
	JR 		NZ, .NO_END_COLL\@
.END_COLL\@:
	; Calculate velocity to stop player with
	LD 		A, [DE] 		; ┐
	LD  	L, A 			; ┴─> L = Y | X
	LD 		A, [_TILE_\3]
	CALL 	CONVERT_REVERSE
	SUB		L 				; A = Tile pixel pos - Player pixel pos
	SUB 	\4 				; A = new player velocity (adjusted)
	LD 		L, A 			; Save A into L
	POINT_NEXT  	PHY_V\3, PHY_\3, E
	; [DE] = VY | [DE] = VX
	LD 		A, L 			; Retrieve A from L
	LD 		[DE], A 		; VY | VX = new player velocity (adjusted) 

	POINT_NEXT  	PHY_C\3, PHY_V\3, E
	; [DE] = CY | [DE] = CX
	LD 		A, [_COL_T]
	LD 		B, BLOCK
	ADD 	B
	LD 		[DE], A 		; Update entity colision type (X or Y dep. \3)
	
	LD 		A, 1
	LD 		[_LVL_END], A

	POINT_INI		PHY_C\3, 0, E
	; [DE] = Y (Entity first component)
	JP 		\2
.NO_END_COLL\@:

	POINT_INI		PHY_\3, 0, E
	; [DE] = Y (Entity first component)
	JP		\1
ENDM
MACRO CHECK_COLLISION
; ---- Checks if calculated tile is collisionable.
; PARAMETERS:
; 	1 = Mempos to next routine when no collision is detected.
;	2 = Mempos to next routine when collision is detected.
;	3 = Axis we are working on (Y or X).
; 	4 = Velocity adjustment for collision detection
; DESTROYS: A, HL, DE
;
	POINT_NEXT  	PHY_\3, PHY_X, E
	; [DE] = Y | [DE] = X
	LD 		A, [HL]
	AND 	%11110000
	CP 		LIMIT_MASK		; Is tile we are moving onto collisionable ?
	JR 		NZ, .NO_COLLISION\@
.COLLISION\@:
	POINT_NEXT  	PHY_V\3, PHY_\3, E
	; [DE] = VY | [DE] = VX
	LD 		A, [DE]
	LD  	B, A
	XOR 	%11111111
	INC 	A
	LD 		[DE], A
	POINT_INI		PHY_V\3, 0, E

	;; Calculate velocity to stop entity with
	;LD 		A, [DE] 		; ┐
	;LD  	L, A 			; ┴─> L = Y | X
	;LD 		A, [_TILE_\3]
	;CALL 	CONVERT_REVERSE
	;SUB		L 				; A = Tile pixel pos - entity pixel pos
	;SUB 	\4 				; A = new entity velocity (adjusted)
	;LD 		L, A 			; Save A into L
	;POINT_NEXT  	PHY_V\3, PHY_\3, E
	;; [DE] = VY | [DE] = VX
	;LD 		A, L 			; Retrieve A from L
	;LD 		[DE], A 		; VY | VX = new entity velocity (adjusted) 

	;POINT_NEXT  	PHY_C\3, PHY_V\3, E
	;; [DE] = CY | [DE] = CX
	;LD 		A, [_COL_T]
	;LD 		B, BLOCK
	;ADD 	B
	;LD 		[DE], A 		; Update entity colision type (X or Y dep. \3)

	;POINT_INI		PHY_C\3, 0, E
	;; [DE] = Y (Entity first component)
	JP		\2
.NO_COLLISION\@:
	POINT_INI		PHY_\3, 0, E
	; [DE] = Y (Entity first component)
	JP		\1
ENDM

;┬───────────────────────────────────────────────────────────────────────
;│ RAM VARIABLES
;└  
SECTION "CollisionsysRAM", WRAM0
_TILE_X: 		DB 	; Tile number in X axis
_TILE_Y: 		DB 	; Tile number in Y axis
_COL_T:			DB 	; Type of collision:

SECTION "CollisionsysMAP", WRAM0,ALIGN[8]
_DYN_COLLMAP: 	DS	MAX_LEVEL_SIZE	; Copy of current background for
									; unrestricted collision checking 

;┬───────────────────────────────────────────────────────────────────────
;│ DATA AREA
;└  
SECTION "CollisionsysData", ROM0

;┬───────────────────────────────────────────────────────────────────────
;│ FUNCTIONS
;└ 
SECTION "CollisionsysFun", ROM0
COLLISIONSYS_INIT::
; ---- Routine to initialize CollisionSystem.
; DESTROYS: 
;	-
	    RET

COLLISIONSYS_UPDATE::
; ---- Converts world pixel positions into tile positions and checks for collision.
; PARAMETERS: 
; 	DE = Pointer to first entity in the PHY entity array (Position).
;  	 A = Number of entities to update.
; DESTROYS: 
;	A, HL, DE, BC
;
	LD 		C, A 						; C = Number of entities to update

; ============ CHECK PLAYER COLLISIONS

	POINT_NEXT 		PHY_CY, PHY_Y, E	; ┐
	; [DE] = Entity(N).CY 				; │
	XOR 	A  							; │
	LD   	[DE], A 					; ┴─> Reset collision indicator of entity

	POINT_NEXT 		PHY_CX, PHY_CY, E	; ┐
	; [DE] = Entity(N).CX 				; │
	XOR 	A  							; │
	LD   	[DE], A 					; ┴─> Reset collision indicator of entity

; ---- CHECK Y
.Y_PLY:
	POINT_NEXT 		PHY_VY, PHY_CX, E
	; [DE] = VY
	
	LD 		A, [DE] 					; A = VY
	OR 		0  							; ┐
	JP		NZ, .CHECK_Y_PLY			; ┴─> Is VY 0 ?
	POINT_INI		PHY_VY, 0, E
	JP		.X_PLY
.CHECK_Y_PLY:
	BIT 	7, A						; Check for sign
	JP  	Z, .DOWN_L_PLY				; Going UP or DOWN ?
.UP_L_PLY:
	LD  	B, -( MAX_ENTITY_H )		; ┐
	ADD		B 							; │
	LD  	B, A 						; ┴─> B = VY - ENTITY_H

	LD 		A, UP_L_T  					; ┐
	LD 		[_COL_T], A  				; ┴─> Collision type setup

	POINT_INI		PHY_VY, 0, E
	; [DE] = Y

	CONVERT_POSITION 	B, -(ENTITY_W/2)
	CHECK_COLLISION_PLAYER	.UP_R_PLY, .X_PLY, Y, -( MAX_ENTITY_H + 8 );(Tile_H=8)
.UP_R_PLY:
	POINT_NEXT  	PHY_VY, 0, E
	; [DE] = VY
	LD 		A, [DE] 					; A = VY
	LD  	B, -( MAX_ENTITY_H )		; ┐
	ADD		B 							; │
	LD  	B, A 						; ┴─> B = VY - ENTITY_H

	POINT_INI		PHY_VY, 0, E
	; [DE] = Y

	CONVERT_POSITION 	B, ENTITY_W/2-1
	CHECK_COLLISION_PLAYER	.X_PLY, .X_PLY, Y, -( MAX_ENTITY_H + 8 );(Tile_H=8)
.DOWN_L_PLY:
	LD  	B, MAX_ENTITY_H-ENTITY_H-1	; ┐
	ADD		B 							; │
	LD  	B, A 						; ┴─> B = VY - (ENTITY_W/2)

	LD 		A, DO_R_T  					; ┐
	LD 		[_COL_T], A  				; ┴─> Collision type setup
	
	POINT_INI		PHY_VY, 0, E
	; [DE] = Y
	
	CONVERT_POSITION 	B, -(ENTITY_W/2)
	CHECK_COLLISION_PLAYER	.DOWN_R_PLY, .X_PLY, Y, -( MAX_ENTITY_H-ENTITY_H )
.DOWN_R_PLY:
	POINT_NEXT  	PHY_VY, 0, E
	; [DE] = VY
	LD 		A, [DE] 					; A = VY
	LD  	B, MAX_ENTITY_H-ENTITY_H-1	; ┐
	ADD		B 							; │
	LD  	B, A 						; ┴─> B = VY - (ENTITY_W/2) - 1
	
	POINT_INI		PHY_VY, 0, E
	; [DE] = Y
	
	CONVERT_POSITION	B, ENTITY_W/2-1
	CHECK_COLLISION_PLAYER	.X_PLY, .X_PLY, Y, -( MAX_ENTITY_H-ENTITY_H )

; ---- CHECK X
.X_PLY:
	POINT_NEXT  	PHY_VX, 0, E
	; [DE] = VX

	LD 		A, [DE] 		; A = VX
	OR 		0  					; ┐
	JP		NZ, .CHECK_X_PLY	; ┴─> Is VX 0 ?
	POINT_INI		PHY_VX, 0, E
	JP		.END_ITERATION_PLY
.CHECK_X_PLY:
	BIT 	7, A			; Check for sign
	JP  	Z, .RIGHT_U_PLY	; Going LEFT or RIGHT ?
.LEFT_U_PLY:
	LD  	B, -( ENTITY_W/2 )			; ┐
	ADD		B 							; │
	LD  	B, A 						; ┴─> B = VX - ENTITY_W/2

	LD 		A, UP_L_T  					; ┐
	LD 		[_COL_T], A  				; ┴─> Collision type setup

	POINT_INI		PHY_VX, 0, E
	; [DE] = Y

	CONVERT_POSITION 	-( MAX_ENTITY_H ), B
	CHECK_COLLISION_PLAYER	.LEFT_D_PLY, .END_ITERATION_PLY, X, -( ENTITY_W/2 + 8 );(Tile_W=8)
.LEFT_D_PLY:
	POINT_NEXT  	PHY_VX, 0, E
	; [DE] = VY
	LD 		A, [DE] 					; A = VY
	LD  	B, -( ENTITY_W/2 )			; ┐
	ADD		B 							; │
	LD  	B, A 						; ┴─> B = VY - ENTITY_H
	POINT_INI		PHY_VX, 0, E
	; [DE] = Y

	CONVERT_POSITION 	-( MAX_ENTITY_H - ENTITY_H + 1 ), B
	CHECK_COLLISION_PLAYER	.END_ITERATION_PLY, .END_ITERATION_PLY, X, -( ENTITY_W/2 + 8 );(Tile_W=8)
.RIGHT_U_PLY:
	LD  	B, ENTITY_W/2 - 1			; ┐
	ADD		B 							; │
	LD  	B, A 						; ┴─> B = VY - (ENTITY_W/2)

	LD 		A, DO_R_T 					; ┐
	LD 		[_COL_T], A  				; ┴─> Collision type setup
	
	POINT_INI		PHY_VX, 0, E
	; [DE] = Y
	
	CONVERT_POSITION 	-( MAX_ENTITY_H ), B
	CHECK_COLLISION_PLAYER	.RIGHT_D_PLY, .END_ITERATION_PLY, X, ( ENTITY_W/2 )
.RIGHT_D_PLY:
	POINT_NEXT  	PHY_VX, 0, E
	; [DE] = VY
	LD 		A, [DE] 					; A = VY
	LD  	B, ENTITY_W/2 - 1			; ┐
	ADD		B 							; │
	LD  	B, A 						; ┴─> B = VY - (ENTITY_W/2) - 1
	
	POINT_INI		PHY_VX, 0, E
	; [DE] = Y
	
	CONVERT_POSITION	-( MAX_ENTITY_H - ENTITY_H + 1 ), B
	CHECK_COLLISION_PLAYER	.END_ITERATION_PLY, .END_ITERATION_PLY, X, ( ENTITY_W/2 )

.END_ITERATION_PLY:
	; COUNTER CHECKS
	DEC  	C 				; One less entity to update
	RET		Z 				; No more entities remaining ?
	
	; POINT TO NEXT ENTITY
	POINT_NEXT  	ENTITY_PHY_SIZE, 0, E

; ============ CHECK REST OF ENTITIIES
.UPDATE_LOOP:

	POINT_NEXT 		PHY_CY, PHY_Y, E	; ┐
	; [DE] = Entity(N).CY 				; │
	XOR 	A  							; │
	LD   	[DE], A 					; ┴─> Reset collision indicator of entity

	POINT_NEXT 		PHY_CX, PHY_CY, E	; ┐
	; [DE] = Entity(N).CX 				; │
	XOR 	A  							; │
	LD   	[DE], A 					; ┴─> Reset collision indicator of entity

; ---- CHECK Y
.Y:
	POINT_NEXT  	PHY_VY, PHY_CX, E
	; [DE] = VY
	
	LD 		A, [DE] 		; A = VY
	OR 		0  				; ┐
	JP		NZ, .CHECK_Y	; ┴─> Is VY 0 ?
	POINT_INI		PHY_VY, 0, E
	JP		.X
.CHECK_Y:
	BIT 	7, A			; Check for sign
	JP  	Z, .DOWN_L		; Going UP or DOWN ?
.UP_L:
	LD  	B, -( MAX_ENTITY_H )		; ┐
	ADD		B 							; │
	LD  	B, A 						; ┴─> B = VY - ENTITY_H

	LD 		A, UP_L_T  					; ┐
	LD 		[_COL_T], A  				; ┴─> Collision type setup

	POINT_INI		PHY_VY, 0, E
	; [DE] = Y

	CONVERT_POSITION 	B, -(ENTITY_W/2)
	;CHECK_COLLISION		.UP_R, .X, PHY_VY
	CHECK_COLLISION		.UP_R, .X, Y, -( MAX_ENTITY_H + 8 );(Tile_H=8)
.UP_R:
	POINT_NEXT  	PHY_VY, 0, E
	; [DE] = VY
	LD 		A, [DE] 					; A = VY
	LD  	B, -( MAX_ENTITY_H )		; ┐
	ADD		B 							; │
	LD  	B, A 						; ┴─> B = VY - ENTITY_H
	POINT_INI		PHY_VY, 0, E
	; [DE] = Y

	CONVERT_POSITION 	B, ENTITY_W/2-1
	;CHECK_COLLISION		.X, .X, PHY_VY
	CHECK_COLLISION		.X, .X, Y, -( MAX_ENTITY_H + 8 );(Tile_H=8)
.DOWN_L:
	LD  	B, MAX_ENTITY_H-ENTITY_H_AI-1	; ┐
	ADD		B 								; │
	LD  	B, A 							; ┴─> B = VY - (ENTITY_W/2)

	LD 		A, DO_R_T  						; ┐
	LD 		[_COL_T], A  					; ┴─> Collision type setup
	
	POINT_INI		PHY_VY, 0, E
	; [DE] = Y
	
	CONVERT_POSITION 	B, -(ENTITY_W/2)
	;CHECK_COLLISION		.DOWN_R, .X, PHY_VY
	CHECK_COLLISION		.DOWN_R, .X, Y, -( MAX_ENTITY_H-ENTITY_H_AI )
.DOWN_R:
	POINT_NEXT  	PHY_VY, 0, E
	; [DE] = VY
	LD 		A, [DE] 						; A = VY
	LD  	B, MAX_ENTITY_H-ENTITY_H_AI-1	; ┐
	ADD		B 								; │
	LD  	B, A 							; ┴─> B = VY - (ENTITY_W/2) - 1
	
	POINT_INI		PHY_VY, 0, E
	; [DE] = Y
	
	CONVERT_POSITION	B, ENTITY_W/2-1
	;CHECK_COLLISION		.X, .X, PHY_VY
	CHECK_COLLISION		.X, .X, Y, -( MAX_ENTITY_H-ENTITY_H_AI )

; ---- CHECK X
.X:
	POINT_NEXT  	PHY_VX, 0, E
	; [DE] = VX
	
	LD 		A, [DE] 		; A = VX
	OR 		0  				; ┐
	JP		NZ, .CHECK_X	; ┴─> Is VX 0 ?
	POINT_INI		PHY_VX, 0, E
	JP		.END_ITERATION
.CHECK_X:
	BIT 	7, A			; Check for sign
	JP  	Z, .RIGHT_U		; Going LEFT or RIGHT ?
.LEFT_U:
	LD  	B, -( ENTITY_W_AI/2 )		; ┐
	ADD		B 							; │
	LD  	B, A 						; ┴─> B = VX - ENTITY_W/2

	LD 		A, UP_L_T  					; ┐
	LD 		[_COL_T], A  				; ┴─> Collision type setup

	POINT_INI		PHY_VX, 0, E
	; [DE] = Y

	CONVERT_POSITION 	-( MAX_ENTITY_H ), B
	;CHECK_COLLISION		.LEFT_D, .END_ITERATION, PHY_VX
	CHECK_COLLISION		.LEFT_D, .END_ITERATION, X, -( ENTITY_W_AI/2 + 8 );(Tile_W=8)
.LEFT_D:
	POINT_NEXT  	PHY_VX, 0, E
	; [DE] = VY
	LD 		A, [DE] 					; A = VY
	LD  	B, -( ENTITY_W_AI/2 )		; ┐
	ADD		B 							; │
	LD  	B, A 						; ┴─> B = VY - ENTITY_H
	POINT_INI		PHY_VX, 0, E
	; [DE] = Y

	CONVERT_POSITION 	-( MAX_ENTITY_H - ENTITY_H + 1 ), B
	;CHECK_COLLISION		.END_ITERATION, .END_ITERATION, PHY_VX
	CHECK_COLLISION		.END_ITERATION, .END_ITERATION, X, -( ENTITY_W_AI/2 + 8 );(Tile_W=8)
.RIGHT_U:
	LD  	B, ENTITY_W_AI/2 - 1		; ┐
	ADD		B 							; │
	LD  	B, A 						; ┴─> B = VY - (ENTITY_W/2)

	LD 		A, DO_R_T 					; ┐
	LD 		[_COL_T], A  				; ┴─> Collision type setup
	
	POINT_INI		PHY_VX, 0, E
	; [DE] = Y
	
	CONVERT_POSITION 	-( MAX_ENTITY_H ), B
	;CHECK_COLLISION		.RIGHT_D, .END_ITERATION, PHY_VX
	CHECK_COLLISION		.RIGHT_D, .END_ITERATION, X, ( ENTITY_W_AI/2 )
.RIGHT_D:
	POINT_NEXT  	PHY_VX, 0, E
	; [DE] = VY
	LD 		A, [DE] 					; A = VY
	LD  	B, ENTITY_W_AI/2 - 1		; ┐
	ADD		B 							; │
	LD  	B, A 						; ┴─> B = VY - (ENTITY_W/2) - 1
	
	POINT_INI		PHY_VX, 0, E
	; [DE] = Y
	
	CONVERT_POSITION	-( MAX_ENTITY_H - ENTITY_H + 1 ), B
	;CHECK_COLLISION		.END_ITERATION, .END_ITERATION, PHY_VX
	CHECK_COLLISION		.END_ITERATION, .END_ITERATION, X, ( ENTITY_W_AI/2 )

.END_ITERATION:
	; COUNTER CHECKS
	DEC  	C 				; One less entity to update
	RET		Z 				; No more entities remaining ?
	
	; POINT TO NEXT ENTITY
	POINT_NEXT  	ENTITY_PHY_SIZE, 0, E

	JP  	.UPDATE_LOOP

COLLISIONSYS_UPDATE_EXE::
; ---- Converts world pixel positions into tile positions and checks for collision.
; PARAMETERS:
; 	HL = Pointer to first entity in the PHY entity array (Position). 
; 	DE = Pointer to first entity in the PHY entity array (Position).
;  	 A = Number of entities to update.
; DESTROYS: 
;	A, HL, DE, BC
;
	LD 		C, A 		; C = Number of entities to update
	DEC  	C 			; Skip player entity. Dont check collisions with itself.
	RET		Z 			; No more entities remaining ?

	POINT_NEXT  	ENTITY_PHY_SIZE, 0, L
	; [HL] = AI_Entity(0).Y

.UPDATE_LOOP:

; !! Is player dead ? Stop checking for collisions.

	PUSH 	BC 			; Save entity counter.

; ---- CHECK Y
.Y:
	; [HL] = AI_Entity(N).Y
	LD 		A, [HL] 	; A = AI_Entity(N).Y
	LD 		C, - MAX_ENTITY_H - ( - MAX_ENTITY_H + ENTITY_H - 1)
	ADD 	C 			; A = Lower Y limit
	LD 		B, A 		; B = Lower Y limit

						; [DE] = Player.Y
	LD  	A, [DE]		; A = Player.Y

	CP  	B
	JR		C, .NO_COLLISION_Y

	LD 		B, A 		; B = Player.Y + Player.VY
	LD 		A, [HL] 	; A = AI_Entity(N).Y
	LD 		C, - MAX_ENTITY_H + ENTITY_H_AI - 1 - ( - MAX_ENTITY_H )
	ADD 	C 			; A = Higher Y limit

	CP 		B
	JR		NC, .COLLISION_Y

.NO_COLLISION_Y:
	; Next iteration.
	;POINT_INI 		PHY_VY, 0, E
	JR 		.END_ITERATION
.COLLISION_Y:
	; Check in X
	;POINT_INI 		PHY_VY, 0, E

; ---- CHECK X
.X:
	; [HL] = AI_Entity(N).Y
	INC  	HL  		; [HL] = AI_Entity(N).X
	LD 		A, [HL] 	; A = AI_Entity(N).X
	LD 		C, - (ENTITY_W_AI/2) - ( ENTITY_W/2 - 1)
	ADD 	C 			; A = Lower X limit
	LD 		B, A 		; B = Lower X limit

	; [DE] = Player.Y
	INC  	DE  		; [DE] = Player.X
	LD  	A, [DE]		; A    = Player.X

	CP  	B
	JR		C, .NO_COLLISION_X

	LD 		B, A 		; B = Player.X + Player.VX
	LD 		A, [HL] 	; A = AI_Entity(N).X
	LD 		C, ENTITY_W_AI/2 - 1 + ENTITY_W/2
	ADD 	C 			; A = Higher X limit

	CP 		B
	JR		NC, .COLLISION_X

.NO_COLLISION_X:
	; Next iteration.
	POINT_INI 		PHY_X, 0, E
	POINT_INI 		PHY_X, 0, L
	JR 		.END_ITERATION
.COLLISION_X:
	; Change player state to dead.
	; !! CALL ...
	POINT_NEXT 	PHY_T, PHY_X, E
	; [DE]  = Entity(N).Type
	LD 		A, PLY_RBD_TWO 		
	CALL 	STATE_REQUEST		; ┴─> Request to change to DEAD state

	POINT_INI 		PHY_ST, 0, E
	POINT_INI 		PHY_X, 0, L

.END_ITERATION:
	; COUNTER CHECKS
	POP 	BC 			; Retrieve entity counter.
	DEC  	C 			; One less entity to update
	RET		Z 			; No more entities remaining ?
	
	; POINT TO NEXT ENTITY
	POINT_NEXT  	ENTITY_PHY_SIZE, 0, L

	JP  	.UPDATE_LOOP

COLLISIONSYS_LOAD_COLLMAP::
; ---- Loads TileMap into WRAM for posterior collision check.
; PARAMETERS: 
; 	HL = ROM mempos of TileMap to load
; DESTROYS: 
;	A, HL, DE, BC
;
    LD      DE, _DYN_COLLMAP
    LD      BC, MAX_LEVEL_SIZE
    CALL    LDIR
    RET

;┬───────────────────────────────────────────────────────────────────────
;│ LOCAL FUNCTIONS
;└ 
CONVERT_Y:
; ---- Converts Y Pixel position into Tile position. Y / 8 * 32.
; PARAMETERS:
;	 A = Y + Amount to add to Y
; DESTROYS: HL
; RETURNS:
; 	HL = Entity.Y in VRAM format
;
	SRL 	A 				;				Y / 2
	SRL 	A 				; 				Y / 4
	SRL 	A 				; A = Y_TILE = 	Y / 8

	LD  	[_TILE_Y], A 	; Save Tile number

	LD 		H, $00 			; ┐
	LD  	L, A 			; ┴─> HL = Y / 8
	ADD	 	HL, HL			; 				Y / 8 * 2
	ADD	 	HL, HL			; 				Y / 8 * 4
	ADD	 	HL, HL			; 				Y / 8 * 8
	ADD	 	HL, HL			; 				Y / 8 * 16
	ADD	 	HL, HL			; A = Y_TILE = 	Y / 8 * 32
	RET

CONVERT_X:
; ---- Converts X Pixel position into Tile position. X / 8.
; PARAMETERS:
;	 A = X + Amount to add to X
; DESTROYS: A
; RETURNS:
; 	 A = Entity.X in VRAM format
;
	SRL 	A 				;				X / 2
	SRL 	A 				; 				X / 4
	SRL 	A 				; A = X_TILE = 	X / 8

	LD  	[_TILE_X], A 	; Save Tile number
	RET

CONVERT_REVERSE:
; ---- Converts Tile number into Pixel position.
; PARAMETERS:
;	A = Tile number
; DESTROYS: A
; RETURNS:
; 	A = Tile initial pixel position
;
	; Calculate initial position of tile in Y axis
	SLA 	A 				;				X * 2
	SLA 	A 				; 				X * 4
	SLA 	A 				; A = X_TILE = 	X * 8
	RET

;║ EOF
;╚══════════════════════════════════════════════════════════════════════