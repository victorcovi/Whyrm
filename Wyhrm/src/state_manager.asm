;╦══════════════════════════════════════════════════════════════════════
;║ STATE MANAGER
;╬══════════════════════════════════════════════════════════════════════
;║ state_manager.asm - Wyhrm for GameBoy
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

;┬───────────────────────────────────────────────────────────────────────
;│ DATA AREA
;└  
SECTION "StatemanData", ROM0
; ==== MOVEMENT TABLES
DEAD_TABLE:
.START:
DB  $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
DB  $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
DB  $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
DB  $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
DB  $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
DB  $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
DB  $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
DB  $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
DB  $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.END:
STATIC_TABLE:
.START:
DB  $80, $80, $80, $80, $80, $80, $80, $80, $80, $80
DB  $80, $80, $80, $80, $80, $80, $80, $80, $80, $80
DB  $80, $80, $80, $80, $80, $80, $80, $80, $80, $80
.END:
GRAV_TABLE:
.START:
DB  $02, $01, $01, $01
.END:
JUMP_TABLE:
.START:
DB  $00,-$00,-$01,-$01,-$01,-$01,-$01,-$01,-$01,-$01
DB -$02,-$02,-$02,-$02,-$02,-$02,-$02,-$02,-$02,-$02
DB -$02,-$02,-$02,-$02,-$02,-$02,-$02,-$02,-$02,-$02
.END:
DASH_R_TABLE:
.START:
DB  $03, $03, $03, $03, $03, $03, $03, $03
.END:
DASH_L_TABLE:
.START:
DB -$03,-$03,-$03,-$03,-$03,-$03,-$03,-$03
.END:
WALL_R_TABLE:
.START:
DB  $80, $80, $80, $80, $80, $80, $80, $80, $80, $80
DB  $80, $80, $80, $01, $01, $01, $01, $01, $01, $01
DB  $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
.END:
WALL_L_TABLE:
.START:
DB  $80, $80, $80, $80, $80, $80, $80, $80, $80, $80
DB  $80, $80, $80,-$01,-$01,-$01,-$01,-$01,-$01,-$01
DB -$01,-$01,-$01,-$01,-$01,-$01,-$01,-$01,-$01,-$01
.END:

; ==== POINTER TO STATES BY ENTITY TYPE
STATE_PTRS:
DW PLAYER_STATES	; Type 0
DW SAW_STATES		; Type 1
DW BEE_STATES		; Type 2
DW SPEAR_STATES		; Type 3

; ==== STATES BY ENTITY TYPE
; ----
PLAYER_STATES:
; --
.STATIC:
DB 	4 							; Frames
DW 	GRAV_TABLE					; Y movement pointer
DW 	STATIC_TABLE				; X movement pointer
; -- 
.DEAD:
DB 	90							; Frames
DW  DEAD_TABLE					; Y movement pointer
DW 	DEAD_TABLE					; X movement pointer
; --
.JUMP:
DB 	25 							; Frames
DW 	JUMP_TABLE					; Y movement pointer
DW 	STATIC_TABLE				; Y movement pointer
; --
.D_JUMP:
DB 	25 							; Frames
DW 	JUMP_TABLE					; Y movement pointer
DW 	STATIC_TABLE				; X movement pointer
; --
.DASH_L:
DB 	8 							; Frames
DW 	DEAD_TABLE					; Y movement pointer
DW 	DASH_L_TABLE 				; X movement pointer
; --
.DASH_R:
DB 	8 							; Frames
DW 	DEAD_TABLE					; Y movement pointer
DW 	DASH_R_TABLE 				; X movement pointer
; --
.WALL_L:
DB 	25 							; Frames
DW 	JUMP_TABLE					; Y movement pointer
DW 	WALL_L_TABLE				; X movement pointer
; --
.WALL_R:
DB 	25 							; Frames
DW 	JUMP_TABLE					; Y movement pointer
DW 	WALL_R_TABLE 				; X movement pointer
; --
.REBOUND_ONE:
DB 	15 							; Frames
DW 	STATIC_TABLE				; Y movement pointer
DW 	STATIC_TABLE				; X movement pointer
; --
.REBOUND_TWO:
DB 	25 							; Frames
DW 	JUMP_TABLE 					; Y movement pointer
DW 	STATIC_TABLE				; X movement pointer
; ----
SAW_STATES:
; --
.MOVE:
;DB 	1							; Frames
;DW  STATIC_TABLE				; Y movement pointer
;DW 	STATIC_TABLE				; X movement pointer
;  INITIAL VELOCITY MASK TABLE
; ----
BEE_STATES:
; --
.DEAD:
; --
.STATIC:
; ----
SPEAR_STATES:
; --
.MOVE:

