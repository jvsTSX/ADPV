# ADPV Version 1.0 Documentation
Audio Driver for PV-1000 by jvsTSX - 2024

Special thanks to Lidnariq and PLGDavid for providing me all the needed details and information about this console's hardware at the NESDev discord server. This wouldn't have been possible without their help, you can find the info for this console at https://obscure.nesdev.org/wiki/Casio_PV-1000.

ADPV is part of a small sound driver family, AD(F), which aims to offer music and SFX capabilities by using as much of the hardware as possible, avoiding softsynth techniques unless strictly necessary. For this driver you have the following features:

- General purpose macro (Gmacro), as all AD(F) compliant drivers should have.
- Kill and Delayed note counters for frame-resolution notes and note cuts.
- Autocut, effectively Kill note counter but automatically triggering as soon as it sees an adjacent note will play.
- Fixed notes on Gmacro for easy drums.
- C#3 to D#5 note range, tuned to A4 = 432.5hz for optimal tuning.
- Sound effects sub-driver included, as all AD(F) compliant drivers should.

### A few first notes before beggining
- The song data doesn't need to be aligned, as the Z80 doesn't take any cycle count hits from page crosses, it's somewhat of a 16-bit CPU when it comes to that aspect.
- Lists are 512-byte long due to the limit of the indices being only a single byte, but in theory they can stretch to any length like the data it points to and the timeline.
- Everything must be propperly `.INCLUDE`d in your main source file before proceeding, keeping in mind that you also have to make a RAM slot for the driver variables.

# 1: Setup Code
In order to initialize the main music driver with all correct values and locations, this function under the label of `ADPV_SETUP_MUSIC` will take the address at register pair `hl` and from there load the song header into the driver's RAM segment, afterwards it will initialize a few things to safe (disabled) values and set the propper timeline and phrase positions.

Its usage is as simple as that, just make sure you load `hl <- header` and not `hl <- [header]`, such as:
```
	ld hl, MenuBGM
  call ADPV_SETUP_MUSIC
```

Note that variables that will automatically be initialized as the song plays will stay undefined.

# 2: Music

## Usage
Once the Setup Code is done, your program has to consistently call the `ADPV_RUN_MUSIC` label every frame, this will call the main music sound driver and step everything by one tick.

## Song Structure
In order for your song to be propperly executed by the music driver it must be formatted in the following way:

### Header
The song header is located in ROM and holds a few pointers that the driver will copy into RAM for faster access and use it to figure out where each element and list base location is inside the cartridge, it should be preceded by a label for clarity.
```
headerlbl:
.dw PhraseList      - base location of the phrases list
.dw GmacroList      - base location of the list of Gmacros
.dw TempoTableStart - base location of the tempo table
.dw TmLineStart1    - base location of the channel 1 timeline
.dw TmLineStart2    - base location of the channel 2 timeline
.dw TmLineStart3    - base location of the channel 3 timeline
```

### List Pointers
In the header example above, the first two pointers ending with "List" do not point directly to the music bytecode or Gmacro bytecode, but instead it points into a list of 16-bit LE pointers (denoted by the `.dw` directive), in the exact same way as the header has pointers, it's done this way so Phrase and Gmacro sequences can be easily re-used, by simply specifying an index from this list.

### Direct Location Pointers
For the last four pointers in the example header, these point directly to the Tempo Table and Timeline base locations, which the driver reads from.

## Timeline format
The Timeline can have any number of entries, each entry consists of two individual bytes, the first byte (offset +0) tells which phrase to reference from the list and the second byte (offset+1) sets a transposition value in semitones for the duration of the entire phrase.
```
TmLineStart1: ; for example, channel 1 from the example header
.db $00, $FF
     |    |
     |    +---> note transpose value for this phrase, this example value transposes by -1 semitone
     +--------> index for which phrase to play from the list, this example value picks the first phrase in the list
```

If the phrase index byte (at offset +0) is $FF, then the timeline sequence for this phrase is done and will loop back to the beggining, but before doing so, the transpose byte (offset+1) now signifies the offset of entries from the start of the phrase, so that your song can contain an intro section that will not be played again when looping.
```
...
.db $FF, $01
     |   |
     |   +---> offset from start of the timeline
     +-------> end of phrase signal

an offset value of 1, will pick the second step in the timeline

TmLineStart1:
.db $00, $FF
.db $01, $00 <- starts from here now
...
```

## Tempo Table
Note: Unlike other lists, the tempo table is only 256-bytes long.

In order to allow for flexible swing tempos, the tempo table allows you to make a sequence of ticks to wait, for a classic swing tempo you may want to wait 5 ticks then 7 ticks for example, which in the tempo table will be encoded like this: `$05, $07, $00, $00`

The first two numbers represent the literal number of ticks to wait, if the tempo table decoder encounters a value of 0, then it will pick the byte ahead of it (offset+1) and use it as a literal value of where to go next in the table, on the example it just goes back to entry 0, which corresponds to looping back to waiting 5 ticks.

## Note Event
Every note that the driver plays is an event that encodes, in a bitfield, all supported software and hardware features just like a tracker has an effects column, the bit field is read from least significant to most significant (right to left) to make it easier for you, the user, to figure the order of all byte fields even when some are not requested.

Parenthesis () denote a conditional field, bits that are 0 will not request the matching field.

```
EDRTGGKK NWWWWWWW (NN) (KK) (GG) (TT) (DD, Delayed note event)
|||||||| ||||||||
|||||||| |+++++++--- number of rows to Wait + 1
|||||||| +---------- request Note index to play
||||||++------------ Kill note modifier selector
||||++-------------- Gmacro request selector
|||+---------------- Tempo table new location request
||+----------------- Ring modulation mode enable
|+------------------ request Delayed note event
+------------------- End phrase marker
```

