; ---- LEVELS DEFINITIONS
MAP1:	
	;INCLUDE     "./inc/maps/map1/FOSO.asm"
	INCLUDE     "./inc/maps/map1/WhyrmMap1.z80"
.META1:
	INCLUDE     "./inc/maps/map1/WhyrmMap1.m.asm"
MAP2:
	INCLUDE     "./inc/maps/map2/WhyrmMap2.z80" 
.META1:
	INCLUDE     "./inc/maps/map2/WhyrmMap2.m.asm"
MAP3:
	INCLUDE     "./inc/maps/map3/WhyrmMap3.z80" 
.META1:
	INCLUDE     "./inc/maps/map3/WhyrmMap3.m.asm"
.META2:
	INCLUDE     "./inc/maps/map3/WhyrmMap3(2).m.asm"
MAP4:
	INCLUDE     "./inc/maps/map4/WhyrmMap4.z80" 
.META1:
	INCLUDE     "./inc/maps/map4/WhyrmMap4.m.asm"
MAP5:
	INCLUDE     "./inc/maps/map5/WhyrmMap5.z80" 
.META1:
	INCLUDE     "./inc/maps/map5/WhyrmMap5.m.asm"
;MAP6:
;	INCLUDE     "./inc/maps/map6/WhyrmMap6.z80" 
;.META1:
;	INCLUDE     "./inc/maps/map6/WhyrmMap6.m.asm"

; ---- LEVELS MAP DATA
MAP_PTR_ARRAY:
; LEVEL 0 
	DW MAP1
; LEVEL 1
    DW MAP2
; LEVEL 2
    DW MAP3
; LEVEL 3
    DW MAP3
; LEVEL 4
    DW MAP4
; LEVEL 5
    DW MAP5
; LEVEL 6
;    DW MAP6
; ---- LEVELS META DATA
META_PTR_ARRAY:
; LEVEL 0
	DW MAP1.META1
; LEVEL 1
    DW MAP2.META1
; LEVEL 2
    DW MAP3.META1
; LEVEL 3
    DW MAP3.META2
; LEVEL 4
    DW MAP4.META1
; LEVEL 5
    DW MAP5.META1
; LEVEL 6
;    DW MAP6.META1

; ---- WINDOWS DEFINITIONS
WIN1::	
	;INCLUDE     "./inc/maps/map1/FOSO.asm"
	INCLUDE     "./inc/maps/win1/WhyrmWin1.z80"