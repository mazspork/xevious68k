;
; ***************************************************************************
;
;	MACLIB.I
;
;	Mazoft Software Standard Macro Library
;
;
; Macro definitions (last rev 2 mar 89):-
;
;	CWAIT	Copper "wait" instruction
;	CMOVE.s	Copper "move" instruction (word or longword)
;	CSKIP	Copper "skip" instruction
;	CGOTO	Copper "goto" instruction
;	CIFNOT	Copper "if not" instruction
;	CNOOP	Copper pseudo no-op instruction
;	COPINSM	68000 macro to build a copper MOVE instruction
;	COPINSS	68000 macro to build a copper SKIP instruction
;	COPINSW	68000 macro to build a copper WAIT instruction
;	EXIT	68000 macro to exit from an interrupt server
;	SETFLAG	68000 set zero, carry, sign, overflow or extended flag
;	CLRFLAG	68000 clear zero, carry, sign, overflow or extended flag
;	INVFLAG	68000 invert zero, carry, sign, overflow or extended flag
;	PUSH.s	68000 push register list onto stack
;	POP.s	68000 pop register list off stack
;	INC.s	68000 increment effective address
;	DEC.s	68000 decrement effective address
;
;	NOTE	Creates a note data structure
;	WAVEFRM	Builds a waveform control data structure
;	ENVELOP	Creates an envelope node data structure
;
; (c) 1987-88-89 Mazoft Software (DK)
;
; Note that in most of the above macros, immediate values are assumed. There
; is NO immediate identifier (such as '#').
;
; ***************************************************************************


; Copper "MOVE" instruction (move immediate data to register)
;
; Format:	cmove.w	data,register
;		cmove.l	data,register
;
; Note that the register value is the offset from the base of the hardware
; register map (the PAD). This is $DFF000, and the values defined in
; EQUATES.I all refer to offset from this base and can thus be used directly.
;
cmove	 MACRO

	      IFC 'l','\0'
		dc.w	(((\2)/2)*2),(\1)>>$10
		dc.w	(((\2+2)/2)*2),(\1)&$FFFF
		MEXIT
	      ENDC

	      IFC 'W','\0'
		dc.w	(((\2)/2)*2),(\1)
		MEXIT
	      ENDC

	      IFC 'w','\0'
		dc.w	(((\2)/2)*2),(\1)
		MEXIT
	      ENDC

		FAIL	Bad size field for copper-move ".\0"
	ENDM


; Copper "SKIP" instruction (skip next instruction if raster has reached
; specified X,Y position)
;
; Format:	cskip	VP,HP
; 		cskipx	VP,HP,Vmask,Hmask,BFD
;
; The cskip macro assumes the mask bytes all set to ones and the blitter
; finished disable bit also set to one. These parameters can be controlled
; through the macro cskipx.
;
cskip	MACRO
		dc.w	(1+(\1)*$100+((\2)/2)*2),$FFFF
	ENDM

cskipx	MACRO
		dc.w	(1+(\1)*$100+((\2)/2)*2)
		dc.w	(1+(\3)*$100+(\4)*2+(\5)*$8000)
	ENDM


; Copper "WAIT" instruction (wait until raster position >= X,Y)
;
; Format:	cwait	VP,HP
; 		cwaitx	VP,HP,Vmask,Hmask,BFD
;		cwait	forever
;
; The cwait macro assumes the mask bytes all set to ones and the blitter
; finished disable bit also set to one. These parameters can be controlled
; through the macro cwaitx. Alternatively, "cwait forever" waits until next
; PC reload (copwait 254,254) either by external interrupt or by the 68000.
;
cwait	MACRO
	      IFC '\1','forever'
		dc.w	$FEFF,$FFFE			    ; wait 254,254
	      ELSEIF
		dc.w	(1+(\1)*$100+((\2)/2)*2)	    ; (\1<<8+\2!1)
		dc.w	$FFFE
	      ENDC
	ENDM

cwaitx	MACRO
		dc.w	(1+(\1)*$100+((\2)/2)*2)	    ; (\1<<8+\2!1)
		dc.w	(0+(\3)*$100+(\4)*2+(\5)*$8000)     ; (\3<<9+\4<<1+\5<<15)
	ENDM


