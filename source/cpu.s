#ifdef __arm__

#include "Shared/nds_asm.h"
#include "ARM6502/M6502.i"
#include "equates.h"

	.global run
	.global stepFrame
	.global cpuInit
	.global cpuReset

	.global frameTotal
	.global waitMaskIn
	.global waitMaskOut
	.global wram_global_base

	.syntax unified
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
	bl newFrame					;@ Display update

;@----------------------------------------------------------------------------
c64FrameLoop:
;@----------------------------------------------------------------------------
	mov r0,#63
	bl m6502RunXCycles
	ldr r1,[r10,#scanline]
	bl irqScanlineHook

	ldr r1,[r10,#scanline]
	add r1,r1,#1
	str r1,[r10,#scanline]
	ldr r0,[r10,#lastscanline]
	cmp r1,r0
	bne c64FrameLoop
;@-------------------------------------------------
	bl endFrame					;@ Display update
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
	ldmfdeq sp!,{r4-r11,lr}		;@ Exit here if doing single frame:
	bxeq lr						;@ Return to rommenu()
	b runStart

;@----------------------------------------------------------
frameTotal:			.long 0		;@ Let Gui.c see frame count for savestates
waitCountIn:		.byte 0
waitMaskIn:			.byte 0
waitCountOut:		.byte 0
waitMaskOut:		.byte 0
irqPinStatus:		.byte 0
nmiPinStatus:		.byte 0
	.align 2
;@----------------------------------------------------------------------------
stepFrame:					;@ Return after 1 frame
	.type stepFrame STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
	ldr m6502ptr,=m6502_0
	add r0,m6502ptr,#m6502Regs
	ldmia r0,{m6502nz-m6502pc,m6502zpage}	;@ Restore M6502 state
	bl newFrame					;@ Display update
;@----------------------------------------------------------------------------
c64StepLoop:
;@----------------------------------------------------------------------------
	mov r0,#63
	bl m6502RunXCycles
	ldr r1,[r10,#scanline]
	bl irqScanlineHook

	ldr r1,[r10,#scanline]
	add r1,r1,#1
	str r1,[r10,#scanline]
	ldr r0,[r10,#lastscanline]
	cmp r1,r0
	bne c64StepLoop
;@-------------------------------------------------
	bl endFrame					;@ Display update
;@-------------------------------------------------
	add r0,m6502ptr,#m6502Regs
	stmia r0,{m6502nz-m6502pc}	;@ Save 6502 state

	ldr r1,frameTotal
	add r1,r1,#1
	str r1,frameTotal

	ldmfd sp!,{r4-r11,lr}
	bx lr
;@----------------------------------------------------------
irqScanlineHook:
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

	tst r1,#0x08				;@ Contigous/oneshoot?
	ldreqb r0,[r10,#cia1timeral]
	ldreqb r1,[r10,#cia1timerah]
	orreq r0,r0,r1,lsl#8
	addeq r2,r2,r0
	movne r2,#-1
noTimerA1:
	str r2,[r10,#timer1a]
TimerA1Disabled:

VICRasterCheck:
	ldrb r0,[r10,#vicRaster]
	ldrb r1,[r10,#vicCtrl1]
	tst r1,#0x80
	orrne r0,r0,#0x100
	ldr r1,[r10,#scanline]
	cmp r0,r1
	bne noRasterIrq
	ldrb r0,[r10,#vicIrqFlag]
	orr r0,r0,#1
	strb r0,[r10,#vicIrqFlag]
noRasterIrq:

	ldrb r2,[r10,#cia1irqctrl]
	ldrb r1,[r10,#cia1irq]
	ands r0,r2,r1
	movne r0,#0x01			;@ Normal interrupt (CIA1)
	ldrb r2,[r10,#vicIrqEnable]
	ldrb r1,[r10,#vicIrqFlag]
	ands r2,r2,r1
	orrne r0,r0,#0x01		;@ Normal interrupt (VIC)

	bl m6502SetIRQPin

	ldmfd sp!,{lr}
	bx lr

;@----------------------------------------------------------------------------
setVicIrq:			;@ r0 = irq status, m6502ptr = r10 = pointer to struct
;@----------------------------------------------------------------------------
	cmp r0,#0
	ldrb r0,irqPinStatus
	biceq r0,r0,#0x01
	orrne r0,r0,#0x01
	strb r0,irqPinStatus
	b m6502SetIRQPin
;@----------------------------------------------------------------------------
setCia1Irq:			;@ r0 = irq status, m6502ptr = r10 = pointer to struct
;@----------------------------------------------------------------------------
	cmp r0,#0
	ldrb r0,irqPinStatus
	biceq r0,r0,#0x02
	orrne r0,r0,#0x02
	strb r0,irqPinStatus
	b m6502SetIRQPin
;@----------------------------------------------------------------------------
setCia2Nmi:			;@ r0 = nmi status, m6502ptr = r10 = pointer to struct
;@----------------------------------------------------------------------------
	cmp r0,#0
	ldrb r0,nmiPinStatus
	biceq r0,r0,#0x01
	orrne r0,r0,#0x01
	strb r0,nmiPinStatus
	b m6502SetNMIPin
;@----------------------------------------------------------------------------
setKeybNmi:			;@ r0 = nmi status, m6502ptr = r10 = pointer to struct
;@----------------------------------------------------------------------------
	cmp r0,#0
	ldrb r0,nmiPinStatus
	biceq r0,r0,#0x02
	orrne r0,r0,#0x02
	strb r0,nmiPinStatus
	b m6502SetNMIPin
;@----------------------------------------------------------------------------
cpuInit:					;@ Called by machineInit
;@----------------------------------------------------------------------------
	ldr r0,=m6502_0
	b m6502Init
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
