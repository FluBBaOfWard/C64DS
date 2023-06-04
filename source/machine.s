#include "equates.h"
#include "memory.h"
#include "ARM6502/M6502mac.h"
#include "ARM6502/M6502.h"

	.global Machine_reset
	.global Machine_run
	.global BankSwitch_R
	.global BankSwitch_0_W
	.global BankSwitch_1_W
//	.global Chargen
//	.global Basic
//	.global Kernal
//	.global Keyboard_gfx


	.text machine
;@----------------------------------------------------------------------------
Machine_reset:
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}

	ldr globalptr,=wram_global_base
	ldr r0,=emu_ram_base
	ldr cpu_zpage,[r0]
	add cpu_zpage,cpu_zpage,#0x1FC
	bic cpu_zpage,cpu_zpage,#0x1FC
	str cpu_zpage,[r0]

	bl Mem_reset
	bl GFX_reset
	bl IO_reset
//	bl SOUND_reset
	bl CPU_reset

	ldmfd sp!,{r4-r11,lr}
	bx lr
;@----------------------------------------------------------------------------
Machine_run:
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}

	ldr globalptr,=wram_global_base
	ldr r0,=emu_ram_base
	ldr cpu_zpage,[r0]

	bl ManageInput
	mov r0,#0
	bl run_frame

	ldmfd sp!,{r4-r11,lr}
	bx lr
;@----------------------------------------------------------------------------
Mem_reset:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	mov r2,#0xFF

	ldr r4,=MEMMAPTBL_
	ldr r5,=RDMEMTBL_
	ldr r6,=WRMEMTBL_
	ldr r7,=ram_R
	ldr r8,=ram_W
	mov r0,#0

