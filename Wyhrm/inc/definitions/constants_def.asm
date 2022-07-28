;╦══════════════════════════════════════════════════════════════════════
;║ GAME MANAGER
;╬══════════════════════════════════════════════════════════════════════

DEF NUM_LEVELS  		EQU 2 	; Total levels in the game

;╦══════════════════════════════════════════════════════════════════════
;║ LEVEL MANAGER
;╬══════════════════════════════════════════════════════════════════════

DEF MAX_LEVEL_SIZE		EQU	1024

;╦══════════════════════════════════════════════════════════════════════
;║ RENDER SYSTEM
;╬══════════════════════════════════════════════════════════════════════
 
DEF PALETTE0        	EQU %11100100   ; Palette 0 definition
DEF PALETTE1        	EQU %11111100   ; Palette 1 definition

DEF NOCOLL_MASK    		EQU $00         ; Non-Collisionable Tiles Mask
DEF LIMIT_MASK			EQU $70 		; Blocking Tiles Mask
DEF BLOCK_MASK       	EQU $80         ; Blocking Tiles Mask
DEF MORTAL_MASK       	EQU $90         ; Blocking Tiles Mask
DEF WIN_MASK  			EQU $A0
DEF FONT_MASK  			EQU $B0

DEF OAM_SIZE        	EQU $A0         ; OAM space size

;╦══════════════════════════════════════════════════════════════════════
;║ ENTITY MANAGER
;╬══════════════════════════════════════════════════════════════════════

DEF MAX_ENTITIES  		EQU 10

; ---- Shadow OAM Data (sOAM)
;  SY,  SX, NUM, ATT ┐
; [0], [1], [2], [3] ┴─> _ENTITY_OAM_ARRAY
; ────────────────────────────────────────
; 	-- OAM Size
DEF NUM_METASPRITES		EQU 4
DEF ENTITY_SCR_SIZE		EQU 4
DEF ENTITY_OAM_SIZE 	EQU ENTITY_SCR_SIZE*NUM_METASPRITES
; ──────────────────────────────────────── 	

; ---- Physics Data (Rest of components)
;  Y ,  X ,  VY,  VX, STA, STD ┐
; [0], [1], [2], [3], [4], [5] ┴─> _ENTITY_PHY_ARRAY
; ────────────────────────────────────────
; 	-- PHY Size
DEF ENTITY_PHY_SIZE 	EQU 12
; 	-- PHY Structure
DEF PHY_Y				EQU 0
DEF PHY_X				EQU 1
DEF PHY_VY				EQU 2
DEF PHY_VX				EQU 3
DEF PHY_IVY				EQU 4
DEF PHY_IVX				EQU 5
DEF PHY_CY				EQU 6
DEF PHY_CX				EQU 7
DEF PHY_T				EQU 8
DEF PHY_ST				EQU 9
DEF PHY_FR				EQU 10
DEF PHY_LF				EQU 11
; ──────────────────────────────────────── 	

; ---- Entities Height and Width
DEF MAX_ENTITY_H		EQU 16
DEF MAX_ENTITY_W		EQU 16
DEF ENTITY_H 			EQU 13
DEF ENTITY_W			EQU 8
DEF ENTITY_H_AI			EQU 16
DEF ENTITY_W_AI			EQU 16

; ---- Entities Types
DEF PLAYER_T			EQU 0
DEF SAW_T				EQU 1
DEF BEE_T 				EQU 2
DEF SPEAR_T				EQU 3

;╦══════════════════════════════════════════════════════════════════════
;║ CAMERA SYSTEM
;╬══════════════════════════════════════════════════════════════════════

DEF CAM_Y_MAXMARGIN		EQU SCRN_VY-(SCRN_Y/2)-1
DEF CAM_Y_MINMARGIN		EQU (SCRN_Y/2)-1
DEF CAM_X_MAXMARGIN		EQU	SCRN_VX-(SCRN_X/2)-1
DEF CAM_X_MINMARGIN		EQU	(SCRN_X/2)-1
DEF CAM_Y_LIMIT			EQU SCRN_VY-SCRN_Y-1
DEF CAM_X_LIMIT			EQU SCRN_VX-SCRN_X-1

;╦══════════════════════════════════════════════════════════════════════
;║ COLLISION SYSTEM
;╬══════════════════════════════════════════════════════════════════════

; !! NOT FINISHED
DEF NOCOL 	EQU 0 	; No Collision 	= 0
DEF UP_L_T	EQU 1	; UP/LEFT 		= 1
DEF DO_R_T	EQU 2	; DOWN/RIGHT 	= 2

DEF LIMIT	EQU 0	; -- LIMITER	(Direction + 0)
DEF LIMITUL	EQU UP_L_T+LIMIT ; UP/LEFT 		= 1 
DEF LIMITDR	EQU DO_R_T+LIMIT ; DOWN/RIGHT 	= 2
DEF BLOCK	EQU 2	; -- BLOCKING 	(Direction + 4)
DEF BLOCKUL	EQU UP_L_T+BLOCK ; UP/LEFT 		= 3 
DEF BLOCKDR	EQU DO_R_T+BLOCK ; DOWN/RIGHT 	= 4
DEF MORTAL	EQU 4	; -- MORTAL		(Direction + 8)
DEF MORTALUL EQU UP_L_T+MORTAL ; UP/LEFT 		= 5 
DEF MORTALDR EQU DO_R_T+MORTAL ; DOWN/RIGHT 	= 6


;╦══════════════════════════════════════════════════════════════════════
;║ STATE MANAGER
;╬══════════════════════════════════════════════════════════════════════

DEF NOMOD_MASK 	EQU $80 
DEF DEFAULT_STATE 	EQU 0

; -- PLAYER states indicator value
DEF	PLY_STATIC 	EQU	DEFAULT_STATE
DEF	PLY_DEAD 	EQU	1
DEF	PLY_JUMP 	EQU	2
DEF	PLY_D_JUMP 	EQU	3
DEF	PLY_DASH_L 	EQU	4
DEF	PLY_DASH_R 	EQU	5
DEF	PLY_WALL_L 	EQU	6
DEF	PLY_WALL_R 	EQU	7
DEF PLY_RBD_ONE EQU 8
DEF PLY_RBD_TWO EQU 9
DEF PLY_TEMPS 	EQU PLY_JUMP ; JUMP state and above have limited duration

; -- SAW states indicator value
DEF	SAW_MOVE 	EQU	DEFAULT_STATE
DEF	SAW_STATIC 	EQU	1
DEF SAW_TEMPS 	EQU SAW_STATIC ; STATIC state and above have limited duration

; -- BEE states indicator value
DEF	BEE_STATIC 	EQU	DEFAULT_STATE
DEF	BEE_DEAD 	EQU	1
DEF BEE_TEMPS 	EQU BEE_DEAD ; DEAD state and above have limited duration

; -- SPEAR states indicator value
DEF	SPE_MOVE 	EQU	DEFAULT_STATE
DEF	SPE_STATIC 	EQU	1
DEF SPE_TEMPS 	EQU SPE_STATIC ; STATIC state and above have limited duration

;╦══════════════════════════════════════════════════════════════════════
;║ PHYSICS SYSTEM
;╬══════════════════════════════════════════════════════════════════════

DEF LF_LEFT 	EQU 0
DEF LF_RIGHT 	EQU 1