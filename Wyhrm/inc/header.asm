;╦══════════════════════════════════════════════════════════════════════
;║ GameBoy Cartridge Header definitions for WYHRM GameBoy game.
;╬══════════════════════════════════════════════════════════════════════
;║ header.asm - Wyhrm for GameBoy
;║

NOP
JP  MAIN

;; [$0104 - $0133] NINTENDO LOGO
;DB  $CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C,$00,$0D
;DB  $00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6,$DD,$DD,$D9,$99
;DB  $BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC,$99,$9F,$BB,$B9,$33,$3E

;; no need to to specify it if youre using rgbdsfix
DB  $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB  $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DB  $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00


;; [$0134 - $013E] + [$013F - $0142] GAME TITLE
DB  "WYHRM      ", "    "
    ;0123456789A   ;0123
    ;NAME          ;PRODUCT CODE
    ;11 ASCII chrs ;4 ASCII chrs

;; [$0143] COLOR COMPATIBILITY
DB  $00

;; [$0144 - $0145] CREATOR CODE
DB  $00
DB  $00

;; [$0146] SUPER GAME BOY INDICATOR
DB  $00

;; [$0147] CARTRIDGE TYPE
DB  $00 

;; [$0148] ROM SIZE
DB  $00

;; [$0149] RAM SIZE
DB  $00

;; [$014A] DESTINATION
DB  $01

;; [$014B] LICENSE CODE
DB  $33

;; [$014C] MASK ROM VERSION / MANAGED BY RGBFIX
DB  $00

;; [$014D] COMPLEMENTARY CHECK / MANAGED BY RGBFIX
DB  $00

;; [$014E - $014F] CARTRIDGE CHECKSUM / MANAGED BY RGBFIX
DW  $00