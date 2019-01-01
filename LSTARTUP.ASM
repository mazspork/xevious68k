	section	text,CODE
* C initial startup procedure under AmigaDOS
* 
* Requirements:

	INCLUDE	"exec/types.i"
	INCLUDE "exec/alerts.i"
	INCLUDE "exec/nodes.i"
	INCLUDE "exec/lists.i"
	INCLUDE "exec/ports.i"
	INCLUDE "exec/libraries.i"
	INCLUDE "exec/tasks.i"
	INCLUDE "libraries/dos.i"
	INCLUDE "libraries/dosextens.i"
	INCLUDE "workbench/startup.i"

; some usefull macros:
xlib	macro
	xref	_LVO\1
	endm

callsys	macro
	CALLLIB	_LVO\1
	endm
	

	xdef	_XCEXIT			* exit(code) is standard way to leave C.

	xref	_Debug
	xref	__main			* Name of C program to start with.
	xref	_MemCleanup
	xref	_AbsExecBase
	xref	_FindTask

	xlib	Alert
	xlib	FindTask
	xlib	Forbid
	xlib	GetMsg
	xlib	OpenLibrary
	xlib	ReplyMsg
	xlib	Wait
	xlib	WaitPort
	xlib	Open
	xlib	Close
	xlib	CurrentDir

start:
	move.l	d0,dosCmdLen
	move.l	a0,dosCmdBuf
	move.l	a7,d0			; save old stack ptr
	movem.l	d1-d6/a0-a6,-(a7)
	move.l	d0,a5
	move.l	_AbsExecBase,a6
	move.l	a6,_SysBase
	move.l	a7,__StackPtr		* Save stack ptr
	clr.l	_WBenchMsg

;------ get the address of our task
	suba.l	a1,a1
	callsys	FindTask
	move.l	d0,a4

;------ are we running as a son of Workbench?
	move.l	pr_CurrentDir(A4),_curdir
	tst.l	pr_CLI(A4)
	beq	fromWorkbench

;=======================================================================
;====== CLI Startup Code ===============================================
;=======================================================================

fromCLI:
	move.l	a5,D0		; get top of stack
	sub.l	4(a5),D0	; compute bottom 
	move.l	D0,__base	; save for stack checking
;------	attempt to open DOS library:
	bsr	openDOS

;------ find command name:
	move.l	#start,a0
;	jsr	_Debug
	clr.l	-(sp)
	jsr	_FindTask
	addq.l	#4,sp
	move.l	d0,a0
	move.l	pr_CLI(a0),a0
	add.l   a0,a0		; bcpl pointer conversion
	add.l   a0,a0
	move.l	cli_CommandName(a0),a1
	add.l   a1,a1		; bcpl pointer conversion
	add.l   a1,a1

;------	collect parameters:
	move.l	dosCmdLen,d0		; get command line length
	moveq.l	#0,d1
	move.b	(a1)+,d1
	move.l	a1,__ProgramName
	add.l	d1,d0			; add length of command name
	addq.l	#1,d0			; allow for space after command	

	clr.w	-(A7)			; set null terminator for command line
	addq.l	#1,D0			; force to even number of bytes
	andi.w	#$fffe,D0		;(round up)
	sub.l	D0,A7			; make room on stack for command line
	subq.l	#2,D0
	clr.w	0(A7,D0)

;------ copy command line onto stack
	move.l	dosCmdLen,d0		; get command line length
	move.l	dosCmdBuf,a0
	move.l	d0,d2
	subq.l	#1,d0
	add.l	d1,d2

copy_line:
	move.b	0(A0,D0.W),0(A7,D2.W)	; copy command line to stack
	subq.l	#1,d2
	dbf	d0,copy_line
	move.b	#' ',0(a7,d2.w)		; add space between command and parms
	subq.l	#1,d2

copy_cmd:
	move.b	0(a1,d2.w),0(a7,d2.w)	; copy command name to stack
	dbf	d2,copy_cmd
	move.l	A7,A1
	move.l	A1,-(A7)		; push command line address
	jsr	__main		        * call C entrypoint
	moveq.l	#0,d0			; set successful status
	bra.s	exit2

