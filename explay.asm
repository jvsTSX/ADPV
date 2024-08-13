.MEMORYMAP       ; memory definition for 32K ROM
	SLOTSIZE $4000
	DEFAULTSLOT 0
	SLOT 0 $0000
	SLOT 1 $BB00 "ADPV_Vars"
	SLOT 2 $BF00 "Mainvars"
.ENDME

.ROMBANKMAP
	BANKSTOTAL 1
	BANKSIZE $4000
	BANKS 1
.ENDRO

.BANK 0 SLOT 0
	.ORGA $0000
  jp Start


;   /////////////////////////////////////////////////////////////////
;  ///                   IRQ AND CONTROLLER READ                 ///
; /////////////////////////////////////////////////////////////////
.ORG $38
IRQ:
	push af
	in a, [$FC]  ; check if frame interrupt is the reason of request
	and a, %00000001
  jp z, ScanKeys
	out [$FD], a ; unlatch frame interrupt
	ld a, [MainFlags]
	or a, 1
	ld [MainFlags], a
	xor a, a
	ld [InterCount], a
@NoScan:
	in a, ($FD)  ; unltach scan irq	
	pop af
	ei
  reti

ScanKeys:
	ld a, [InterCount]
	cp a, 4
  jp z, @JoinKeys
  jp nc, IRQ@NoScan
	or a, a
  jp z, @JustSetKeysToFirstSet

	dec a
	push hl
	ld hl, RawKeys0
	add a, l
	ld l, a
	adc a, h
	sub a, l
	ld h, a

	in a, [$FD]
	ld [hl], a

	; select next keys
	ld hl, InterCount
	ld a, [hl]
	inc [hl] ; increment counter

	dec a
	ld l, a
	ld a, %00000010
  jp z, @NoShift
	rlca ; 0100
	dec l
  jp z, @NoShift
	rlca ; 1000

@NoShift:
	out [$FD], a ; select next controller bits
	pop hl
	pop af
	ei
  reti

; vvv subroutines and functions vvv
@JoinKeys: ;;;;;;;;;;;;;;;;;;;;;;;
	in a, [$FD]
	ld [RawKeys3], a
    
	push hl
	push bc
  call KeyBitJoin
	ld [Player1Keys], a
  call KeyBitJoin
	ld [Player2Keys], a

	ld hl, InterCount
	inc [hl]

	pop bc
	pop hl
  jp IRQ@NoScan

@JustSetKeysToFirstSet: ;;;;;;;;;;
	ld a, 1
	out [$FD], a
	ld [InterCount], a
  jp IRQ@NoScan

KeyBitJoin: ;;;;;;;;;;;;;;;;;;;;;;
	xor a, a
	ld hl, RawKeys3
	ld b, 4
@KeyBitLoopP1:
	rrc [hl]
	rra
	rrc [hl]
	rra
	dec hl
  djnz @KeyBitLoopP1
  ret

; wtf is this casio



;   /////////////////////////////////////////////////////////////////
;  ///                       INITIAL SETUP                       ///
; /////////////////////////////////////////////////////////////////
.ORG $100
Start:
	di
	im 1
	ld sp, $BFFF

; mainly copied from the hello world example i made for hello-world-everything
	; setup ULA regs
	ld a, $FF
	out [$F8], a ; shut up all channels first
	out [$F9], a
	out [$FA], a
	ld a, %00000010
	out [$FB], a ; enable sound

	ld a, %00000011 ; enable frame and scan interrupts (MAME currently treats them as always on)
	out [$FC], a

	ld a, $FF ; unlatch both interrupts just in case
	out [$FD], a
	in a, [$FD]

	ld a, $B8 ; tilemap and tile ram base address
	out [$FE], a

	ld a, %00100000 ; tile rom base address, some configs and border
	out [$FF], a

	ld bc, $B822
	ld hl, $B822 ; tilemap
	ld de, HwdStr
PrintLinLoop:
	ld a, [de]
	inc de
	or a, a
  jp z, EnterMain
	cp a, 10
  jp z, LineFeed
	ld [bc], a
	inc bc
  jp PrintLinLoop

LineFeed:
	ld bc, 32
	add hl, bc

	ld a, [de]
	inc de

	add a, l
	ld c, a
	adc a, h
	sub a, c
	ld b, a
	inc bc
  jp PrintLinLoop

EnterMain:
	ei
	xor a, a
	ld [MainFlags], a
	out [$FD], a

	; setup SFX list
	ld hl, TestSFXList
	ld [ADPV_RAM_SFX_ListLocal], hl

	; make sure SFX is silent
	ld a, $FF
	ld [ADPV_RAM_Channel1+SFX_Req], a

	; setup music driver
	ld hl, song_no999
  call ADPV_SETUP_MUSIC



