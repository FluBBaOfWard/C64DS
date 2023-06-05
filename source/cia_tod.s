
	.global CIA1_TOD_F_R
	.global CIA1_TOD_S_R
	.global CIA1_TOD_M_R
	.global CIA1_TOD_H_R
	.global CIA1_TOD_F_W
	.global CIA1_TOD_S_W
	.global CIA1_TOD_M_W
	.global CIA1_TOD_H_W
	.global CIA2_TOD_F_R
	.global CIA2_TOD_S_R
	.global CIA2_TOD_M_R
	.global CIA2_TOD_H_R
	.global CIA2_TOD_F_W
	.global CIA2_TOD_S_W
	.global CIA2_TOD_M_W
	.global CIA2_TOD_H_W
	.global CIA_TOD_Init
	.global CIA_TOD_Count

	.section .text
;@----------------------------------------------------------------------------
CIA_TOD_Init:
;@----------------------------------------------------------------------------
	ldr r1,=cia1_running
	mov r0,#1
	strb r0,[r1]
	ldr r1,=cia2_running
	strb r0,[r1]
	bx lr
;@----------------------------------------------------------------------------
CIA_TOD_Count:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldr r0,=cia1_base
	bl count_frames
	ldr r0,=cia2_base
	bl count_frames

	ldr r1,=cia1_running
	ldrb r0,[r1]
	cmp r0,#0
	blne copy_cia1_regs

	ldr r1,=cia2_running
	ldrb r0,[r1]
	cmp r0,#0
	blne copy_cia2_regs
	
	ldmfd sp!,{lr}
	bx lr

;@----------------------------------------------------------------------------
copy_cia2_regs:	;@ r0=source, r1=destination, r2=garbadge
;@----------------------------------------------------------------------------
	ldr r0,=cia2_base
	ldr r1,=CIA2_TOD_Base
	b copy_cia_regs
;@----------------------------------------------------------------------------
copy_cia1_regs:	;@ r0=source, r1=destination, r2=garbadge
;@----------------------------------------------------------------------------
	ldr r0,=cia1_base
	ldr r1,=CIA1_TOD_Base
