
kill		move.b	voiceinfoblock+voxstatus,d0
		lsl	#1,d0
		lea	colours,a0
		move	(a0,d0),color(pad)
		jmp	kill
colours		dc.w	black,blue,red,magenta,green,cyan,yellow,white
