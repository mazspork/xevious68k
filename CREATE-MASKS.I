create_masks	move	objects,d0		; how many objects
		move.l	#object_table,a0

maskoff1	move.l	(a0),a1		; graphic
		move	12(a0),d1	; size in bytes of each plane
		move	d1,d4
		lsr	#2,d4		; longwords
		subq	#1,d4

maskoff2	moveq	#4-1,d2		; 4 planes
		moveq	#0,d3		; mask
		move.l	a1,a2

maskoff3	or.l	(a2),d3		; mask through
		add	d1,a2
		dbra	d2,maskoff3

		move.l	d3,(a2)
		addq	#4,a1
		dbra	d4,maskoff2

		add	#$10,a0
		dbra	d0,maskoff1
		rts
