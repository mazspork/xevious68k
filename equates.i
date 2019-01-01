* Sequencer-specific equates ------------------------------------------------

;	----- Graphic quick info
window_width	equ	48			; bytes across
window_height	equ	256			; lines downwards
window_depth	equ	4			; bitplanes inwards
window_size	equ	window_width*window_height
plane1		equ	$1000			; addr of bitplane #1
plane2		equ	plane1+window_size
plane3		equ	plane2+window_size
plane4		equ	plane3+window_size
plane5		equ	plane4+window_size

;	----- STRUCTURE voxtable (16 bytes)
voxA		equ	$00
voxL		equ	$04
voxX		equ	$06
voxB		equ	$08
voxY		equ	$0C
voxZ		equ	$0E
voxtablelength	equ	$10

; 	----- STRUCTURE envelope (4 bytes)
envdistance	equ	$00	; Length of transition (*20ms)
envoffset	equ	$02	; Delta value (2's complement 16 bit)
envelopelength	equ	$04

; 	----- STRUCTURE note (10 bytes)
soundid		equ	$00	; waveform no. or zero for last note
volume		equ	$01	; initial volume 0-64
duration	equ	$02	; duration of note in 20ms intervals
pause		equ	$04	; subsequent pause also in 20ms intervals
period		equ	$06	; initial sample rate
envelope	equ	$08	; envelope no. or zero for same volume
pitchbender	equ	$09	; pitchbend no. or zero for same pitch
notelength	equ	$0A	; (10 bytes, no padding)

; 	----- STRUCTURE voxinfo (32 bytes)
noteaddr	equ	$00	; address of current note for channel.
durationcounter	equ	$04	; 20ms intervals left of note, counts.
envaddr		equ	$06	; address of envelope structure (if any).
envdelay	equ	$0A	; 20ms intervals left of envelope (if any).
pitchbendaddr	equ	$0C	; address of pitchbender structure (if any).
pitchbenddelay	equ	$10	; 20ms intervals left of pitchbender (if any).
envdelta	equ	$12	; fractional part of envelope's transition value
pitchbenddelta	equ	$14	; fractional part of pitchbender's transition
curvolume	equ	$16	; current volume on channel (0-64)
xcurvolume	equ	$17	; current volume fraction -128 to 127
curpitch	equ	$18	; current period (124 to ca. 8000)
lcurpitch	equ	$19	; (LSB of period)
xcurpitch	equ	$1A	; current period fraction -128 to 127
pad3		equ	$1B	; ---
voxstatus	equ	$1C	; voice status (see below)
voiceinfolength	equ	$20	; (1 pad byte)

; 	----- STATE voxstatus
playing_off	equ	0	; channel silent, DMA off
playing_AtoC	equ	1	; channel playing one-shot from A to C
looping_BtoC	equ	2	; channel playing loop from B to C
playing_BtoC	equ	3	; channel playing one-shot from B to C
playing_BtoD	equ	4	; channel playing one-shot from B to D
playing_zero	equ	5	; channel silent, DMA on (playing zeros)


* Equates -------------------------------------------------------------------


level1autovect	equ	$64

;	----- Exception vectors
swi0		equ	$80			; The sixteen TRAP vectors
swi1		equ	$81			; (software exceptions)
swi2		equ	$82
swi3		equ	$83
swi4		equ	$84
swi5		equ	$85
swi6		equ	$86
swi7		equ	$87
swi8		equ	$88
swi9		equ	$89
swiA		equ	$8A
swiB		equ	$8B
swiC		equ	$8C
swiD		equ	$8D
swiE		equ	$8E
swiF		equ	$8F

;	----- specific info on memory
custom		equ	$DFF000 		; base of custom registers
ramtop		equ	$80000			; stack pointer initial value
pad		equr	a6			; Paula, Agnus, Denise base

;	----- Some frequently used colour codes
white		equ	$FFF
brick_red	equ	$D00
red		equ	$F00
red_orange	equ	$F80
orange		equ	$F90
golden_orange	equ	$FB0
cadmium_yellow	equ	$FD0
lemon_yellow	equ	$FF0
lime_green	equ	$FB0
light_green	equ	$8E0
green		equ	$0F0
dark_green	equ	$2C0
forest_green	equ	$0B1
blue_green	equ	$0BB
aqua		equ	$0DB
light_aqua	equ	$1FB
sky_blue	equ	$6FE
light_blue	equ	$6CE
blue		equ	$00F
bright_blue	equ	$61F
dark_blue	equ	$06D
purple		equ	$91F
violet		equ	$C1F
magenta		equ	$F1F
pink		equ	$FAC
tangerine	equ	$DB9
brown		equ	$C80
dark_brown	equ	$A87
light_grey	equ	$CCC
medium_grey	equ	$999
dark_grey	equ	$666
black		equ	$000
yellow		equ	$FF0
cyan		equ	$0FF

* Bit positions -------------------------------------------------------------

clrbitx 	equ	(00)	; set/clr (use clrbit to clr, setbit to set)
setbitx 	equ	(15)	; set/clear control bit
intenx		equ	(14)	; master interrupt (enable only )
exterx		equ	(13)	; external interrupt
dsksynx 	equ	(12)	; disk re-synchronized
rbfx		equ	(11)	; equrial port receive buffer full
audio3x 	equ	(10)	; audio channel 3 block finished
audio2x 	equ	(09)	; audio channel 2 block finished
audio1x 	equ	(08)	; audio channel 1 block finished
audio0x 	equ	(07)	; audio channel 0 block finished
blitx		equ	(06)	; blitter finished
vertbx		equ	(05)	; start of vertical blank
coperx		equ	(04)	; coprocessor
portsx		equ	(03)	; i/o ports and timers
softintx	equ	(02)	; software interrupt request
dskblx		equ	(01)	; disk block done
tbex		equ	(00)	; serial port transmit buffer empty
bbusyx		equ	(14)	; blitter busy (r/o)
bzerox		equ	(13)	; blitter logic 0 (r/o)
bltprix 	equ	(10)	; "blitter-nasty", DMA priority
dmaenx		equ	(09)	; DMA master enable
bplenx		equ	(08)	; Bit-plane DMA enable
copenx		equ	(07)	; Copper DMA enable
bltenx		equ	(06)	; Blitter DMA enable
sprenx		equ	(05)	; Sprite DMA enable
dskenx		equ	(04)	; Disk DMA enable
aud3enx 	equ	(03)	; Aul 3 enable
aud2enx 	equ	(02)	; - 2 enable
aud1enx 	equ	(01)	; - 1 enable
aud0enx 	equ	(00)	; - 0 enable
clrall		equ	$7FFF	; writing this pattern resets all bits
setall		equ	$FFFF	; and this sets them all

* Bit patterns --------------------------------------------------------------

clrbit		equ	(0<<15)
setbit		equ	(1<<15)
inten		equ	(1<<14)
exter		equ	(1<<13)
dsksyn		equ	(1<<12)
rbf		equ	(1<<11)
audio3		equ	(1<<10)
audio2		equ	(1<<09)
audio1		equ	(1<<08)
audio0		equ	(1<<07)
blit		equ	(1<<06)
vertb		equ	(1<<05)
coper		equ	(1<<04)
ports		equ	(1<<03)
softint 	equ	(1<<02)
dskbl		equ	(1<<01)
tbe		equ	(1<<00)
bbusy		equ	(1<<14)
bzero		equ	(1<<13)
bltpri		equ	(1<<10)
dmaen		equ	(1<<09)
bplen		equ	(1<<08)
copen		equ	(1<<07)
blten		equ	(1<<06)
spren		equ	(1<<05)
dsken		equ	(1<<04)
aud3en		equ	(1<<03)
aud2en		equ	(1<<02)
aud1en		equ	(1<<01)
aud0en		equ	(1<<00)

* Custom PAD registers ------------------------------------------------------

bltddat 	equ	$000
dmaconr 	equ	$002
vposr		equ	$004
vhposr		equ	$006
dskdatr 	equ	$008
joy0dat 	equ	$00A
joy1dat 	equ	$00C
clxdat		equ	$00E

adkconr 	equ	$010
pot0dat 	equ	$012
pot1dat 	equ	$014
potinp		equ	$016
serdatr 	equ	$018
dskbytr 	equ	$01A
intenar 	equ	$01C
intreqr 	equ	$01E

dskpt		equ	$020
dsklen		equ	$024
dskdat		equ	$026
refptr		equ	$028
vposw		equ	$02A
vhposw		equ	$02C
copcon		equ	$02E
serdat		equ	$030
serper		equ	$032
potgo		equ	$034
joytest 	equ	$036
str		equ	$038
strvbl		equ	$03A
strhor		equ	$03C
strlong 	equ	$03E

bltcon0 	equ	$040
bltcon1 	equ	$042
bltafwm 	equ	$044
bltalwm 	equ	$046
bltcptr		equ	$048
bltbptr		equ	$04C
bltaptr		equ	$050
bltdptr		equ	$054
bltsize 	equ	$058

bltcmod 	equ	$060
bltbmod 	equ	$062
bltamod 	equ	$064
bltdmod 	equ	$066

bltcdat 	equ	$070
bltbdat 	equ	$072
bltadat 	equ	$074

dsksync 	equ	$07E

cop1lc		equ	$080
cop2lc		equ	$084
copjmp1 	equ	$088
copjmp2 	equ	$08A
copins		equ	$08C
diwstrt 	equ	$08E
diwstop 	equ	$090
ddfstrt 	equ	$092
ddfstop 	equ	$094
dmacon		equ	$096
clxcon		equ	$098
intena		equ	$09A
intreq		equ	$09C
adkcon		equ	$09E

audio		equ	$0A0
audptr		equ	0
audlc		equ	0
audlch		equ	0
audlen		equ	4
audper		equ	6
audvol		equ	8

aud0lc		equ	$0A0
aud0lch		equ	$0A0
aud0lcl		equ	$0A2
aud0len		equ	$0A4
aud0per		equ	$0A6
aud0vol		equ	$0A8
aud0dat		equ	$0AA

aud1lc		equ	$0B0
aud1lch		equ	$0B0
aud1lcl		equ	$0B2
aud1len		equ	$0B4
aud1per		equ	$0B6
aud1vol		equ	$0B8
aud1dat		equ	$0BA

aud2lc		equ	$0C0
aud2lch		equ	$0C0
aud2lcl		equ	$0C2
aud2len		equ	$0C4
aud2per		equ	$0C6
aud2vol		equ	$0C8
aud2dat		equ	$0CA

aud3lc		equ	$0D0
aud3lch		equ	$0D0
aud3lcl		equ	$0D2
aud3len		equ	$0D4
aud3per		equ	$0D6
aud3vol		equ	$0D8
aud3dat		equ	$0DA

bplpt		equ	$0E0
bpl1pth		equ	$0E0
bpl1ptl		equ	$0E2
bpl2pth		equ	$0E4
bpl2ptl		equ	$0E6
bpl3pth		equ	$0E8
bpl3ptl		equ	$0EA
bpl4pth		equ	$0EC
bpl4ptl		equ	$0EE
bpl5pth		equ	$0F0
bpl5ptl		equ	$0F2
bpl6pth		equ	$0F4
bpl6ptl		equ	$0F6
bplcon0 	equ	$100
bplcon1 	equ	$102
bplcon2 	equ	$104
bpl1mod 	equ	$108
bpl2mod 	equ	$10A

sprpt		equ	$120
spr0pt		equ	$120
spr1pt		equ	$124
spr2pt		equ	$128
spr3pt		equ	$12C
spr4pt		equ	$130
spr5pt		equ	$134
spr6pt		equ	$138
spr7pt		equ	$13C

color		equ	$180
color0		equ	$180
color1		equ	$182
color2		equ	$184
color3		equ	$186
color4		equ	$188
color5		equ	$18A
color6		equ	$18C
color7		equ	$18E
color8		equ	$190
color9		equ	$192
color10		equ	$194
color11		equ	$196
color12		equ	$198
color13		equ	$19A
color14		equ	$19C
color15		equ	$19E
color16		equ	$1A0
color17		equ	$1A2
color18		equ	$1A4
color19		equ	$1A6
color20		equ	$1A8
color21		equ	$1AA
color22		equ	$1AC
color23		equ	$1AE
color24		equ	$1B0
color25		equ	$1B2
color26		equ	$1B4
color27		equ	$1B6
color28		equ	$1B8
color29		equ	$1BA
color30		equ	$1BC
color31		equ	$1BE



