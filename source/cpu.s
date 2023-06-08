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

	.arm

#ifdef GBA
	.section .ewram, "ax", %progbits	;@ For the GBA
#else
	.section .text						;@ For anything else
#endif
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

;@----------------------------------------------------------------------------
runStart:
;@----------------------------------------------------------------------------
	ldr r0,=EMUinput
	ldr r0,[r0]

	bl refreshEMUjoypads

	ldr m6502ptr,=m6502_0
	add r0,m6502ptr,#m6502Regs
	ldmia r0,{m6502nz-m6502pc,m6502zpage}	;@ Restore M6502 state
	bl newframe					;@ Display update

;@----------------------------------------------------------------------------
c64FrameLoop:
;@----------------------------------------------------------------------------
	mov r0,#63
	bl m6502RunXCycles
	ldr r1,[r10,#scanline]
	bl irq_scanlinehook

	ldr r1,[r10,#scanline]
	add r1,r1,#1
	str r1,[r10,#scanline]
	ldr r0,[r10,#lastscanline]
	cmp r1,r0
	bne c64FrameLoop
;@-------------------------------------------------
	bl endframe					;@ Display update
;@-------------------------------------------------
	add r0,m6502ptr,#m6502Regs
	stmia r0,{m6502nz-m6502pc}	;@ Save 6502 state

	ldr r1,=fpsValue
	ldr r0,[r1]
	add r0,r0,#1
	str r0,[r1]

	ldr r1,frameTotal
	add r1,r1,#1
	str r1,frameTotal

	ldrh r0,waitCountOut
	add r0,r0,#1
	ands r0,r0,r0,lsr#8
	strb r0,waitCountOut
	ldmeqfd sp!,{r4-r11,lr}		;@ Exit here if doing single frame:
	bxeq lr						;@ Return to rommenu()
	b runStart

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
	stmfd sp!,{r4-r11,lr}
	ldr m6502ptr,=m6502_0
	add r0,m6502ptr,#m6502Regs
	ldmia r0,{m6502nz-m6502pc,m6502zpage}	;@ Restore M6502 state
	bl newframe					;@ Display update
;@----------------------------------------------------------------------------
c64StepLoop:
;@----------------------------------------------------------------------------
	mov r0,#63
	bl m6502RunXCycles
	ldr r1,[r10,#scanline]
	bl irq_scanlinehook

	ldr r1,[r10,#scanline]
	add r1,r1,#1
	str r1,[r10,#scanline]
	ldr r0,[r10,#lastscanline]
	cmp r1,r0
	bne c64StepLoop
;@-------------------------------------------------
	bl endframe					;@ Display update
;@-------------------------------------------------
	add r0,m6502ptr,#m6502Regs
	stmia r0,{m6502nz-m6502pc}	;@ Save 6502 state

	ldr r1,frameTotal
	add r1,r1,#1
	str r1,frameTotal

	ldmfd sp!,{r4-r11,lr}
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

	ldr r0,=m6502_0
	bl m6502Init
	ldr r0,=m6502_0
	bl m6502Reset

	ldmfd sp!,{lr}
	bx lr

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
