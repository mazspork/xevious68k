
screen		equ	$20000

debuginit	move	#black,color0(pad)
		move	#white,color1(pad)

		move	#$1000,bplcon0(pad)	; main attributes for playfield
		move	#$2C81,diwstrt(pad)
		move	#$F4C1,diwstop(pad)
		move	#$0038,ddfstrt(pad)
		move	#$00D0,ddfstop(pad)
		move	#0,bpl1mod(pad)
		move	#0,bpl2mod(pad)

		move	#$640,d0
		moveq	#0,d1
		lea	screen,a1
fillscreen1:	move.l	d1,(a1)+
		dbra	d0,fillscreen1

		rts

debugw		jsr	debug

wait4key	move	SR,-(sp)

wait4key1	btst	#10,potinp(pad)
		beq.s	wait4key1

wait4key2	btst	#10,potinp(pad)
		bne.s	wait4key2

		move	(sp)+,CCR
		rts


p_hexprint	equ	$FD
p_newcolour	equ	$FE
p_moretext	equ	$FF

print		moveq	#0,d0
		move.b	(a0)+,d0		; get X position
		lea	screen,a1		; then init a1 to dfaddr
		add	d0,a1			; and add that X position

		moveq	#0,d0
		move.b	(a0)+,d0	 	; Y position in pixels
		mulu	#$140,d0	 	; Multiply with screen width
		add.l	d0,a1		 	; final result in a1

step2		move.b	(a0)+,d3		; colour mask (bits 0-3)

printloop	moveq	#0,d0			; reset d0
		move.b	(a0)+,d0		; get an ascii char
		beq.s	endprint		; last, then jump
		cmp.b	#p_moretext,d0		; Repeat step 1
		beq.s	print
		cmp.b	#p_newcolour,d0		; Repeat step 2			
		beq.s	step2
		cmp	#p_hexprint,d0		; Go print out d7.l
		beq	print_long
		bsr	vdu			; else VDU it
		bra.s	printloop		; and goback

endprint	rts

char_height	equ	8			; BBC Font has 8 pixel lines

vdu		and	#$ff,d0
		lsl	#3,d0		 	; Multiply by 8
		move.l	#charset-$100,a2 	; Add up to char set
		add	d0,a2		 	; index into charset data
		moveq	#8-1,d1		; How many bytes to copy

vdu2		move.b	(a2)+,(a1)
		add.l	#40,a1		 	; next
		dbra	d1,vdu2

		sub.l	#$140-1,a1
		rts				; Back to first


;	----- Print all registers

debug		movem.l	d0-d7/a0-a6,-(sp)
		move	SR,-(sp)

		move	SR,regs_sr
		move.l	a0,regs_a0
		move.l	a1,regs_a1
		move.l	a2,regs_a2
		move.l	a3,regs_a3
		move.l	a4,regs_a4
		move.l	a5,regs_a5
		move.l	a6,regs_a6
		move.l	a7,regs_a7
		move.l	d0,regs_d0
		move.l	d1,regs_d1
		move.l	d2,regs_d2
		move.l	d3,regs_d3
		move.l	d4,regs_d4
		move.l	d5,regs_d5
		move.l	d6,regs_d6
		move.l	d7,regs_d7

		move.l	#regs_text,a0
		jsr	print

		move	(sp)+,CCR
		movem.l	(sp)+,d0-d7/a0-a6
		rts


		dc.b	0
regs_text	dc.b	0,0,16,"A0:",p_hexprint
regs_a0		dc.l	0
		dc.b	p_moretext,0,1,16,"A1:",p_hexprint
regs_a1		dc.l	0
		dc.b	p_moretext,0,2,16,"A2:",p_hexprint
regs_a2		dc.l	0
		dc.b	p_moretext,0,3,16,"A3:",p_hexprint
regs_a3		dc.l	0
		dc.b	p_moretext,0,4,16,"A4:",p_hexprint
regs_a4		dc.l	0
		dc.b	p_moretext,0,5,16,"A5:",p_hexprint
regs_a5		dc.l	0
		dc.b	p_moretext,0,6,16,"A6:",p_hexprint
regs_a6		dc.l	0
		dc.b	p_moretext,0,7,16,"A7:",p_hexprint
regs_a7		dc.l	0
		dc.b	p_moretext,0,9,16,"D0:",p_hexprint
regs_d0		dc.l	0
		dc.b	p_moretext,0,10,16,"D1:",p_hexprint
regs_d1		dc.l	0
		dc.b	p_moretext,0,11,16,"D2:",p_hexprint
regs_d2		dc.l	0
		dc.b	p_moretext,0,12,16,"D3:",p_hexprint
regs_d3		dc.l	0
		dc.b	p_moretext,0,13,16,"D4:",p_hexprint
regs_d4		dc.l	0
		dc.b	p_moretext,0,14,16,"D5:",p_hexprint
regs_d5		dc.l	0
		dc.b	p_moretext,0,15,16,"D6:",p_hexprint
regs_d6		dc.l	0
		dc.b	p_moretext,0,16,16,"D7:",p_hexprint
regs_d7		dc.l	0
		dc.b	p_moretext,0,18,16,"CCR: ",p_hexprint
regs_sr		dc.l	0
		dc.b	0


		even

