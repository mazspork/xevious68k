;	Run-time sound and music sequencer
;	(C) 1989 Mazoft Software (DK) - written by Maz Spork - all rights reserved
;
;	Uses Paula's A/D-converters to produce waveform patterns. Interrupts
;	processed are audio IRQs on 4 channels (level 4) and the raster
;	retrace (lavel 3) IRQ.
;
;
;	Accepts data tables from the editing sequencer "The WaveShaper"
;	or can be programmed directly.
;
;	This software contains raw code.
;
;
		INCLUDE	MACLIB.I
		INCLUDE	EQUATES.I

		SECTION	_main,CODE_C		; code must go in chip memory

		OPT	D+,O+,OW-		; Debug, Optimisation (no opti-warnings)

supervisor	move.l	#sequencer,swi0
		trap	#0

sequencer	lea	custom,pad		; Keep this always in a6
		lea	ramtop,SP		; Keep this in a7 at all times

		move	#clrall,intena(pad)	; Kill IRQs
		move	#clrall,dmacon(pad)	; Kill DMAs

;		jsr	debuginit

		lea	IRQvectortable,a0	; Set up IRQ vectors
		lea	level1autovect,a1
		moveq	#7-1,d0
initialise	move.l	(a0)+,(a1)+
		dbra	d0,initialise

		move.l	#copperlist,cop1lc(pad)
		move	d0,copjmp1(pad)
		move	#%11111111,adkcon(pad)	; no modulation

		move	#setbit+inten+vertb+audio3+audio2+audio1+audio0,intena(pad)
		move	#setbit+dmaen+copen+bplen,dmacon(pad)

		moveq	#1,d0
		bsr	tune_start

kill		lea	voiceinfoblock,a0
		move.l	curpitch(a0),d0
		move	pitchbenddelta(a0),d1
		move	pitchbenddelay(a0),d2
		move.b	voxstatus(a0),d3
		move	durationcounter(a0),d4
		move	curvolume(a0),d5
		move	envdelta(a0),d6
		move	envdelay(a0),d7

		jsr	debug

		bra	kill

cols		dc.w	black,blue,red,magenta,green,yellow,white


		include	debug.i


; Run a tune	d0=tune no.
tune_start	lea	tune_table-4,a0
		lsl	#2,d0			; *4 for a longword/entry
		move.l	(a0,d0),a0		; a0 now points to tune's header

		lea	voiceinfoblock,a1
		moveq	#4-1,d0
tune_start1	move.l	(a0)+,(a1)		; Initialise addresses of note data
		add	#voiceinfolength,a1	; for all channels 3-2-1-0
		dbra	d0,tune_start1
		moveq	#4-1,d3
		move	#$8008,d4
tune_start2	move	d3,d0
		bsr	start_channel		; 3-2-1-0
		beq.s	no_sound_here
		move	d4,dmacon(pad)		; start DMA for this channel
no_sound_here	lsr.b	#1,d4
		dbra	d3,tune_start2
		rts


; Find a free channel (with DMA disabled, voxstatus = playing_off)
; returns EQ and d0=channel (0-3) if free
;         NE (d0=FF) if no free channels

find_channel	lea	voiceinfoblock+voxstatus-voiceinfolength,a0
		moveq	#4-1,d0
find_channels	add	#voiceinfolength,a0
		tst	(a0)			; test for playing_off (== 0)
		dbne	d0,find_channels
		rts


; Renewing the channels by calling update_chx will inevitably force that
; channel to play the next note in the respective track.
; D0.W = channel to update (0-3)
; returns NE if ok, eq if no more notes
; uses & destroys d0-d2/a0-a2

start_channel	move	d0,d2
		lsl	#4,d0
		lea	voiceinfoblock,a1
		add	d0,a1
		add	d0,a1			; a1 points to entry+1 (for downwards clear)
		add	#audio,d0		; now -> chip address audio

		move.l	noteaddr(a1),a0		; address of note
		moveq	#0,d1
		move.b	soundid(a0),d1		; (soundid) which waveform?
		bmi	lastnote		; but there are no more notes
		lsl	#4,d1			; 16 bytes each
		lea	voicetable-voxtablelength,a2
		add	d1,a2			; a2 now -> waveformtable

		move	period(a0),audper(pad,d0)	; AUDxPER
		move	period(a0),curpitch(a1)

		moveq	#0,d1
		move.b	volume(a0),d1
		move	d1,audvol(pad,d0)	; AUDxVOL
		move.b	d1,curvolume(a1)

		move	duration(a0),durationcounter(a1)	

		move.l	voxA(a2),audptr(pad,d0)	; VOXA is zero
		moveq	#playing_AtoC,d2
		move	voxX(a2),d1		; length from A to C
		bne.s	ch1_looped		; jump if loop-type waveform
		move	voxL(a2),d1		; use length of whole sample
		moveq	#playing_BtoD,d2	; pretend playing B->D

