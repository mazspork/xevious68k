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

allaud		equ	aud0en
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

		move.l	#waveform0,aud0(pad)
		move.w	#(wf0end-waveform0)/2,aud0+4(pad)
		move.w	#48,aud0+8(pad)
		move.w	#65000,aud0+6(pad)
		
		move.l	#waveform1,aud1(pad)
		move.w	#(wf1end-waveform1)/2,aud1+4(pad)
		move.w	#48,aud1+8(pad)
		move.w	#300,aud1+6(pad)
		
		move.l	#waveform2,aud2(pad)
		move.w	#(wf2end-waveform2)/2,aud2+4(pad)
		move.w	#48,aud2+8(pad)
		move.w	#65000,aud2+6(pad)
		
		move.l	#waveform1,aud3(pad)
		move.w	#(wf1end-waveform1)/2,aud3+4(pad)
		move.w	#48,aud3+8(pad)
		move.w	#300,aud3+6(pad)
		
		move.w	#setbit+1<<4+1<<6,adkcon(pad)
		

; --- Enable IRQs for vertical blank and the coprocessor
		move	#setbit+inten+vertb+coper,intena(pad)

; --- Enable DMA for bit planes and the coprocessor and the blitter
		move	#setbit+dmaen+copen+aud0en+aud1en+aud2en+aud3en,dmacon(pad)
		
;
hang:		bra	hang			; main code ends here!

		cnop	0,2

waveform0:	dc.w	500,400,300,200,100,200,300,400,500,600,700,800
		dc.w	700,600
wf0end:
waveform1:	dc.b	0,39,75,103,121,127,121,103,75,39,0
		dc.b	-39,-75,-103,-121,-127,-121,-103,-75,-39
wf1end:
waveform2:	dc.w	0,10,20,40,80,160,320,160,80,40,20,10
wf2end:
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
		exit	(blit)
copperint:
		exit	(coper)

vertblankint:	
		exit	(vertb)
;
;	----- Come here after a successful interrupt to clear intreq
finished:	move	d0,intreq(pad)
		rte

		section	"copperstuff",data

;	----- These are the addresses of all seven superstates.
vectortable:	dc.l	level1,level2,level3,level4,level5,level6,level7

;	----- This is the Coprocessor List
copperlist:	copwait	254,254			; sleep until Vblank
coplistend:	nop
;
slut:		end