; ==== PLAYER COOLDOWNS
PLAYER_CD:
.DASH:	DB 40 ; 40 - 8  = 32
.RBND: 	DB 25 ; 20

;┬───────────────────────────────────────────────────────────────────────
;│ RAM VARIABLES
;└  
SECTION "StatemanRAM", WRAM0
; ---- MOVEMENT VALUE BY STATE
_TYPE: 	 		DB
_STATE:			DB
_MOV_Y:			DB
_MOV_X:			DB
_TABLE_Y_PTR:	DW
_TABLE_X_PTR:	DW
; -- States cooldown
_DASH_CD: 		DB
_RBND_CD:		DB
_RBND_FR:		DB
;_D_JUMP_FLAG: 	DB

;┬───────────────────────────────────────────────────────────────────────
;│ FUNCTIONS
;└ 
SECTION "StatemanFun", ROM0
STATEMAN_INIT::
; ---- Routine to initialize StateManager.
; DESTROYS: 
;	-
;	
	XOR 	A
	LD 		[_DASH_CD], A
	LD 		[_RBND_CD], A
	LD 		[_RBND_FR], A

    RET

STATEMAN_UPDATE::
; ---- Updates states and velocity (according to state) of entities.
; PARAMETERS: 
; 	DE = Pointer to first entity in the PHY entity array (Type).
;  	 A = Number of entities to update.
; DESTROYS: 
;	A, HL, DE, BC
;
	LD 		C, A 			; C = Number of entities to update

.UPDATE_LOOP:
	PUSH 	BC 				; Save entities counter

							; [DE]  = Entity(N).Type
	LD 		A, [DE]			; ┐
	LD  	[_TYPE], A 		; ┴─> TYPE = Entity(N).Type

	POINT_NEXT 	PHY_ST, PHY_T, E
	; [DE]  = Entity(N).State

	LD 		A, [DE]			; ┐
	LD  	[_STATE], A 	; ┴─> TYPE = Entity(N).State
	LD 		C, A 			; C = Entity(N).State

	POINT_NEXT 	PHY_FR, PHY_ST, E
	; [DE]  = Entity(N).Frame

	LD 		A, [DE] 		; A = Entity(N).Frame
	CP 		$00				; State frames already spent?
	JR 		NZ, .CONTINUE	; If frames remaining, continue.
	LD 		A, C 			; A = Entity(N).State
	CP 		DEFAULT_STATE	; Default State ?
	JR 		Z, .CONTINUE_SKIP	; Default state has no end frame
.END_STATE:
	LD 		A, [_TYPE]
	CP 		PLAYER_T
	JR 		NZ, .END_STATE_REST;.END_STATE_NOPLY
.END_STATE_PLY:
	CALL 	PLAYER_END_STATE
	JR 		.X
;.END_STATE_NOPLY:
;	CP 		BEE_T
;	JR 		NZ, .END_STATE_REST
;.END_STATE_BEE:
;	CALL 	BEE_END_STATE
;	JR 		.CONTINUE
.END_STATE_REST:
	CALL 	REST_END_STATE
	JR 		.X

.CONTINUE:
	LD 		A, [DE]			; ┐
	DEC 	A 				; ┴─> A = Entity(N).Frame -1
	LD 		[DE], A 		; Entity(N).Frame = Entity(N).Frame - 1
.CONTINUE_SKIP:
	CALL 	GET_MOV_TABLES
.X
	; UPDATE X
							; HL  = Pointer to MOV.TableX + 1
	CALL 	READ_PTR_B 		; HL  = Adress for MOV.TableX
	LD 		A, [DE]			; A = Entity(N).Frame -1
	LD 		C, A			; C               = Entity(N).Frame - 1
							; BC    = Entity(N).Frame - 1
	ADD  	HL, BC 			; Frame position in TableX
	LD 		A, [HL] 		; A = velocity in X for that frame
	CP 		NOMOD_MASK
	JR 		Z, .Y
	LD 		C, A 			; C = velocity in X for that frame

	POINT_NEXT 	PHY_VX, PHY_FR, E
	; [DE]  = Entity(N).VX
	LD  	A, C 			; A = velocity in X for that frame
	LD 		[DE], A 		; Entity(N).VX = velocity in X for that frame

	POINT_NEXT 	PHY_FR, PHY_VX, E
	; [DE]  = Entity(N).Frame