ch1_looped	move	d1,audlen(pad,d0)	; store length in AUDxLEN
		move.b	d2,voxstatus(a1)	; playing a->c

		moveq	#0,d0
		move	d0,envdelay(a1)		; assume no envelope
		move.b	envelope(a0),d0		; any envelope?
		beq.s	ch1_no_envelope

		lsl	#2,d0			; 4 bytes per address entry
		lea	envelopetable-4,a2
		move.l	(a2,d0),a2		; a2 is now address of envelope
		move.l	a2,envaddr(a1)		; set up envelope address
		move	(a2),envdelay(a1)	; set up envelope delay
		move	envoffset(a2),envdelta(a1) ; set up envelope delta

ch1_no_envelope	moveq	#0,d0
		move	d0,pitchbenddelay(a1)	; assume no pitchbending
		move.b	pitchbender(a0),d0	; any pitch bending?
		beq.s	ch1_no_pbend

		lsl	#2,d0			; 4 bytes per address entry
		lea	envelopetable-4,a2
		move.l	(a2,d0),a2		; a2 is now address of envelope
		move.l	a2,pitchbendaddr(a1)	; set up pitchbend address
		move	(a2),pitchbenddelay(a1)	; set up pitchbend delay
		move	envoffset(a2),pitchbenddelta(a1)

ch1_no_pbend	and	#%11011,CCR		; set zero flag = success
		rts

lastnote	moveq	#0,d0
		bset	d2,d0			; set for DMA register
		move	d0,dmacon(pad)		; now shut it up
		lsl	#7,d0			; rotate for IRQ reg.
		move	d0,intena(pad)
		move.b	#playing_off,voxstatus(a1)	; silencio! (and NZ = no DMA)
		rts


; LEVEL 4 INTERRUPT REQUEST SERVER ENTRY POINT
; --------------------------------------------
;
; Audio channel 3/2/1/0 block finished (initiated)
;

level4		movem.l	d0-d2/a0-a2,-(sp)

		move	intreqr(pad),d1		; what bits
		and	#$0780,d1		; only audio bits
		move	d1,intreq(pad)		; clear it (bit 15 clear)
		move	d1,d2			; keep copy here

		moveq	#6,d0			; test bit
find4src	addq	#1,d0
		btst	d0,d1
		beq.s	find4src
		subq	#7,d0			; D0 now holds channel 0-3

		lsl	#4,d0			; *8
		lea	voiceinfoblock,a0
		add	d0,a0
		add	d0,a0			; * 32 (current size of voxinfoblock)
		add	#audio,d0
		move.l	noteaddr(a0),a1		; noteaddr

		moveq	#0,d1
		move.b	soundid(a1),d1		; waveform no.
		lsl	#4,d1			; 16 bytes/waveform entry
		lea	voicetable-voxtablelength,a2
		add	d1,a2			; A0->voxinfo,A1->note,A2->waveform

		cmp.b	#playing_AtoC,voxstatus(a0)	; one-shot part done?
		beq.s	audioloop			; time for looping sequence
		cmp.b	#playing_BtoC,voxstatus(a0)	; was it playing b to c?
		beq.s	audioend
		cmp.b	#playing_BtoD,voxstatus(a0)	; was it playing b to d?
		beq.s	audiosilence

		movem.l	(sp)+,d0-d2/a0-a2
		rte

audiosilence	move.l	#silence,audptr(pad,d0)		; zeros
		move	#96,audlen(pad,d0)		; length
		move.b	#playing_zero,voxstatus(a0)
		move	d2,intena(pad)			; stop IRQ for that channel

		movem.l	(sp)+,d0-d2/a0-a2
		rte

audioend	move.l	voxB(a2),audptr(pad,d0)		; from B
		move	voxZ(a2),audlen(pad,d0) 	; to D
		move.b	#playing_BtoD,voxstatus(a0)

		movem.l	(sp)+,d0-d2/a0-a2
		rte

