#ifdef __arm__

#include "ARM6581/ARM6581.i"

	.global soundInit
	.global soundReset
	.global VblSound2
	.global setMuteSoundGUI
	.global soundUpdate

	.extern pauseEmulation

#define WRITE_BUFFER_SIZE (0x800)

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
	mov r0,#WRITE_BUFFER_SIZE/2
	str r0,pcmWritePtr
	mov r0,#0
	str r0,pcmReadPtr
//	ldr spxptr,=sphinx0
//	bl wsAudioReset			;@ sound
	mov r0,#WRITE_BUFFER_SIZE
	ldr r1,=WAVBUFFER
	bl silenceMix
	ldmfd sp!,{lr}
	bx lr

;@----------------------------------------------------------------------------
setMuteSoundGUI:
	.type   setMuteSoundGUI STT_FUNC
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
soundUpdate:			;@ Should be called at every scanline
;@----------------------------------------------------------------------------
	mov r0,#2			;@ 24kHz / (75Hz * 160 scanlines) = 2
	ldr r1,pcmWritePtr
	mov r2,r1,lsl#21	;@ Only keep 11 bits
	add r1,r1,r0
	str r1,pcmWritePtr
	ldr r1,=WAVBUFFER
	add r1,r1,r2,lsr#19
//	b wsAudioMixer
	bx lr

;@----------------------------------------------------------------------------
pcmWritePtr:	.long 0
pcmReadPtr:		.long 0
neededExtra:	.long 0

muteSound:
muteSoundGUI:
	.byte 0
muteSoundChip:
	.byte 0
	.space 2

	.section .bss
	.align 2
WAVBUFFER:
	.space WRITE_BUFFER_SIZE*4
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
