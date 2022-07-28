; Camera initial position
DB 0, CAM_Y_LIMIT
; Number of entities to load from the file
DB 2
	;DEFINE_ENTITY	x,	y,	att
	DEFINE_PLAYER	40,180,0
	DEFINE_SPEAR 	128,224,OAMF_PAL0 	;$10 $1C