audioloop	move.l	voxB(a2),audptr(pad,d0)		; from B
		move	voxY(a2),audlen(pad,d0)		; to C		
		move.b	#looping_BtoC,voxstatus(a0)	; looping
		move	d2,intena(pad)			; disable IRQ for this channel

		movem.l	(sp)+,d0-d2/a0-a2
		rte


; LEVEL 3 INTERRUPT REQUEST SERVER ENTRY POINT
; --------------------------------------------
;
; Start of vertical blank (raster beam retrace)
; Blitter finished
; Copper requesting 68000

level3		movem.l	d0-d7/a0-a5,-(sp)

		move	intreqr(pad),d1
		and	#$0070,d1
		move	d1,intreq(pad)

		btst	#coperx,d1			; Copper interrupt
		bne.s	copperirq
		btst	#vertbx,d1
		bne.s	vblankirq			; Vertical Blank IRQ

;	----- Blitter finished interrupt
blitterirq	nop
blitterirqend	movem.l	(sp)+,d0-d7/a0-a5
		rte

;	----- Copper interrupt request
copperirq	nop
copperirqend	movem.l	(sp)+,d0-d7/a0-a5
		rte

;	----- Vertical beam resync interrupt
vblankirq

;		move.l	#screen,bplpt(pad)

update_audio	moveq	#4-1,d3			; run through 4 channels
		lea	3*voiceinfolength+voiceinfoblock,a3	

