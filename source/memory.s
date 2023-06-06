#include "equates.h"
#include "ARM6502/M6502.i"

//	.extern Chargen
//	.extern Basic
//	.extern Kernal
	.extern BankSwitch_R
	.extern BankSwitch_0_W
	.extern BankSwitch_1_W

	.global empty_IO_R
	.global empty_R
	.global empty_W
	.global ram_low_R
	.global ram_R
	.global ram_W
	.global ram_low_W
	.global chargen_R
	.global basic_R
	.global kernal_R
//	.global rom_R0
	.global rom_W

	.section .text
	.align 2
;@----------------------------------------------------------------------------
empty_IO_R:		;@ Read bad address (error)
;@----------------------------------------------------------------------------
	mov r11,r11			;@ No$GBA debugg
	mov r0,#0x10
	bx lr
;@----------------------------------------------------------------------------
empty_R:		;@ Read bad address (error)
;@----------------------------------------------------------------------------
	mov r11,r11			;@ No$GBA debugg
	mov r0,#0
	bx lr
;@----------------------------------------------------------------------------
empty_W:		;@ Write bad address (error)
;@----------------------------------------------------------------------------
	mov r11,r11			;@ No$GBA debugg
	mov r0,#0xBA
	bx lr
;@----------------------------------------------------------------------------
rom_W:			;@ Write ROM address (error)
;@----------------------------------------------------------------------------
	mov r11,r11			;@ No$GBA debugg
	mov r0,#0xB0
	bx lr
;@----------------------------------------------------------------------------
	.section .itcm
	.align 2
;@----------------------------------------------------------------------------
ram_R:			;@ Ram read ($0000-$FFFF)
;@----------------------------------------------------------------------------
	ldrb r0,[m6502zpage,addy]
	cmp addy,#1
	bxne lr
	b BankSwitch_R
;@----------------------------------------------------------------------------
ram_low_R:		;@ Ram read ($0000-$00FF)
;@----------------------------------------------------------------------------
	ldrb r0,[m6502zpage,addy,lsr#24]
	cmp addy,#0x01000000
	bxne lr
	b BankSwitch_R
;@----------------------------------------------------------------------------
ram_W:			;@ Ram write ($0000-$FFFF)
;@----------------------------------------------------------------------------
	cmp addy,#1
	strhib r0,[m6502zpage,addy]
	bxhi lr
	beq BankSwitch_1_W
	b BankSwitch_0_W
;@----------------------------------------------------------------------------
ram_low_W:		;@ Ram write ($0000-$00FF)
;@----------------------------------------------------------------------------
	cmp addy,#0x02000000
	strcsb r0,[m6502zpage,addy,lsr#24]
	bxcs lr								;@ greater or equal.
	cmp addy,#0x01000000
	beq BankSwitch_1_W
	b BankSwitch_0_W

;@----------------------------------------------------------------------------
basic_R:		;@ Rom read ($A000-$BFFF)
;@----------------------------------------------------------------------------
	ldr r1,=Basic-0xA000
	ldrb r0,[r1,addy]
	bx lr
;@----------------------------------------------------------------------------
chargen_R:		;@ Rom read
;@----------------------------------------------------------------------------
	cmp addy,#0xD000
	ldrmib r0,[m6502zpage,addy]
	ldrpl r1,=Chargen-0xD000
	ldrplb r0,[r1,addy]
	bx lr
;@----------------------------------------------------------------------------
kernal_R:		;@ Rom read ($E000-$FFFF)
;@----------------------------------------------------------------------------
	ldr r1,=Kernal-0xE000
	ldrb r0,[r1,addy]
	bx lr
;@----------------------------------------------------------------------------
rom_R0:			;@ Rom read ($0000-$1FFF)
;@----------------------------------------------------------------------------
	ldr r1,[m6502ptr,#m6502MemTbl]
	ldrb r0,[r1,addy]
	bx lr
;@----------------------------------------------------------------------------
rom_R1:			;@ Rom read ($2000-$3FFF)
;@----------------------------------------------------------------------------
	ldr r1,[m6502ptr,#m6502MemTbl+4]
	ldrb r0,[r1,addy]
	bx lr
;@----------------------------------------------------------------------------
rom_R2:			;@ Rom read ($4000-$5FFF)
;@----------------------------------------------------------------------------
	ldr r1,[m6502ptr,#m6502MemTbl+8]
	ldrb r0,[r1,addy]
	bx lr
;@----------------------------------------------------------------------------
rom_R3:			;@ Rom read ($6000-$7FFF)
;@----------------------------------------------------------------------------
	ldr r1,[m6502ptr,#m6502MemTbl+12]
	ldrb r0,[r1,addy]
	bx lr
;@----------------------------------------------------------------------------
rom_R4:			;@ Rom read ($8000-$9FFF)
;@----------------------------------------------------------------------------
	ldr r1,[m6502ptr,#m6502MemTbl+16]
	ldrb r0,[r1,addy]
	bx lr
;@----------------------------------------------------------------------------
rom_R5:			;@ Rom read ($A000-$BFFF)
;@----------------------------------------------------------------------------
	ldr r1,[m6502ptr,#m6502MemTbl+20]
	ldrb r0,[r1,addy]
	bx lr
;@----------------------------------------------------------------------------
rom_R6:			;@ Rom read ($C000-$DFFF)
;@----------------------------------------------------------------------------
	ldr r1,[m6502ptr,#m6502MemTbl+24]
	ldrb r0,[r1,addy]
	bx lr
;@----------------------------------------------------------------------------
rom_R7:			;@ Rom read ($E000-$FFFF)
;@----------------------------------------------------------------------------
	ldr r1,[m6502ptr,#m6502MemTbl+28]
	ldrb r0,[r1,addy]
	bx lr
;@----------------------------------------------------------------------------
//mem_R			;@ Mem read
;@----------------------------------------------------------------------------
//	add r2,m6502ptr,m6502MemTbl
//	ldr r1,[r2,r1,lsr#11]	;@ r1=addy & 0xe000
//	ldrb r0,[r1,addy]
//	bx lr
;@----------------------------------------------------------------------------
	.end