tbloop1:
	and r1,r0,r2
	add r1,cpu_zpage,r1,lsl#13
	str r1,[r4,r0,lsl#2]
	str r7,[r5,r0,lsl#2]
	str r8,[r6,r0,lsl#2]
	add r0,r0,#1
	cmp r0,#0x08
	bne tbloop1


	ldr r7,=chargen_R
	mov r0,#0x0C			;@ Chargen
	add r1,cpu_zpage,#0xC000
//	ldr r1,=Chargen
	str r1,[r4,r0,lsl#2]
	str r7,[r5,r0,lsl#2]	;@ RdMem
	str r8,[r6,r0,lsl#2]	;@ WrMem

	ldr r7,=basic_R
	mov r0,#0x0D			;@ Basic
	ldr r1,=_binary_basic_rom
//	ldr r1,=Basic
	str r1,[r4,r0,lsl#2]
	str r7,[r5,r0,lsl#2]	;@ RdMem
	str r8,[r6,r0,lsl#2]	;@ WrMem

	ldr r7,=kernal_R
	mov r0,#0x0F			;@ Kernal
	ldr r1,=_binary_kernal_rom
//	ldr r1,=Kernal
	str r1,[r4,r0,lsl#2]
	str r7,[r5,r0,lsl#2]	;@ RdMem
	str r8,[r6,r0,lsl#2]	;@ WrMem

	ldr r7,=IO_R
	ldr r8,=IO_W
	mov r0,#0x0E			;@ IO
	add r1,cpu_zpage,#0xC000
	str r1,[r4,r0,lsl#2]
	str r7,[r5,r0,lsl#2]	;@ RdMem
	str r8,[r6,r0,lsl#2]	;@ WrMem

//	mov m6502_pc,#0		;@ (eliminates any encodePC errors during mapper*init)
//	str m6502_pc,lastbank

	adr r4,HuMapData
	mov r5,#0x80
HuDataLoop:
	mov r0,r5
	ldrb r1,[r4],#1
	bl HuMapper_
	movs r5,r5,lsr#1
	bne HuDataLoop

	mov r0,cpu_zpage		;@ Clear RAM
	mov r1,#0
	mov r2,#0x10000/4
	bl memset_
	mov r0,#0x2F
	strb r0,[cpu_zpage]
	mov r0,#0x37
	strb r0,[cpu_zpage,#1]

	ldmfd sp!,{lr}
	bx lr
;@----------------------------------------------------------------------------
HuMapData:
	.byte 0x0F,0x0E,0x0D,0x04,0x03,0x02,0x01,0x00	;@ C64 Kernal/IO/Basic mapped in.
;@----------------------------------------------------------------------------
WRMEMTBL_:	.space 16*4
RDMEMTBL_:	.space 16*4
MEMMAPTBL_:	.space 16*4
;@----------------------------------------------------------------------------
;@----------------------------------------------------------------------------
HuMapper_:	;@ Rom paging..
;@----------------------------------------------------------------------------
	stmfd sp!,{r3-r7}
	ldr r6,=MEMMAPTBL_
	ldr r2,[r6,r1,lsl#2]!
	ldr r3,[r6,#-64]		;@ RDMEMTBL_
	ldr r4,[r6,#-128]		;@ WRMEMTBL_

wr_tbl:
	add r6,r10,#readmem_tbl
	tst r0,#0xFF
	bne memaps				;@ Safety
	b flush
memapl:
	add r6,r6,#4
memap2:
	sub r2,r2,#0x2000
memaps:
	movs r0,r0,lsr#1
	bcc memapl				;@ C=0
	strcs r3,[r6],#4		;@ readmem_tbl
	strcs r4,[r6,#28]		;@ writemem_tb
	strcs r2,[r6,#60]		;@ memmap_tbl
	bne memap2

;@------------------------------------------
flush:		;@ Update cpu_pc & lastbank
;@------------------------------------------
	ldr r1,[r10,#lastbank]
	sub m6502_pc,m6502_pc,r1
	encodePC

	ldmfd sp!,{r3-r7}
	mov pc,lr
;@----------------------------------------------------------------------------
BankSwitch_R:
;@----------------------------------------------------------------------------
	ldrb r1,[cpu_zpage]		;@ Dir
	ldrb r0,[cpu_zpage,#1]	;@ Data
	ldr r2,data_out
	orr r2,r2,#0x17

	tst r1,#0x20
	eor r1,r1,#0xFF
	orr r0,r0,r1			;@ Cleared bits are input (=1)
	and r0,r0,r2
	biceq r0,r0,#0x20
	bx lr

;@----------------------------------------------------------------------------
BankSwitch_0_W:
;@----------------------------------------------------------------------------
	ldrb r1,[cpu_zpage]		;@ Dir
	cmp r0,r1
	bxeq lr
	strb r0,[cpu_zpage]
	b setPort
;@----------------------------------------------------------------------------
BankSwitch_1_W:
;@----------------------------------------------------------------------------
	ldrb r1,[cpu_zpage,#1]	;@ Data
	cmp r0,r1
	bxeq lr
	strb r0,[cpu_zpage,#1]

setPort:
	stmfd sp!,{r0,r3,lr}

	ldrb r1,[cpu_zpage]
	ldrb r0,[cpu_zpage,#1]
	ldr r3,data_out
	bic r3,r3,r1
	and r0,r0,r1
	orr r3,r3,r0
	str r3,data_out

	ldrb r0,[cpu_zpage,#1]
	eor r1,r1,#7
	orr r3,r0,r1


	tst r3,#0x02
	moveq r1,#0x07		;@ Ram
	movne r1,#0x0F		;@ Kernal rom
	mov r0,#0x80		;@ Bank 0xE000.
	bl HuMapper_

	and r0,r3,#0x03
	cmp r0,#0x03
	movne r1,#0x05		;@ Ram
	moveq r1,#0x0D		;@ Basic rom
	mov r0,#0x20		;@ Bank 0xA000.
	bl HuMapper_

	tst r3,#0x04
	moveq r1,#0x0C		;@ Chargen/ram
	movne r1,#0x0E		;@ IO
	tst r3,#0x03		;@ Special!?
	moveq r1,#0x06		;@ Ram
	mov r0,#0x40		;@ Bank 0xC000.
	bl HuMapper_

//	ldr r0,[r10,#lastbank]
//	sub m6502_pc,m6502_pc,r0
//	encodePC

	ldmfd sp!,{r0,r3,pc}
;@----------------------------------------------------------------------------
data_out:
	.word	0x3f



;@----------------------------------------------------------------------------
	.bss
//Chargen:
//	.space 0x1000
//Basic:
//	.space 0x2000
//Kernal:
//	.space 0x2000
//Keyboard_gfx:			;@ Space for loading gfx
///	.space 0x1000

