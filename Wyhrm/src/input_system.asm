;╦══════════════════════════════════════════════════════════════════════
;║ INPUT SYSTEM
;╬══════════════════════════════════════════════════════════════════════
;║ input_system.asm - Wyhrm for GameBoy
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
SECTION "InputsysData", ROM0

;┬───────────────────────────────────────────────────────────────────────
;│ FUNCTIONS
;└  
SECTION "InputsysFun", ROM0
INPUTSYS_INIT::
; ---- Routine to initialize input system.
; DESTROYS: 
;	-
;	
    RET

INPUTSYS_UPDATE::
; ---- Checks key inputs and updates Screen velocities.
; PARAMETERS: 
; 	HL = Pointer to first entity (player) in the PHY entity array.
; DESTROYS: 
;	A, HL, DE, BC
;
	; Reset screen and player velocities
	; [HL] = Entity(0).VY
	XOR  	A 					; A    = 0
	LD  	[HL+], A  			; VY   = 0 . [HL] = VX
	;INC 	HL					; [HL] = VX
	LD 		[HL], A 			; VX   = 0

	; Scan keypad for direction keys input state.
	CALL 	READ_PAD_DIR 		; Save it into A and B registers.

	; Check for direction keys
	;	   (%XXXX↓↑←→)
	AND  	%00000010 			; Check for Left direction
	JR 		NZ, .LEFT_NO_PRESS 	; If Left not pressed check for Right
.LEFT_PRESS:
	LD 		[HL], -$01    		; VX = -1
	;PUSH 	HL
	;LD  	HL, rSCX
	;DEC  	[HL]
	;POP  	HL
.LEFT_NO_PRESS:
	LD 		A, B 				; Retrieve input state into A
	;	   (%XXXX↓↑←→)
	AND  	%00000001 			; Check for Right direction
	JR 		NZ, .RIGHT_NO_PRESS ; If Right not pressed check for Up
.RIGHT_PRESS:
	LD 		[HL], $01    		; VX = +1 
	;PUSH 	HL
	;LD  	HL, rSCX
	;INC  	[HL]
	;POP  	HL
.RIGHT_NO_PRESS:
	DEC 	HL 					; [HL] = VY

	LD 		D, H 	; ┐
	LD  	E, L 	; ┴─> PHY array to DE !! Provisional

	LD 		A, B 				; Retrieve input state into A
	;	   (%XXXX↓↑←→)
	AND  	%00000100 			; Check for Up direction
	JR 		NZ, .UP_NO_PRESS 	; If Up not pressed check for Down 
.UP_PRESS:
	LD 		[HL], -$01 		   	; VY = -1
	;PUSH 	HL
	;LD  	HL, rSCY
	;DEC  	[HL]
	;POP  	HL
.UP_NO_PRESS:
	LD 		A, B 				; Retrieve input state into A
	;	   (%XXXX↓↑←→)
	AND  	%00001000 			; Check for Down direction
	JR 		NZ, .DOWN_NO_PRESS 	; If Down not pressed return
.DOWN_PRESS:
	CALL 	RBND_REQUEST		; ┴─> Request to change to JUMP state
.DOWN_NO_PRESS:

	; Scan keypad for action keys input state.
	CALL 	READ_PAD_ACT 		; Save it into A and B registers.

	; Check for action keys
	;	   (%XXXX+-BA)
	AND  	%00000010 			; Check for Left direction
	JR 		NZ, .B_NO_PRESS 	; If B not pressed check for Right
.B_PRESS:
	POINT_NEXT 	PHY_LF, PHY_VY, E
	; [DE]  = Entity(N).LastFaced

	LD 		A, [DE]
	CP 		LF_RIGHT
	JR 		Z, .DASH_RIGHT
.DASH_LEFT:
	POINT_NEXT 	PHY_T, PHY_LF, E
	; [DE]  = Entity(N).Type
	LD 		A, PLY_DASH_L		; ┐
	CALL 	STATE_REQUEST		; ┴─> Request to change to JUMP state
	POINT_NEXT 	PHY_VY, PHY_ST, E
	; [DE]  = Entity(N).VY
	JR 		.B_NO_PRESS
.DASH_RIGHT:
	POINT_NEXT 	PHY_T, PHY_LF, E
	; [DE]  = Entity(N).Type
	LD 		A, PLY_DASH_R		; ┐
	CALL 	STATE_REQUEST		; ┴─> Request to change to JUMP state
	POINT_NEXT 	PHY_VY, PHY_ST, E
	; [DE]  = Entity(N).VY
