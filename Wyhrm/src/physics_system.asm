;╦══════════════════════════════════════════════════════════════════════
;║ PHYSICS SYSTEM
;╬══════════════════════════════════════════════════════════════════════
;║ physics_system.asm - Wyhrm for GameBoy
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
; ---- Points to next entity in corresponding array
; PARAMETERS:
; 	1 = Corresponding entity size
; 	2 = Register (L or E)
; DESTROYS: A, HL, DE
;
	LD 		A, \1 -1				; [8] ┐
	ADD 	\2 						; [4] ┼─> A = LOW(Entity(N).X + (ENT_SIZE-1))
	LD 		\2, A 					; [4] ┴─> L = LOW(Entity(N+1).Y)
ENDM

;┬───────────────────────────────────────────────────────────────────────
;│ DATA AREA
;└  
SECTION "PhysicssysData", ROM0

;┬───────────────────────────────────────────────────────────────────────
;│ FUNCTIONS
;└ 
SECTION "PhysicssysFun", ROM0
PHYSICSSYS_INIT::
; ---- Routine to initialize physics system.
; DESTROYS: 
;	-
;	
    RET

PHYSICSSYS_UPDATE::
; ---- Updates velocity and positions of entities.
; PARAMETERS: 
; 	HL = Pointer to first entity in the PHY entity array (Position).
; 	DE = Pointer to first entity in the PHY entity array (Velocity).
;  	 A = Number of entities to update.
; DESTROYS: 
;	A, HL, DE, BC
;
	LD 		B, A 			; B = Number of entities to update

	; UPDATE Y
							; [HL] = Entity(N).Y
							; [DE] = Entity(N).VY
	LD 		A, [DE]			; A = Entity(N).VY
	ADD  	A, [HL] 		; ┐
	LD 		[HL], A 		; ┴─> [HL] = Y + (+/-)VY . Updated Y

	;LD 		A, $02 			; Add gravity
	;LD 		[DE], A			; [DE] = Player Gravity

	; UPDATE X
	INC 	HL 				; [HL] = Entity(N).X
	INC  	DE 				; [DE] = Entity(N).VX
	LD 		A, [DE]			; A = Entity(N).VX

	; ┌─── LAST FACED DIRECTION UPDATE
	LD  	C, A
	LD 		A, PHY_LF - PHY_VX	; [8] ┐
	ADD 	E 					; [4] ┼─> A = LOW(Entity(N).X + (ENT_SIZE-1))
	LD 		E, A 				; [4] ┴─> L = LOW(Entity(N+1).Y)
	LD   	A, C 			; A = Entity(N).VX
	CP 		0
	JR 		Z, .LAST_FACED_END
	BIT 	7, C				; Check for sign
	JP  	Z, .LAST_FACED_RIGHT; Going LEFT or RIGHT ?
.LAST_FACED_LEFT:
	LD 		A, 0
	LD  	[DE], A
	JR 		.LAST_FACED_END
.LAST_FACED_RIGHT:
	LD 		A, 1
	LD  	[DE], A
.LAST_FACED_END:
	LD 		A, PHY_VX - PHY_LF	; [8] ┐
	ADD 	E 					; [4] ┼─> A = LOW(Entity(N).X + (ENT_SIZE-1))
	LD 		E, A 				; [4] ┴─> L = LOW(Entity(N+1).Y)
	LD   	A, C 			; A = Entity(N).VX
	; └─── LAST FACED DIRECTION UPDATE END

	ADD  	A, [HL] 		; ┐
	LD 		[HL], A 		; ┴─> [HL] = X + (+/-)VX . Updated X
	
	; COUNTER CHECKS
	DEC  	B 				; One less entity to update
	RET		Z 				; No more entities remaining ?
	
	; POINT TO NEXT ENTITY
	POINT_NEXT 	ENTITY_PHY_SIZE, L
	POINT_NEXT 	ENTITY_PHY_SIZE, E

	; ---- UPDATE NPC ENTITIES
.UPDATE_LOOP:
	; UPDATE Y
							; [HL] = Entity(N).Y
							; [DE] = Entity(N).VY
	LD 		A, [DE]			; A = Entity(N).VY
	ADD  	A, [HL] 		; ┐
	LD 		[HL], A 		; ┴─> [HL] = Y + (+/-)VY . Updated Y

	; UPDATE X
	INC 	HL 				; [HL] = Entity(N).X
	INC  	DE 				; [DE] = Entity(N).VX
	LD 		A, [DE]			; A = Entity(N).VX
	ADD  	A, [HL] 		; ┐
	LD 		[HL], A 		; ┴─> [HL] = X + (+/-)VX . Updated X
	
	; COUNTER CHECKS
	DEC  	B 				; One less entity to update
	RET		Z 				; No more entities remaining ?
	
	; POINT TO NEXT ENTITY
	POINT_NEXT 	ENTITY_PHY_SIZE, L
	POINT_NEXT 	ENTITY_PHY_SIZE, E

	JR  	.UPDATE_LOOP

;┬───────────────────────────────────────────────────────────────────────
;│ LOCAL FUNCTIONS
;└ 

;║ EOF
;╚══════════════════════════════════════════════════════════════════════