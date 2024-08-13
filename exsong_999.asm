; --- AD(F) bytecode file ---
; System: Casio PV-1000
; Driver: ADPV v1.0

; song: "999" by jvsTSX

; composed using furnace tracker by tildearrow and hand-encoded using a text editor

song_no999:
.dw no999_phrasesLst
.dw no999_GmacroLst
.dw no999_Groove
.dw no999_Ch1Tl
.dw no999_Ch2Tl
.dw no999_Ch3Tl

no999_Ch1Tl: ; bass
.db $03, $00
.db $03, $00
.db $03, $08
.db $03, $FE
.db $FF, 0

no999_Ch2Tl: ; lead
.db $00, $00
.db $01, $00
.db $01, $02
.db $02, $00
.db $01, $00
.db $01, $02
.db $FF, 0

no999_Ch3Tl: ; perc
.db $04, $00
.db $04, $00 
.db $04, $00
.db $05, $00

.db $FF, 0

no999_Groove:
.db 7, $0, 0, 8, 0, 3

no999_GmacroLst:
.dw no999_Gm1_Bend
.dw no999_Gm2_KDrum
.dw no999_Gm3

no999_Gm1_Bend:
.db %00101001, 1
.db %10101001, 0, 0

no999_Gm2_KDrum:
.db %00111001, 8
.db %00111001, 5
.db %00111001, 4
.db %10001001, 0, 0

no999_Gm3:
.db %00100001
.db %10000001, 0, 0

no999_phrasesLst:
.dw no999_0lead1
.dw no999_1lead2
.dw no999_2lead3
.dw no999_3bass
.dw no999_4drums1
.dw no999_5drums2
.dw no999_nothing

no999_nothing:
.db %10000000, $7F

no999_0lead1:
.db %00001110, $83, $0F, $00



.db %00000110, $80, $0D
.db %00000110, $81, $0C

.db %00000110, $82, $0A


.db %00000110, $81, $08

.db %00000110, $81, $05

.db %00000110, $80, $08
.db %00000100, $83, $03



.db %00000011, $00
.db %00000100, $82, $03


.db %00000011, $00
.db %00000110, $82, $03


.db %00000110, $82, $00


.db %10000110, $81, $03


no999_1lead2:
.db %00000110, $81, $0B

.db %00000110, $81, $0D

.db %00000110, $80, $0B
.db %00000110, $81, $0A

.db %00000110, $82, $06


.db %00000100, $82, $01


.db %00000011, $00
.db %10000110, $81, $01

no999_2lead3:
.db %00000110, $83, $0F



.db %00000110, $80, $0D
.db %00000110, $81, $0C

.db %00000110, $82, $0A


.db %00000110, $81, $08

.db %00000110, $81, $05

.db %00000110, $80, $08
.db %00000100, $83, $0F



.db %00000011, $00
.db %00000110, $83, $0F



.db %00000110, $82, $16


.db %00000110, $82, $14


.db %10000110, $81, $0F



no999_3bass:
.db %00000001, $81, $03, $07

.db %00000001, $82, $03, $07


.db %00000001, $82, $03, $07


.db %00000001, $83, $03, $07



.db %00000001, $81, $03, $07

.db %10000001, $81, $03, $07


no999_4drums1:
.db %00001000, $81, $06, $01

.db %00001100, $80, $1B, $02
.db %00000100, $80, $1B
.db %00001000, $81, $06, $01

.db %00000100, $80, $1B
.db %00000100, $80, $1B
.db %00001000, $81, $06, $01

.db %00000100, $80, $1B
.db %00000100, $80, $1B
.db %00001000, $80, $06, $01
.db %00000100, $80, $1B
.db %00000100, $80, $1B
.db %10000100, $80, $1B

no999_5drums2:
.db %00001000, $81, $06, $01

.db %00000100, $80, $1B
.db %00000100, $80, $1B
.db %00001000, $81, $06, $01

.db %00000100, $80, $1B
.db %00000100, $80, $1B
.db %00001000, $80, $06, $01
.db %00000100, $80, $1B
.db %00001000, $80, $06, $01
.db %00000100, $80, $1B
.db %00001000, $80, $06, $01
.db %00001000, $80, $06, $01
.db %00001000, $80, $06, $01
.db %10001000, $80, $06, $01
