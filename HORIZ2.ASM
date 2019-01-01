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
; ******************************************************************************
;
		ttl	Grab the PAD
		plen	66
;
; Include files: ---------------------------------------------------------------
;
		include	"custom.i"              ; all custom chips addresses
		include	"bits.i"                ; bits within custom regs
		include	"macro.i"               ; macro defs
;
; Equates: ---------------------------------------------------------------------
;
trap0adr	equ	$80			; The sixteen TRAP vectors
trap1adr	equ	$81			; (software exceptions)
trap2adr	equ	$82
trap3adr	equ	$83
trap4adr	equ	$84
trap5adr	equ	$85
trap6adr	equ	$86
trap7adr	equ	$87
trap8adr	equ	$88
trap9adr	equ	$89
trapAadr	equ	$8A
trapBadr	equ	$8B
trapCadr	equ	$8C
trapDadr	equ	$8D
trapEadr	equ	$8E
trapFadr	equ	$8F
custom		equ	$DFF000 		; base of custom registers
copperlist	equ	$000400 		; lowest useable ram address
plane1		equ	$1000			; addr of bitplane #1

pad		equr	a6
;
; Main code: -------------------------------------------------------------------
;
		section	"init",code
;
main:		move.l	#custom,pad		; keep this always

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
		move	#$FFF,color+2(pad)
		move	#$F00,color+4(pad)
		move	#$FF0,color+6(pad)
		move	#$0FF,color+8(pad)
		move	#$F0F,color+10(pad)
		move	#$0F0,color+12(pad)
		move	#$FFF,color+14(pad)
		move	#$777,color+16(pad)
		move	#$F00,color+18(pad)

;	----- Initialize some hardware
		move	#$1000,bplcon0(pad)	; main attributes for playfield
		move	#$2C81,diwstrt(pad)
		move	#$F4C1,diwstop(pad)
		move	#$0030,ddfstrt(pad)	; (disables sprite #7)
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

; --- Enable IRQs for vertical blank and the coprocessor
		move	#setbit+inten+vertb+coper,intena(pad)

; --- Enable DMA for bit planes and the coprocessor
		move	#setbit+bplen+dmaen+copen,dmacon(pad)
;
hang:		bra	hang			; main code ends here!
;
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
;
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
;
; THE INTERRUPT SERVERS:-
;	Blitter finished (3)
;	Coprocessor initiated interrupt (3)
;	Vertical Blank (raster retrace) (3)
;
blitfinishint:	exit	(blit)
copperint:
		move.l	#dfaddr,a0
		move.l	#delay,a1
		move.l	#copperlist+2,a2
		moveq	#$11,d0
		moveq	#8,d1

copint1:	add	d0,(a1)
		cmp	#$100,(a1)
		beq	multiplum
		bcs	copint2
		sub	#$10,(a1)
multiplum:	and	#$FF,(a1)
		subq.l	#2,(a0)
		or.l	#$10,(a0)
copint2:	move.w	(a0)+,(a2)
		addq.l	#4,a2
		move.w	(a0)+,(a2)
		addq.l	#4,a2
		move.w	(a1)+,(a2)
		addq.l	#8,a2
		add.b	#$11,d0
		subq	#1,d1
		bne	copint1

		exit	(coper)

vertblankint:	exit	(vertb)
;
;	----- Come here after a successful interrupt to clear intreq
finished:	move	d0,intreq(pad)
		rte

		section	"copperstuff",data

;	----- These are the addresses of all seven superstates.
vectortable:	dc.l	level1,level2,level3,level4,level5,level6,level7

;	----- This is the Coprocessor List
orglist:
l0:		copmove	0,bplpt
l1:		copmove	0,bplpt+2
l2:		copmove	0,bplcon1
l3:		copwait	$45,0
l4:		copmove 0,bplpt
l5:		copmove	0,bplpt+2
l6:		copmove 0,bplcon1
l7:		copwait	$5E,0
l8:		copmove 0,bplpt
l9:		copmove	0,bplpt+2
l10:		copmove 0,bplcon1
l11:		copwait	$77,0
l12:		copmove 0,bplpt
l13:		copmove	0,bplpt+2
l14:		copmove 0,bplcon1
l15:		copwait	$90,0
l16:		copmove	0,bplpt
l17:		copmove	0,bplpt+2
l18:		copmove	0,bplcon1
l19:		copwait	$A9,0
l20:		copmove 0,bplpt
l21:		copmove	0,bplpt+2
l22:		copmove 0,bplcon1
l23:		copwait	$C2,0
l24:		copmove 0,bplpt
l25:		copmove	0,bplpt+2
l26:		copmove 0,bplcon1
l27:		copwait	$DB,0
l28:		copmove 0,bplpt
l29:		copmove	0,bplpt+2
l30:		copmove 0,bplcon1
l31:		copmove setbit+coper,intreq	; make up new list
l32:		copwait	254,254			; sleep until Vblank
orglistend:	nop
;
delay:		dc.w	$FF,$DD,$BB,$99,$77,$55,$33,$11
dfaddr:		dc.l	0,0,0,0,0,0,0,0,0,0
;
		end

