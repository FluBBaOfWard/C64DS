#ifdef __arm__

#include "ARM6526/ARM6526.i"
#include "ARM6502/M6502.i"

	.global IO_reset
	.global IO_R
	.global IO_W
	.global ciaTodCount
	.global refreshEMUjoypads
	.global SetC64Key

	.global EMUinput
	.global joyCfg
	.global mytouch_x
	.global mytouch_y
	.global mytouch_press
	.global keyb_pos
	.global Keyboard_M
	.global joy0state
	.global joy1state
	.global cia1Base
	.global cia2Base

	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
IO_reset:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	ldr r0,=cia1Base
	bl m6526Init
	ldr r1,=joy2KeybRead
	str r1,[r0,#ciaPortAReadFunc]
	ldr r1,=joy1KeybRead
	str r1,[r0,#ciaPortBReadFunc]

	ldr r0,=cia2Base
	bl m6526Init
	ldr r1,=SetC64GfxBases
	str r1,[r0,#ciaPortAWriteFunc]

	ldmfd sp!,{lr}
	bx lr
;@----------------------------------------------------------------------------
ciaTodCount:
	.type ciaTodCount STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldr r0,=cia1Base
	bl m6526CountFrames
	ldmfd sp!,{lr}
	ldr r0,=cia2Base
	b m6526CountFrames

;@----------------------------------------------------------------------------
IO_R:		;@ I/O read, 0xD000-0xDFFF
;@----------------------------------------------------------------------------
	cmp addy,#0xD000
	andpl r1,addy,#0xF00
	ldrpl pc,[pc,r1,lsr#6]
	b ram_R
;@---------------------------
// io_read_tbl
	.long VIC_R				;@ 0xD000
	.long VIC_R				;@ 0xD100
	.long VIC_R				;@ 0xD200
	.long VIC_R				;@ 0xD300
	.long sidRead			;@ 0xD400
	.long sidRead			;@ 0xD500
	.long sidRead			;@ 0xD600
	.long sidRead			;@ 0xD700
	.long VIC_ram_R			;@ 0xD800
	.long VIC_ram_R			;@ 0xD800
	.long VIC_ram_R			;@ 0xDA00
	.long VIC_ram_R			;@ 0xDB00
	.long CIA1_R			;@ 0xDC00
	.long CIA2_R			;@ 0xDD00
	.long IO_RES0_R			;@ 0xDE00
	.long IO_RES1_R			;@ 0xDF00

;@----------------------------------------------------------------------------
IO_W:		;@ I/O write, 0xD000-0xDFFF
;@----------------------------------------------------------------------------
	cmp addy,#0xD000
	andpl r1,addy,#0xF00
	ldrpl pc,[pc,r1,lsr#6]
	b ram_W
;@---------------------------
// io_read_tbl
	.long VIC_W				;@ 0xD000
	.long VIC_W				;@ 0xD100
	.long VIC_W				;@ 0xD200
	.long VIC_W				;@ 0xD300
	.long sidWrite			;@ 0xD400
	.long sidWrite			;@ 0xD500
	.long sidWrite			;@ 0xD600
	.long sidWrite			;@ 0xD700
	.long VIC_ram_W			;@ 0xD800
	.long VIC_ram_W			;@ 0xD900
	.long VIC_ram_W			;@ 0xDA00
	.long VIC_ram_W			;@ 0xDB00
	.long CIA1_W			;@ 0xDC00
	.long CIA2_W			;@ 0xDD00
	.long IO_RES0_W			;@ 0xDE00
	.long IO_RES1_W			;@ 0xDF00

;@----------------------------------------------------------------------------
CIA1_R:
	ldr r2,=cia1Base
	b m6526Read
;@----------------------------------------------------------------------------
CIA1_W:
	ldr r2,=cia1Base
	b m6526Write
;@----------------------------------------------------------------------------
CIA2_R:
	ldr r2,=cia2Base
	b m6526Read
;@----------------------------------------------------------------------------
CIA2_W:
	ldr r2,=cia2Base
	b m6526Write

;@----------------------------------------------------------------------------
VIC_ram_R:
;@----------------------------------------------------------------------------
	mov r1,addy,lsl#22
	sub r2,m6502zpage,#0x400
	ldrb r0,[r2,r1,lsr#22]
	bx lr
;@----------------------------------------------------------------------------
IO_RES0_R:
;@----------------------------------------------------------------------------
IO_RES1_R:
;@----------------------------------------------------------------------------
	mov r11,r11
	mov r0,#0x10
	bx lr

;@----------------------------------------------------------------------------
VIC_ram_W:
;@----------------------------------------------------------------------------
	mov r1,addy,lsl#22
	sub r2,m6502zpage,#0x400
	and r0,r0,#0xF
	strb r0,[r2,r1,lsr#22]
	bx lr
;@----------------------------------------------------------------------------

;@----------------------------------------------------------------------------
IO_RES0_W:
;@----------------------------------------------------------------------------
IO_RES1_W:
;@----------------------------------------------------------------------------
	mov r11,r11
	mov r0,#0xFF
	bx lr

;@----------------------------------------------------------------------------
joy2KeybRead:				;@ 0xDC00 Joy2/Keyboard, r2 = cia
;@----------------------------------------------------------------------------
	ldrb r0,joy0state
//	ldrb r0,[r2,#ciaDataDirA]
	eor r0,r0,#0xFF
	bx lr
;@----------------------------------------------------------------------------
joy1KeybRead:				;@ 0xDC01 Joy1/Keyboard, r2 = cia
;@----------------------------------------------------------------------------
	ldrb r2,[r2,#ciaDataPortA]
	eor r2,r2,#0xFF
	adr addy,Keyboard_M
	mov r0,#0xFF
portBLoop:
	movs r2,r2,lsr#1
	ldrcsb r1,[addy]
	andcs r0,r0,r1
	add addy,addy,#1
	bne portBLoop
	ldrb r1,joy1state
	eor r1,r1,#0xFF
	and r0,r0,r1

	bx lr
;@----------------------------------------------------------------------------
refreshEMUjoypads:			;@ Call every frame
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
		ldr r4,=frameTotal
		ldr r4,[r4]
		movs r0,r4,lsr#2		;@ C=frame&2 (autofire alternates every other frame)
	ldr r4,EMUinput
	and r0,r4,#0xF0
		ldr r2,joyCfg
		andcs r4,r4,r2
		movcss addy,r4,lsr#10	;@ L?
		andcs r4,r4,r2,lsr#16
	adr addy,rlud2udlr
	ldrb r0,[addy,r0,lsr#4]		;@ downupleftright
	tst r4,#0x02				;@ B
	orrne r0,r0,#0x10			;@ C64 fire button
	mov r1,#0
	tst r2,#0x20000000
	movne r1,r0
	movne r0,#0
	strb r0,joy1state
	strb r1,joy0state

	ldmfd sp!,{r4,lr}
	bx lr

;@----------------------------------------------------------------------------
SetC64Key:			;@ r0=x,r1=y,r2=touch.
	.type SetC64Key STT_FUNC
;@----------------------------------------------------------------------------
	adr r3,Keyboard_M			;@ Clear Keyboard Matrix
	mov r12,#-1
	str r12,[r3]
	str r12,[r3,#4]

	cmp r2,#0
	bxeq lr
	sub r1,r1,#0xD
	movs r1,r1,asr#1			;@ Y ready.
	bxmi lr
	cmp r1,#5
	bxpl lr

	add r1,r0,r1,lsl#5

	adr r2,VKB_Array
	ldrb r0,[r2,r1]
	mov r0,r0,lsl#1
	adr r2,Keyb_trans
	ldrh r1,[r2,r0]
	adr r2,Keyboard_M
	ldrb r0,[r2,r1,lsr#8]
	bic r0,r0,r1
	strb r0,[r2,r1,lsr#8]

	bx lr

;@----------------------------------------------------------------------------
joyCfg: .long 0x00ff01ff	;@ byte0=auto mask, byte1=(saves R), byte2=R auto mask
							;@ bit 31=single/multi, 30,29=1P/2P, 27=(multi) link active, 24=reset signal received
EMUinput:			;@ This label here for main.c to use
	.long 0			;@ EMUjoypad (this is what Emu sees)

mytouch_x:
	.long 0
mytouch_y:
	.long 0
mytouch_press:
	.long 0
keyb_pos:
	.long 0

joy0state:
	.byte 0
joy1state:
	.byte 0
	.skip 2

rlud2udlr:	.byte 0x00,0x08,0x04,0x0C, 0x01,0x09,0x05,0x0D, 0x02,0x0A,0x06,0x0E, 0x03,0x0B,0x07,0x0F

Keyboard_M:
	.byte 0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF
	.byte 0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF


VKB_Array:
	.byte 0x39,0x39		;@ <-
	.byte 0x38,0x38		;@ 1
	.byte 0x3B,0x3B		;@ 2
	.byte 0x08,0x08		;@ 3
	.byte 0x0B,0x0B		;@ 4
	.byte 0x10,0x10		;@ 5
	.byte 0x13,0x13		;@ 6
	.byte 0x18,0x18		;@ 7
	.byte 0x1B,0x1B		;@ 8
	.byte 0x20,0x20		;@ 9
	.byte 0x23,0x23		;@ 0
	.byte 0x28,0x28		;@ +
	.byte 0x2B,0x2B		;@ -
	.byte 0x30,0x30		;@ pound
	.byte 0x33,0x33		;@ Clr/Home
	.byte 0x00,0x00		;@ Insert/Del

	.byte 0x3A,0x3A,0x3A;@ Ctrl
	.byte 0x3E,0x3E		;@ Q
	.byte 0x09,0x09		;@ W
	.byte 0x0E,0x0E		;@ E
	.byte 0x11,0x11		;@ R
	.byte 0x16,0x16		;@ T
	.byte 0x19,0x19		;@ Y
	.byte 0x1E,0x1E		;@ U
	.byte 0x21,0x21		;@ I
	.byte 0x26,0x26		;@ O
	.byte 0x29,0x29		;@ P
	.byte 0x2E,0x2E		;@ @
	.byte 0x31,0x31		;@ *
	.byte 0x36,0x36		;@ ^
	.byte 0x40,0x40,0x40;@ Restore!!!!! not read by keyboard

	.byte 0x3F,0x3F		;@ Run Stop
	.byte 0x41,0x41		;@ Shift Lock. Extra code for it.
	.byte 0x0A,0x0A		;@ A
	.byte 0x0D,0x0D		;@ S
	.byte 0x12,0x12		;@ D
	.byte 0x15,0x15		;@ F
	.byte 0x1A,0x1A		;@ G
	.byte 0x1D,0x1D		;@ H
	.byte 0x22,0x22		;@ J
	.byte 0x25,0x25		;@ K
	.byte 0x2A,0x2A		;@ L
	.byte 0x2D,0x2D		;@ :
	.byte 0x32,0x32		;@ ;
	.byte 0x35,0x35		;@ =
	.byte 0x01,0x01,0x01,0x01	;@ Return

	.byte 0x3D,0x3D		;@ C=
	.byte 0x0F,0x0F,0x0F;@ Left Shift
	.byte 0x0C,0x0C		;@ Z
	.byte 0x17,0x17		;@ X
	.byte 0x14,0x14		;@ C
	.byte 0x1F,0x1F		;@ V
	.byte 0x1C,0x1C		;@ B
	.byte 0x27,0x27		;@ N
	.byte 0x24,0x24		;@ M
	.byte 0x2F,0x2F		;@ ,
	.byte 0x2C,0x2C		;@ .
	.byte 0x37,0x37		;@ /
	.byte 0x34,0x34,0x34;@ Right Shift
	.byte 0x07,0x07		;@ Down/up
	.byte 0x02,0x02		;@ Right/Left

	.byte 0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40	;@ Empty
	.byte 0x3C,0x3C,0x3C,0x3C,0x3C,0x3C,0x3C,0x3C,0x3C,0x3C,0x3C,0x3C,0x3C,0x3C,0x3C	;@ Space
	.byte 0x04,0x04		;@ F1
	.byte 0x05,0x05		;@ F3
	.byte 0x06,0x06		;@ F5
	.byte 0x03,0x03		;@ F7
	
	.align 4

Keyb_trans:	;@ Which row and bit should be affected.
	.short 0x0001,0x0002,0x0004,0x0008,0x0010,0x0020,0x0040,0x0080
	.short 0x0101,0x0102,0x0104,0x0108,0x0110,0x0120,0x0140,0x0180
	.short 0x0201,0x0202,0x0204,0x0208,0x0210,0x0220,0x0240,0x0280
	.short 0x0301,0x0302,0x0304,0x0308,0x0310,0x0320,0x0340,0x0380
	.short 0x0401,0x0402,0x0404,0x0408,0x0410,0x0420,0x0440,0x0480
	.short 0x0501,0x0502,0x0504,0x0508,0x0510,0x0520,0x0540,0x0580
	.short 0x0601,0x0602,0x0604,0x0608,0x0610,0x0620,0x0640,0x0680
	.short 0x0701,0x0702,0x0704,0x0708,0x0710,0x0720,0x0740,0x0780
	.short 0x0000,0x0880,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000

;@----------------------------------------------------------------------------

#ifdef NDS
	.section .dtcm, "ax", %progbits				;@ For the NDS
#elif GBA
	.section .iwram, "ax", %progbits			;@ For the GBA
#else
	.section .text
#endif
	.align 2

cia1Base:
	.skip m6526Size
cia2Base:
	.skip m6526Size

;@----------------------------------------------------------------------------

	.end
#endif // #ifdef __arm__
