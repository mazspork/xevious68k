; ******************************************************************************
; *
; *	MAZ.ASM - skeleton code. (GRAB the PAD)
; *
; *	Useful information:-
; *		FOO,BAR,QRT are all metasyntactic variables
; *		A6 will ALWAYS point to the base of the custom registers
; *		The processor is put in supervisor state by a TRAP #0.
; *		All 'error' exceptions are kept as Exec has set them.
; *
; *	Code copyright (C) 1987 Maz Spork.
; *
; ******************************************************************************

; Assembler stuff --------------------------------------------------------------

		idnt	"copperstuff"
		ttl	"Grab the PAD"
		plen	66

; Include files ----------------------------------------------------------------

		include	"macros.i"
		include "equates.i"

; Main code --------------------------------------------------------------------

main:		move.l	#custom,pad		; keep this always

;	----- Put processor in Supervisor mode
grab:		move.l	#start,trap0adr		; This is user vector #1
		trap	#0			; Resume execution at interrupt

;	----- Disable IRQ and DMA
start:		move.w	#clrall,custom+intena	; No interrupts.
		move.w	#clrall,custom+dmacon	; No DMA

;	----- Reset all interrupt vectors
		move.l	#vectortable,a0		; Ptr to addresses of IRQ
		move.l	#level1autovect,a1	; This is level 1 autovect addr
		moveq	#7,d0			; 7 vectors to move
1$:		move.l	(a0)+,(a1)+		; Do one vector
		subq	#1,d0
		bne.s	1$			; seven times...

;	----- Set up stuff for copper
		move.l	#orglist,a0
		move.l	#copperlist,a1
		move.w	#orglistend-orglist,d0
2$:		move.w	(a0)+,(a1)+
		subq.w	#1,d0
		bne.s	2$
		move.l	#copperlist,cop1lc(pad)	; address of copperlist
		move.l	#w1-orglist+copperlist,cop2lc(pad)
		move	copjmp1(pad),d0		; strobe - reset internal PC

;	----- Set up the colours (not really useful)
		move	#$000,color(pad)
		move	#$00F,color+2(pad)
		move	#$F00,color+4(pad)
		move	#$FF0,color+6(pad)
		move	#$0FF,color+8(pad)
		move	#$F0F,color+10(pad)
		move	#$0F0,color+12(pad)
		move	#$FFF,color+14(pad)
		move	#$777,color+16(pad)
		move	#$0F0,color+18(pad)

;	----- Initialize some hardware
		move	#$2C81,diwstrt(pad)
		move	#$F4C1,diwstop(pad)
		move	#$0030,ddfstrt(pad)	; (this disables sprite #7)
		move	#$00D0,ddfstop(pad)
		move	#7,bpl1mod(pad)
		move	#7,bpl2mod(pad)

;	----- Fill the screen with some graphics
		move.l	#plane1,a0		; plane 1's address
		move.l	#plane1+$A00,a1
		move.l	#big_a,a2		; address of the graphic A
		move.l	#50,d1			; 50 lines
fillscreen1:
		moveq	#8,d3			; 8 A's per line
fillscreen2:		
		move.l	a2,a3			; current start
		move.w	(a3)+,(a0)+		; move to 1st bpl
		move.w	(a3)+,(a0)+
		move.w	(a3)+,(a0)+
		subq	#1,d3
		bne	fillscreen2
		add.l	#6,a2
		moveq	#8,d3			; 8 A's per line
fillscreen3:		
		move.l	a2,a3			; current start
		move.w	(a3)+,(a1)+		; move to 1st bpl
		move.w	(a3)+,(a1)+
		move.w	(a3)+,(a1)+
		subq	#1,d3
		bne	fillscreen3
		add.l	#6,a2
		
		subq	#1,d1
		bne	fillscreen1

		move.l	#plane1+$1400,a0
		moveq	#0,d0
		move.l	#$1400/4,d1
clearsomemem:
		move.l	d0,(a0)+
		subq	#1,d1
		bne	clearsomemem
		
;	----- initialize screen addresses for all intersections
		moveq	#8,d0
		move.l	#dfaddr,a0
inittable1:	move.l	#plane1+8,(a0)+
		subq	#1,d0
		bne	inittable1

		move.b	#8,angle
		move.b	#1,speed
		move.b	#1,speed1
		
;	----- Enable IRQs for vertical blank and the coprocessor
		move	#setbit+inten+vertb+coper,intena(pad)

