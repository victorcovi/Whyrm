;╦══════════════════════════════════════════════════════════════════════
;║ RENDER SYSTEM
;╬══════════════════════════════════════════════════════════════════════
;║ render_system.asm - Wyhrm for GameBoy
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
MACRO LOAD_TILES
; ---- Load Tiles routine.
; PARAMETERS:
;	1 = ROM start location of Tiles to load
;	2 = ROM end location of Tiles to load
; DESTROYS: 
; 	A, HL, DE, BC
;
    LD      HL, \1
    LD      DE, _VRAM + (\3 * 16)  ; Load video memory location to DE.
    LD      BC, \2 - \1 	       ; Number of bytes in the TILE file
    CALL    LDIR
ENDM
MACRO LOAD_TILEMAP
; ---- Load TileMap routine.
; PARAMETERS:
;	1 = Target Mempos. Options: $9800(_SCRN0) or $9C00(_SCRN1)
; DESTROYS: 
; 	A, HL, DE, BC
;
	LD      DE, \1
    LD      BC, MAX_LEVEL_SIZE
    CALL    LDIR
ENDM

;┬───────────────────────────────────────────────────────────────────────
;│ RAM VARIABLES
;└  
SECTION "RendersysRAM", WRAM0
_BG_DISPLAY: DB 	; Current memory area for BG TileMap Display
 					; $98 = [$9800,$9BFF] | $9C = [$9C00,$9FFF]
 					; Used to control LCD Control Register ($FF40) Bit 3 
_WN_DISPLAY: DB 

;┬───────────────────────────────────────────────────────────────────────
;│ DATA AREA
;└  
SECTION "RendersysData", ROM0
; !! Shoould be owned by Game Manager
TILES:
.NC:    ; Non-Collisionable Tiles
    INCLUDE     "./inc/sprites/Whyrm1.z80"
.NC_END:
.LM:    ; Non-Collisionable Tiles
    INCLUDE     "./inc/sprites/Whyrm2.z80"
.LM_END:
.C:
    INCLUDE     "./inc/sprites/Whyrm3.z80"
.C_END:
.W:
    INCLUDE     "./inc/sprites/font.z80"
.W_END:

;┬───────────────────────────────────────────────────────────────────────
;│ FUNCTIONS
;└  
SECTION "RendersysFun", ROM0
RENDERSYS_INIT::
; ---- Routine to initialize LCD state, Palettes, OAM & VRAM.
; DESTROYS: 
;	A, HL, DE, BC
;	
    ; Trurn Off LCD
	CALL    RENDERSYS_LCD_OFF

    ; Move DMA subroutine into HRAM
    CALL    COPY_DMA_ROUTINE
    
    ; Load Palettes
    CALL	LOAD_PALETTE
 	
    ; VRAM Tile section = [$8000,$9FFF]
 	; (MACRO) Load Non-Collisionable Tiles into Tile section 
    LOAD_TILES TILES.NC, TILES.NC_END, NOCOLL_MASK
    ; (MACRO) Load Limiter Tiles in the Tile section
    LOAD_TILES TILES.LM, TILES.LM_END, LIMIT_MASK
    ; (MACRO) Load Blocking Tiles in the Tile section
    LOAD_TILES TILES.C, TILES.C_END, BLOCK_MASK
    ; (MACRO) Load Mortal Tiles in the Tile section
    ;LOAD_TILES TILES.C, TILES.C_END, MORTAL_MASK
    ; (MACRO) Load Window Tiles in the Tile section
    LOAD_TILES TILES.W, TILES.W_END, FONT_MASK

    ; Load Window
    LD      HL, _WN_DISPLAY     ; ┐
    LD      A, HIGH(_SCRN1)     ; │
    LD      [HL], A             ; ┴─> _WN_DISPLAY = $9C
    LD      HL, WIN1            ; !! !!
    ;CALL    READ_PTR_B
    CALL    RENDERSYS_LOAD_WINDOW

    ; Clean Sprite memory (_OARAM, Object Attribute RAM)
    CALL    CLEAN_OAM
    
    ; Set BG TileMap Display to _SCRN0 => [$9800,$9BFF]
    LD 		HL, _BG_DISPLAY     ; ┐
    LD      A, HIGH(_SCRN0)     ; │
    LD 		[HL], A             ; ┴─> _BG_DISPLAY = $98

    ; Set LCD parameters and activate it. !! Describe it
    LD      A, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON|LCDCF_WIN9C00
    LDH     [rLCDC], A
    RET

RENDERSYS_UPDATE::
; ---- Updates the Object Attribute memory.
; PARAMETERS: 
; 	HL = Pointer to first entity to render.
; DESTROYS: 
;	A, HL, DE, BC
;
	LD  	A, HIGH(HL)
    CALL    OAM_DMA     ; CALL DMA_ROUTINE , copied in HRAM
    RET

RENDERSYS_UPDATE_CAMERA::
; ---- Updates camera render position (rSCY & rSCX).
; PARAMETERS: 
;   HL = Pointer to camera shadow position Y.
; DESTROYS: 
;   A, HL, DE, BC
;
    ; ---- UPDATE Y
    LD      A, [HL+]        ; A = CAM.Y
                            ; └─> INC HL
    LDH     [LOW(rSCY)], A  ; Camera render position Y = Camera shadow position Y
    
    LD      A, [HL]         ; A = CAM.X
    LDH     [LOW(rSCX)], A  ; Camera render position Y = Camera shadow position Y
    RET