; Copper "GOTO" instruction
;
; Format:	cgoto	address
;
; Sets copper PC to address (takes three copper instructions). The address
; field MUST be an absolute value - not a data or address register.
;
cgoto		MACRO
		cmove.l	\1,cop2lc
		cmove	0,copjmp2
		ENDM

; Copper "IF NOT <condition> GOTO <address>" instruction
;
; Format:	cifnot	X,Y,address
;
; Jumps to "address" if raster has not yet reached position X,Y. Sets copper
; PC to new address, takes up 3 instructions if condition not met (ie. if
; raster >= X,Y) in which case it won't goto address, and 4 instructions if
; condition met (ie. if raster < X,Y) in which case it goes to address.
;
cifnot	MACRO
		cmove.l	\3,cop2lc
		cskip	\1,\2
		cmove	0,copjmp2
	ENDM


; Copper NOP (no-operation)
;
; Format:	cnoop
;		cnoop	count
;
; Cnoop is just a move instruction to a read-only register, and takes up
; one copper instruction (32 bits). Alternatively, a count field can be added
; to denote how many succesive copper nops are to be carried out.
;
cnoop	MACRO

	      IFC '\1',''
\1		SET	1
	      ENDC

	      REPT \1
		copmove	0,intenar
	      ENDR

	ENDM


; 68000 Make Copper "MOVE" instruction (at run time)
;
; Format:	copinsM	data,destination,location
;
; Where "data" is a real effective address, "destination" is the i/o register
; and "location" is where the instruction (32 bits, in "data") are to go. The
; "location" must be address register indirect with decrement or increment,
; eg. "copinsM d4,bplcon1,(a3)+" puts a MOVE D4,BPLCON1 at address (a3).
;
; Destroys no extra registers.
;
copinsM	MACRO
		move.w	#(((\2)/2)*2),\3
		move.w	\1,\3
	ENDM


; 68000 Make Copper "SKIP" instruction (at run time)
;
; Format:	copinsS	X,Y,location
;
; Creates a copper SKIP instruction at "location" with X and Y as the raster
; compare values.
;
; Destroys D0.
;
copinsS	MACRO
		move.b	\1,d0
		lsl.w	#8,d0
		or.w	\2,d0
		or.b	#1,d0
		move.w	d0,\3
		move.w	#$FFFF,\3
	ENDM


; 68000 Make Copper "WAIT" instruction (at run time)
;
; Format:	copinsW	X,Y,address
;
; Creates a copper WAIT instruction at "location" with X and Y as the raster
; compare values.
;
; Destroys D0.
;
copinsW	MACRO
		move.b	\1,d0
		lsl.w	#8,d0
		or.w	\2,d0
		or.b	#1,d0
		move.w	d0,\3
		move.w	#$FFFE,\3
	ENDM


; 68000 Exit from interrupt server.
;
; Format:	exit	server
;
; Where "server" is the bit in INTREQ that requested the interrupt. Remember
; that it is the programmer's responsibility to handle the various bits in
; these control registers to avoid multiple spurious interrupt. This macro
; will move the bit number to D0 and jump to "finished", where it will be
; reset in INTREQ.
;
exit	MACRO
		move	#\1,d0
		bra	finished
	ENDM


; Waveform data table build-up. (16 bytes)
;
; Format:	Wavefrm	ADDR,B,C,D
; 		Wavefrm	ADDR,D
;
; The ADDR is the longword address where the first sample is found, the
; B, C and D parameters are the distance (in BYTES, NOT WORDS) to the
; looping points B, C and C respectively.
;
wavefrm	MACRO
	      IFC '\3',''
		dc.l	(\1)		; Simple waveform
		dc.w	(\2)/2
		dc.w	0
		dc.l	0
		dc.w	0
		dc.w	0
	      ELSEIF
		dc.l	(\1)		; address of A		@ 0
		dc.w	(\4)/2		; length		@ 4
		dc.w	(\3)/2		; length from A to C	@ 6
		dc.l	((\1)+(\2))	; address of B		@ 8
		dc.w	((\3)-(\2))/2	; length from B to C	@ C
		dc.w	((\4)-(\2))/2	; length from B to D	@ E
	      ENDC
	ENDM