.Y:
	; UPDATE Y
	LD  	A, [_TABLE_Y_PTR]
	LD 		H, A
	LD 		A, [_TABLE_Y_PTR+1] 
	LD 		L, A 			; HL  = Pointer to MOV.TableY + 1
	CALL 	READ_PTR_B 		; HL  = Adress for MOV.TableY
	LD 		A, [DE]			; ┐
	;DEC 	A 				; │
	LD 		C, A			; ┴─> C = Entity(N).Frame - 1
							; BC    = Entity(N).Frame - 1
	ADD  	HL, BC 			; Frame position in TableY
	LD 		A, [HL] 		; A = velocity in XYfor that frame
	CP 		NOMOD_MASK
	JR 		Z, .END_ITERATION
	LD 		C, A 			; C = velocity in Y for that frame

	POINT_NEXT 	PHY_VY, PHY_FR, E
	; [DE]  = Entity(N).VY
	LD  	A, C 			; A = velocity in Y for that frame
	LD 		[DE], A 		; Entity(N).VX = velocity in Y for that frame

	POINT_NEXT 	PHY_T, PHY_VY, E
	; [DE]  = Entity(N).Type

.END_ITERATION:
	; COUNTER CHECKS
	POP 	BC 				; Retrieve entities counter
	DEC  	C 				; One less entity to update
	JR 		.UPDATE_CD;!!JR 		Z, .UPDATE_CD
	
	; POINT TO NEXT ENTITY TYPE
	; POINT_NEXT
	RET ; !! PROVISIONAL
	JR  	.UPDATE_LOOP

.UPDATE_CD:
	CALL UPDATE_CD
	RET

STATE_REQUEST::
; ---- .
; PARAMETERS: 
;  	 A = State we want to change to.
; 	DE = Pointer to entity in the PHY entity array (Type).
; DESTROYS: 
;	A, HL, DE, BC
;
	LD 		C, A 			; C = Objetive state
	LD 		A, [DE]	 		; A = Entity(N).Type
	LD  	[_TYPE], A
	CP 		PLAYER_T
	JR		NZ, .AI
.PLAYER:
	POINT_NEXT 	PHY_ST, PHY_T, E
	; [DE] = Entity(N).State

	LD 		A, [DE] 		; A = Entity(N).State
	CP 		PLY_DEAD
	RET 	Z 				; If player dead, no state change.

	LD 		A, C
	CP  	PLY_DASH_L
	JR 		Z, .PLAYER_DASH
	CP  	PLY_DASH_R
	JR 		Z, .PLAYER_DASH
	CP 		PLY_RBD_TWO
	JR  	Z, .PLAYER_RBND

	LD  	[DE], A
	LD  	[_STATE], A

	CALL 	GET_MOV_TABLES_STR
	RET
.PLAYER_DASH:
	LD 		A, [_DASH_CD]
	CP 		0
	RET  	NZ
	
	LD 		A, C
	LD  	[DE], A
	LD  	[_STATE], A
	LD 		A, [PLAYER_CD.DASH]
	LD 		[_DASH_CD], A

	CALL 	GET_MOV_TABLES_STR
	RET	
.PLAYER_RBND:
	LD 		A, [_RBND_FR]
	CP 		0
	JR  	Z, .KILL_PLAYER
	
	LD 		A, C
	LD  	[DE], A
	LD  	[_STATE], A
	LD 		A, [PLAYER_CD.RBND]
	LD 		[_RBND_CD], A

	CALL 	GET_MOV_TABLES_STR
	RET
.KILL_PLAYER:
	LD 		A, PLY_DEAD
	LD  	[DE], A
	LD  	[_STATE], A
	LD 		A, [PLAYER_CD.RBND]
	LD 		[_RBND_CD], A

	CALL 	GET_MOV_TABLES_STR
	RET

.AI:
	POINT_NEXT 	PHY_ST, PHY_T, E
	; [DE] = Entity(N).State
	RET