RENDERSYS_LOAD_TILEMAP::
; ---- Loads TileMap into current BG TileMap Display.
; PARAMETERS: 
; 	HL = ROM mempos of TileMap to load
; DESTROYS: 
;	A, HL, DE, BC
;
    LD      A, [_BG_DISPLAY]
    LD      D, A
    LD      E, $00
    LD      BC, MAX_LEVEL_SIZE
    CALL    LDIR
    RET

RENDERSYS_LOAD_WINDOW::
; ---- Loads TileMap into current WN TileMap Display.
; PARAMETERS: 
;   HL = ROM mempos of TileMap to load
; DESTROYS: 
;   A, HL, DE, BC
;
    LD      A, [_WN_DISPLAY]
    LD      D, A
    LD      E, $00
    LD      BC, MAX_LEVEL_SIZE
    CALL    LDIR
    RET

RENDERSYS_LCD_OFF::
; ---- LCD turn Off routine.
; DESTROYS: 
;   A
;
    LDH     A, [rLCDC]
    RLCA                    ; Sets High bit (7) of the LCDC in the carriage flag.
    RET     NC              ; LCD is already Off, return.
                            ; Bit 7 of the rLCDC indicates LCD ON/OFF state.
                            ; If the carriage Flag is 0 the LCD was already OFF. 
    ; Wait for VBlank interruption, LCD cant turn off outside it. 
    CALL    WAIT_VBLANK
    ; In VBlank, turn off LCD
    LDH     A, [rLCDC]      ; A contains LCDC
    RES     7, A            ; Reset bit 7 (LCD OFF)
    LDH     [rLCDC], A      ; 
    RET 

RENDERSYS_LCD_ON::
; ---- LCD turn On routine.
; DESTROYS: 
;   A
;
    LDH     A, [rLCDC]
    RLCA                    ; Sets High bit (7) of the LCDC in the carriage flag.
    RET     C               ; LCD is already On, return.
                            ; Bit 7 of the rLCDC indicates LCD ON/OFF state.
                            ; If the carriage Flag is 0 the LCD was already OFF. 
    LDH     A, [rLCDC]      ; A contains LCDC
    SET     7, A            ; Reset bit 7 (LCD OFF)
    LDH     [rLCDC], A      ; 
    RET 

RENDERSYS_GET_BGDISPLAY::
; ---- Returns current BGDISPLAY in BC.
; DESTROYS: 
;   A, BC
;
    LD      A, [_BG_DISPLAY]
    LD      B, A
    LD      C, $00
    RET

;┬───────────────────────────────────────────────────────────────────────
;│ LOCAL FUNCTIONS
;└ 
COPY_DMA_ROUTINE:
; ---- Copies DMA_ROUTINE into HRAM for use in OAM data load (RENDERSYS_UPDATE).
; DESTROYS: 
;   A, HL, BC
;
    LD      HL, DMA_ROUTINE
    LD      B, DMA_ROUTINE.END - DMA_ROUTINE ; Number of bytes to copy
    LD      C, LOW(OAM_DMA)   ; Low byte of the destination address
.COPY
    LD      A, [HL+]
    LDH     [C], A
    INC     C
    DEC     B
    JR      NZ, .COPY
    RET

DMA_ROUTINE:
; ---- DMA transfer routine.
; DESTROYS: 
;   A
;
    LDH     [rDMA], A   ; Start DMA transfer (starts right after instruction). 
                        ; Only HRAM is accesible.
    LD      A, 40       ; Delay for a total of 4×40 = 160 cycles     
.WAIT
    DEC     A           ; 1 cycle
    JR      NZ, .WAIT   ; 3 cycles
    RET
DMA_ROUTINE.END:

LOAD_PALETTE:
; ---- Load Sprite palette 0 and Sprite palette 1.
; DESTROYS: 
;	A
;
    ; Palette - $FF47 - BGP - BG Palette Data (R/W) - Non CGB Mode Only
    ;
    ; Bit 7-6 - Shade for Color Number 3
    ; Bit 5-4 - Shade for Color Number 2
    ; Bit 3-2 - Shade for Color Number 1
    ; Bit 1-0 - Shade for Color Number 0
    ;
    ; 0  White      (%00)
    ; 1  Light gray (%01)  
    ; 2  Dark gray  (%10)
    ; 3  Black      (%11)
    ;
    LD      A, PALETTE0		; Define palette as Darkest to Lightest (11 10 01 00)
    LDH     [rBGP], A       ; Load palette data into BG Palette Data register
    LDH     [rOBP0], A      ; Load same palette into (first) SpritePalette0.

    LD      A, PALETTE1		; Define palette as (11 01 00 00)
    LDH     [rOBP1], A      ; Load palette into SpritePalette1.
    RET

CLEAN_OAM:
; ---- Sprite (Object Attribute) memory cleaning routine. Everything to 0.
; DESTROYS: 
;	A, HL, DE
;
    LD      HL, _OAMRAM     ; Object/Sprites attribute memory location
    LD      DE, 40*4        ; Total size = 40 sprites * 4 bytes each
.CLEAN_SPRITES_LOOP
    LD      A, 0
    LD      [HL+], A 		; Load 0 and increment HL
    
    DEC     DE 				; Decrease counter, if 0 end loop
    LD      A, D
    OR      E
    JR      NZ, .CLEAN_SPRITES_LOOP
    RET

;┬───────────────────────────────────────────────────────────────────────
;│ RAM FUNCTIONS
;└  
SECTION "RendersysHRAM", HRAM
OAM_DMA:
    DS DMA_ROUTINE.END - DMA_ROUTINE ; Reserve space to copy the routine

;║ EOF
;╚══════════════════════════════════════════════════════════════════════