;╦══════════════════════════════════════════════════════════════════════
;║ CAMERA SYSTEM
;╬══════════════════════════════════════════════════════════════════════
;║ camera_system.asm - Wyhrm for GameBoy
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
SECTION "CamerasysData", ROM0

;┬───────────────────────────────────────────────────────────────────────
;│ FUNCTIONS
;└ 
SECTION "CamerasysFun", ROM0
CAMERASYS_INIT::
; ---- Routine to initialize Camera system.
; DESTROYS: 
;	-
;	
    RET

CAMERASYS_UPDATE::
; ---- Converts world positions into screen positions.
; PARAMETERS: 
;	HL = Pointer to first entity in the sOAM entity array.
; 	DE = Pointer to first entity in the PHY entity array (Position).
;  	 A = Number of entities to update.
; DESTROYS: 
;	A, HL, DE, BC
;
	PUSH	AF				; Save Number of entities to update
	PUSH	BC				; Save Cam poistion into stack

.UPDATE_LOOP:
	; ---- UPDATE Y
							; [HL] = Entity(N).Y (Screen)
							; [DE] = Entity(N).Y (World)
							; [BC] = Cam Y
	POP  	BC				; Retrieve Cam poisiton from stack
	PUSH 	BC				; Save Cam poistion into stack
	LD 		A, [BC] 		; ┐
	LD  	B, A 			; ┴─> B = Pixel Y position of Camera (Cam.Y)
	LD 		A, [DE]			; A = Y (World)
	SUB  	B				; ┐
	LD 		[HL], A 		; ┴─> [HL] = Y - Cam_Y = Y Screen position

	; 	-- Update complementary SPRITES
	LD 		B, A 			; B = Y Screen position
	POINT_NEXT  	ENTITY_SCR_SIZE, 0, L 	
	; [HL] = Y (Complementary nº1)
	LD 		[HL], B 		; ┴─> [HL] = Y Screen position

	LD 		A, B 			; A = Y Screen position
	ADD		8				; ┐
	LD 		B, A 			; ┴─> B = Y Screen position + 8
	POINT_NEXT  	ENTITY_SCR_SIZE*2, ENTITY_SCR_SIZE, L 	
	; [HL] = Y (Complementary nº2)
	LD 		[HL], B 		; ┴─> [HL] = Y Screen position + 8	
	POINT_NEXT  	ENTITY_SCR_SIZE*3, ENTITY_SCR_SIZE*2, L 		
	; [HL] = Y (Complementary nº3)
	LD 		[HL], B 		; ┴─> [HL] = Y Screen position + 8	
	POINT_INI		ENTITY_SCR_SIZE*3, 0, L  	
	; [HL] = Y (Complementary nº0)

	; ---- UPDATE X
	POP 	BC				; Retrieve Cam poisiton from stack
	PUSH	BC				; Save Cam poistion into stack
	INC 	HL 				; [HL] = Entity(N).X (Screen)
	INC 	DE 				; [DE] = Entity(N).X (World)
	INC 	BC				; [BC] = Cam Y
	LD 		A, [BC] 		; ┐
	LD  	B, A 			; ┴─> B = Pixel X position of Camera (Cam.X)
	LD 		A, [DE]			; A = X (World)
	SUB		B   	 		; ┐
	LD 		[HL], A 		; ┴─> [HL] = X - Cam_X = X Screen position
	
	; 	-- Update complementary SPRITES
	LD 		B, A 			; B = X Screen position
	POINT_NEXT  	ENTITY_SCR_SIZE*2, 0, L 		
	; [HL] = X (Complementary nº2)
	LD 		[HL], B 		; ┴─> [HL] = X Screen position + 8	

	LD 		A, B 			; A = X Screen position
	ADD		8				; ┐
	LD 		B, A 			; ┴─> B = X Screen position + 8
	POINT_NEXT  	ENTITY_SCR_SIZE, ENTITY_SCR_SIZE*2, L 		
	; [HL] = X (Complementary nº1)
	LD 		[HL], B 		; ┴─> [HL] = X Screen position + 8	
	POINT_NEXT  	ENTITY_SCR_SIZE*3, ENTITY_SCR_SIZE, L 	
	; [HL] = X (Complementary nº3)
	LD 		[HL], B 		; ┴─> [HL] = X Screen position + 8	
	POINT_INI		ENTITY_SCR_SIZE*3, 0, L  	
	; [HL] = X (Complementary nº0)

	; COUNTER CHECKS
	POP 	BC				; Retrieve Cam poisiton from stack
	POP 	AF				; Retrieve Number of entities to update
	DEC  	A 				; One less entity to update
	RET		Z				; No more entities remaining ?
	PUSH	AF				; Save Number of entities to update
	PUSH	BC 				; Save Cam poistion into stack
	
	; POINT TO NEXT ENTITY
	POINT_NEXT  	ENTITY_OAM_SIZE, PHY_X, L
	POINT_NEXT  	ENTITY_PHY_SIZE, PHY_X, E

	JR  	.UPDATE_LOOP