RBND_REQUEST::
; ---- .
; PARAMETERS: 
;  	 A = .
; 	DE = .
; DESTROYS: 
;	A, HL, DE, BC
;
	LD 		A, [_RBND_CD]
	CP 		0
	RET  	NZ
	LD 		A, [_RBND_FR]
	CP 		0
	RET 	NZ
	LD  	A, [PLAYER_STATES.REBOUND_ONE]
	LD  	[_RBND_FR], A
	LD  	A, [PLAYER_CD.RBND]
	LD  	[_RBND_CD], A
	LD 		A, [$C003] 		; !! Provisional
	OR 		OAMF_PAL1		; !! Provisional
	LD 		[$C003], A 		; !! Provisional
	LD 		A, [$C003+4] 		; !! Provisional
	OR 		OAMF_PAL1		; !! Provisional
	LD 		[$C003+4], A 		; !! Provisional
	LD 		A, [$C003+8] 		; !! Provisional
	OR 		OAMF_PAL1		; !! Provisional
	LD 		[$C003+8], A 		; !! Provisional
	LD 		A, [$C003+12] 		; !! Provisional
	OR 		OAMF_PAL1		; !! Provisional
	LD 		[$C003+12], A 		; !! Provisional
	RET

;┬───────────────────────────────────────────────────────────────────────
;│ LOCAL FUNCTIONS
;└ 
PLAYER_END_STATE:
	LD 		A, [_STATE]
	CP 		PLY_DEAD
	JR		NZ, .OTHER
	; !! CALL EVENT MANAGER . PLAYER DIED
	LD 		A, [_DEATHS_TOT]
	CP 		9
	JR 		Z, .PLUS_TEN
	INC 	A
	LD 		[_DEATHS_TOT], A
	JR 		.RESTART_PLY
.PLUS_TEN:
	XOR 	A
	LD 		[_DEATHS_TOT], A
	LD 		A, [_DEATHS_TOT+1]
	INC 	A
	LD 		[_DEATHS_TOT+1], A
.RESTART_PLY:
	LD  	A, [_PLY_INIT_Y]
	LD 		[$C100], A
	LD  	A, [_PLY_INIT_X]
	LD 		[$C101], A 			; Reset player to initial Y and X
	LD  	A, [_CAM_INIT_Y]
	LD 		[_CAM_Y], A
	LD  	A, [_CAM_INIT_X]
	LD 		[_CAM_X], A 		; Reset camera to initial Y and X
.OTHER
	CALL 	REST_END_STATE
	RET

BEE_END_STATE:
	RET

REST_END_STATE:
	POINT_NEXT 	PHY_ST, PHY_FR, E
	; [DE]  = Entity(N).State
	LD 		A, DEFAULT_STATE
	LD 		[DE], A
	LD 		[_STATE], A
	CALL 	GET_MOV_TABLES_END
	RET

GET_MOV_TABLES:
	LD 		A, [_TYPE]		; ┐
	LD 		C, A  			; ┴─> C = Entity(N).Type
	SLA 	C 				; C  = Entity(N).Type * 2
	LD 		B, 0 			; BC = Entity(N).Type * 2
	LD 		HL, STATE_PTRS	; ┐
	ADD 	HL, BC			; │
	CALL 	READ_PTR_B 		; ┴─> HL = Entity(N)_STATE

	LD 		A, [_STATE]	 	; ┐
	LD 		C, A 			; │
	SLA 	A 				; │
	SLA 	A 				; │
	ADD 	C 				; ┴─> A = Entity(N).State * 5
	LD 		C, A 			; C  = Entity(N).State * 5
							; BC = Entity(N).State * 5
	ADD 	HL, BC			; HL = Entity(N)_STATE.MOVE(0)
	INC 	HL 				; HL = Entity(N)_STATE.MOVE(1)
	LD 		A, H
	LD  	[_TABLE_Y_PTR], A
	LD 		A, L
	LD 		[_TABLE_Y_PTR+1], A ; TABLE_Y = Pointer to MOV.TableY + 1
	INC 	HL 				; HL = Entity(N)_STATE.MOVE(2)
	INC 	HL 				; HL = Entity(N)_STATE.MOVE(3)
	RET