;   /////////////////////////////////////////////////////////////////
;  ///                         MAIN LOOP                         ///
; /////////////////////////////////////////////////////////////////
Main:
	halt
	ld a, [MainFlags] ; check if V-Blank interrupt triggered
	and a, %00000001
  jp z, Main
	ld hl, MainFlags ; reset the software flag
	res 0, [hl]

  call ADPV_RUN_MUSIC ; update music

; display keys pressed (by a standard controller) for P1 and P2
	ld hl, $B9F1
	ld de, ControlLetters
	ld a, [Player1Keys]
	ld c, a
	ld b, 8
  call DispControls
	ld hl, $BA11
	ld de, ControlLetters
	ld a, [Player2Keys]
	ld c, a
	ld b, 8
  call DispControls

; play SFX from player 1 key presses
	ld a, [Last1Keys]
	cpl ; pv controllers are active high ??????
	ld b, a
	ld a, [Player1Keys]
	ld [Last1Keys], a
	cpl
	ld c, 0
  call ButtonsSFXPlay

; play SFX from player 2 key presses
	ld a, [Last2Keys]
	cpl
	ld b, a
	ld a, [Player2Keys]
	ld [Last2Keys], a
	cpl
	ld c, 0
  call ButtonsSFXPlay

; update SFX
	ld ix, ADPV_RAM_Channel3
	ld c, $FA
  call ADPV_RUN_SFX
  jp Main



;   /////////////////////////////////////////////////////////////////
;  ///                        SUBROUTINES                        ///
; /////////////////////////////////////////////////////////////////
ButtonsSFXPlay: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	xor a, b ; get difference
	and a, b ; exclude difference from 1-to-0
	ld b, 8
	ld hl, ADPV_RAM_Channel3+SFX_Req
@loop:
	rrca
  jp nc, @skip
	ld [hl], c
@skip:
	inc c
  djnz @loop
  ret

DispControls: ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	rlc c
	ld a, ' '
  jp nc, @NoLetter
	ld a, [de]
@NoLetter:
	ld [hl], a
	inc hl
	inc de
  djnz DispControls
  ret

; sound driver
.include "ADPV.asm"

;   /////////////////////////////////////////////////////////////////
;  ///                         DATA STUFF                        ///
; /////////////////////////////////////////////////////////////////
TestSFXList:
.dw Example_SFX_0
.dw Example_SFX_1
.dw Example_SFX_2
.dw Example_SFX_3
.dw Example_SFX_4
.dw Example_SFX_5
.dw Example_SFX_6
.dw Example_SFX_7

ControlLetters:
.db "SsRDUL12"

HwdStr:
;              111111111122222222
;        0123456789012345678901234567
.db     10
.db 0,  10
.db 0,  10
.db 0,  10
.db 7,  $80, $81, $82, $83, $84, $85, $86, $87, $88, $89, $8A, $8B, 10 ; logo
.db 7,  $8C, $8D, $8E, $8F, $90, $91, $92, $93, $94, $95, $96, $97, 10
.db 7,  $98, $99, $9A, $9B, $9C, $9D, $9E, $9F, $A0, $A1, $A2, $A3, 10
.db 7,  $A4, $A5, $A6, $A7, $A8, $A9, $AA, $AB, $AC, $AD, $AE, $AF, 10
.db 0,  10
.db 7,  "Version 1.0", 10
.db 5,  "By jvsTSX (2024)", 10
.db 0,  10
.db 3,  "Press buttons for SFX", 10
.db 0, 10
.db 5,  "Player 1:", 10
.db 5,  "Player 2:", 10
.db 0,  0
;   |
;   +-> for clarity, this column is the offset ammount of chars that the text line starts at, very likely nonstandard nonsense
; the original implementation in the hello world everything repo should not have this
; this value is read after linefeed (10) is read so the first line should not have this value

; music data
.include "exsong_999.asm"
.include "exsfx.asm"

; graphics
.ORG $2000
.incbin "tiles.bin"



;   /////////////////////////////////////////////////////////////////
;  ///                       RAM DEFINITIONS                     ///
; /////////////////////////////////////////////////////////////////
.RAMSECTION "Mainvars" BANK 0 SLOT 2
InterCount db
Player1Keys db
Player2Keys db
Last1Keys db
Last2Keys db
RawKeys0 db
RawKeys1 db
RawKeys2 db
RawKeys3 db

MainFlags db
.ENDS