;@----------------------------------------------------------------------------
copy_cia_regs:	;@ r0=source, r1=destination, r2=garbadge
;@----------------------------------------------------------------------------
	ldrb r2,[r0,#0]			;@ Frame
	mov r2,r2,lsr#4
	strb r2,[r1,#0]
	ldrb r2,[r0,#1]			;@ Second
	strb r2,[r1,#1]
	ldrb r2,[r0,#2]			;@ Minute
	strb r2,[r1,#2]
	ldrb r2,[r0,#3]			;@ Hour
	strb r2,[r1,#3]
	bx lr
;@----------------------------------------------------------------------------


;@----------------------------------------------------------------------------
CIA1_TOD_F_R:
;@----------------------------------------------------------------------------
	ldr r1,=cia1_base
	mov r0,#1
	strb r0,[r1,#8]			;@ Running
	ldrb r0,[r1,#0]			;@ Frame
	mov r0,r0,lsr#4
	bx lr
;@----------------------------------------------------------------------------
CIA1_TOD_S_R:
;@----------------------------------------------------------------------------
	ldr r1,=cia1_base
	ldrb r0,[r1,#1]			;@ Second
	bx lr
;@----------------------------------------------------------------------------
CIA1_TOD_M_R:
;@----------------------------------------------------------------------------
	ldr r1,=cia1_base
	ldrb r0,[r1,#2]			;@ Minute
	bx lr
;@----------------------------------------------------------------------------
CIA1_TOD_H_R:
;@----------------------------------------------------------------------------
	ldr r1,=cia1_base
	mov r0,#0
	strb r0,[r1,#8]			;@ Running
	ldrb r0,[r1,#3]			;@ Hour
	bx lr

;@----------------------------------------------------------------------------
CIA1_TOD_F_W:
;@----------------------------------------------------------------------------
	ldr r1,=cia1_base
	mov r0,r0,lsl#4
	strb r0,[r1,#0]			;@ Frame
	mov r0,#1
	strb r0,[r1,#8]			;@ Running
	b copy_cia1_regs
;@----------------------------------------------------------------------------
CIA1_TOD_S_W:
;@----------------------------------------------------------------------------
	ldr r1,=cia1_base
	strb r0,[r1,#1]			;@ Second
	bx lr
;@----------------------------------------------------------------------------
CIA1_TOD_M_W:
;@----------------------------------------------------------------------------
	ldr r1,=cia1_base
	strb r0,[r1,#2]			;@ Minute
	bx lr
;@----------------------------------------------------------------------------
CIA1_TOD_H_W:
;@----------------------------------------------------------------------------
	ldr r1,=cia1_base
	strb r0,[r1,#3]			;@ Hour
	mov r0,#0
	strb r0,[r1,#8]			;@ Running
	bx lr

;@----------------------------------------------------------------------------
CIA2_TOD_F_R:
;@----------------------------------------------------------------------------
	ldr r1,=cia2_base
	mov r0,#1
	strb r0,[r1,#8]			;@ Running
	ldrb r0,[r1,#0]			;@ Frame
	mov r0,r0,lsr#4
	bx lr
;@----------------------------------------------------------------------------
CIA2_TOD_S_R:
;@----------------------------------------------------------------------------
	ldr r1,=cia2_base
	ldrb r0,[r1,#1]			;@ Second
	bx lr
;@----------------------------------------------------------------------------
CIA2_TOD_M_R:
;@----------------------------------------------------------------------------
	ldr r1,=cia2_base
	ldrb r0,[r1,#2]			;@ Minute
	bx lr
;@----------------------------------------------------------------------------
CIA2_TOD_H_R:
;@----------------------------------------------------------------------------
	ldr r1,=cia2_base
	mov r0,#0
	strb r0,[r1,#8]			;@ Running
	ldrb r0,[r1,#3]			;@ Hour
	bx lr

;@----------------------------------------------------------------------------
CIA2_TOD_F_W:
;@----------------------------------------------------------------------------
	ldr r1,=cia2_base
	mov r0,r0,lsl#4
	strb r0,[r1,#0]			;@ Frame
	mov r0,#1
	strb r0,[r1,#8]			;@ Running
	b copy_cia2_regs
;@----------------------------------------------------------------------------
CIA2_TOD_S_W:
;@----------------------------------------------------------------------------
	ldr r1,=cia2_base
	strb r0,[r1,#1]			;@ Second
	bx lr
;@----------------------------------------------------------------------------
CIA2_TOD_M_W:
;@----------------------------------------------------------------------------
	ldr r1,=cia2_base
	strb r0,[r1,#2]			;@ Minute
	bx lr
;@----------------------------------------------------------------------------
CIA2_TOD_H_W:
;@----------------------------------------------------------------------------
	ldr r1,=cia2_base
	strb r0,[r1,#3]			;@ Hour
	mov r0,#0
	strb r0,[r1,#8]			;@ Running
	bx lr
;@----------------------------------------------------------------------------


;@----------------------------------------------------------------------------
count_frames:		;@ r0=cia1/cia2.
;@----------------------------------------------------------------------------
	stmfd sp!,{r3-r5,lr}

	ldrb r1,[r0,#0]			;@ Frame
	add r1,r1,#1
	and r2,r1,#0xF
	cmp r2,#5				;@ 5 or 6 depending on bit 7 byte 0xE.
	andhi r1,r1,#0xF0
	addhi r1,r1,#0x10
	cmp r1,#0x9F
	movhi r1,#0
	strb r1,[r0,#0]			;@ Frame
	blhi count_seconds

	ldmfd sp!,{r3-r5,lr}
	bx lr
;@----------------------------------------------------------------------------
count_seconds:		;@ r0=cia1/cia2.
;@----------------------------------------------------------------------------
	ldrb r1,[r0,#1]			;@ Second
	add r1,r1,#1
	and r2,r1,#0xF
	cmp r2,#9
	andhi r1,r1,#0xF0
	addhi r1,r1,#0x10
	cmp r1,#0x59
	movhi r1,#0
	strb r1,[r0,#1]			;@ Second
	bhi count_minutes

	bx lr
;@----------------------------------------------------------------------------
count_minutes:		;@ r0=cia1/cia2.
;@----------------------------------------------------------------------------
	ldrb r1,[r0,#2]			;@ Minute
	add r1,r1,#1
	and r2,r1,#0xF
	cmp r2,#9
	andhi r1,r1,#0xF0
	addhi r1,r1,#0x10
	cmp r1,#0x59
	movhi r1,#0
	strb r1,[r0,#2]			;@ Minute
	bhi count_hours

	bx lr
;@----------------------------------------------------------------------------
count_hours:		;@ r0=cia1/cia2.
;@----------------------------------------------------------------------------
	ldrb r1,[r0,#3]			;@ Hour
	add r1,r1,#1
	and r2,r1,#0xF
	cmp r2,#9
	andhi r1,r1,#0xF0
	addhi r1,r1,#0x10
	and r2,r1,#0x3F
	cmp r2,#0x12
	bichi r1,r1,#0x32
	eorhi r1,r1,#0x80
	strb r1,[r0,#3]			;@ Hour

	bx lr
;@----------------------------------------------------------------------------

cia1_base:
cia1_t_frame:
	.byte 0x00
cia1_t_second:
	.byte 0x00
cia1_t_minute:
	.byte 0x00
cia1_t_hour:
	.byte 0x00
cia1_a_frame:
	.byte 0x00
cia1_a_second:
	.byte 0x00
cia1_a_minute:
	.byte 0x00
cia1_a_hour:
	.byte 0x00
cia1_running:
	.byte 0x00

cia2_base:
cia2_t_frame:
	.byte 0x00
cia2_t_second:
	.byte 0x00
cia2_t_minute:
	.byte 0x00
cia2_t_hour:
	.byte 0x00
cia2_a_frame:
	.byte 0x00
cia2_a_second:
	.byte 0x00
cia2_a_minute:
	.byte 0x00
cia2_a_hour:
	.byte 0x00
cia2_running:
	.byte 0x00

	.byte 0x00,0x00