GET_MOV_TABLES_END:
	LD 		A, [_TYPE]		; ┐
	LD 		C, A  			; ┴─> C = Entity(N).Type
	SLA 	C 				; C  = Entity(N).Type * 2
	LD 		B, 0 			; BC = Entity(N).Type * 2
	LD 		HL, STATE_PTRS	; ┐
	ADD 	HL, BC			; │
	CALL 	READ_PTR_B 		; ┴─> HL = Entity(N)_STATE

	LD 		A, [_STATE]	 	; ┐
	LD 		C, A 			; │
	SLA 	A 				; │
	SLA 	A 				; │
	ADD 	C 				; ┴─> A = Entity(N).State * 5 
	LD 		C, A 			; C  = Entity(N).State * 5
							; BC = Entity(N).State * 5
	ADD 	HL, BC			; HL = Entity(N)_STATE.MOVE
	
	POINT_NEXT 	PHY_FR, PHY_ST, E
	; [DE]  = Entity(N).Frame
	; HL  = Entity(N)_STATE.MOVE(0) = MOVE.Frames
	LD 		A, [HL+] 		; ┐
	DEC 	A 		 		; │
	LD  	[DE], A 		; ┴─> Entity(N).Frame = MOVE.Frames - 1
							; HL = Entity(N)_STATE.MOVE(1)
	LD 		A, H
	LD  	[_TABLE_Y_PTR], A
	LD 		A, L
	LD 		[_TABLE_Y_PTR+1], A ; TABLE_Y = Pointer to MOV.TableY
	INC 	HL 				; HL = Entity(N)_STATE.MOVE(2)
	INC 	HL 				; HL = Entity(N)_STATE.MOVE(3)
	RET

GET_MOV_TABLES_STR:
	LD 		A, [_TYPE]		; ┐
	LD 		C, A  			; ┴─> C = Entity(N).Type
	SLA 	C 				; C  = Entity(N).Type * 2
	LD 		B, 0 			; BC = Entity(N).Type * 2
	LD 		HL, STATE_PTRS	; ┐
	ADD 	HL, BC			; │
	CALL 	READ_PTR_B 		; ┴─> HL = Entity(N)_STATE

	LD 		A, [_STATE]	 	; ┐
	LD 		C, A 			; │
	SLA 	A 				; │
	SLA 	A 				; │
	ADD 	C 				; ┴─> A = Entity(N).State * 5 
	LD 		C, A 			; C  = Entity(N).State * 5
							; BC = Entity(N).State * 5
	ADD 	HL, BC			; HL = Entity(N)_STATE.MOVE
	
	POINT_NEXT 	PHY_FR, PHY_ST, E
	; [DE]  = Entity(N).Frame
	; HL  = Entity(N)_STATE.MOVE(0) = MOVE.Frames
	LD 		A, [HL+] 		; ┐
	;DEC 	A 		 		; │
	LD  	[DE], A 		; ┴─> Entity(N).Frame = MOVE.Frames
							; HL = Entity(N)_STATE.MOVE(1)
	LD 		A, H
	LD  	[_TABLE_Y_PTR], A
	LD 		A, L
	LD 		[_TABLE_Y_PTR+1], A ; TABLE_Y = Pointer to MOV.TableY
	INC 	HL 				; HL = Entity(N)_STATE.MOVE(2)
	INC 	HL 				; HL = Entity(N)_STATE.MOVE(3)
	RET

UPDATE_CD:
.DASH:
	LD 		A, [_DASH_CD]
	CP     	0
	JR 		Z, .RBND
	DEC 	A
	LD 		[_DASH_CD], A

.RBND:
	LD 		A, [_RBND_CD]
	CP     	0
	JR 		Z, .RBND_FRAME
	DEC 	A
	LD 		[_RBND_CD], A
.RBND_FRAME:
	LD 		A, [_RBND_FR]
	CP     	0
	JR 		Z, .END
	DEC 	A
	LD 		[_RBND_FR], A
	CP 		0 					; !! Provisional
	JR 		NZ, .END  			; !! Provisional
	LD 		A, [$C003] 		; !! Provisional
	RES 	4, A 			; Set palette 0 
	LD 		[$C003], A 		; !! Provisional
	LD 		A, [$C003+4] 		; !! Provisional
	RES 	4, A
	LD 		[$C003+4], A 		; !! Provisional
	LD 		A, [$C003+8] 		; !! Provisional
	RES 	4, A
	LD 		[$C003+8], A 		; !! Provisional
	LD 		A, [$C003+12] 		; !! Provisional
	RES 	4, A
	LD 		[$C003+12], A 		; !! Provisional

.END:
	RET

;║ EOF
;╚══════════════════════════════════════════════════════════════════════