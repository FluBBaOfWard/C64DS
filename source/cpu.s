	.include "equates.h"


	.global run_frame
	.global irq_scanlinehook
	.global frametotal
	.global sleeptime
	.global novblankwait

	.text machine_cpu
;@----------------------------------------------------------------------------
run_frame:	;@ r0=0 to return after frame
;@----------------------------------------------------------------------------
//	mov r1,#0
//	strb r1,novblankwait

	str r0,dontstop
	tst r0,#1
	stmeqfd sp!,{r4-r11,lr}

	ldr globalptr,=wram_global_base
	ldr r0,=emu_ram_base
	ldr cpu_zpage,[r0]
	b line0x
;@----------------------------------------------------------------------------
;@ Cycles ran out
;@----------------------------------------------------------------------------
line0:
	ldr r2,=cpustate
	stmia r2,{m6502_nz-m6502_pc}	;@ Save 6502 state
waitformulti:
	ldr r1,=0x04000130			;@ Refresh input every frame
	ldrh r0,[r1]
		eor r0,r0,#0xff
		eor r0,r0,#0x300		;@ r0=button state (raw)
	ldr r1,AGBjoypad
	eor r1,r1,r0
	and r1,r1,r0				;@ r1=button state (0->1)
	str r0,AGBjoypad


	ldr r2,dontstop
	cmp r2,#0
	ldmeqfd sp!,{r4-r11,lr}			;@ Exit here if doing single frame:
	bxeq lr							;@ Return to rommenu()

	;@----anything from here til line0x won't get executed while rom menu is active---

	adr lr,line0x			;@ Return here after doing L/R + SEL/START

//	tst r1,#0x300			;@ If L or R was pressed
//	tstne r0,#0x100
//	tstne r0,#0x200			;@ And both L+R are held..
//	ldrne r1,=ui
//	bxne r1					;@ Do menu

	ands r3,r0,#0x300		;@ If either L or R is pressed (not both)
	eornes r3,r3,#0x300
	bicne r0,r0,#0x0c		;@ Hide sel,start from EMU
	str r0,EMUjoypad
	beq line0x				;@ Skip ahead if neither or both are pressed

//	tst r0,#0x200
//	tstne r1,#4				;@ L+SEL for BG adjust
//	ldrne r2,adjustblend
//	addne r2,r2,#1
//	strne r2,adjustblend

//	tst r0,#0x200			;@ L?
//	tstne r1,#8				;@ START?
//	ldrb r2,novblankwait	;@ 0=Normal, 1=No wait, 2=Slomo
//	addne r2,r2,#1
//	cmp r2,#3
//	moveq r2,#0
//	strb r2,novblankwait


	tst r0,#0x100			;@ R?
	tstne r1,#4				;@ SELECT:
line0x:
//	tst r1,#0x030			;@ If L or R was pressed
//	beq nolr
//	ldr r0,songnumber
//	ldr r2,songcount
//	tst r1,#0x010			;@ If L was pressed
//	addne r0,r0,#1
//	tst r1,#0x020			;@ If R was pressed
//	subnes r0,r0,#1
//	movmi r0,#0
//	cmp r0,r2
//	subpl r0,r2,#1
//	str r0,songnumber
//nolr

//	bl refreshEMUjoypads	;@ Z=1 if communication ok
//	bne waitformulti		;@ Waiting on other GBA..

	ldr r0,AGBjoypad
	ldr r2,fiveminutes		;@ Sleep after 5/10/30 minutes of inactivity
	cmp r0,#0				;@ (left out of the loop so waiting on multi-link
	ldrne r2,sleeptime		;@ Doesn't accelerate time)
	subs r2,r2,#1
	str r2,fiveminutes
//	bleq suspend

//	ldrb r4,novblankwait
	cmp r4,#2
	beq l03
l01:
	ldr r0,emuflags
	tst r0,#PALTIMING
	moveq r1,#0x01			;@ VBL wait
	movne r1,#0x20			;@ Timer2 wait

	cmp r4,#1
	movne r0,#0				;@ Wait for vblank if it hasn't allready happened.
	moveq r0,#1				;@ Wait for next vblank.
//	swi 0x040000			;@ Turn of CPU until IRQ if not too late allready.
	cmp r4,#3				;@ Check for slomo
	moveq r4,#0
	beq l01
l03:

	bl newframe				;@ Display update

	ldr r0,fpsvalue
	add r0,r0,#1
	str r0,fpsvalue

//	mov r11,r11

	ldr r0,=cpustate
	ldmia r0,{m6502_nz-m6502_pc}	;@ Restore 6502 state

	adr r0,line1_to_VBL
	str r0,[r10,#nexttimeout]
	str r0,[r10,#nexttimeout_]


line1_to_VBL: ;@------------------------
	ldr r0,[r10,#cyclesperscanline]
	add cycles,cycles,r0

	ldr r1,[r10,#scanline]
	add r1,r1,#1
	str r1,[r10,#scanline]
	ldr r0,[r10,#lastscanline]
	cmp r1,r0
	ldrne pc,[r10,#scanlinehook]


;@-------------------------------------------------
	bl endframe					;@ Display update
;@-------------------------------------------------

	ldr r0,[r10,#frame]
	add r0,r0,#1
	str r0,[r10,#frame]
	b line0
	adr addy,line0
	str addy,[r10,#nexttimeout]
	str addy,[r10,#nexttimeout_]

	ldr pc,[r10,#scanlinehook]

;@----------------------------------------------------------
irq_scanlinehook:
;@----------------------------------------------------------
	bl RenderLine
ScanlineTimerA1:
	ldrb r1,[r10,#cia1ctrla]
	tst r1,#0x01				;@ Timera1 active?
	beq TimerA1Disabled
//	tst r1,#0x20				;@ Count 02 clock or CNT signals?
	ldr r2,[r10,#timer1a]
	subs r2,r2,#63
	bcs noTimerA1
	ldrb r0,[r10,#cia1irq]		;@ Set cia1 timera irq
	orr r0,r0,#1
	strb r0,[r10,#cia1irq]

	tst r1,#0x08				;@ Continuous/oneshoot?
	ldreqb r0,[r10,#cia1timeral]
	ldreqb r1,[r10,#cia1timerah]
	orreq r0,r0,r1,lsl#8
	addeq r2,r2,r0
	movne r2,#-1
noTimerA1:
	str r2,[r10,#timer1a]
TimerA1Disabled:

VICRasterCheck:
	ldrb r0,[r10,#vicraster]
	ldrb r1,[r10,#vicctrl1]
	tst r1,#0x80
	orrne r0,r0,#0x100
	ldr r1,[r10,#scanline]
	cmp r0,r1
	bne norasterirq
	ldrb r0,[r10,#vicirqflag]
	orr r0,r0,#1
	strb r0,[r10,#vicirqflag]
	
norasterirq:
	b CheckIRQs


;@----------------------------------------------------------
AGBjoypad:		.word 0
EMUjoypad:		.word 0
fiveminutes:	.word 5*60*60
sleeptime:		.word 5*60*60
dontstop:		.word 0
novblankwait:	.word 0
songnumber:		.word 0
songcount:		.word 0
emuflags:		.word 0
fpsvalue:		.word 0