;	----- Write out next long word as a long word
print_long	moveq	#4-1,d6
		move.l	(a0)+,d7
printd71	rol.l	#8,d7
		move	d7,d0
		bsr.s	hexprint
		dbne	d6,printd71
		bra	printloop

;	----- Print contents of D0.B
hexprint	move.b	d0,-(sp)
		lsr.b	#4,d0
		bsr.s	hex1
		move.b	(sp)+,d0
hex1		and.b	#$F,d0
		cmp.b	#$A,d0
		bcs.s	hex2
		add.b	#7,d0
hex2		add.b	#48,d0
		bra	vdu


;	----- Generic ASCII 8x8 mapped character set
charset:	dc.b	0,0,0,0,0,0,0,0,24,24,24,24,24,0,24,0
		dc.b	108,108,108,0,0,0,0,0,108,108,254,108,254,108,108,0
		dc.b	24,62,88,60,26,124,24,0,0,198,204,24,48,102,198,0
		dc.b	56,108,56,118,220,204,118,0,24,24,48,0,0,0,0,0
		dc.b	12,24,48,48,48,24,12,0,48,24,12,12,12,24,48,0
		dc.b	0,102,60,255,60,102,0,0,0,24,24,126,24,24,0,0
		dc.b	0,0,0,0,0,24,24,48,0,0,0,126,0,0,0,0
		dc.b	0,0,0,0,0,24,24,0,6,12,24,48,96,192,128,0
		dc.b	124,198,206,214,230,198,124,0,24,56,24,24,24,24,126,0
		dc.b	60,102,6,60,96,102,126,0,60,102,6,28,6,102,60,0
		dc.b	28,60,108,204,254,12,30,0,126,98,96,124,6,102,60,0
		dc.b	60,102,96,124,102,102,60,0,126,102,6,12,24,24,24,0
		dc.b	60,102,102,60,102,102,60,0,60,102,102,62,6,102,60,0
		dc.b	0,0,24,24,0,24,24,0,0,0,24,24,0,24,24,48
		dc.b	12,24,48,96,48,24,12,0,0,0,126,0,0,126,0,0
		dc.b	96,48,24,12,24,48,96,0,60,102,102,12,24,0,24,0
		dc.b	124,198,222,222,222,192,124,0,24,60,102,102,126,102,102,0
		dc.b	252,102,102,124,102,102,252,0,60,102,192,192,192,102,60,0
		dc.b	248,108,102,102,102,108,248,0,254,98,104,120,104,98,254,0
		dc.b	254,98,104,120,104,96,240,0,60,102,192,192,206,102,62,0
		dc.b	102,102,102,126,102,102,102,0,126,24,24,24,24,24,126,0
		dc.b	30,12,12,12,204,204,120,0,230,102,108,120,108,102,230,0
		dc.b	240,96,96,96,98,102,254,0,198,238,254,254,214,198,198,0
		dc.b	198,230,246,222,206,198,198,0,56,108,198,198,198,108,56,0
		dc.b	252,102,102,124,96,96,240,0,56,108,198,198,218,204,118,0
		dc.b	252,102,102,124,108,102,230,0,60,102,96,60,6,102,60,0
		dc.b	126,90,24,24,24,24,60,0,102,102,102,102,102,102,60,0
		dc.b	102,102,102,102,102,60,24,0,198,198,198,214,254,238,198,0
		dc.b	198,108,56,56,108,198,198,0,102,102,102,60,24,24,60,0
		dc.b	254,198,140,24,50,102,254,0,60,48,48,48,48,48,60,0
		dc.b	192,96,48,24,12,6,2,0,60,12,12,12,12,12,60,0
		dc.b	24,60,126,24,24,24,24,0,0,0,0,0,0,0,0,255
		dc.b	48,24,12,0,0,0,0,0,0,0,120,12,124,204,118,0
		dc.b	224,96,124,102,102,102,220,0,0,0,60,102,96,102,60,0
		dc.b	28,12,124,204,204,204,118,0,0,0,60,102,126,96,60,0
		dc.b	28,54,48,120,48,48,120,0,0,0,62,102,102,62,6,124
		dc.b	224,96,108,118,102,102,230,0,24,0,56,24,24,24,60,0
		dc.b	6,0,14,6,6,102,102,60,224,96,102,108,120,108,230,0
		dc.b	56,24,24,24,24,24,60,0,0,0,108,254,214,214,198,0
		dc.b	0,0,220,102,102,102,102,0,0,0,60,102,102,102,60,0
		dc.b	0,0,220,102,102,124,96,240,0,0,118,204,204,124,12,30
		dc.b	0,0,220,118,96,96,240,0,0,0,60,96,60,6,124,0
		dc.b	48,48,124,48,48,54,28,0,0,0,102,102,102,102,62,0
		dc.b	0,0,102,102,102,60,24,0,0,0,198,214,214,254,108,0
		dc.b	0,0,198,108,56,108,198,0,0,0,102,102,102,62,6,124
		dc.b	0,0,126,12,24,48,126,0,14,24,24,112,24,24,14,0
		dc.b	24,24,24,24,24,24,24,0,112,24,24,14,24,24,112,0
		dc.b	118,220,0,0,0,0,0,0,60,66,153,161,161,153,66,60

