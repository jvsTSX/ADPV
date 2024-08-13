# ADPV

## What is this?
ADPV is a compact music and SFX replayer written entirely in Z80 assembly, it executes its various bytecode formats everytime you call its functions. It should feature all hardware functions of the PV-1000 sound source and also offer a few software features such as the General purpose macro (Gmacro) and tempo control.

## What are the PV-1000 sound specs?
The PV-1000 has a super simple and barebones sound source built into its ULA:
- **Channels**: 3
- **Volumes**: on/off only
- **Frequency control method**: clock divider, 0 is the lowest frequency (up-counting)
- **Frequency resolution**: 6-bit, no +1 increment (such as AY-3-8910)
- **Number of possible frequencies**: 63 frequencies, as frequency $3F silences the channel
- **Other features**: global ring modulation, higher channels will XOR the lower channels as such: `1 <-2 <-3`

Notes: Channels have certain volumes to them, channel 1 is the quiet, channel 2 is medium and channel 3 is loud.

## Building
Make sure you have WLA-DX installed first! - https://github.com/vhelin/wla-dx

You can build the example program using these commands on your command line program of choice (after CD'ing into the directory of this repo):
```
wla-z80 -o explay.o explay.asm
wlalink linkfile explay.bin
```

### How to play it?
Use MAME, the current most accurate emulator for the PV-1000 - https://github.com/mamedev/mame

And then invoke it using a command line: `mame pv1000 -cartridge explay.bin -w -r 512x384 -nofilter`, optionally with `-debug` if you wish.

## How to use it?
ADPV is basically a library, simply include `ADPV.asm` in your main source file and call its functions, the example program and markdown docs shows you the functions and usage in practice.