#include "equates.h"
#include "memory.h"
#include "ARM6502/M6502.i"

	.global IO_reset
	.global IO_R
	.global IO_W
	.global CIA1_TOD_Base
	.global CIA2_TOD_Base
	.global ManageInput
	.global CalibrateTouch
	.global SetC64Key

	.global EMUinput
	.global joyCfg
	.global mytouch_x
	.global mytouch_y
	.global mytouch_press
	.global ntr_pad_current
	.global ntr_pad_down
	.global ntr_pad_up
	.global keyb_pos

	.section .text
	.align 2
;@----------------------------------------------------------------------------
IO_reset:
;@----------------------------------------------------------------------------
	mov r0,#0
	add r2,r10,#cia_base_offset
	mov r1,#47
cialoop:
	strb r0,[r2,r1]
	subs r1,r1,#1
	bpl cialoop
	strb r0,[r10,#cia1irq]

	mov r0,#0x01				;@ TimerA1 enabled?
	strb r0,[r10,#cia1irqctrl]
	mov r0,#-1
	str r0,[r10,#timer1a]
	str r0,[r10,#timer1b]
	str r0,[r10,#timer2a]
	str r0,[r10,#timer2b]

	bx lr
;@----------------------------------------------------------------------------
IO_R:		;@ I/O read, 0xD000-0xDFFF
;@----------------------------------------------------------------------------
//	mov r11,r11
	cmp addy,#0xD000
	andpl r1,addy,#0xF00
	ldrpl pc,[pc,r1,lsr#6]
	b ram_R
;@---------------------------
//io_read_tbl
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
//	mov r11,r11
	cmp addy,#0xD000
	andpl r1,addy,#0xF00
	ldrpl pc,[pc,r1,lsr#6]
	b ram_W
;@---------------------------
//io_read_tbl
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
//	mov r11,r11
	and r1,addy,#0xF
	ldr pc,[pc,r1,lsl#2]
;@---------------------------
	.long 0
//cia1_read_tbl
	.long CIA1_PortA_R		;@ 0xDC00
	.long CIA1_PortB_R		;@ 0xDC01
	.long CIA1_empty_R		;@ 0xDC02
	.long CIA1_empty_R		;@ 0xDC03
	.long CIA1_TimerA_L_R	;@ 0xDC04
	.long CIA1_TimerA_H_R	;@ 0xDC05
	.long CIA1_TimerB_L_R	;@ 0xDC06
	.long CIA1_TimerB_H_R	;@ 0xDC07
	.long CIA1_TOD_F_R		;@ 0xDD08
	.long CIA1_TOD_S_R		;@ 0xDD09
	.long CIA1_TOD_M_R		;@ 0xDD0A
	.long CIA1_TOD_H_R		;@ 0xDD0B
	.long CIA1_empty_R		;@ 0xDC0C
	.long CIA1_IRQCTRL_R	;@ 0xDC0D
	.long CIA1_empty_R		;@ 0xDC0E
	.long CIA1_empty_R		;@ 0xDC0F
CIA1_empty_R:
	add r2,r10,#cia1_base_offset
	ldrb r0,[r2,r1]
	bx lr
	ldr r2,=CIA1State
;@----------------------------------------------------------------------------
CIA1_W:
//	mov r11,r11
	and r1,addy,#0xF
	ldr pc,[pc,r1,lsl#2]
;@---------------------------
	.long 0
//cia1_write_tbl
	.long CIA1_empty_W		;@ 0xDC00
	.long CIA1_empty_W		;@ 0xDC01
	.long CIA1_empty_W		;@ 0xDC02
	.long CIA1_empty_W		;@ 0xDC03
	.long CIA1_empty_W		;@ 0xDC04
	.long CIA1_TimerA_H_W	;@ 0xDC05
	.long CIA1_empty_W		;@ 0xDC06
	.long CIA1_TimerB_H_W	;@ 0xDC07
	.long CIA1_TOD_F_W		;@ 0xDC08
	.long CIA1_TOD_S_W		;@ 0xDC09
	.long CIA1_TOD_M_W		;@ 0xDC0A
	.long CIA1_TOD_H_W		;@ 0xDC0B
	.long CIA1_empty_W		;@ 0xDC0C
	.long CIA1_IRQCTRL_W	;@ 0xDC0D
	.long CIA1_CTRLA_W		;@ 0xDC0E
	.long CIA1_CTRLB_W		;@ 0xDC0F
CIA1_empty_W:
	add r2,r10,#cia1_base_offset
	strb r0,[r2,r1]
	bx lr
;@----------------------------------------------------------------------------
CIA2_R:
//	mov r11,r11
	and r1,addy,#0xF
	ldr pc,[pc,r1,lsl#2]
;@---------------------------
	.long 0xC1A20
//cia2_read_tbl
	.long CIA2_empty_R		;@ 0xDD00
	.long CIA2_empty_R		;@ 0xDD01
	.long CIA2_empty_R		;@ 0xDD02
	.long CIA2_empty_R		;@ 0xDD03
	.long CIA2_TimerA_L_R	;@ 0xDD04
	.long CIA2_TimerA_H_R	;@ 0xDD05
	.long CIA2_TimerB_L_R	;@ 0xDD06
	.long CIA2_TimerB_H_R	;@ 0xDD07
	.long CIA2_TOD_F_R		;@ 0xDD08
	.long CIA2_TOD_S_R		;@ 0xDD09
	.long CIA2_TOD_M_R		;@ 0xDD0A
	.long CIA2_TOD_H_R		;@ 0xDD0B
	.long CIA2_empty_R		;@ 0xDD0C
	.long CIA2_empty_R		;@ 0xDD0D
	.long CIA2_empty_R		;@ 0xDD0E
	.long CIA2_empty_R		;@ 0xDD0F
CIA2_empty_R:
	ldr r2,=cia2_base_offset
	add r2,r10,r2
	ldrb r0,[r2,r1]
	bx lr
;@----------------------------------------------------------------------------
CIA2_W:
//	mov r11,r11
	and r1,addy,#0xF
	ldr pc,[pc,r1,lsl#2]
;@---------------------------
	.long 0xC1A21
//cia2_write_tbl
	.long CIA2_PORTA_W		;@ 0xDD00
	.long CIA2_empty_W		;@ 0xDD01
	.long CIA2_empty_W		;@ 0xDD02
	.long CIA2_empty_W		;@ 0xDD03
	.long CIA2_empty_W		;@ 0xDD04
	.long CIA2_empty_W		;@ 0xDD05
	.long CIA2_empty_W		;@ 0xDD06
	.long CIA2_empty_W		;@ 0xDD07
	.long CIA2_TOD_F_W		;@ 0xDD08
	.long CIA2_TOD_S_W		;@ 0xDD09
	.long CIA2_TOD_M_W		;@ 0xDD0A
	.long CIA2_TOD_H_W		;@ 0xDD0B
	.long CIA2_empty_W		;@ 0xDD0C
	.long CIA2_empty_W		;@ 0xDD0D
	.long CIA2_empty_W		;@ 0xDD0E
	.long CIA2_empty_W		;@ 0xDD0F
CIA2_empty_W:
	ldr r2,=cia2_base_offset
	add r2,r10,r2
	strb r0,[r2,r1]
	bx lr

;@----------------------------------------------------------------------------
CIA2_PORTA_W:
;@----------------------------------------------------------------------------
	ldr r2,=cia2_base_offset
	add r2,r10,r2
	strb r0,[r2,r1]
	b SetC64GfxBases
;@----------------------------------------------------------------------------
CIA1_TimerA_H_W:			;@ 0xDC05
;@----------------------------------------------------------------------------
	strb r0,[r10,#cia1timerah]
	ldr r1,[r10,#timer1a]
	tst r1,#0x80000000
	bmi CIA1_Reload_TA
	bx lr
;@----------------------------------------------------------------------------
CIA1_TimerB_H_W:			;@ 0xDC07
;@----------------------------------------------------------------------------
	strb r0,[r10,#cia1timerbh]
	ldr r1,[r10,#timer1b]
	tst r1,#0x80000000
	bmi CIA1_Reload_TB
	bx lr
;@----------------------------------------------------------------------------
CIA1_IRQCTRL_W:				;@ 0xDC0D
;@----------------------------------------------------------------------------
//	mov r11,r11
	ldrb r1,[r10,#cia1irqctrl]
	tst r0,#0x80
	and r2,r0,#0x1F
	biceq r1,r1,r2
	orrne r1,r1,r2
	strb r1,[r10,#cia1irqctrl]
//	b PrepareIRQCheck
	bx lr
;@----------------------------------------------------------------------------
CIA1_CTRLA_W:				;@ 0xDC0E
;@----------------------------------------------------------------------------
	strb r0,[r10,#cia1ctrla]

//	tst r0,#0x01					;@ Timer enable?
//	ldreqb r1,[r10,#cia1irq]
//	biceq r1,r1,#0x01
//	streqb r1,[r10,#cia1irq]

	tst r0,#0x10					;@ Force load?
	bxeq lr
CIA1_Reload_TA:
	ldrb r1,[r10,#cia1timeral]
	ldrb r2,[r10,#cia1timerah]
	orr r1,r1,r2,lsl#8
	str r1,[r10,#timer1a]
	bx lr
;@----------------------------------------------------------------------------
CIA1_CTRLB_W:				;@ 0xDC0F
;@----------------------------------------------------------------------------
	mov r11,r11
	strb r0,[r10,#cia1ctrlb]

	tst r0,#0x10					;@ Force load?
	bxeq lr
CIA1_Reload_TB:
	ldrb r1,[r10,#cia1timerbl]
	ldrb r2,[r10,#cia1timerbh]
	orr r1,r1,r2,lsl#8
	str r1,[r10,#timer1b]
	bx lr

;@----------------------------------------------------------------------------
CIA1_PortA_R:				;@ 0xDC00 Joy2/Keyboard
;@----------------------------------------------------------------------------
//	mov r11,r11					;@ No$GBA debugg
	ldr r0,joy0state
//	ldrb r0,[r10,#cia1ddra]
	eor r0,r0,#0xFF
	bx lr
;@----------------------------------------------------------------------------
CIA1_PortB_R:				;@ 0xDC01 Joy1/Keyboard
;@----------------------------------------------------------------------------
//	mov r11,r11					;@ No$GBA debugg
	ldrb r2,[r10,#cia1porta]
	eor r2,r2,#0xFF
	adr addy,Keyboard_M
	mov r0,#0xFF
cia1portbloop:
	movs r2,r2,lsr#1
	ldrcsb r1,[addy]
	andcs r0,r0,r1
	add addy,addy,#1
	bne cia1portbloop
	ldr r1,joy1state
	eor r1,r1,#0xFF
	and r0,r0,r1

	bx lr
;@----------------------------------------------------------------------------
CIA1_TimerA_L_R:			;@ 0xDC04
;@----------------------------------------------------------------------------
	ldrb r0,[r10,#timer1a]
	bx lr
;@----------------------------------------------------------------------------
CIA1_TimerA_H_R:			;@ 0xDC05
;@----------------------------------------------------------------------------
	ldr r0,[r10,#timer1a]
	mov r0,r0,lsr#8
	and r0,r0,#0xFF
	bx lr
;@----------------------------------------------------------------------------
CIA1_TimerB_L_R:			;@ 0xDC06
;@----------------------------------------------------------------------------
	ldrb r0,[r10,#timer1b]
	bx lr
;@----------------------------------------------------------------------------
CIA1_TimerB_H_R:			;@ 0xDC07
;@----------------------------------------------------------------------------
	ldr r0,[r10,#timer1b]
	mov r0,r0,lsr#8
	and r0,r0,#0xFF
	bx lr
;@----------------------------------------------------------------------------
CIA1_IRQCTRL_R:				;@ 0xDC0D
;@----------------------------------------------------------------------------
//	mov r11,r11
	ldrb r0,[r10,#cia1irqctrl]
	ldrb r1,[r10,#cia1irq]
	ands r0,r0,r1
	orrne r0,r0,#0x80
	mov r1,#0
	strb r1,[r10,#cia1irq]
	bx lr
;@----------------------------------------------------------------------------
CIA2_TimerA_L_R:			;@ 0xDD04
;@----------------------------------------------------------------------------
	ldrb r0,[r10,#timer2a]
	bx lr
;@----------------------------------------------------------------------------
CIA2_TimerA_H_R:			;@ 0xDD05
;@----------------------------------------------------------------------------
	ldr r0,[r10,#timer2a]
	mov r0,r0,lsr#8
	and r0,r0,#0xFF
	bx lr
;@----------------------------------------------------------------------------
CIA2_TimerB_L_R:			;@ 0xDD06
;@----------------------------------------------------------------------------
	ldrb r0,[r10,#timer2b]
	bx lr
;@----------------------------------------------------------------------------
CIA2_TimerB_H_R:			;@ 0xDD07
;@----------------------------------------------------------------------------
	ldr r0,[r10,#timer2b]
	mov r0,r0,lsr#8
	and r0,r0,#0xFF
	bx lr

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
CalibrateTouch:			;@ (r0=mytouch struct), out x = 0->31, y = 0->23
;@----------------------------------------------------------------------------
	ldr r1,[r0]
	ldr r2,[r0,#4]

	sub r1,r1,#0x140
	ldr r3,=1231355
	mul r1,r3,r1
	mov r1,r1,lsr#24+3			;@ X ready.

	sub r2,r2,#0x0E0
	ldr r3,=875333				;@ for 0 -> 191
	mul r2,r3,r2
	mov r2,r2,lsr#24+3			;@ Y ready.

	str r1,[r0]
	str r2,[r0,#4]

	bx lr
;@----------------------------------------------------------------------------
ManageInput:
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}

	ldr r3,=mytouch_x
	ldr r0,[r3],#4
	ldr r1,[r3],#4
	ldr r2,[r3]

	ldr r3,=keyb_pos
	ldr r3,[r3]
	cmp r3,#0
	bleq SetC64Key



	ldr r4,ntr_pad_current
	mov r0,r4,lsr#4
	and r0,r0,#0x0F
//		ldr r2,joycfg
//		andcs r4,r4,r2
//		movcss addy,r4,lsr#10	;@ L?
//		andcs r4,r4,r2,lsr#16
	adr addy,rlud2udlr
	ldrb r0,[addy,r0]			;@ downupleftright
	tst r4,#0x02
	orrne r0,r0,#0x10			;@ C64 fire button
//	mov r1,#0
//	tst r2,#0x20000000
//	movne r1,r0
//	movne r0,#0
	str r0,joy0state


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
	sub r1,r1,#0xC
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

ntr_pad_current:
	.long 0
ntr_pad_down:
	.long 0
ntr_pad_up:
	.long 0
mytouch_x:
	.long 0
mytouch_y:
	.long 0
mytouch_press:
	.long 0
keyb_pos:
	.long 0

joy0state:
	.long 0
joy1state:
	.long 0

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
					;@ !!! Something MUST be referenced here, otherwise the compiler scraps it !!!
CIA1State:
	.byte 0 ;@ cia1porta
	.byte 0 ;@ cia1portb
	.byte 0 ;@ cia1ddra
	.byte 0 ;@ cia1ddrb
	.byte 0 ;@ cia1timeral
	.byte 0 ;@ cia1timerah
	.byte 0 ;@ cia1timerbl
	.byte 0 ;@ cia1timerbh
CIA1_TOD_Base:
	.byte 0 ;@ cia1tod0
	.byte 0 ;@ cia1tod1
	.byte 0 ;@ cia1tod2
	.byte 0 ;@ cia1tod3
	.byte 0 ;@ cia1sioport
	.byte 0 ;@ cia1irqctrl
	.byte 0 ;@ cia1ctrla
	.byte 0 ;@ cia1ctrlb
	.long 0 ;@ timer1a
	.long 0 ;@ timer1b
CIA2State:
	.byte 0 ;@ cia2porta
	.byte 0 ;@ cia2portb
	.byte 0 ;@ cia2ddra
	.byte 0 ;@ cia2ddrb
	.byte 0 ;@ cia2timeral
	.byte 0 ;@ cia2timerah
	.byte 0 ;@ cia2timerbl
	.byte 0 ;@ cia2timerbh
CIA2_TOD_Base:
	.byte 0 ;@ cia2tod0
	.byte 0 ;@ cia2tod1
	.byte 0 ;@ cia2tod2
	.byte 0 ;@ cia2tod3
	.byte 0 ;@ cia2sioport
	.byte 0 ;@ cia2irqctrl
	.byte 0 ;@ cia2ctrla
	.byte 0 ;@ cia2ctrlb
	.long 0 ;@ timer2a
	.long 0 ;@ timer2b

	.byte 0 ;@ cia1irq
	.byte 0 ;@ cia2nmi
	.byte 0
	.byte 0