CAMERASYS_UPDATE_CAMERA::
; ---- If possible, moves camera with the speed of player.
; PARAMETERS: 
;	HL = Pointer to camera Y position.
; 	DE = Pointer to first entity in the PHY entity array (Y).
; DESTROYS: 
;	A, HL, DE, BC
;
	; ---- UPDATE Y
.Y:
								; [DE] = Player.VY
								; [HL] = Cam.Y
	LD 		A, [HL]				; A    = Cam.Y
	CP 		0
	JR		Z, .Y_INFERIOR
	CP 		CAM_Y_LIMIT
	JR		Z, .Y_SUPERIOR
	LD  	A, [DE] 			; A = Player.VY
	BIT 	7, A				; Check for sign
	JR  	Z, .DOWN 			; Going UP or DOWN ?
.UP:
	POINT_INI 	PHY_VY, 0, E
	LD 		A, [DE] 			; A = Player.Y
	SUB		CAM_Y_MINMARGIN 	; A = Player.Y - CAM_Y_MINMARGIN
	JR 		C, .UP_LIMIT		; Has player surpased limit ?
	POINT_NEXT	PHY_VY, PHY_Y, E
	LD 		A, [HL] 		; ┐
	LD  	B, A 			; ┴─> B = Cam.Y
	LD 		A, [DE]			; A = Player.VY
	ADD  	B				; ┐
	LD 		[HL], A 		; ┴─> Cam.Y = Cam.Y + Player.VY
	JR		.X
.UP_LIMIT:
	XOR  	A 					; ┐
	LD  	[HL], A  			; ┴─> Cam.Y fixed to 0
	POINT_NEXT	PHY_VY, PHY_Y, E
	JR		.X
.DOWN:
	POINT_INI 	PHY_VY, 0, E
	LD 		A, [DE] 			; A = Player.Y
	SUB		CAM_Y_MAXMARGIN 	; A = Player.Y - CAM_Y_MAXMARGIN
	JR 		NC, .DOWN_LIMIT		; Has player surpased limit ?
	POINT_NEXT	PHY_VY, PHY_Y, E
	LD 		A, [HL] 		; ┐
	LD  	B, A 			; ┴─> B = Cam.Y
	LD 		A, [DE]			; A = Player VY
	ADD  	B				; ┐
	LD 		[HL], A 		; ┴─> Cam.Y = Cam.Y + Player.VY
	JR		.X
.DOWN_LIMIT:
	LD 		A, CAM_Y_LIMIT		; ┐
	LD  	[HL], A  			; ┴─> Cam.Y fixed to CAM_Y_LIMIT
	POINT_NEXT	PHY_VY, PHY_Y, E
	JR		.X
.Y_INFERIOR:
	LD  	A, [DE] 			; A = Player.VY
	BIT 	7, A				; Check for sign
	JP  	NZ, .X 				; Going UP or DOWN ? If up dont move cam in Y
	POINT_INI 	PHY_VY, 0, E
	LD 		A, [DE] 			; A = Player.Y
	SUB		CAM_Y_MINMARGIN 	; A = Player.Y - CAM_Y_MINMARGIN
	JR 		C, .END_Y_INFERIOR	; Has player surpased limit ? If not dont move cam in Y
	LD 		B, A  				; B = Player.Y - CAM_Y_MINMARGIN
	LD 		A, [HL] 			; A = Cam.Y
	ADD		B 					; A = Cam.Y + (Player.Y - CAM_Y_MINMARGIN)
	LD 		[HL], A 			; Cam.Y updated
.END_Y_INFERIOR:
	POINT_NEXT	PHY_VY, PHY_Y, E
	JR		.X
.Y_SUPERIOR:
	LD  	A, [DE] 			; A = Player.VY
	BIT 	7, A				; Check for sign
	JP  	Z, .X 				; Going UP or DOWN ? If down dont move cam in Y
	POINT_INI 	PHY_VY, 0, E
	LD 		A, [DE] 			; A = Player.Y
	SUB		CAM_Y_MAXMARGIN 	; A = Player.Y - CAM_Y_MAXMARGIN
	JR 		NC, .END_Y_SUPERIOR	; Has player surpased limit ? If not dont move cam in Y
	LD 		B, A  				; B = Player.Y - CAM_Y_MAXMARGIN
	LD 		A, [HL] 			; A = Cam.Y
	ADD		B 					; A = Cam.Y + (Player.Y - CAM_Y_MAXMARGIN)
	LD 		[HL], A 			; Cam.Y updated