;	----- Enable DMA for bit planes and the coprocessor
		move	#setbit+bplen+dmaen+copen,dmacon(pad)

hang:		bra	hang			; main code ends here!

; Interrupt entry points -------------------------------------------------------
;
; These are the supported sources:-
;	Level 1: Software initiated, Disk Block Finished, UART buffer empty
;	Level 2: I/O ports and timers
;	Level 3: Copper, Blitter finished, Vertical blank (raster retrace)
;	Level 4: Audio channel 0,1,2,3 block finished (after a playback)
;	Level 5: UART buffer full, Disk Sync (DSKSYNC) matches disk data
;	Level 6: External Interrupt (how wise to put this at top priority)
;	Level 7: NMI, not used.
;
; The interrupt servers must exit through "finished" with their respective
; bit set in D0 to tell the hardware that they're finished. There is a macro,
; exit, which takes the mask as parameter, eg. exit coper.

level1: 	rte
level2: 	rte
level3: 	move	intreqr(pad),d0
		btst	#coperx,d0
		bne	copperint
		btst	#vertbx,d0
		bne	vertblankint
		bra	blitfinishint
level4: 	rte
level5: 	rte
level6: 	rte
level7: 	rte

; THE INTERRUPT SERVERS --------------------------------------------------------
;	Blitter finished (3)
;	Coprocessor initiated interrupt (3)
;	Vertical Blank (raster retrace) (3)

blitfinishint:	exit	(blit)

copperint:	exit	(coper)

; Come here when the vertical blanking starts ----------------------------------
;
; Address register allocation:-
;
;  A0 -> dfaddr
;  A1 -> delay
;  A2 -> coppersections
;  A3 -> copperwaits
;  A4 -> (coppersections)
;  A5 -> (copperwaits)
;  A6 -> the PAD base (custom)
;  A7 -> USP
;
; - access to "positions" is gained by disp(A1) where disp currently is 8.

vertblankint:	
		move.l	#dfaddr,a0		; all dfaddrs are stored here
		move.l	#delay,a1		; all delays are stored here
		move.l	#coppersections,a2	; addresses of sections of list
		move.l	#copperwaits,a3		; addresses of wait x,y instr's
		moveq	#1,d0			; this holds the pf priorities
		moveq	#0,d1			; copy of BPLCON1 (delays)		
		move.b	#$F0,d2			; delay intersection mask
copperloop:	
		move.l	(a2)+,a4		; get section address
		move.l	(a3)+,a5		; get wait instruction address
		
		move.w	positions-delay(a1),(a5); the vertical beam position

		tst.l	(a2)
		beq	nofurther		; don't put in more for last

		move.l	(a0)+,d4
		swap	d4
		move.w	d4,2(a4)
		swap	d4
		move.w	d4,6(a4)
		add.l	#$A00,d4
		move.w	d4,14(a4)
		swap	d4
		move.w	d4,10(a4)
		
		move.w	(a1)+,d3		; delay 0-15 for this playfield
		btst	#0,d0			; if this is set, is's 1st loop
		beq	morethanone
		moveq	#0,d0			; so just copy 0-3 to 4-7
		move	d3,d4			; in RAM copy of BPLCON1
		lsl.b	#4,d4
		or.b	d4,d3
		bra	playfield1				
morethanone:
		btst	#$06,d0			; test which playfield
		beq	playfield1		; zero is pf1 priority
		lsl.b	#4,d3			; if pf2, move to bits 4-7
playfield1:	
		and.b	d2,d1			; take off previous delay
		or.b	d3,d1			; insert new delay

		move.w	d1,18(a4)		; add to copper list
		move.w	d0,22(a4)		; the playfield priority
		
		not.b	d2			; change mask for pf delays
		eor.w	#$40,d0			; change PF2PRI bit
		bra	copperloop
nofurther:
		move.w	positions-delay+2(a1),w9-orglist+copperlist
		
		move.b	joy1dat(pad),d0
		move.b	speed,d1
		and.b	#$02,d0
		beq	noleft
		cmp.b	#127,d1
		beq	nopantoday
		add.b	#1,d1
		move.b	d1,speed
noleft:
		move.b	joy1dat+1(pad),d0
		and.b	#$02,d0
		beq	nopantoday
		cmp.b	#1,d1
		beq	nopantoday
		subq.b	#1,d1
		move.b	d1,speed