;=======================================================================
;====== Workbench Startup Code =========================================
;=======================================================================

fromWorkbench:

	move.l	TC_SPLOWER(a4),__base	; set base of stack
;------ open the DOS library:
	bsr	openDOS

;------ we are now set up.  wait for a message from our starter
	bsr	waitmsg
	move.l	d0,_WBenchMsg
	move.l	d0,-(SP)
;
	move.l	d0,a2			; get first argument
	move.l	sm_ArgList(a2),d0
	beq.s	do_cons
	move.l	_DOSBase,a6
	move.l	d0,a0
	move.l	wa_Lock(a0),d1
	callsys	CurrentDir
do_cons:
	move.l	sm_ToolWindow(a2),d1	; get the window argument
	beq.s	do_main
	move.l	#MODE_OLDFILE,d2
	callsys	Open
	move.l	d0,stdin
	beq.s	do_main
	lsl.l	#2,d0
	move.l	d0,a0
	move.l	fh_Type(a0),pr_ConsoleTask(A4)
do_main:
	pea	_NULL
	jsr	__main		        * call C entrypoint
	moveq.l	#0,d0			; set successful status
	bra.s	exit2
;

_XCEXIT:
	move.l	4(SP),d0	; extract return code
exit2:
	move.l	d0,-(a7)
	jsr	_MemCleanup		; cleanup leftover memory alloc.

;------ if we ran from CLI, skip workbench cleanup:
	tst.l	_WBenchMsg
	beq.s	exitToDOS
	move.l	_console_dev,d1
	beq.s	done_2
	callsys	Close
done_2:
	move.l	stdin,d1
	beq.s	done_4
	callsys	Close
done_4:

;------ return the startup message to our parent
;	we forbid so workbench can't UnLoadSeg() us
;	before we are done:
	move.l	_AbsExecBase,A6
	callsys Forbid
	move.l	_WBenchMsg,a1
	callsys	ReplyMsg

;------ this rts sends us back to DOS:
exitToDOS:
	MOVE.L	(A7)+,D0
	movea.l  __StackPtr,SP		* restore stack ptr
	movem.l	(a7)+,d1-d6/a0-a6
	rts				* and exit

;-----------------------------------------------------------------------
noDOS:
		ALERT	(AG_OpenLib!AO_DOSLib)
		moveq.l	#100,d0
		bra.s	exit2


;-----------------------------------------------------------------------
; This routine gets the message that workbench will send to us
; called with task id in A4

waitmsg:
		lea	pr_MsgPort(A4),a0  	* our process base
		callsys	WaitPort
		lea	pr_MsgPort(A4),a0  	* our process base
		callsys GetMsg
		rts

;-----------------------------------------------------------------------
;  Open the DOS library:

openDOS
		lea	DOSName,A1
		moveq.l	#0,D0
		callsys OpenLibrary
		move.l	D0,_DOSBase
		beq	noDOS
		rts

	section	data,DATA
;
	XDEF	_NULL,_DOSBase,_SysBase,_LoadAddress,_console_dev,_WBenchMsg
	XDEF	__mbase,__mnext,__msize,__tsize,__oserr,__fperr,__mstep
	XDEF	__ProgramName,__StackPtr,__base
;
_NULL	DC.L	0			;
__base	DC.L	0			; base of stack
__mbase	DC.L	0			; base of memory pool
__mnext	DC.L	0			; next available memory location
__msize	DC.L	0			; size of memory pool
__mstep	DC.L	1024			; memory pool step size
__tsize	DC.L	0			; total size?
__oserr	DC.L	0
__fperr	DC.L	0
_curdir	DC.L	0
_console_dev DC.L 0
_SysBase     DC.L 0
_DOSBase     DC.L 0	
_LoadAddress DC.L 0			; program load address
_WBenchMsg	dc.l	0
__StackPtr	dc.l	0
dosCmdLen	dc.l	0
dosCmdBuf	dc.l	0
stdin	dc.l	0
__ProgramName	dc.l	0
DOSName 	DOSNAME

	END