The kill note modifier selector has the following options to choose from:
|Bits|Function|
|-|-|
|00|No effect|
|01|Kill note, requests (KK) field|
|10|Enable Autocut|
|11|Mutes any previous sound instantly untill the next event|

While the Gmacro request selector lets you choose whether you want:
|Bits|Function|
|-|-|
|00|No Gmacro|
|01|Use last Gmacro|
|10|Request the (GG) field but only to affect this event|
|11|Request the (GG) field and set it as the last played macro that "Use last" will load from next time|

## Delayed Note Event
A delayed note is essencially a smaller main note that can play in a number of ticks instead of number of rows, this function is mostly intended for triplets, all modifier fields are the same as the main note event ones.

Once the D bit in the main note event is set to "1", it will request the (DD) field and then delayed note event right after:
```
RNGGKKOO (KK) (GG) (NN)
||||||||
||||||++------------ Offset number in bytes (more on that below)
||||++-------------- Kill note modifier selector
||++---------------- Gmacro request selector
|+------------------ request Note index to play
+------------------- Ring modulation mode enable
```

Note that there is no tempo table request in delayed notes as that might cause weird unpredictable tempo timings.

The 2-bit Offset field is not used by the actual delay event decoder, instead it's used by the main event note to know how many bytes after the (DD) field and delay event header are there to skip, if for example, all conditional fields (NN), (KK) and (GG) are specified, then the `O` field must be `%11` to signify 3 bytes after the header. Specifying a wrong value will cause the main note event decoder to misalign itself relative to the song data.

## Gmacro
The Gmacro or General purpose macro, is a small sequence that can change some things around to implement percursion and chords (trough arpeggiation), it's capable of either looping or running once.
```
EROMNWWW (WW) (NN) (LL)
||||||||
|||||+++--- Wait ticks, if 0, request (WW) field
||||+------ Note request, requests (NN) field
|||+------- Note mode
||+-------- Output enable (0 = mute channel)
|+--------- Ring modulation enable
+---------- marks the End of the gmacro sequence and requests (LL) field
```

Note, Mode and Output bits work in conjunction to either offset the currently playing note or to overlay the current playing note with a forced note for drums.

- Normal note: N requests a semitone offset value such as +1, +2 or -1, -2 ($FF and $FE) that adds itself to the currently playing note, the output bit will set the current note-side mute.
- Fixed note: N requests a note lookup table value that forcefully ignores the currently playing note, the output bit will also override current note-side mutes.

## Kill Note Counter and Autocut
To allow for precise note cuts, the Kill counter requests a tick counter duration, once that duration is done it stops the currently playing Gmacro (if any) and mutes the note.

As for Autocut, it essencially performs a similar role as the Kill Counter, but instead of counting down by itself, it checks if there is exactly 1 tick left before a new event plays and cuts the note at that tick, it saves one byte of event data compared to Kill Counter (which requests an 8-bit count value) and is meant for clarity, such as when to indicate that two of the same note plays.

# 3: SFX Sub-driver

## Setup
Setting up the SFX list is much easier than setting up the main music driver, so for that reason there is no setup code for it, instead just simply load a register pair with the location of the SFX list and then store the pair at `ADPV_RAM_SFX_ListLocal`.

## SFX List
Similar to the main music driver, sound effect sequences are called from a list, each entry of the SFX list is just a 16-bit LE pointer like those used in the song header and lists.
```
SFX_List:
.dw ThisGame_SFX_0
.dw ThisGame_SFX_1
.dw ThisGame_SFX_2
.dw ThisGame_SFX_3
...
```

## Usage
Similarly to the main music driver, the `ADPV_RUN_SFX` variable must be called once every some consistent amount of time, such as V-Sync.

But, unlike the main song routine, SFX calls will only target one channel at a time so that you can have better control on which channels will be overlayed by a sound effect or not, therefore before calling the function, after the list location variable being initialized, you must load the constant `ADPV_RAM_Channel(number)` into register `ix` and the corresponding I/O register number at register `c`.

For clarity, the table below shows which values to use for each channel:
|Channel|IX value|C value|
|-|-|-|
|1|`ADPV_RAM_Channel1`|$F8|
|2|`ADPV_RAM_Channel2`|$F9|
|3|`ADPV_RAM_Channel3`|$FA|

And if you want to call all channels, it should look something like this:
```
	ld ix, ADPV_RAM_Channel1
	ld c, $F8
  call ADPV_RUN_SFX
	ld ix, ADPV_RAM_Channel2
	ld c, $F9
  call ADPV_RUN_SFX
	ld ix, ADPV_RAM_Channel3
	ld c, $FA
  call ADPV_RUN_SFX
```

## Format
```
ERFWWWWW (FF)
||||||||
|||+++++--- Wait frames
||+-------- Frequency request
|+--------- Ring modulation enable
+---------- End SFX sequence
```

## Triggering
To trigger a sound effect, load a SFX list index to the RAM variable `ADPV_RAM_Channel(n)+MUS_OvrNote`, once the SFX ends, this variable will be set to the value of $FF to indicate it's currently innactive, it's important to keep it with this value as it signals the main music driver that it can output its state into the sound registers. When a sound effect is executing, the overlay variable is set to the value $FE, if you want to know which SFX is currently playing, simply read from the variable `ADPV_RAM_Channel(n)+SFX_Curr`.

Note: replace "(n)" in `ADPV_RAM_Channel(n)` for 1, 2 or 3 depending on your desired channel to play the sound effect on.