nopantoday:
		subq.b	#1,speed1
		bne	skipframe		; don't scroll now...
		move.b	speed,speed1
		
		move.l	#dfaddr,a0
		move.l	#delay,a1
		moveq	#1,d0			; change this to whatever...
vertbloop:	
		add.w	d0,(a1)			; next delay
		cmp.w	#$10,(a1)
		bcs	multiplum		; jump if within same word
		and.w	#$0F,(a1)		; else calculate next delay
		sub.l	#$02,(a0)		; and go to next word
		cmp.b	#$FE,3(a0)		; if the lowest byte is FE -
		bne	multiplum	
		add.l	#6,(a0)			; go back to the 1st A again
multiplum:	
		addq.l	#4,a0			; next dfaddr entry
		addq.l	#2,a1			; next delay entry
		inc	d0			; next delay offset to use
		tst.l	(a0)			; last?
		bne	vertbloop
skipframe:

;	----- Now find the new positions of the interrupts
		move.b	joy1dat(pad),d0		; get the joystick values.
		move.b	angle,d1
		and.b	#$03,d0
		cmp.b	#$01,d0
		beq	downpressed
		cmp.b	#$10,d0
		bne	notdown
downpressed:
		cmp.b	#8,d1
		beq	nochange
		subq.b	#1,d1
		bra	newpositions
notdown:
		move.b	joy1dat+1(pad),d0
		and.b	#$03,d0
		cmp.b	#$01,d0
		beq	uppressed
		cmp.b	#$10,d0
		bne	nochange
uppressed:
		cmp.b	#200,d1
		beq	nochange
		addq.b	#1,d1
newpositions:
		move.b	d1,angle
		move.b	d1,d0
		moveq	#1,d7
		lsr.b	d7,d0
		move.b	d0,d1
		lsr.b	d7,d0
		move.b	d0,d2
		lsr.b	d7,d0
		move.b	d0,d3
		move.b	#$2C,d7
		move.b	angle,d0
		
		move.l	#positions,a0
		move.b	d7,(a0)+
		addq.l	#1,a0		; first

;	----- Find positions for all changes in the vertical sequence
		move.b	d7,d4		; second
		add.b	d3,d4
		move.b	d4,(a0)+
		addq.l	#1,a0
		
		move.b	d7,d4		; third
		add.b	d2,d4
		move.b	d4,(a0)+
		addq.l	#1,a0
		
		move.b	d7,d4		; fourth
		add.b	d3,d4
		add.b	d2,d4
		move.b	d4,(a0)+
		addq.l	#1,a0
		
		move.b	d7,d4		; fifth
		add.b	d1,d4
		move.b	d4,(a0)+
		addq.l	#1,a0
		
		move.b	d7,d4		; sixth
		add.b	d1,d4
		add.b	d3,d4
		move.b	d4,(a0)+
		addq.l	#1,a0
		
		move.b	d7,d4		; seventh
		add.b	d1,d4
		add.b	d2,d4
		move.b	d4,(a0)+
		addq.l	#1,a0
		
		move.b	d7,d4		; eighth
		add.b	d1,d4
		add.b	d2,d4
		add.b	d3,d4
		move.b	d4,(a0)+
		add.l	#1,a0
		
		move.b	d7,d4		; ninth
		add.b	d0,d4
		move.b	d4,(a0)+
nochange:
		move	d0,copjmp2(pad)

		exit	(vertb)

; end-of-interrupt -------------------------------------------------------------

;	----- Come here after a successful interrupt to clear intreq
finished:	move	d0,intreq(pad)
		rte

; initialized data -------------------------------------------------------------


;	----- These are the addresses of all seven superstates.
vectortable:	dc.l	level1,level2,level3,level4,level5,level6,level7

; positions [] holds the actual first instruction word of the copper wait
; instruction. Alter byte one (MSB) for other positions.

delay:		dc.w	0,0,0,0,0,0,0,0,0
positions:	dc.w	$2C01,$2D01,$2E01,$2F01,$3001,$3101,$3201,$3301,$3401,0
dfaddr:		dc.l	0,0,0,0,0,0,0,0,0

coppersections:	dc.l	s1-orglist+copperlist,s2-orglist+copperlist
		dc.l	s3-orglist+copperlist,s4-orglist+copperlist
		dc.l	s5-orglist+copperlist,s6-orglist+copperlist
		dc.l	s7-orglist+copperlist,s8-orglist+copperlist
		dc.l	0