.END_Y_SUPERIOR:
	POINT_NEXT	PHY_VY, PHY_Y, E
	JR		.X
	
	; ---- UPDATE X
.X:
	INC 	DE					; [DE] = Player.VX (World)
	INC 	HL					; [HL] = Cam.X
	LD 		A, [HL]				; A    = Cam.X
	CP 		0
	JR		Z, .X_INFERIOR
	CP 		CAM_X_LIMIT
	JR		Z, .X_SUPERIOR
	LD  	A, [DE] 			; A = Player.VX
	BIT 	7, A				; Check for sign
	JR  	Z, .RIGHT 			; Going LEFT or RIGHT ?
.LEFT:
	POINT_NEXT 	PHY_X, PHY_VX, E; = POINT_INI
	LD 		A, [DE] 			; A = Player.X
	SUB		CAM_X_MINMARGIN 	; A = Player.X - CAM_X_MINMARGIN
	JR 		C, .LEFT_LIMIT		; Has player surpased limit ?
	POINT_NEXT	PHY_VX, PHY_X, E
	LD 		A, [HL] 		; ┐
	LD  	B, A 			; ┴─> B = Cam.X
	LD 		A, [DE]			; A = Player.VX
	ADD  	B				; ┐
	LD 		[HL], A 		; ┴─> Cam.X = Cam.X + Player.VX
	JR		.END
.LEFT_LIMIT:
	XOR  	A 					; ┐
	LD  	[HL], A  			; ┴─> Cam.X fixed to 0
	JR		.END
.RIGHT:
	POINT_NEXT 	PHY_X, PHY_VX, E; = POINT_INI
	LD 		A, [DE] 			; A = Player.X
	SUB		CAM_X_MAXMARGIN 	; A = Player.X - CAM_X_MAXMARGIN
	JR 		NC, .RIGHT_LIMIT	; Has player surpased limit ?
	POINT_NEXT	PHY_VX, PHY_X, E
	LD 		A, [HL] 		; ┐
	LD  	B, A 			; ┴─> B = Cam.X
	LD 		A, [DE]			; A = Player.VX
	ADD  	B				; ┐
	LD 		[HL], A 		; ┴─> Cam.X = Cam.X + Player.VX
	JR		.END
.RIGHT_LIMIT:
	LD 		A, CAM_X_LIMIT		; ┐
	LD  	[HL], A  			; ┴─> Cam.X fixed to CAM_X_LIMIT
	JR		.END
.X_INFERIOR:
	LD  	A, [DE] 			; A = Player.VX
	BIT 	7, A				; Check for sign
	JP  	NZ, .END			; Going UP or DOWN ? If left dont move cam in X
	POINT_NEXT 	PHY_X, PHY_VX, E; = POINT_INI
	LD 		A, [DE] 			; A = Player.X
	SUB		CAM_X_MINMARGIN 	; A = Player.X - CAM_X_MINMARGIN
	JR 		C, .END_X_INFERIOR	; Has player surpased limit ? If not dont move cam in X
	LD 		B, A  				; B = Player.X - CAM_X_MINMARGIN
	LD 		A, [HL] 			; A = Cam.X
	ADD		B 					; A = Cam.X + (Player.X - CAM_X_MINMARGIN)
	LD 		[HL], A 			; Cam.X updated
.END_X_INFERIOR:
	JR		.END
.X_SUPERIOR:
	LD  	A, [DE] 			; A = Player.VX
	BIT 	7, A				; Check for sign
	JP  	Z, .END				; Going UP or DOWN ? If down dont move cam in Y
	POINT_NEXT 	PHY_X, PHY_VX, E; = POINT_INI
	LD 		A, [DE] 			; A = Player.X
	SUB		CAM_X_MAXMARGIN 	; A = Player.X - CAM_X_MAXMARGIN
	JR 		NC, .END			; Has player surpased limit ? If not dont move cam in Y
	LD 		B, A  				; B = Player.X - CAM_X_MAXMARGIN
	LD 		A, [HL] 			; A = Cam.X
	ADD		B 					; A = Cam.X + (Player.X - CAM_X_MAXMARGIN)
	LD 		[HL], A 			; Cam.Y updated

.END:	
	RET

;┬───────────────────────────────────────────────────────────────────────
;│ LOCAL FUNCTIONS
;└ 

;║ EOF
;╚══════════════════════════════════════════════════════════════════════