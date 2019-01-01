; ******************************************************************************
; *
; *	Xevio(u)s - The Arcade Game!
; *
; *	A Jolly Duplicator, Pirates Touch and STZ production
; *	Inspired by The Game and a silly record called 'video
; *	game music'.
; *
; *	- You want a licence for your pet fish Eric?
; *	- Yes.
; *	- You ARE a loony!
; *
; ******************************************************************************

; Include files: ---------------------------------------------------------------
;
		include	"df0:baCKUP/macro.i"               ; Macro stuff
		include	"DF0:BACKUP/equates.i"		; Everything under the sun

first_line	equ	$2C			; start display at this line

screen1		equ	$10000
screen2		equ	$16000
screen3		equ	$1c000



; Main code: -------------------------------------------------------------------
;
		org	$28000			; Ample room for bitplanes below

xevious		lea	custom,pad		; keep this always

;	----- Put processor in Supervisor mode
		move.l	#start,swi0		; This is user vector #1
		trap	#0			; Resume execution at interrupt

;	----- Reset all interrupt vectors
start		move.w	#clrall,intena(pad)	; No interrupts.
		move.w	#clrall,dmacon(pad)	; No DMA

		move.l	#vectortable,a0		; Ptr to addresses of IRQ
		move.l	#level1autovect,a1	; This is level 1 autovect addr
		moveq	#7-1,d0			; 7 vectors to move
initialise	move.l	(a0)+,(a1)+		; Do one vector
		dbra	d0,initialise

;	----- Set up stuff for copper
		move.l	#copperlist,cop1lc(pad)	; address of copperlist
		move	copjmp1(pad),d0		; strobe - reset internal PC

;	----- Set up the colours
		move.l	#palette+2,a0
		move.l	#custom+color,a1
		move	#16-1,d0		; 32 words to init.
set_up_palette	move.w	(a0)+,(a1)+
		dbra	d0,set_up_palette

		move	#blue,color17(pad)
		move	#red,color21(pad)
		move	#green,color25(pad)
		move	#lemon_yellow,color29(pad)

;	----- Initialize some hardware
		move	#$4000,bplcon0(pad)	; High Resolution & 4 bitplanes
		move	#$2CC1,diwstrt(pad)	; DisplWind Start at (C1,2C)
		move	#$2C81,diwstop(pad)	; DisplWind End at (12C,181)
		move	#$0058,ddfstrt(pad)	; Data fetch after 5C clocks
		move	#$00B0,ddfstop(pad)	; and end after B4 clocks
		move	#$0000,bpl1mod(pad)	; No modoulo on even planes
		move	#$0000,bpl2mod(pad)	; Nor on odd ones

		jsr	clearscreen

; 	----- Enable IRQs for vertical blank and the coprocessor
		move	#setbit+inten+blit+vertb+coper,intena(pad)

; 	----- Enable DMA for bit planes and the coprocessor and the blitter, sprites
		move	#setbit+bltpri+dmaen+blten+bplen+copen+spren,dmacon(pad)

main_loop	bclr	#0,flag			; Time for a vertical blank?
		beq.s	main_loop

		jsr	update_sprites
		jsr	update_blitter		; Blit process screen to buffer screen
		jsr	wait_4_blitter
		jsr	scroll			; Do scrolling
		jsr	redshift		; Glow ceartain colours

		jsr	update_display

		bra.s	main_loop

delay		equ	0			; Amount of frames between each scroll

;	----- Update pointers to copper waits and bitmap refreshes
scroll		move.l	#sfraction,a0
		subq	#1,(a0)
		bcc.s	scroll1

		move	#delay,(a0)+		; new wait value
		subq	#$01,(a0)		; new scrollposition
		and	#$FF,(a0)

		bsr	copy_line		; Drop me a line

		subq	#1,vstrobe
		bcc.s	scroll1			; New buffer fill?
		move	#15,vstrobe

;	----- Update the contents in the off-screen character buffer
update_buffer	move.l	ground_data_ptr,a0		; points to ground data
		move	(a0)+,d0			; Row ID word

		cmp	#42,d0				; quick&dirty start over
		bne.s	upd0

		move.l	#ground_data+2,ground_data_ptr
		bra.s	update_buffer

upd0		move	#12-1,d2			; 12 blocks across
		move.l	#ground_buffer,a1

upd1		move	(a0)+,d0			; object number
		lsl	#7,d0				; 128 bytes per object
		move.l	#ground_graphics+2,a2
		add	d0,a2				; size is 2 bytes * 8 lines * 4 planes = 64
		move	#64-1,d1			; 64 words to move

upd2		move	(a2)+,(a1)			; Object
		add	#24,a1				; Next down
		dbra	d1,upd2

		sub	#$600-2,a1			; back to first address, next word
		dbra	d2,upd1
		move.l	a0,ground_data_ptr

scroll1		rts

; Flag byte
;  0: Vertical Blank

flag		dc.w	0
sfraction	dc.w	0
scrollposition	dc.w	0			; current scroll value

;	----- Return when blitter is not doing anything
wait_4_blitter	btst	#bbusyx,dmaconr(pad)
		bne.s	wait_4_blitter
		rts

;	----- Clear whole display file
clearscreen	move.l	#screen1,a0		; Physically clear ALL display files
		moveq	#0,d0
		move	#$4800,d1
cls1		move.l	d0,(a0)+
		dbra	d1,cls1
		rts

;	----- Cycle colour 15 smoothly through "redshiftdata"
redshift	move.l	redshiftpointer,a0
		cmp	#$1000,(a0)
		bne	redshift1
		move.l	#redshiftdata,a0
redshift1	move	(a0)+,d0
		lsl	#8,d0			; change to 4 for G or 0 for B
		move	d0,color+30(pad)
		move.l	a0,redshiftpointer
		rts

redshiftpointer	dc.l	redshiftdata
redshiftdata	dc.w	15,15,14,14,13,13,12,12,11,11,10,10,9,9,8,8
		dc.w	7,7,6,6,5,5,4,4,3,3,2,2,1,1,0,0
		dc.w	1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8
		dc.w	9,9,10,10,11,11,12,12,13,13,14,14
		dc.w	$1000

ground_data_ptr	dc.l	ground_data+2