.B_NO_PRESS:
	LD 		A, B 				; Retrieve input state into A
	;	   (%XXXX+-BA)
	AND  	%00000001 			; Check for Right direction
	JR 		NZ, .A_NO_PRESS ; If A not pressed check for Up
.A_PRESS:
	POINT_NEXT 	PHY_CY, PHY_VY, E
	; [DE]  = Entity(N).CollisionY

	LD 		A, [DE]
	CP 		BLOCKDR
	JR 		NZ, .NO_Y_COL

	POINT_NEXT 	PHY_T, PHY_CY, E
	; [DE]  = Entity(N).Type
	LD 		A, PLY_JUMP 		
	CALL 	STATE_REQUEST		; ┴─> Request to change to JUMP state
	POINT_NEXT 	PHY_VY, PHY_ST, E
	; [DE]  = Entity(N).VY
.NO_Y_COL:
	POINT_NEXT 	PHY_CX, PHY_CY, E
	; [DE]  = Entity(N).CollisionX
	LD 		A, [DE]
	CP 		BLOCKDR
	JR 		NZ, .NO_X_L_COL
	POINT_NEXT 	PHY_T, PHY_CX, E
	; [DE]  = Entity(N).Type
	LD 		A, PLY_WALL_L 		
	CALL 	STATE_REQUEST		; ┴─> Request to change to JUMP state
	POINT_NEXT 	PHY_VY, PHY_ST, E
	; [DE]  = Entity(N).VY
.NO_X_L_COL:
	CP 		BLOCKUL
	JR 		NZ, .A_NO_PRESS
	POINT_NEXT 	PHY_T, PHY_CX, E
	; [DE]  = Entity(N).Type
	LD 		A, PLY_WALL_R 		
	CALL 	STATE_REQUEST		; ┴─> Request to change to JUMP state
	POINT_NEXT 	PHY_VY, PHY_ST, E
	; [DE]  = Entity(N).VY

.A_NO_PRESS:
	DEC 	HL 					; [HL] = VY
	LD 		A, B 				; Retrieve input state into A
	;	   (%XXXX+-BA)
	AND  	%00000100 			; Check for Up direction
	JR 		NZ, .SELECT_NO_PRESS 	; If SELECT not pressed check for Down 
.SELECT_PRESS:
	;LD 		[HL], -$03 		   	; VY = -1
.SELECT_NO_PRESS:
	LD 		A, B 				; Retrieve input state into A
	;	   (%XXXX+-BA)
	AND  	%00001000 			; Check for Down direction
	JR 		NZ, .START_NO_PRESS 	; If START not pressed return
.START_PRESS:
	LD 		A, [_LVL_END]
	CP 		1
	JR		NZ, .START_NO_PRESS
	LD 		A, 2
	LD 		[_LVL_END], A

.START_NO_PRESS:
	RET

;┬───────────────────────────────────────────────────────────────────────
;│ LOCAL FUNCTIONS
;└ 
READ_PAD_DIR:
; ---- Keypad directions scan routine. Sets and reads from $FF00 (rP1).
; DESTROYS: 
;	A, BC
; RETURNS: 
; 	A = Direction keys input state as % XXXX ↓↑←→ .
;   B = Direction keys input state as % XXXX ↓↑←→ .
;
	; Read Direction buttons
    ;          %---↓----
    LD      A, %11101111    ; ┬─> Set Bit 5, Reset Bit 4
    LD      [rP1], A 		; ┴─> Selects direction buttons

    ; Several reads to avoid 'bouncing'
    LD      A, [rP1]
    LD      A, [rP1]
    LD      A, [rP1]
    LD      A, [rP1] 		
    LD   	B, A 			; ┴─> Save input state in A and B registers
    RET

READ_PAD_ACT:
; ---- Keypad actions scan routine. Sets and reads from $FF00 (rP1).
; DESTROYS: 
;	A, BC
; RETURNS: 
; 	A = Action keys input state as % XXXX +-BA .
;   B = Direction keys input state as % XXXX ↓↑←→ .
;
	; Read Action buttons
    ;          %--↓-----
    LD      A, %11011111    ; ┬─> Set Bit 4, Reset Bit 5
    LD      [rP1], A        ; ┴─> Selects action buttons

    ; Several reads to avoid 'bouncing'
    LD      A, [rP1]
    LD      A, [rP1]
    LD      A, [rP1]
    LD      A, [rP1] 		; ┐
    LD   	B, A 			; ┴─> Save input state in A and B registers
    RET

;║ EOF
;╚══════════════════════════════════════════════════════════════════════