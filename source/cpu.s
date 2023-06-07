#ifdef __arm__

#include "Shared/nds_asm.h"
#include "ARM6502/M6502.i"
#include "equates.h"

	.global run
	.global stepFrame
	.global cpuInit
	.global cpuReset
	.global irq_scanlinehook

	.global frameTotal
	.global waitMaskIn
	.global waitMaskOut
	.global wram_global_base

	.section .text
	.align 2
;@----------------------------------------------------------------------------
run:						;@ Return after X frame(s)
	.type   run STT_FUNC
;@----------------------------------------------------------------------------
	ldrh r0,waitCountIn
	add r0,r0,#1
	ands r0,r0,r0,lsr#8
	strb r0,waitCountIn
	bxne lr
	stmfd sp!,{r4-r11,lr}

	ldr globalptr,=wram_global_base
	ldr r0,=emu_ram_base
	ldr m6502zpage,[r0]
	b line0x

;@----------------------------------------------------------------------------
;@ Cycles ran out
;@----------------------------------------------------------------------------
line0:
	add r0,m6502ptr,#m6502Regs
	stmia r0,{m6502nz-m6502pc}	;@ Save 6502 state

	ldr r1,=fpsValue
	ldr r0,[r1]
	add r0,r0,#1
	str r0,[r1]

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
	ldmeqfd sp!,{r4-r11,lr}		;@ Exit here if doing single frame:
	bxeq lr						;@ Return to rommenu()

line0x:
//	bl ManageInput

	bl newframe					;@ Display update

	add r0,m6502ptr,#m6502Regs
	ldmia r0,{m6502nz-m6502pc}	;@ Restore 6502 state


line1_to_VBL: ;@------------------------
	mov r0,#63
	bl m6502RunXCycles
	ldr r1,[r10,#scanline]
	bl irq_scanlinehook

	ldr r1,[r10,#scanline]
	add r1,r1,#1
	str r1,[r10,#scanline]
	ldr r0,[r10,#lastscanline]
	cmp r1,r0
	bne line1_to_VBL

;@-------------------------------------------------
	bl endframe					;@ Display update
;@-------------------------------------------------

	ldr r1,frameTotal
	add r1,r1,#1
	str r1,frameTotal
	b line0

;@----------------------------------------------------------
frameTotal:			.long 0		;@ Let ui.c see frame count for savestates
waitCountIn:		.byte 0
waitMaskIn:			.byte 0
waitCountOut:		.byte 0
waitMaskOut:		.byte 0

;@----------------------------------------------------------------------------
stepFrame:					;@ Return after 1 frame
	.type stepFrame STT_FUNC
;@----------------------------------------------------------------------------
	bx lr
;@----------------------------------------------------------
irq_scanlinehook:
;@----------------------------------------------------------
	stmfd sp!,{lr}
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

	ldrb r2,[r10,#cia1irqctrl]
	ldrb r1,[r10,#cia1irq]
	ands r0,r2,r1
	movne r0,#0x01			;@ Normal interrupt (CIA1)
	ldrb r2,[r10,#vicirqenable]
	ldrb r1,[r10,#vicirqflag]
	ands r2,r2,r1
	orrne r0,r0,#0x01		;@ Normal interrupt (VIC)

	bl m6502SetIRQPin

	ldmfd sp!,{lr}
	bx lr

;@----------------------------------------------------------------------------
cpuReset:		;@ Called by loadCart/resetGame
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

;@---Speed - 0.96MHz / 50Hz
	mov r0,#63
;@--------------------------------------
	ldr r0,=m6502_0
	bl m6502Init
	ldr r0,=m6502_0
	bl m6502Reset

	ldmfd sp!,{lr}
	bx lr
;@----------------------------------------------------------
AGBjoypad:		.long 0
EMUjoypad:		.long 0
dontstop:		.long 0

;@----------------------------------------------------------------------------
#ifdef NDS
	.section .dtcm, "ax", %progbits			;@ For the NDS
#elif GBA
	.section .iwram, "ax", %progbits		;@ For the GBA
#else
	.section .text
#endif
	.align 2
;@----------------------------------------------------------------------------
wram_global_base:
m6502_0:
	.space m6502Size
	.space 0x180
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
