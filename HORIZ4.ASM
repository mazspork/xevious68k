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

		include	"custom.i"              ; all custom chips addresses
		include	"bits.i"                ; bits within custom regs
		include	"macro.i"               ; macro defs
		include "equates.i"

; Main code --------------------------------------------------------------------

main:		section	"main code",CODE

		lea	custom,pad		; keep this always

;	----- Put processor in Supervisor mode
grab:		move.l	#start,trap0adr		; This is user vector #1
		trap	#0			; Resume execution at interrupt

;	----- Disable IRQ and DMA
start:		move.w	#clrall,custom+intena	; No interrupts.
		move.w	#clrall,custom+dmacon	; No DMA

;	----- Reset all interrupt vectors
		move.l	#vectortable,a0		; Ptr to addresses of IRQ
		move.l	#$64,a1			; This is level 1 autovect addr
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
		move	#2,bpl1mod(pad)
		move	#2,bpl2mod(pad)

;	----- Fill the screen with some garbage
		move	#$898,d0
		move.l	#plane1,a1
fillscreen1:	move.l	#$FFFF0000,(a1)+
		subq	#1,d0
		bne	fillscreen1

		move	#8,d0
		move.l	#dfaddr,a0
inittable1:	move.l	#plane1+$810,(a0)+
		subq	#1,d0
		bne	inittable1

;	----- Enable IRQs for vertical blank and the coprocessor
		move	#setbit+inten+vertb+coper,intena(pad)

;	----- Fake a vertical blank interrupt to set up some data
		move	#setbit+vertb,intreq(pad)

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

; Address register allocation in coprocessor interrupt -------------------------
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

copperint:
		move.l	#dfaddr,a0		; all dfaddrs are stored here
		move.l	#delay,a1		; all delays are stored here
		move.l	#coppersections,a2	; addresses of sections of list
		move.l	#copperwaits,a3		; addresses of wait x,y instr's
		moveq	#0,d0			; this holds the pf priorities
		moveq	#0,d1			; copy of BPLCON1 (delays)		
		move.b	#$F0,d2			; delay intersection mask
copperloop:	
		move.l	(a2)+,a4		; get section address
		move.l	(a3)+,a5		; get wait instruction address
		
		move.w	positions-delay(a1),(a5); the vertical beam position
		move.w	(a0)+,$02(a4)		; bplpt MSW
		move.w	(a0)+,$06(a4)		; bplpt LSW
		
		move.w	(a1)+,d3		; delay 0-15 for this playfield
		btst	#6,d0			; test which playfield
		beq	playfield1		; zero is pf1 priority
		lsl.b	#4,d3			; if pf2, move to bits 4-7
playfield1:	
		and.b	d2,d1			; take off previous delay
		or.b	d3,d1			; insert new delay

		move.w	d1,$0A(a4)		; add to copper list
		
*		move	d3,color(pad)
		move.w	d0,$0E(a4)		; the playfield priority
		
		eor.b	#$FF,d2			; change mask for pf delays
		eor.w	#$40,d0			; change PF2PRI bit

		tst.l	(a2)			; go4another if it's there.
		bne	copperloop

		exit	(coper)

; Come here when the vertical blanking starts ----------------------------------

vertblankint:	
		move.l	#dfaddr,a0
		move.l	#delay,a1
		moveq	#1,d0			; change this to whatever...
vertbloop:	
		add.w	d0,(a1)			; next delay
		cmp.w	#$10,(a1)
		bcs	multiplum		; jump if within same word
		and.w	#$0F,(a1)		; else calculate next delay
		subq.l	#$02,(a0)		; and go to next word
multiplum:	addq.l	#4,a0			; next dfaddr entry
		addq.l	#2,a1			; next delay entry
		inc	d0			; next delay offset to use
		tst.l	(a0)			; last?
		bne	vertbloop
		
		exit	(vertb)

; end-of-interrupt -------------------------------------------------------------

;	----- Come here after a successful interrupt to clear intreq
finished:	move	d0,intreq(pad)
		rte

; initialized data -------------------------------------------------------------

		section "tables",data

;	----- These are the addresses of all seven superstates.
vectortable:	dc.l	level1,level2,level3,level4,level5,level6,level7

; positions [] holds the actual first instruction word of the copper wait
; instruction. Alter byte one (MSB) for other positions.

delay:		dc.w	0,0,0,0,0,0,0,0,0,0
positions:	dc.w	$2C01,$4501,$5E01,$7701,$9001,$A901,$C201,$DB01
dfaddr:		dc.l	0,0,0,0,0,0,0,0,0,0

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

;	----- This is the Coprocessor List (for two bit-planes DPF)
orglist:
w1:		copwait	0,0
		copmove	$1000,bplcon0	; only one playfield for now
		copmove	aqua,color+2
s1:		copmove	0,bplpt
		copmove 0,bplpt+2	; set address of that
		copmove	0,bplcon1	; delay for both playfield
		copmove 0,bplcon2	; playfield priorities

w2:		copwait 0,0
		copmove	brick_red,color+18
		copmove	$2400,bplcon0	; two bpl's, two playfields.
s2:		copmove 0,bplpt+4	; set address of plane two
		copmove 0,bplpt+6	
		copmove	0,bplcon1	; set delay
		copmove 0,bplcon2	; set priority

w3:		copwait 0,0
		copmove	orange,color+2
s3:		copmove	0,bplpt 	; new pointer for #1
		copmove	0,bplpt+2	
		copmove	0,bplcon1	; new delay and priority
		copmove 0,bplcon2

w4:		copwait 0,0
		copmove	violet,color+18
s4:		copmove 0,bplpt+4	; new pointer for #2
		copmove 0,bplpt+6
		copmove	0,bplcon1	; new delay and priority
		copmove 0,bplcon2

w5:		copwait 0,0
		copmove	bright_blue,color+2
s5:		copmove	0,bplpt		; new pointer for #1
		copmove	0,bplpt+2
		copmove	0,bplcon1	; new delay and priority
		copmove 0,bplcon2

w6:		copwait 0,0
		copmove	light_green,color+18
s6:		copmove 0,bplpt+4	; new pointer for #2
		copmove 0,bplpt+6
		copmove	0,bplcon1	; new delay and priority
		copmove 0,bplcon2

w7:		copwait 0,0
		copmove	lime_green,color+2
s7:		copmove	0,bplpt		; new pointer for #1
		copmove	0,bplpt+2	
		copmove	0,bplcon1	; new delay and priority
		copmove 0,bplcon2

w8:		copwait 0,0
		copmove	lemon_yellow,color+18
s8:		copmove 0,bplpt+4	; new pointer for #2
		copmove 0,bplpt+6
		copmove	0,bplcon1	; new delay and priority
		copmove 0,bplcon2

		copmove setbit+coper,intreq	; make up new list
		copwait	254,254			; sleep until Vblank
orglistend:	nop
;
		end