copperwaits:	dc.l	w1-orglist+copperlist,w2-orglist+copperlist
		dc.l	w3-orglist+copperlist,w4-orglist+copperlist
		dc.l	w5-orglist+copperlist,w6-orglist+copperlist
		dc.l	w7-orglist+copperlist,w8-orglist+copperlist
		dc.l	0

temp1w:		dc.w	0
temp2w:		dc.w	0
temp3w:		dc.w	0
temp1l:		dc.l	0
temp2l:		dc.l	0
temp3l:		dc.l	0
angle:		dc.w	0
speed:		dc.w	0
speed1:		dc.w	0

;	----- This is the Coprocessor List (for two bit-planes DPF)
orglist:

		copmove 0,bplcon0	; no screen yet.
		copwait	254,254		; wait to be interrupted

w1:		copwait	0,0
		copmove	$4400,bplcon0	; dual playfield, 4 bit-planes in all
		copmove	$800,color+2
		copmove	$B00,color+6
		copmove	$F00,color+4
		copmove $0000,bplpt+4
		copmove (plane1+$1400)&$FFFF,bplpt+6
		copmove $0000,bplpt+12
		copmove (plane1+$1400)&$FFFF,bplpt+14
s1:		copmove	0,bplpt+0
		copmove 0,bplpt+2	; set address of that
		copmove	0,bplpt+8
		copmove	0,bplpt+10
		copmove	0,bplcon1	; delay for both playfield
		copmove 0,bplcon2	; playfield priorities

w2:		copwait 0,0
		copmove	$080,color+18
		copmove	$0B0,color+22
		copmove	$0F0,color+20
s2:		copmove 0,bplpt+4	; set address of plane two
		copmove 0,bplpt+6	
		copmove	0,bplpt+12
		copmove	0,bplpt+14
		copmove	0,bplcon1	; set delay
		copmove 0,bplcon2	; set priority

w3:		copwait 0,0
		copmove	$008,color+2
		copmove	$00B,color+6
		copmove	$00F,color+4
s3:		copmove	0,bplpt+0	; new pointer for #1
		copmove	0,bplpt+2	
		copmove	0,bplpt+8
		copmove	0,bplpt+10
		copmove	0,bplcon1	; new delay and priority
		copmove 0,bplcon2

w4:		copwait 0,0
		copmove	$880,color+18
		copmove	$BB0,color+22
		copmove	$FF0,color+20
s4:		copmove 0,bplpt+4	; new pointer for #2
		copmove 0,bplpt+6
		copmove	0,bplpt+12
		copmove	0,bplpt+14
		copmove	0,bplcon1	; new delay and priority
		copmove 0,bplcon2

w5:		copwait 0,0
		copmove	$088,color+2
		copmove	$0BB,color+6
		copmove	$0FF,color+4
s5:		copmove	0,bplpt+0	; new pointer for #1
		copmove	0,bplpt+2
		copmove	0,bplpt+8
		copmove	0,bplpt+10
		copmove	0,bplcon1	; new delay and priority
		copmove 0,bplcon2

w6:		copwait 0,0
		copmove	$808,color+18
		copmove	$B0B,color+22
		copmove	$F0F,color+20
s6:		copmove 0,bplpt+4	; new pointer for #2
		copmove 0,bplpt+6
		copmove	0,bplpt+12
		copmove	0,bplpt+14
		copmove	0,bplcon1	; new delay and priority
		copmove 0,bplcon2

w7:		copwait 0,0
		copmove	$888,color+2
		copmove	$BBB,color+6
		copmove	$FFF,color+4
s7:		copmove	0,bplpt+0	; new pointer for #1
		copmove	0,bplpt+2	
		copmove	0,bplpt+8
		copmove	0,bplpt+10
		copmove	0,bplcon1	; new delay and priority
		copmove 0,bplcon2

w8:		copwait 0,0
		copmove $0000,bplpt+4
		copmove (plane1+$1400)&$FFFF,bplpt+6
		copmove $0000,bplpt+12
		copmove (plane1+$1400)&$FFFF,bplpt+14
s8:

w9:		copwait	0,0
		copmove	0,bplcon0
		copwait	254,254		; sleep until Vblank
