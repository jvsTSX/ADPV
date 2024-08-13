; //////////////////////////////////////////////////////////////
;           ____ ______   _______ ___     __   ________________
;         /     |   __  \|   ___  \  |   /  / |""|""""""""""|""|
;        /  /|  |  |  \  \  |___|  | |  /  /  |--|-========-|--|
;       /  /_|  |  |   |  |  ______| | /  /   |   \  ----  /   |
;      /  ___   |  |   |  | |     |  |/  /    |    "--__--"    |
;     /  /   |  |  |__/  /  |     |     /     |              __|
;    /__/    |__|_______/|__|     |___ /      |________________|
;              Audio Driver for casio PV-1000       ||
;                               jvsTSX / 2024       ~
; //////////////////////////////////////////////////////////////

; --- history ---
; v1.0: initial version, around 2 weeks of design and development (incl. procrastination)
;
; --- Thanks to --- 
; Lidnariq and PLG David (on discord) for providing me all the info about this console
; they also made a wiki page for it under NesDev - https://obscure.nesdev.org/wiki/Casio_PV-1000
;
; --- Features ---
; - General purpose macro (Gmacro)
; - Kill and Delayed note counters
; - Fixed notes on Gmacro for easy drums
; - C#3 to D#5 note range
; - Sound effects sub-driver included



;   /////////////////////////////////////////////////////////////////
;  ///                      SETUP SONG CODE                      ///
; /////////////////////////////////////////////////////////////////
ADPV_SETUP_MUSIC:

	; hl = song header location
	ld e, [hl]
	inc hl
	ld d, [hl]
	inc hl
	ld [ADPV_RAM_Hdr_PhraseList], de
	ld e, [hl]
	inc hl
	ld d, [hl]
	inc hl
	ld [ADPV_RAM_Hdr_GmacroList], de
	ld e, [hl]
	inc hl
	ld d, [hl]
	inc hl
	ld [ADPV_RAM_Hdr_TempoTableLocal], de
	ld e, [hl]
	inc hl
	ld d, [hl]
	inc hl
	ld [ADPV_RAM_Channel1+MUS_TmLineStartL], de
	ld e, [hl]
	inc hl
	ld d, [hl]
	inc hl
	ld [ADPV_RAM_Channel2+MUS_TmLineStartL], de
	ld e, [hl]
	inc hl
	ld d, [hl]
	inc hl
	ld [ADPV_RAM_Channel3+MUS_TmLineStartL], de

	xor a, a ; = 0
	ld [ADPV_RAM_TempoPos], a
	ld [ADPV_RAM_Channel1+MUS_CurrTsp], a
	ld [ADPV_RAM_Channel2+MUS_CurrTsp], a
	ld [ADPV_RAM_Channel3+MUS_CurrTsp], a
	ld [ADPV_RAM_Channel1+MUS_WorkFlags], a ; main+ovr muted, autos disabled
	ld [ADPV_RAM_Channel2+MUS_WorkFlags], a
	ld [ADPV_RAM_Channel3+MUS_WorkFlags], a
	ld [ADPV_RAM_Channel1+MUS_OffsetNote], a
	ld [ADPV_RAM_Channel2+MUS_OffsetNote], a
	ld [ADPV_RAM_Channel3+MUS_OffsetNote], a

	inc a ; = 1
	ld [ADPV_RAM_TempoCnt], a
	ld [ADPV_RAM_Channel1+MUS_WaitRows], a
	ld [ADPV_RAM_Channel2+MUS_WaitRows], a
	ld [ADPV_RAM_Channel3+MUS_WaitRows], a

	ld a, $FF
	ld [ADPV_RAM_Channel1+SFX_Req], a
	ld [ADPV_RAM_Channel2+SFX_Req], a
	ld [ADPV_RAM_Channel3+SFX_Req], a
	ld [ADPV_RAM_Channel1+SFX_Curr], a
	ld [ADPV_RAM_Channel2+SFX_Curr], a
	ld [ADPV_RAM_Channel3+SFX_Curr], a
	ld [ADPV_RAM_Channel1+MUS_OvrNote], a
	ld [ADPV_RAM_Channel2+MUS_OvrNote], a
	ld [ADPV_RAM_Channel3+MUS_OvrNote], a
	ld [ADPV_RAM_Channel1+MUS_LastGmIdx], a
	ld [ADPV_RAM_Channel2+MUS_LastGmIdx], a
	ld [ADPV_RAM_Channel3+MUS_LastGmIdx], a
	ld [ADPV_RAM_Channel1+MUS_GmacroIdx], a
	ld [ADPV_RAM_Channel2+MUS_GmacroIdx], a
	ld [ADPV_RAM_Channel3+MUS_GmacroIdx], a

	ld hl, [ADPV_RAM_Channel1+MUS_TmLineStartL]
	ld b, [hl] ; get phrase index
	inc hl
	ld a, [hl] ; get new transpose
	inc hl
	ld [ADPV_RAM_Channel1+MUS_NextTsp], a
	ld [ADPV_RAM_Channel1+MUS_TmLinePosL], hl ; store advanced pointer (+2'ed)
  call @GetPhraseFromList
	ld [ADPV_RAM_Channel1+MUS_PhrasePosL], hl

	ld hl, [ADPV_RAM_Channel2+MUS_TmLineStartL]
	ld b, [hl]
	inc hl
	ld a, [hl]
	inc hl
	ld [ADPV_RAM_Channel2+MUS_NextTsp], a
	ld [ADPV_RAM_Channel2+MUS_TmLinePosL], hl
  call @GetPhraseFromList
	ld [ADPV_RAM_Channel2+MUS_PhrasePosL], hl

	ld hl, [ADPV_RAM_Channel3+MUS_TmLineStartL]
	ld b, [hl]
	inc hl
	ld a, [hl]
	inc hl
	ld [ADPV_RAM_Channel3+MUS_NextTsp], a
	ld [ADPV_RAM_Channel3+MUS_TmLinePosL], hl
  call @GetPhraseFromList
	ld [ADPV_RAM_Channel3+MUS_PhrasePosL], hl
  ret

@GetPhraseFromList:
	ld a, b
	ld hl, [ADPV_RAM_Hdr_PhraseList]
	add a, a ; 16-bit add with 9-bit (8 <<1)
	ld e, a
	ld d, 0
	rl d
	add hl, de
	ld a, [hl] ; deref new phrase pos from list
	inc hl
	ld h, [hl]
	ld l, a
  ret



;   /////////////////////////////////////////////////////////////////
;  ///                       SFX SUBDRIVER                       ///
; /////////////////////////////////////////////////////////////////

; no setup code included, to setup SFX just load a [pair] with your SFX list location and then 
; load [pair] -> [ADPV_RAM_SFX_ListLocal]

; SFX list format:
; .dw MySFX1
; .dw MySFX2
; .dw MySFX3
; .dw...

; the label of each SFX is in the start of the SFX bytecode that forms your sound effects
; MySFX1: ; example beep sound
; .db %10101111 $FD

ADPV_RUN_SFX:

; ERFWWWWW ($FF)

; ix must be the channel base, c must be the register number
	ld a, [ix+SFX_Req]
	cp a, $FF
  ret z
	cp a, $FE
  jp z, @SFXPlaying
; sfx init
	ld [ix+SFX_Curr], a ; sfx status number for priority purposes
	ld b, $FE
	ld [ix+SFX_Req], b ; currently playing flag

	ld hl, [ADPV_RAM_SFX_ListLocal]
	ld d, 0
	add a, a
	ld e, a
	rl d
	add hl, de
	ld a, [hl] ; deref
	inc hl
	ld h, [hl]
	ld l, a
  jp @SFXKickstart

@SFXPlaying:
	dec [ix+SFX_Wait]
  ret nz

	ld l, [ix+SFX_PosL]
	ld h, [ix+SFX_PosH]
@SFXKickstart:
	ld a, [hl] ; get sfx header
	ld b, a
	and a, %00011111
	ld [ix+SFX_Wait], a

	bit 5, b
  jp z, @NoFreq
	inc hl
	ld a, [hl]
	out [c], a
@NoFreq:

	bit 6, b
	ld a, %00000010 ; sound enable on, ring off
  jp z, @NoFRing
	inc a
@NoFRing:
	out [$FB], a

	bit 7, b
  jp z, @NoEnd
	ld a, $FF
	ld [ix+SFX_Req], a
	ld [ix+SFX_Curr], a
	out [c], a ; tone off, in case you're only using the SFX with the main sound driver off
  ret

@NoEnd:
	inc hl
	ld [ix+SFX_PosL], l
	ld [ix+SFX_PosH], h
  ret



;   /////////////////////////////////////////////////////////////////
;  ///                         MAIN DRIVER                       ///
; /////////////////////////////////////////////////////////////////
ADPV_RUN_MUSIC:

; TEMPO STAGE
	ld hl, ADPV_RAM_TempoCnt ; decrement tempo count
	dec [hl]
  jp nz, @NoPatProcess       ; is it 0? if not leave the tempo status flag zero, process only block B
	ld a, 1                  ; flag for Block A to execute
	ld [ADPV_RAM_TempoStatus], a
@NoPatProcess:               ; setup a few things before entering the indexed loop

;   /////////////////////////////////////////////////////////////////
;  ///                       RUN AUTOCUT                         ///
; /////////////////////////////////////////////////////////////////
; it's basically an automatic kill command but always set to kill right before the next note
; so far it's unrolled for performance, as a 32K cart should be plenty of space

	ld a, [ADPV_RAM_TempoCnt] ; check if tempo is 1 tick left
	cp a, 1
  jp nz, @NoACut
	ld a, [ADPV_RAM_Channel1+MUS_WorkFlags] ; channel 1
	bit 2, a
  jp z, @NoACutCh1
	ld a, [ADPV_RAM_Channel1+MUS_WaitRows]
	cp a, 1
  jp nz, @NoACutCh1
	xor a, a ; = 0
	ld [ADPV_RAM_Channel1+MUS_WorkFlags], a
	dec a ; = $FF
	ld [ADPV_RAM_Channel1+MUS_GmacroIdx], a
@NoACutCh1:

	ld a, [ADPV_RAM_Channel2+MUS_WorkFlags] ; channel 2
	bit 2, a
  jp z, @NoACutCh2
	ld a, [ADPV_RAM_Channel2+MUS_WaitRows]
	cp a, 1
  jp nz, @NoACutCh2
	xor a, a ; = 0
	ld [ADPV_RAM_Channel2+MUS_WorkFlags], a
	dec a ; = $FF
	ld [ADPV_RAM_Channel2+MUS_GmacroIdx], a
@NoACutCh2:

	ld a, [ADPV_RAM_Channel3+MUS_WorkFlags] ; channel 3
	bit 2, a
  jp z, @NoACutCh3
	ld a, [ADPV_RAM_Channel3+MUS_WaitRows]
	cp a, 1
  jp nz, @NoACutCh3
	xor a, a ; = 0
	ld [ADPV_RAM_Channel3+MUS_WorkFlags], a
	dec a ; = $FF
	ld [ADPV_RAM_Channel3+MUS_GmacroIdx], a
@NoACutCh3:
@NoACut:

; prepare to enter block A
	ld ix, ADPV_RAM_Channel1 ; ix base
	ld a, 3                  ; number of channel iterations
	ld [ADPV_RAM_ChannelCntDw], a

;   /////////////////////////////////////////////////////////////////
;  ///                         BLOCK A                           ///
; /////////////////////////////////////////////////////////////////
ADPV_BlockA:
	ld a, [ADPV_RAM_TempoStatus]
	or a, a
  jp z, ADPV_BlockB ; zero? if yes no note to handle now

; process pattern stuff
	dec [ix+MUS_WaitRows]
  jp nz, ADPV_BlockB

	ld l, [ix+MUS_PhrasePosL]
	ld h, [ix+MUS_PhrasePosH]

	ld c, [hl] ; header
	inc hl
	ld b, [hl] ; wait num
	ld a, b
	and a, %01111111
	inc a
	ld [ix+MUS_WaitRows], a
	inc hl
	
	bit 7, b
  jp z, @NoNote
	ld a, [hl]
	ld [ix+MUS_CurrNote], a
	inc hl
	set 7, [ix+MUS_WorkFlags] ; enable sound out

	ld a, [ix+MUS_NextTsp]
	ld [ix+MUS_CurrTsp], a
@NoNote:

; high header

; 00: no, 01: kill, 10: acut, 11: instamute
	bit 1, c
  jp nz, @Kf_FieldHigh
	bit 0, c
  jp z, @NoKill
	ld a, [hl]
	inc hl
	ld [ix+MUS_KillWait], a
	set 0, [ix+MUS_WorkFlags]
  jp @NoKill
@Kf_FieldHigh:
	bit 0, c
  jp z, @SetACut
	xor a, a
	ld [ix+MUS_WorkFlags], a
	dec a ; = $FF
	ld [ix+MUS_GmacroIdx], a
  jp @NoKill
@SetACut:
	set 2, [ix+MUS_WorkFlags]
@NoKill:

; 00: no, 01: last, 10: current, 11: both
	bit 3, c
  jp nz, @Gm_FieldHigh
	bit 2, c
  jp z, @NoGmacro
	ld a, [ix+MUS_LastGmIdx]
	ld [ix+MUS_GmacroIdx], a
  jp @NoGmacro
@Gm_FieldHigh:
	ld a, [hl]
	inc hl
	ld [ix+MUS_GmacroIdx], a
	bit 2, c
  jp z, @NoGmacro
	ld [ix+MUS_LastGmIdx], a
@NoGmacro:

	; Tempotable
	bit 4, c
  jp z, @NoTempoTable	
	ld a, [hl]
	inc hl
	ld [ADPV_RAM_TempoPos], a
@NoTempoTable:

	; ringmod
	ld a, c
	and a, %00100000
	ld b, [ix+MUS_WorkFlags]
	res 5, b
	or a, b
	ld [ix+MUS_WorkFlags], a

	; Delay
	bit 6, c
  jp z, @NoDelay
	set 1, [ix+MUS_WorkFlags]
	ld a, [hl]
	inc hl
	ld [ix+MUS_DelayWait], a
	ld [ix+MUS_DelayAddrL], l ; remember here
	ld [ix+MUS_DelayAddrH], h

	ld a, [hl] ; offset HL accordingly
	and a, %00000011
	inc a	
	add a, l
	ld l, a
	adc a, h
	sub a, l
	ld h, a
@NoDelay:
	
	; End
	bit 7, c
  jp z, @OffsetPhrase
	; or else this phrase is done, lookup next
	ld l, [ix+MUS_TmLinePosL]
	ld h, [ix+MUS_TmLinePosH]

	ld a, [hl] ; new phrase
	cp a, $FF
  jp nz, @ContinueTimeLine
	inc hl
	ld a, [hl] ; offset from start
	add a, a
	ld e, a
	ld d, 0
	rl d
	ld l, [ix+MUS_TmLineStartL]
	ld h, [ix+MUS_TmLineStartH]
	add hl, de

	ld [ix+MUS_TmLinePosL], l
	ld [ix+MUS_TmLinePosH], h
	ld a, [hl]
@ContinueTimeLine:
	inc hl
	ld b, [hl]
	ld [ix+MUS_NextTsp], b
	inc hl
	ld [ix+MUS_TmLinePosL], l
	ld [ix+MUS_TmLinePosH], h
	
	; get new phrase location from index
	ld hl, [ADPV_RAM_Hdr_PhraseList]
	add a, a
	ld e, a
	ld d, 0
	rl d
	add hl, de
	
	ld a, [hl]
	inc hl
	ld h, [hl]
	ld [ix+MUS_PhrasePosL], a
	ld [ix+MUS_PhrasePosH], h
  jp ADPV_BlockB
	
; offset current phrase pos
@OffsetPhrase:
	ld [ix+MUS_PhrasePosL], l
	ld [ix+MUS_PhrasePosH], h

;   /////////////////////////////////////////////////////////////////
;  ///                         BLOCK B                           ///
; /////////////////////////////////////////////////////////////////
ADPV_BlockB:


ADPV_B_KillNote:; ///////////////////////////////////////////////////
	bit 0, [ix+MUS_WorkFlags]
  jp z, @NoKill
	dec [ix+MUS_KillWait]
  jp nz, @NoKill
	xor a, a
	ld [ix+MUS_WorkFlags], a
	dec a ; = $FF
	ld [ix+MUS_GmacroIdx], a ; kill gmacro
@NoKill:

ADPV_B_DelayNote:; //////////////////////////////////////////////////
	bit 1, [ix+MUS_WorkFlags]
  jp z, @NoDelay
	dec [ix+MUS_DelayWait]
  jp nz, @NoDelay
	res 1, [ix+MUS_WorkFlags]
	ld l, [ix+MUS_DelayAddrL]
	ld h, [ix+MUS_DelayAddrH]
	
	ld a, [hl] ; grab header
	ld c, a

; 00: no, 01: kill, 10: acut, 11: instamute
	bit 3, c
  jp nz, @Kf_FieldHigh
	bit 2, c
  jp z, @NoKill
	ld a, [hl]
	inc hl
	ld [ix+MUS_KillWait], a
	set 0, [ix+MUS_WorkFlags]
  jp @NoKill
@Kf_FieldHigh:
	bit 2, c
  jp z, @SetACut
	xor a, a
	ld [ix+MUS_WorkFlags], a
	dec a ; = $FF
	ld [ix+MUS_GmacroIdx], a
  jp @NoKill
@SetACut:
	set 2, [ix+MUS_WorkFlags]
@NoKill:
	
; 00: no, 01: last, 10: current, 11: both
	bit 5, c
  jp nz, @Gm_FieldHigh
	bit 4, c
  jp z, @NoGmacro
	ld a, [ix+MUS_LastGmIdx]
	ld [ix+MUS_GmacroIdx], a
  jp @NoGmacro
@Gm_FieldHigh:
	ld a, [hl]
	inc hl
	ld [ix+MUS_GmacroIdx], a
	bit 4, c
  jp z, @NoGmacro
	ld [ix+MUS_LastGmIdx], a
@NoGmacro:
	
	; note
	bit 6, c
  jp z, @NoNote
	ld a, [hl]
	ld [ix+MUS_CurrNote], a
	set 7, [ix+MUS_WorkFlags]
@NoNote:

	; ringmod flag
	ld a, c
	and a, %10000000
	rrca
	rrca
	ld b, [ix+MUS_WorkFlags]
	res 5, b
	or a, b
	ld [ix+MUS_WorkFlags], a

@NoDelay:

ADPV_B_Gmacro:; /////////////////////////////////////////////////////
	ld a, [ix+MUS_GmacroIdx]
	cp a, $FF ; = disabled
  jp z, @NoGmacro
	cp a, $FE ; = running
  jp z, @MacroIsRunning
	; otherwise setup a new gmacro location
	ld hl, [ADPV_RAM_Hdr_GmacroList]
	add a, a
	ld e, a
	ld d, 0
	rl d
	add hl, de
	ld a, [hl]
	inc hl
	ld h, [hl]
	ld l, a
	
	ld a, $FE
	ld [ix+MUS_GmacroIdx], a ; = running
  jp @RunGmacro
	
@MacroIsRunning:
	dec [ix+MUS_GmacroWait]
  jp nz, @NoGmacro
	
	ld l, [ix+MUS_GmacroPosL]
	ld h, [ix+MUS_GmacroPosH]
@RunGmacro:
; %EROMNWWW (WW) (NN) (LL)
	ld c, [hl]
	inc hl
	ld a, c
	and a, %00000111
  jp nz, @NoWaitExField
	ld a, [hl]
	inc hl
@NoWaitExField:
	ld [ix+MUS_GmacroWait], a

	bit 4, c
  jp nz, @FixedGEv
	bit 5, c
	res 7, [ix+MUS_WorkFlags]
  jp z, @NormalNoteMute
	set 7, [ix+MUS_WorkFlags]
@NormalNoteMute:
	bit 3, c
  jp z, @NoteDone
	ld a, [hl]
	inc hl
	ld [ix+MUS_OffsetNote], a
	ld a, $FF
	ld [ix+MUS_OvrNote], a
  jp @NoteDone

@FixedGEv:
	bit 5, c
	res 6, [ix+MUS_WorkFlags]
  jp z, @FixedNoteMute
	set 6, [ix+MUS_WorkFlags]
@FixedNoteMute:
	bit 3, c
  jp z, @NoteDone
	ld a, [hl]
	inc hl
	ld [ix+MUS_OvrNote], a
@NoteDone:

	; ringmod
	ld a, c
	and a, %01000000
	rrca
	ld b, [ix+MUS_WorkFlags]
	res 5, b
	or a, b
	ld [ix+MUS_WorkFlags], a

	; end gmacro
	bit 7, c
  jp z, @WriteGmacroPos
	ld a, [hl]
	or a, a
  jp nz, @GmacroLoop
	ld a, $FF
	ld [ix+MUS_GmacroIdx], a ; = disabled
  jp @NoGmacro
@GmacroLoop:
	ld e, a
	ld d, 0
	ccf
	sbc hl, de
@WriteGmacroPos:
	ld [ix+MUS_GmacroPosL], l
	ld [ix+MUS_GmacroPosH], h
@NoGmacro:

; offset to next channel ////////////////////////////////////////////
	ld a, ADPV_CH_RAMIDXBLKSIZE
	add a, ixl
	ld ixl, a
	adc a, ixh
	sub a, ixl
	ld ixh, a

	ld hl, ADPV_RAM_ChannelCntDw
	dec [hl]
  jp nz, ADPV_BlockA

; finish tempo stage

ADPV_TempoTableProcess:
	ld a, [ADPV_RAM_TempoStatus]
	or a, a
  jp z, @NoTempoStep
	ld hl, ADPV_RAM_TempoPos
	ld de, [ADPV_RAM_Hdr_TempoTableLocal]
	ld a, [hl]    ; local + position
	add a, e
	ld e, a
	adc a, d
	sub a, e
	ld d, a
	ld a, [de]    ; get current value
	inc [hl]      ; next pos
	or a, a       ; is it 0?
  jp nz, @TempoValWrite
	inc de        ; if yes else we reached an end point
	ld a, [de]    ; new pos
	ld [hl], a

	ld de, [ADPV_RAM_Hdr_TempoTableLocal] ; do this again, to get the new tempo length
	ld a, [hl] ; local + position
	add a, e
	ld e, a
	adc a, d
	sub a, e
	ld d, a
	ld a, [de]
	inc [hl]
@TempoValWrite:
	ld [ADPV_RAM_TempoCnt], a
	xor a, a
	ld [ADPV_RAM_TempoStatus], a
@NoTempoStep:


;   /////////////////////////////////////////////////////////////////
;  ///                        REGISTER GEN                       ///
; /////////////////////////////////////////////////////////////////
ADPV_RegGen:

	; channel 1
	ld ix, ADPV_RAM_Channel1
	ld c, $F8
  call ADPV_CalcNote

	; channel 2
	ld ix, ADPV_RAM_Channel2
	ld c, $F9
  call ADPV_CalcNote

	; channel 3
	ld ix, ADPV_RAM_Channel3
	ld c, $FA
  call ADPV_CalcNote

	; global
	ld a, [ADPV_RAM_Channel1+MUS_WorkFlags]
	ld b, a
	ld a, [ADPV_RAM_Channel2+MUS_WorkFlags]
	ld c, a
	ld a, [ADPV_RAM_Channel3+MUS_WorkFlags]
	or a, b
	or a, c
	and a, %00100000
	ld a, %00000010
  jp z, @NoRingMod
	inc a
@NoRingMod:
	out [$FB], a
  ret



ADPV_CalcNote:
	ld a, [ix+SFX_Req] ; SFX playing?
	cp a, $FF
  ret nz
	ld a, [ix+MUS_OvrNote]
	cp a, $FF
  jp z, @NormalNote
	bit 6, [ix+MUS_WorkFlags]
  jp z, @ChannelMuted
  jp @CalcPitch

@NormalNote:
	bit 7, [ix+MUS_WorkFlags]
  jp z, @ChannelMuted
	ld a, [ix+MUS_CurrNote]
	add a, [ix+MUS_CurrTsp]
	add a, [ix+MUS_OffsetNote]
@CalcPitch:
	ld hl, ADPV_NoteLut
	add a, l
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	ld a, [hl]
	out [c], a
  ret

@ChannelMuted:
	ld a, $3F
	out [c], a
  ret



;   /////////////////////////////////////////////////////////////////
;  ///                           NOTE LUT                        ///
; /////////////////////////////////////////////////////////////////
ADPV_NoteLut:
; PV-1000's pitch formula is divider without +1 (like AY-3-8910) and inverted (00 = lowest)
; A4 = 432.5Hz

.db $00 ; C#3 00
.db $02 ; D-3 01
.db $06 ; D#3 02
.db $09 ; E-3 03
.db $0C ; F-3 04
.db $0F ; F#3 05
.db $12 ; G-3 06
.db $14 ; G#3 07
.db $17 ; A-3 08
.db $19 ; A#3 09
.db $1B ; B-3 0A
.db $1D ; C-4 0B
.db $1F ; C#4 0C
.db $21 ; D-4 0D
.db $22 ; D#4 0E
.db $24 ; E-4 0F
.db $26 ; F-4 10
.db $27 ; F#4 11
.db $28 ; G-4 12
.db $2A ; G#4 13
.db $2B ; A-4 14
.db $2C ; A#4 15
.db $2D ; B-4 16
.db $2E ; C-5 17
.db $2F ; C#5 18
.db $30 ; D-5 19
.db $31 ; D#5 1A
.db $3E ; HAT 1B



;   /////////////////////////////////////////////////////////////////
;  ///                      RAM DEFINITIONS                      ///
; /////////////////////////////////////////////////////////////////
.define ADPV_CH_RAMIDXBLKSIZE = $1B

.define MUS_WaitRows   = $0
.define MUS_WorkFlags  = $1
.define MUS_PhrasePosL = $2
.define MUS_PhrasePosH = $3
.define MUS_TmLinePosL = $4
.define MUS_TmLinePosH = $5
.define MUS_LastGmIdx  = $6

.define MUS_GmacroWait = $7
.define MUS_GmacroPosL = $8
.define MUS_GmacroPosH = $9
.define MUS_GmacroIdx  = $A

.define MUS_KillWait   = $B
.define MUS_DelayWait  = $C
.define MUS_DelayAddrL = $D
.define MUS_DelayAddrH = $E

.define MUS_NextTsp    = $F
.define MUS_CurrTsp    = $10
.define MUS_CurrNote   = $11
.define MUS_OffsetNote = $12
.define MUS_OvrNote    = $13

.define MUS_TmLineStartL = $14
.define MUS_TmLineStartH = $15

.define SFX_Req     = $16
.define SFX_Curr    = $17
.define SFX_Wait    = $18
.define SFX_PosL    = $19
.define SFX_PosH    = $1A


; RAMDEFS
.RAMSECTION "ADPV_Vars" BANK 0 SLOT 1
ADPV_RAM_Hdr_PhraseList        dw
ADPV_RAM_Hdr_GmacroList        dw
ADPV_RAM_Hdr_TempoTableLocal   dw
ADPV_RAM_SFX_ListLocal         dw

ADPV_RAM_TempoCnt     db
ADPV_RAM_TempoPos     db
ADPV_RAM_TempoStatus  db ; nonzero = ok, step
ADPV_RAM_ChannelCntDw db

; workflags = EOR--ADK: sound Enable; Overlay sound enable; Ringmod; Autocut enabled; Delay pending; Kill pending
; ringmod state from all channels are ORed together
; if 0 mute/disabled, if 1 enabled

; global control RAM = 12 bytes

; total RAM = 93 bytes

ADPV_RAM_Channel1 dsb $1B ; total channel RAM =  81 bytes (27 each)
ADPV_RAM_Channel2 dsb $1B
ADPV_RAM_Channel3 dsb $1B
; +0     WaitRows
; +1     WorkFlags
; +2,3   PhrasePos
; +4,5   TmLinePos
; +6     LastGmIdx
;
; +7     GmacroWait
; +8,9   GmacroPos
; +A     GmacroIdx
;
; +B     KillWait
; +C     DelayWait
; +D,E   DelayAddr
;
; +F     NextTsp
; +10    CurrTsp
; +11    CurrNote
; +12    OffsetNote
; +13    OvrNote
;
; +14,15 TimelineStart
;
; +14    SFX_Req
; +15    SFX_Curr
; +16    SFX_Wait
; +17,18 SFX_Pos
.ends
