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
		include	"equates.i"
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
		move	#$0038,ddfstrt(pad)
		move	#$00D0,ddfstop(pad)
		move	#0,bpl1mod(pad)
		move	#0,bpl2mod(pad)

;	----- Fill the screen with some garbage
		move	#$898,d0
		move	#$ABCD,d1
		move.l	#plane1,a1
fillscreen1:	add.l	d0,d1
		move.l	d1,(a1)+
		subq	#1,d0
		bne	fillscreen1
		
		move	#8,d0
		move.l	#dfaddr,a0
inittable1:	move.l	#plane1+$800,(a0)+
		subq	#1,d0
		bne	inittable1
		
		move.l	#sprite,d0
		move.w	d0,cop2+2
		swap	d0
		move.w	d0,cop1+2
		
		
; --- Enable IRQs for vertical blank and the coprocessor
		move	#setbit+blit+inten+vertb+coper,intena(pad)

; --- Enable DMA for bit planes and the coprocessor and the blitter
		move	#setbit+spren+blten+bplen+dmaen+copen,dmacon(pad)
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
blitfinishint:	
		move	#black,color(pad)

fromhere:	exit	(blit)

doblitter:
		move.l	blitA,d1
		move.l	d1,bltapt(pad)
		add.l	#40,d1
		move.l	d1,blitA
		move.l	blitB,d1
		move.l	d1,bltbpt(pad)
		sub.l	#40,d1
		move.l	d1,blitB
		move.l	#plane1+1284,bltdpt(pad)
		move	#8,bltamod(pad)
		move	#8,bltbmod(pad)
		move	#8,bltdmod(pad)
		move	#$FFFF,bltafwm(pad)
		move	#$FFFF,bltalwm(pad)	; no mask on edges
		move	#%0000110111111100,bltcon0(pad)
		move	#%0000000000000000,bltcon1(pad)
		move	#16+136<<6,bltsize(pad)
		rts
		
blitA:		dc.l	plane1-40*400
blitB:		dc.l	plane1+80000

copperint:
		exit	(coper)

vertblankint:	
		move	#red,color(pad)
		jsr	doblitter
		add.w	#$0101,sprite
		exit	(vertb)
;
;	----- Come here after a successful interrupt to clear intreq
finished:	move	d0,intreq(pad)
		rte

		section	"copperstuff",data

;	----- These are the addresses of all seven superstates.
vectortable:	dc.l	level1,level2,level3,level4,level5,level6,level7

;	----- This is the Coprocessor List
copperlist:	copmove	plane1/$10000,bplpt
		copmove	plane1&$0FFFF,bplpt+2
		
cop1:		copmove	0,sprpt
cop2:		copmove	0,sprpt+2

		copwait	254,254			; sleep until Vblank
coplistend:	nop
;
delay:		dc.w	0,0,0,0,0,0,0,0,0,0
dfaddr:		dc.l	0,0,0,0,0,0,0,0,0,0
;
sprite:		dc.w	$6464
		dc.w	$CD00
		dc.w	$0000,$0000,$7FE0,$7FE0
		dc.w	$7038,$7038,$701C,$701C
		dc.w	$701C,$701C,$701C,$701C
		dc.w	$7038,$7038,$7FF0,$7FF0
		dc.w	$7038,$7038,$701C,$701C
		dc.w	$701C,$701C,$701C,$701C
		dc.w	$701C,$701C,$7038,$7038
		dc.w	$7FE0,$7FE0,$0000,$0000
		dc.w	$0000,$7000,$0000,$7000
		dc.w	$0000,$7000,$0000,$7000
		dc.w	$0000,$7000,$0000,$7000
		dc.w	$0000,$7000,$0000,$7000
		dc.w	$0000,$7000,$0000,$7000
		dc.w	$0000,$7000,$0000,$7000
		dc.w	$0000,$7000,$0000,$7FF8
		dc.w	$0000,$0000,$0380,$0000
		dc.w	$0380,$0000,$0380,$0000
		dc.w	$0380,$0000,$0380,$0000
		dc.w	$0380,$0000,$0380,$0000
		dc.w	$0380,$0000,$0380,$0000
		dc.w	$0380,$0000,$0380,$0000
		dc.w	$0380,$0000,$0380,$0000
		dc.w	$0380,$0000,$0000,$0000
		dc.w	$FFFE,$FFFE,$0380,$0380
		dc.w	$0380,$0380,$0380,$0380
		dc.w	$0380,$0380,$0380,$0380
		dc.w	$0380,$0380,$0380,$0380
		dc.w	$0380,$0380,$0380,$0380
		dc.w	$0380,$0380,$0380,$0380
		dc.w	$0380,$0380,$0380,$0380
		dc.w	$0000,$0000,$0000,$FFFE
		dc.w	$0000,$0380,$0000,$0380
		dc.w	$0000,$0380,$0000,$0380
		dc.w	$0000,$0380,$0000,$0380
		dc.w	$0000,$0380,$0000,$0380
		dc.w	$0000,$0380,$0000,$0380
		dc.w	$0000,$0380,$0000,$0380
		dc.w	$0000,$0380,$0000,$0000
		dc.w	$7FFC,$0000,$7000,$0000
		dc.w	$7000,$0000,$7000,$0000
		dc.w	$7000,$0000,$7000,$0000
		dc.w	$7FF0,$0000,$7000,$0000
		dc.w	$7000,$0000,$7000,$0000
		dc.w	$7000,$0000,$7000,$0000
		dc.w	$7000,$0000,$7FFC,$0000
		dc.w	$0000,$0000,$7FE0,$7FE0
		dc.w	$7038,$7038,$701C,$701C
		dc.w	$701C,$701C,$701C,$701C
		dc.w	$7038,$7038,$7FE0,$7FE0
		dc.w	$7700,$7700,$7380,$7380
		dc.w	$71C0,$71C0,$70E0,$70E0
		dc.w	$7070,$7070,$7038,$7038
		dc.w	$701C,$701C
		dc.l	0

slut:		end