orglistend:	nop
;
big_a:		
		dc.w	$0000,$0000,$0000,$0000
		dc.w	$0000,$0000,$0000,$0000
		dc.w	$0000,$0000,$0000,$0000
		dc.w	$0000,$0000,$0000,$0000
		dc.w	$0FF8,$0000,$0000,$0000
		dc.w	$0000,$0000,$7FFF,$0000
		dc.w	$0000,$0000,$0000,$0003
		dc.w	$FFFF,$E000,$0000,$0000
		dc.w	$0000,$0007,$F007,$F000
		dc.w	$0003,$0000,$0000,$001F
		dc.w	$8000,$FC00,$0003,$8003
		dc.w	$0000,$003F,$8003,$1E00
		dc.w	$0002,$C002,$8000,$007A
		dc.w	$C002,$8F00,$0002,$6006
		dc.w	$C000,$00E2,$6006,$C380
		dc.w	$0002,$2004,$7FFC,$01C2
		dc.w	$2004,$7FFC,$00FE,$0080
		dc.w	$000C,$03FE,$0080,$00EC
		dc.w	$0030,$0080,$0738,$03B0
		dc.w	$0080,$07F8,$020C,$01C0
		dc.w	$0FE0,$070C,$01C0,$0FF0
		dc.w	$0303,$0080,$3F00,$0F01
		dc.w	$0080,$3F38,$0007,$C001
		dc.w	$FC00,$0E03,$C001,$DC38
		dc.w	$0007,$3007,$3800,$0E03
		dc.w	$3007,$2838,$0617,$F007
		dc.w	$F880,$1E13,$E003,$E89C
		dc.w	$0437,$F007,$F0C0,$1C33
		dc.w	$E003,$E0DC,$0FE7,$E423
		dc.w	$E040,$1FE1,$C421,$C05C
		dc.w	$0201,$C661,$C044,$3A00
		dc.w	$0660,$004E,$0200,$0240
		dc.w	$0088,$3A00,$0240,$008E
		dc.w	$0200,$43C0,$00B8,$3A00
		dc.w	$43C0,$00BE,$0201,$8180
		dc.w	$0190,$3A01,$8180,$019E
		dc.w	$0607,$03C0,$0120,$3E07
		dc.w	$03C0,$012E,$0E0C,$0FF0
		dc.w	$0178,$3E0C,$0FF0,$017E
		dc.w	$3E10,$03E0,$0100,$3E10
		dc.w	$03E0,$010E,$0B20,$03E0
		dc.w	$02F0,$3B20,$03E0,$02FE
		dc.w	$11C0,$01C0,$021C,$39C0
		dc.w	$01C0,$021E,$0180,$01C0
		dc.w	$0580,$1D80,$01C0,$059C
		dc.w	$02C0,$0080,$0CF0,$1EC0
		dc.w	$0080,$0CFC,$0DC0,$0EB8
		dc.w	$1C60,$1DC0,$0EB8,$1C7C
		dc.w	$0370,$700E,$3440,$0F70
		dc.w	$700E,$3478,$029E,$C003
		dc.w	$E440,$0E9E,$C003,$E478
		dc.w	$00B7,$FC01,$83C0,$0EB7
		dc.w	$FC01,$83F8,$0148,$80C7
		dc.w	$4200,$0748,$80C7,$4270
		dc.w	$0191,$BF8C,$6200,$0391
		dc.w	$BF8C,$62E0,$0039,$1F53
		dc.w	$B200,$03B9,$1F53,$B2E0
		dc.w	$0032,$0C57,$9A00,$01F2
		dc.w	$0C57,$9BC0,$0016,$0635
		dc.w	$8800,$00F6,$0635,$8B80
		dc.w	$0007,$0435,$0000,$007F
		dc.w	$0435,$0F00,$0007,$0C32
		dc.w	$0000,$003F,$0C32,$1E00
		dc.w	$0007,$0C32,$0000,$001F
		dc.w	$8C32,$FC00,$0000,$0020
		dc.w	$0000,$0007,$F027,$F000
		dc.w	$0000,$0000,$0000,$0003
		dc.w	$FFFF,$E000,$0000,$0000
		dc.w	$0000,$0000,$7FFF,$0000
		dc.w	$0000,$0000,$0000,$0000
		dc.w	$0FF8,$0000,$0000,$0000
		dc.w	$0000,$0000,$0000,$0000
		dc.w	$0000,$0000,$0000,$0000
		dc.w	$0000,$0000,$0000,$0000
		dc.w	$0000,$0000,$0000,$0000
;
		end