; "Note" creates note data for the sound data tables (8 bytes)
;
; Format	note	<ID>,<vol>,<total_dur>,<note_dur>,<rate>,<env>,<pb>
; 		note	off
;
; Note (!) that the <total_duration> determines for how long the note 
; is to be played. If (<note_duration> == <total_duration>), there will
; be no subsequent pause after the sound.

note	MACRO
	      IFC '\1','off'
		dc.l	$FFFFFFFF,$FFFFFFFF
		dc.w	0
	      ELSEIF
		dc.b	(\1),(\2)	; sound ID and volume
		dc.w	(\4)		; sustain note this long
		dc.w	(\3)-(\4)	; pause for this long
		dc.w	(\5)		; rate
		dc.b	(\6)		; envelope #
		dc.b	(\7)		; pitchbender #
	      ENDC
	ENDM


; Envelope data structure creator (4 bytes)
;
; Format	Envelop	<distance>, <delta>
; 		Envelop	off
;		Envelop	goto, <number>
;
; where <number> is another envelope structure index.
; The delta is presented in 256-fractional steps

envelop	MACRO

	      IFC '\1','off'
		dc.l	0		; No more data in this list
		MEXIT
	      ENDC

	      IFC '\1','goto'
		dc.w	0		; End of this structure
	      ELSEIF
		dc.w	(\1)		; Timespan * 20ms
	      ENDC
		dc.w	(\2)		; Delta (as 16-bit 2's complement)
	ENDM


; 68000 Dynamic condition code flagging:-
;
; Format:	setflag	<c|v|z|n|x>	sets appropriate condition code
;		clrflag <c|v|z|n|x>	resets appropriate condition code
;		invflag <c|v|z|n|x>	inverts appropriate condition code

setflag	MACRO

	      IFC '\1','c'
		or	#%00001,CCR
	      ENDC

	      IFC '\1','v'
		or	#%00010,CCR
	      ENDC

	      IFC '\1','z'
		or	#%00100,CCR
	      ENDC

	      IFC '\1','n'
		or	#%01000,CCR
	      ENDC

	      IFC '\1','x'
		or	#%10000,CCR
	      ENDC

	ENDM

clrflag	MACRO

	      IFC '\1','c'
		and	#%00001,CCR
	      ENDC

	      IFC '\1','v'
		and	#%00010,CCR
	      ENDC

	      IFC '\1','z'
		and	#%00100,CCR
	      ENDC

	      IFC '\1','n'
		and	#%01000,CCR
	      ENDC

	      IFC '\1','x'
		and	#%10000,CCR
	      ENDC

	ENDM

invflag	MACRO

	      IFC '\1','c'
		eor	#%00001,CCR
	      ENDC

	      IFC '\1','v'
		eor	#%00010,CCR
	      ENDC

	      IFC '\1','z'
		eor	#%00100,CCR
	      ENDC

	      IFC '\1','n'
		eor	#%01000,CCR
	      ENDC

	      IFC '\1','x'
		eor	#%10000,CCR
	      ENDC

	ENDM


; 68000 Pushing and popping register lists to and from the system stack.
;
; Format:	push.s	<register(s)>
; 		pop.s	<register(s)>
; 		push	all
; 		pop	all
;
push	MACRO

	      IFC '\1','all'
		movem.l  a0-a6/d0-d7,-(sp)
	      ELSEIF
		movem.\0 \1,-(sp)
	      ENDC

	ENDM

pop	MACRO

	      IFC '\1','all'
		movem.l	(sp)+,a0-a6/d0-d7
	      ELSEIF
		movem.\0 (sp)+,\1
	      ENDC

	ENDM

; 68000 Increment and decrement instructions
;
; Format:	inc.s	<ea>
; 		dec.s	<ea>
;
inc	MACRO
		addq.\0	#1,\1
	ENDM

dec	MACRO
		subq.\0	#1,\1
	ENDM


