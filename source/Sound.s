#ifdef __arm__

#include "ARM6581/ARM6581.i"

	.global soundInit
	.global soundReset
	.global VblSound2
	.global setMuteSoundGUI

	.extern pauseEmulation

;@----------------------------------------------------------------------------

	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
soundInit:
	.type soundInit STT_FUNC
;@----------------------------------------------------------------------------
//	stmfd sp!,{lr}

//	ldmfd sp!,{lr}
//	bx lr

;@----------------------------------------------------------------------------
soundReset:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	bl m6581Reset			;@ sound
	ldmfd sp!,{lr}
	bx lr

;@----------------------------------------------------------------------------
setMuteSoundGUI:
	.type setMuteSoundGUI STT_FUNC
;@----------------------------------------------------------------------------
	ldr r1,=pauseEmulation		;@ Output silence when emulation paused.
	ldrb r0,[r1]
	strb r0,muteSoundGUI
	bx lr
;@----------------------------------------------------------------------------
VblSound2:					;@ r0=length, r1=pointer
;@----------------------------------------------------------------------------
	ldr r2,muteSound
	cmp r2,#0
	bne silenceMix

	stmfd sp!,{r0,lr}
	bl SID_StartMixer

	ldmfd sp!,{r0,lr}
	bx lr
;@----------------------------------------------------------------------------
silenceMix:
;@----------------------------------------------------------------------------
	mov r3,r0
	ldr r2,=0x80008000
silenceLoop:
	subs r0,r0,#1
	strpl r2,[r1],#4
	bhi silenceLoop

	mov r0,r3				;@ Return same amount as requested.
	bx lr

;@----------------------------------------------------------------------------

muteSound:
muteSoundGUI:
	.byte 0
muteSoundChip:
	.byte 0
	.space 2

	.section .bss
	.align 2
sidChip_0:
	.space m6581Size
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