audiorefresh	tst	durationcounter(a3)	; 50Hz ticker
		beq.s	audio_effects		; jump if already zero (and don't store)
		subq	#1,durationcounter(a3)	; decrement
		bne.s	audio_effects		; store and jump if not yet zero

		move	#$100,d0		; Enable IRQ for this channel
		bset	d3,d0
		rol	#7,d0
		move	d0,intena(pad)

		cmp.b	#looping_BtoC,voxstatus(a3)	; was it looping?
		bne.s	audio_new			; no, it was silent

		move.b	#playing_BtoC,voxstatus(a3)	; play it ONCE more
		move.l	noteaddr(a3),a0			; note address
		move	pause(a0),durationcounter(a3)	; pause delay already here!
		bne.s	audio_effects			; jump if pause <> 0

audio_new	add.l	#notelength,noteaddr(a3)	; assume new note now (from silence)
		move	d3,d0				; d0 becomes channel
		bsr	start_channel			; start that new one

audio_effects	move	d3,d4				; Find paula's I/O block in the PAD
		lsl	#4,d4				; for this audio channel
		add	#audio,d4

		tst	envdelay(a3)			; Is there an envelope running?
		beq.s	audio_effects2			; jump if none

		move	envdelta(a3),d0			; two's complement integer+fraction
		add	d0,curvolume(a3)		; add fraction to current volume

		moveq	#0,d0
		move.b	curvolume(a3),d0		; integer part of volume ...
		move	d0,audvol(pad,d4)		; new volume into Paula

		subq	#1,envdelay(a3)			; delay envelope
		bne.s	audio_effects2			; jump if still running

		move.l	envaddr(a3),a4			; address of envelope
		addq.l	#envelopelength,a4		; next one
		move	(a4),envdelay(a3)		; delay - take action if "env off"
		bne.s	good_envelope1

		move	envoffset(a4),d0		; is it the last one?
		beq.s	audio_effects2			; jump if so leaving envdelay = 0 too

		lsl	#2,d0				; offset 4 bytes per address
		lea	envelopetable-4,a4
		move.l	(a4,d0),a4			; index to get new address
		move	(a4),envdelay(a3)		; delay - should be nonzero

good_envelope1	move	envoffset(a4),envdelta(a3)	; fractional and integer offsets
		move.l	a4,envaddr(a3)			; new address of envelope

audio_effects2	tst	pitchbenddelay(a3)		; Is there a pitchbender running?
		beq.s	next_channel

		move.l	curpitch(a3),d2			; HLFX
		move	pitchbenddelta(a3),d0		; offset
		ext.l	d0
		ror.l	#8,d2				; XHLF
		add.l	d0,d2				; add fraction to number
		rol.l	#8,d2				; HLFX
		move.l	d2,curpitch(a3)			; store in table again
		swap	d2				; FXHL

		move	d2,audper(pad,d4)		; Store in Paula's period register		

		subq	#1,pitchbenddelay(a3)		; decrease delay
		bne.s	next_channel			; still going...

		move.l	pitchbendaddr(a3),a4
		addq.l	#envelopelength,a4		; next envelope entry
		move	(a4),pitchbenddelay(a3)		; new delay
		bne.s	good_envelope2			; nonzero, ok, use it

		move	envoffset(a4),d0		; this is the new envelope struct #
		beq.s	next_channel			; if zero, no more pitch bending

		lsl	#2,d0				; 4 bytes per address entry
		lea	envelopetable-4,a4		; addresses of envelope structs
		move.l	(a4,d0),a4			; address of new envelope struct in a4
		move	(a4),pitchbenddelay(a3)		; new delay

good_envelope2	move	envoffset(a4),pitchbenddelta(a3)
		move.l	a4,pitchbendaddr(a3)		; store new address

next_channel	sub	#voiceinfolength,a3		; next data block
		dbra	d3,audiorefresh


vblankirqend	movem.l	(sp)+,d0-d7/a0-a5
		rte


level1		movem.l	d0,-(sp)
		move	intreqr(pad),d0
		and	#$0003,d0
		move	d0,intreq(pad)

		movem.l	(sp)+,d0
		rte

level2		movem.l	d0,-(sp)
		move	intreqr(pad),d0
		and	#$0004,d0
		move	d0,intreq(pad)

		movem.l	(sp)+,d0
		rte

level5		movem.l	d0,-(sp)
		move	intreqr(pad),d0
		and	#$1800,d0
		move	d0,intreq(pad)

		movem.l	(sp)+,d0
		rte

level6		movem.l	d0,-(sp)
		move	intreqr(pad),d0
		and	#$2000,d0
		move	d0,intreq(pad)

		movem.l	(sp)+,d0
		rte

level7		rte			; NMI is not used, but returned though

		even

;	----- Addresses of all interrupt request entry points
IRQvectortable	dc.l	level1,level2,level3,level4,level5,level6,level7

;	----- Copper instructions
copperlist	cmove.l	screen,bplpt		; point plane 0 to screen
		cmove	black,color
		cwait	100,0
		cmove	blue,color
		cwait	110,0
		cmove	black,color
		cwait	forever			; Wait until beam resync

;	----- Status vox information (uninitialised)
voiceinfoblock	ds.b	4*voiceinfolength ; status of all channels

;	----- Addresses of all tunes
tune_table	dc.l	tuneAdata	

;	----- Addresses of four channels for tune A
tuneAdata	dc.l	Achannel0,Achannel1,Achannel2,Achannel3

; 	----- Note channel info - ID, VOL, TOTAL, DUR, PER, ENV, PBEND
Achannel0	note	1,64,500,350,200,0,0
		note	3,64,500,350,210,0,0
		note	3,64,500,350,220,0,0
		note	3,64,500,350,230,0,0
		note	off
Achannel1	note	off
Achannel2	note	off
Achannel3	note	off

;	----- Addresses of envelope structures
envelopetable	dc.l	envelope1
		dc.l	envelope2
		dc.l	envelope3
		dc.l	envelope4

envelope1	envelop	250,16
		envelop	goto,1

envelope2	envelop	90,-284
		envelop	goto,2

envelope3	envelop	15,409
		envelop	off

envelope4	envelop	1,0
		envelop	off

;	----- Addresses & loop info of wavetables - ADDR, B, C, D
voicetable	wavefrm	sinuswaveform,0,64,64
		wavefrm	squarewaveform,0,32,32
		wavefrm	swanee,$1480,$4466,$4466

; 	----- 96 words/192 bytes of zeros for silence
silence		dc.l	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		dc.l	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

;	----- Example wavertables: a 64-byte sinewave and a 32-byte square
sinuswaveform	dc.b	12,14,37,48,60,71,81,90,98,106,112,118,122,125
		dc.b	127,127,127,125,122,118,112,106,98,90,81,71,60,48
		dc.b	37,24,12,-1,-13,-25,-38,-49,-61,-72,-82,-91,-99,-107
		dc.b	-113,-119,-123,-126,-128,-128,-128,-126,-123,-119
		dc.b	-113,-107,-99,-91,-82,-72,-61,-49,-38,-25,-13,-1

squarewaveform	dc.b	-128,-128,-128,-128,-128,-128,-128,-128
		dc.b	-128,-128,-128,-128,-128,-128,-128,-128
		dc.b	 127,127,127,127,127,127,127,127
		dc.b	 127,127,127,127,127,127,127,127

swanee		incbin	swanee.raw


 
