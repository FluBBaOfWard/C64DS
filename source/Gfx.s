#include "Shared/nds_asm.h"
#include "equates.h"
#include "memory.h"
#include "ARM6502/M6502mac.h"

	.global vblIrqHandler
	.global gfxInit
	.global gfxReset
	.global VIC_R
	.global VIC_W
	.global newframe
	.global endframe
	.global RenderLine
	.global SetC64GfxBases

	.global VICState
	.global gScaling
	.global gTwitch
	.global gFlicker
	.global gGfxMask
	.global EMUPALBUFF
	.global tile_base
	.global obj_base

	.section .text
	.align 2
;@----------------------------------------------------------------------------
gfxInit:	;@ (called from main.c) only need to call once
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	mov r0,#NTR_VRAM
	mov r1,#0
	mov r2,#0x8000
	bl memset_					;@ Clear
	
	ldr r0,=obj_base
	ldr r0,[r0]
	mov r2,#0x8000
	bl memset_					;@ Clear all Main VRAM

	ldr r0,=obj_buf_ptr0
	ldr r1,=obj_buffer0
	str r1,[r0],#4
	add r1,r1,#128*8
	str r1,[r0]

	ldr r0,=scroll_ptr0
	ldr r1,=scroll_buffer0
	str r1,[r0],#4
	add r1,r1,#256
	str r1,[r0]

	ldr r1,=tile_base
	ldr r1,[r1]
	add r1,r1,#0x1000		;@ Offset the background so we have space for a tilemaped mode.
	ldr r0,=bg2_ptr0
	str r1,[r0],#4
	add r1,r1,#0x20000
	str r1,[r0]

	mov r2,#0xffffff00		;@ Build bg tile decode tbl
	ldr r3,=chr_decode
ppi0:
	mov r0,#0
	tst r2,#0x01
	orrne r0,r0,#0x10000000
	tst r2,#0x02
	orrne r0,r0,#0x01000000
	tst r2,#0x04
	orrne r0,r0,#0x00100000
	tst r2,#0x08
	orrne r0,r0,#0x00010000
	tst r2,#0x10
	orrne r0,r0,#0x00001000
	tst r2,#0x20
	orrne r0,r0,#0x00000100
	tst r2,#0x40
	orrne r0,r0,#0x00000010
	tst r2,#0x80
	orrne r0,r0,#0x00000001
	str r0,[r3],#4
	adds r2,r2,#1
	bne ppi0

	mov r2,#0xffffff00		;@ Build bg tile decode tbl
	ldr r3,=chr_decode_2
ppi2:
	and r0,r2,#0x00000003
	mov r0,r0,lsl#24
	and r12,r2,#0x0000000C
	orr r0,r0,r12,lsl#14
	and r12,r2,#0x00000030
	orr r0,r0,r12,lsl#4
	and r12,r2,#0x000000C0
	orr r0,r0,r12,lsr#6
	orr r0,r0,r0,lsl#4
	str r0,[r3],#4
	adds r2,r2,#1
	bne ppi2

	mov r2,#0xffffff00		;@ Build bg tile decode tbl
	ldr r3,=chr_decode_3
ppi3:
	mov r0,#0
	mov r1,#0
	tst r2,#0x10
	orrne r0,r0,#0x01000000
	tst r2,#0x20
	orrne r0,r0,#0x00010000
	tst r2,#0x40
	orrne r0,r0,#0x00000100
	tst r2,#0x80
	orrne r0,r0,#0x00000001
	tst r2,#0x01
	orrne r1,r1,#0x01000000
	tst r2,#0x02
	orrne r1,r1,#0x00010000
	tst r2,#0x04
	orrne r1,r1,#0x00000100
	tst r2,#0x08
	orrne r1,r1,#0x00000001
	stmia r3!,{r0-r1}
	adds r2,r2,#1
	bne ppi3

	mov r2,#0xffffff00		;@ Build bg tile decode tbl
	ldr r3,=chr_decode_4
ppi4:
	mov r0,#0
	mov r1,#0
	and r12,r2,#0x00000030
	orr r0,r0,r12,lsl#20
	orr r0,r0,r12,lsl#12
	and r12,r2,#0x000000C0
	orr r0,r0,r12,lsl#2
	orr r0,r0,r12,lsr#6
	and r12,r2,#0x00000003
	orr r1,r1,r12,lsl#24
	orr r1,r1,r12,lsl#16
	and r12,r2,#0x0000000C
	orr r1,r1,r12,lsl#6
	orr r1,r1,r12,lsr#2
	stmia r3!,{r0-r1}
	adds r2,r2,#1
	bne ppi4

//	mov r2,#0xffffff00		;@ Build bg tile decode tbl
//	ldr r3,=chr_decode_new
//ppi5:
//	mov r0,#0
//	mov r1,#0
//	and r12,r2,#0x00000030
//	orr r0,r0,r12,lsl#20
//	orr r0,r0,r12,lsl#12
//	and r12,r2,#0x000000C0
//	orr r0,r0,r12,lsl#2
//	orr r0,r0,r12,lsr#6
//	and r12,r2,#0x00000003
//	orr r1,r1,r12,lsl#24
//	orr r1,r1,r12,lsl#16
//	and r12,r2,#0x0000000C
//	orr r1,r1,r12,lsl#6
//	orr r1,r1,r12,lsr#2
//	stmia r3!,{r0-r1}
//	adds r2,r2,#1
//	bne ppi5

	ldmfd sp!,{lr}
	bx lr
;@----------------------------------------------------------------------------
gfxReset:	;@ Called with CPU reset
;@----------------------------------------------------------------------------
	str lr,[sp,#-4]!

//	mov r1,#0
//	str r1,windowtop
//	strb r1,ystart

//	ldr r0,=gfxstate
//	mov r2,#5				;@ 5*4
//	bl memset_				;@ Clear GFX regs

//	mov r0,#1
//	strb r0,sprmemreload

//	mov r0,#-1
//	strb r0,oldchrbase

	mov r1,#REG_BASE
	mov r0,#0x0140			;@ X-delta
	strh r0,[r1,#REG_BG2PA]
//	mov r0,#0x0001			;@ X-delta
	mov r0,#0x0028			;@ X-delta
	strh r0,[r1,#REG_BG3PA]
	ldr r0,=0x010B			;@ Y-delta
	strh r0,[r1,#REG_BG2PD]
	strh r0,[r1,#REG_BG3PD]

	mov r3,#0x0410
	strh r3,[r1,#REG_BLDCNT]		;@ OBJ blend to BG0
	mov r3,#0x1000					;@ BG0=16, OBJ=0
	strh r3,[r1,#REG_BLDALPHA]		;@ Alpha values

//	mov r0,#AGB_OAM
//	mov r1,#0x2c0
//	mov r2,#0x100
//	bl memset_		;@ No stray sprites please
//	ldr r0,=obj_buffer0
//	mov r2,#0x180
//	bl memset_

	bl BorderInit
//	bl InitBGTiles
	bl SpriteScaleInit
	bl paletteinit	;@ do palette mapping
	ldr pc,[sp],#4

;@----------------------------------------------------------------------------
BorderInit:
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r5,lr}
	ldr r5,=tile_base
	ldr r5,[r5]
	mov r0,#64			;@ First free tile after map
	mov r1,#66			;@ First border tile
	orr r2,r1,#0x0400	;@ X flip
	mov r3,#25
border_loop:
	strh r1,[r5],#0x2
	mov r4,#30
border_loop_2:
	strh r0,[r5],#0x2
	subs r4,r4,#1
	bne border_loop_2
	strh r2,[r5],#0x02
	add r1,r1,#1
	add r2,r2,#1
	subs r3,r3,#1
	bne border_loop

	ldmfd sp!,{r4-r5,lr}
	bx lr
;@----------------------------------------------------------------------------
paletteinit:	;@ r0-r3 modified.
//called by ui.c:  void map_palette(char gammavalue)
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r7,lr}

	adr r7,C64_Palette
	ldr r6,=c64_palette_mod
//	ldrb r1,gammavalue	;@ Gamma value = 0 -> 4
	mov r1,#1			;@ Gamma value = 0 -> 4
	mov r4,#15			;@
nomap:					;@ Map rrrrrrrrggggggggbbbbbbbb  ->  0bbbbbgggggrrrrr
	ldrb r0,[r7],#1
	bl gammaconvert
	mov r5,r0

	ldrb r0,[r7],#1
	bl gammaconvert
	orr r5,r5,r0,lsl#5

	ldrb r0,[r7],#1
	bl gammaconvert
	orr r5,r5,r0,lsl#10

	strh r5,[r6],#2
	subs r4,r4,#1
	bpl nomap

	ldmfd sp!,{r4-r7,lr}
	bx lr

;@----------------------------------------------------------------------------
C64_Palette:
	.byte 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0x89, 0x40, 0x36, 0x7A, 0xBF, 0xC7, 0x8A, 0x46, 0xAE, 0x68
	.byte 0xA9, 0x41, 0x3E, 0x31, 0xA2, 0xD0, 0xDC, 0x71, 0x90, 0x5F, 0x25, 0x5C, 0x47, 0x00, 0xBB, 0x77
	.byte 0x6D, 0x55, 0x55, 0x55, 0x80, 0x80, 0x80, 0xAC, 0xEA, 0x88, 0x7C, 0x70, 0xDA, 0xAB, 0xAB, 0xAB
;@----------------------------------------------------------------------------
gprefix:
	orr r0,r0,r0,lsr#4
;@----------------------------------------------------------------------------
gammaconvert:	;@ Takes value in r0(0-0xFF), gamma in r1(0-4),returns new value in r0=0x1F
;@----------------------------------------------------------------------------
	rsb r2,r0,#0x100
	mul r3,r2,r2
	rsbs r2,r3,#0x10000
	rsb r3,r1,#4
	orr r0,r0,r0,lsl#8
	mul r2,r1,r2
	mla r0,r3,r0,r2
	mov r0,r0,lsr#13

	bx lr

;@----------------------------------------------------------------------------
scaleparms:
	.long 0x0000,0x0138,0x0100,0x009C,0x0080,obj_buffer0+6
;@----------------------------------------------------------------------------
SpriteScaleInit:
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6}
	adr r5,scaleparms		;@ Set sprite scaling params
	ldmia r5,{r0-r5}

	mov r6,#2
scaleloop:
	strh r1,[r5],#8				;@ Buffer1, buffer2. normal sprites
	strh r0,[r5],#8
	strh r0,[r5],#8
	strh r2,[r5],#8
		strh r3,[r5],#8			;@ Horizontaly expanded sprites
		strh r0,[r5],#8
		strh r0,[r5],#8
		strh r2,[r5],#8
			strh r1,[r5],#8			;@ Verticaly expanded sprites
			strh r0,[r5],#8
			strh r0,[r5],#8
			strh r4,[r5],#8
				strh r3,[r5],#8		;@ Double sprites
				strh r0,[r5],#8
				strh r0,[r5],#8
				strh r4,[r5],#136
		add r5,r5,#0x300
	subs r6,r6,#1
	bne scaleloop
	ldmfd sp!,{r4-r6}
	bx lr

;@----------------------------------------------------------------------------
vblIrqHandler:
	.type vblIrqHandler STT_FUNC
;@----------------------------------------------------------------------------
	;@ r0 = address of ula memory

	stmdb sp!,{r4-r11,lr}  ;@ save registers on stack


	ldr r6,gFlicker
	eors r6,r6,r6,lsl#31
	str r6,gFlicker

	ldr r3,=scroll_ptr1
	ldr r3,[r3]
	ldr r4,=dma_buffer0
	
	ldr r1,=0x010B			;@ Y-delta
	mov r5,#0
	moveq r5,#0x000B
//	mov r7,r5				;@ Y-Offset
	mov r8,#0
	moveq r8,#0x0040
	mov r2,#192
loop0:
	ldrb r0,[r3,r5,lsr#8]
	sub r0,r8,r0,lsl#8
	str r0,[r4],#4
//	str r5,[r4],#4
//	mov r0,r0,asr#3
//	str r0,[r4],#4
	add r5,r5,r1
	subs r2,r2,#1
	bne loop0

	ldr r2,=pal_buffer
	ldr r3,=BG_PALETTE
	mov r4,#512
loop1:
	ldr r0,[r2],#4
	str r0,[r3],#4
	subs r4,r4,#2
	bne loop1

	mov r12,#REG_BASE
	tst r6,#0x80000000
	mov r0,#0x0B00							;@ 11 pixels offset.
	addeq r0,r0,#0x000B
	strh r0,[r12,#REG_BG2Y]
	strh r0,[r12,#REG_BG3Y]
	mov r0,#0x14000							;@ 320<<8
	addeq r0,r0,#0x00008
	str r0,[r12,#REG_BG3X]

	ldr r0,=bg2_ptr1
	ldr r0,[r0]
	and r0,r0,#0x20000
	ldrh r1,[r12,#REG_BG2CNT]				;@ Switch bg2 buffers
	bic r1,r1,#0x800
	orr r1,r1,r0,lsr#6
	strh r1,[r12,#REG_BG2CNT]
	strh r1,[r12,#REG_BG3CNT]

	mov r0,#0
	str r0,[r12,#REG_DMA2CNT]				;@ Stop DMA2

	ldr r1,=obj_buf_ptr1
	ldr r1,[r1]
	ldr r2,=0x07000000
	ldr r3,=0x84000100
	str r1,[r12,#REG_DMA3SAD]
	str r2,[r12,#REG_DMA3DAD]
	str r3,[r12,#REG_DMA3CNT]			;@ DMA3 Go!

	ldr r1,=dma_buffer0
	add r2,r12,#REG_BG2HOFS
	ldr r3,=0x96600001						;@ 1 word(s)
	ldr r0,[r1],#4							;@ Change this if you change number of words transfered!
	str r0,[r2]
	str r1,[r12,#REG_DMA2SAD]
	str r2,[r12,#REG_DMA2DAD]
	str r3,[r12,#REG_DMA2CNT]				;@ DMA2 Go!


;@----------------- GUI screen -------------------
	add r12,r12,#0x1000							;@ SUB gfx
//	ldr r0,=film_pos
	ldr r0,=0
	strh r0,[r12,#REG_BG0VOFS]
	ldr r0,=keyb_pos
	ldr r0,[r0]
	strh r0,[r12,#REG_BG1VOFS]

	blx scanKeys
	ldmia sp!,{r4-r11,pc}

;@----------------------------------------------------------------------------
gFlicker:		.byte 1
				.space 2
gTwitch:		.byte 0

gScaling:		.byte SCALED
gGfxMask:		.byte 0
yStart:			.byte 0
				.byte 0
;@----------------------------------------------------------------------------
	.pool
;@----------------------------------------------------------------------------
VIC_R:
;@----------------------------------------------------------------------------
	and r1,addy,#0x3F
	cmp r1,#0x2F
	ldrmi pc,[pc,r1,lsl#2]
;@---------------------------
	b VIC_empty_R
;@ VIC_read_tbl
	.long VIC_default_R		;@ 0xD000
	.long VIC_default_R		;@ 0xD001
	.long VIC_default_R		;@ 0xD002
	.long VIC_default_R		;@ 0xD003
	.long VIC_default_R		;@ 0xD004
	.long VIC_default_R		;@ 0xD005
	.long VIC_default_R		;@ 0xD006
	.long VIC_default_R		;@ 0xD007
	.long VIC_default_R		;@ 0xD008
	.long VIC_default_R		;@ 0xD009
	.long VIC_default_R		;@ 0xD00A
	.long VIC_default_R		;@ 0xD00B
	.long VIC_default_R		;@ 0xD00C
	.long VIC_default_R		;@ 0xD00D
	.long VIC_default_R		;@ 0xD00E
	.long VIC_default_R		;@ 0xD00F
	.long VIC_default_R		;@ 0xD010
	.long VIC_ctrl1_R		;@ 0xD011
	.long VIC_scanline_R	;@ 0xD012
	.long VIC_default_R		;@ 0xD013
	.long VIC_default_R		;@ 0xD014
	.long VIC_default_R		;@ 0xD015
	.long VIC_ctrl2_R		;@ 0xD016
	.long VIC_default_R		;@ 0xD017
	.long VIC_memctrl_R		;@ 0xD018
	.long VIC_irqflag_R		;@ 0xD019
	.long VIC_irqenable_R	;@ 0xD01A
	.long VIC_default_R		;@ 0xD01B
	.long VIC_default_R		;@ 0xD01C
	.long VIC_default_R		;@ 0xD01D
	.long VIC_default_R		;@ 0xD01E
	.long VIC_default_R		;@ 0xD01F
	.long VIC_palette_R		;@ 0xD020
	.long VIC_palette_R		;@ 0xD021
	.long VIC_palette_R		;@ 0xD022
	.long VIC_palette_R		;@ 0xD023
	.long VIC_palette_R		;@ 0xD024
	.long VIC_palette_R		;@ 0xD025
	.long VIC_palette_R		;@ 0xD026
	.long VIC_palette_R		;@ 0xD027
	.long VIC_palette_R		;@ 0xD028
	.long VIC_palette_R		;@ 0xD029
	.long VIC_palette_R		;@ 0xD02A
	.long VIC_palette_R		;@ 0xD02B
	.long VIC_palette_R		;@ 0xD02C
	.long VIC_palette_R		;@ 0xD02D
	.long VIC_palette_R		;@ 0xD02E

VIC_default_R:
	add r2,r10,#vic_base_offset
	ldrb r0,[r2,r1]
	bx lr

	ldr r2,=VICState			;@ This is needed for the compiler!

;@----------------------------------------------------------------------------
VIC_ctrl1_R:		;@ 0xD011
;@----------------------------------------------------------------------------
	ldr r1,[r10,#scanline]
	and r1,r1,#0x100
	ldrb r0,[r10,#vicctrl1]
	and r0,r0,#0x7F
	orr r0,r0,r1,lsr#1
	bx lr
;@----------------------------------------------------------------------------
VIC_scanline_R:		;@ 0xD012
;@----------------------------------------------------------------------------
	ldrb r0,[r10,#scanline]
	bx lr
;@----------------------------------------------------------------------------
VIC_ctrl2_R:		;@ 0xD016
;@----------------------------------------------------------------------------
	ldrb r0,[r10,#vicctrl2]
	orr r0,r0,#0xC0
	bx lr
;@----------------------------------------------------------------------------
VIC_memctrl_R:		;@ 0xD018
;@----------------------------------------------------------------------------
	ldrb r0,[r10,#vicmemctrl]
	orr r0,r0,#0x01
	bx lr
;@----------------------------------------------------------------------------
VIC_irqflag_R:		;@ 0xD019
;@----------------------------------------------------------------------------
//	mov r11,r11
	ldrb r0,[r10,#vicirqflag]
	ands r0,r0,#0x0F
	orrne r0,r0,#0x80
	orr r0,r0,#0x70
	bx lr
;@----------------------------------------------------------------------------
VIC_irqenable_R:	;@ 0xD01A
;@----------------------------------------------------------------------------
	ldrb r0,[r10,#vicirqenable]
	orr r0,r0,#0xF0
	bx lr
;@----------------------------------------------------------------------------
VIC_palette_R:		;@ 0xD020 -> 0xD02E
;@----------------------------------------------------------------------------
	add r2,r10,#vic_base_offset
	ldrb r0,[r2,r1]
	orr r0,r0,#0xF0
	bx lr
;@----------------------------------------------------------------------------
VIC_empty_R:		;@ 0xD02F -> 0xD03F
;@----------------------------------------------------------------------------
	mov r0,#0xFF
	bx lr

;@----------------------------------------------------------------------------
VIC_W:
;@----------------------------------------------------------------------------
	and r1,addy,#0x3F
	cmp r1,#0x2F
	ldrmi pc,[pc,r1,lsl#2]
;@---------------------------
	bx lr
//VIC_write_tbl
	.long VIC_default_W		;@ 0xD000
	.long VIC_default_W		;@ 0xD001
	.long VIC_default_W		;@ 0xD002
	.long VIC_default_W		;@ 0xD003
	.long VIC_default_W		;@ 0xD004
	.long VIC_default_W		;@ 0xD005
	.long VIC_default_W		;@ 0xD006
	.long VIC_default_W		;@ 0xD007
	.long VIC_default_W		;@ 0xD008
	.long VIC_default_W		;@ 0xD009
	.long VIC_default_W		;@ 0xD00A
	.long VIC_default_W		;@ 0xD00B
	.long VIC_default_W		;@ 0xD00C
	.long VIC_default_W		;@ 0xD00D
	.long VIC_default_W		;@ 0xD00E
	.long VIC_default_W		;@ 0xD00F
	.long VIC_default_W		;@ 0xD010
	.long VIC_ctrl1_W		;@ 0xD011
	.long VIC_default_W		;@ 0xD012
	.long VIC_default_W		;@ 0xD013
	.long VIC_default_W		;@ 0xD014
	.long VIC_default_W		;@ 0xD015
	.long VIC_ctrl2_W		;@ 0xD016
	.long VIC_default_W		;@ 0xD017
	.long VIC_memctrl_W		;@ 0xD018
	.long VIC_irqflag_W		;@ 0xD019
	.long VIC_default_W		;@ 0xD01A
	.long VIC_default_W		;@ 0xD01B
	.long VIC_default_W		;@ 0xD01C
	.long VIC_default_W		;@ 0xD01D
	.long VIC_default_W		;@ 0xD01E
	.long VIC_default_W		;@ 0xD01F
	.long VIC_default_W		;@ 0xD020
	.long VIC_default_W		;@ 0xD021
	.long VIC_default_W		;@ 0xD022
	.long VIC_default_W		;@ 0xD023
	.long VIC_default_W		;@ 0xD024
	.long VIC_default_W		;@ 0xD025
	.long VIC_default_W		;@ 0xD026
	.long VIC_default_W		;@ 0xD027
	.long VIC_default_W		;@ 0xD028
	.long VIC_default_W		;@ 0xD029
	.long VIC_default_W		;@ 0xD02A
	.long VIC_default_W		;@ 0xD02B
	.long VIC_default_W		;@ 0xD02C
	.long VIC_default_W		;@ 0xD02D
	.long VIC_default_W		;@ 0xD02E


VIC_default_W:
//	mov r11,r11
//	ldr r2,=VICState
	add r2,r10,#vic_base_offset
	strb r0,[r2,r1]
	bx lr


;@----------------------------------------------------------------------------
VIC_ctrl1_W:		;@ 0xD011
;@----------------------------------------------------------------------------
	strb r0,[r10,#vicctrl1]
	b SetC64GfxMode
;@----------------------------------------------------------------------------
VIC_ctrl2_W:		;@ 0xD016
;@----------------------------------------------------------------------------
	stmfd sp!,{r0,r12}
	ldrb r1,[r10,#vicctrl2]
	strb r0,[r10,#vicctrl2]
	and r1,r1,#7

	ldr addy,[r10,#scanline]	;@ addy=scanline
	subs addy,addy,#50
	bmi exit_sx
	cmp addy,#200
	movhi addy,#200
	ldr r0,scrollXline
	cmp r0,addy
	bhi exit_sx
	str addy,scrollXline

	ldr r2,=scroll_ptr0
	ldr r2,[r2]
	add r0,r2,r0
	add r2,r2,addy
sx1:
	strb r1,[r2],#-1			;@ Fill backwards from scanline to lastline
	cmp r2,r0
	bpl sx1
exit_sx:
	ldmfd sp!,{r0,r12}
	b SetC64GfxMode
//	bx lr

scrollXline: .long 0 ;@..was when?
;@----------------------------------------------------------------------------
VIC_memctrl_W:		;@ 0xD018
;@----------------------------------------------------------------------------
	strb r0,[r10,#vicmemctrl]
	b SetC64GfxBases
;@----------------------------------------------------------------------------
VIC_irqflag_W:		;@ 0xD019
;@----------------------------------------------------------------------------
//	mov r11,r11
	ldrb r1,[r10,#vicirqflag]
	bic r1,r1,r0
	strb r1,[r10,#vicirqflag]
	bx lr

;@----------------------------------------------------------------------------
SetC64GfxBases:
;@----------------------------------------------------------------------------
	stmfd sp!,{r0,r12}

	ldrb r0,[r10,#cia2porta]	;@ VIC bank
	eor r0,r0,#0x03
	and r0,r0,#0x03
	ldrb r2,[r10,#vicmemctrl]
	and r1,r2,#0xF0
	orr r1,r1,r0,lsl#8
	add r1,m6502zpage,r1,lsl#6

	ldr r12,=c64_map_base
	str r1,[r12]

	and r1,r2,#0x0E
	orr r0,r1,r0,lsl#4

	and r1,r0,#0x3C
	cmp r1,#0x04				;@ 0x1000
	cmpne r1,#0x24				;@ 0x9000
	ldreq r2,=Chargen			;@ r1 = CHRROM
	movne r2,m6502zpage			;@ r1 = RAM

	bic r1,r0,#0x07
	add r1,r2,r1,lsl#10
	ldr r12,=c64_bmp_base
	str r1,[r12]

	andeq r0,r0,#0x02
	add r1,r2,r0,lsl#10
	ldr r12,=c64_chr_base
	str r1,[r12]

	ldmfd sp!,{r0,r12}
	bx lr
;@----------------------------------------------------------------------------
SetC64GfxMode:
;@----------------------------------------------------------------------------
	stmfd sp!,{r0,r12}

	ldrb r0,[r10,#vicctrl1]		;@ VIC control 1
	ldrb r1,[r10,#vicctrl2]		;@ VIC control 2

	mov r0,r0,lsr#4
	and r0,r0,#0x07
	and r1,r1,#0x10
	orr r0,r0,r1,lsr#1
	adr r1,RenderModeTbl
	ldr r1,[r1,r0,lsl#2]
	str r1,RenderModePtr

	ldmfd sp!,{r0,r12}
	bx lr

RenderModeTbl:
	.long RenderBlankLine
	.long RenderTiles			;@ 1
	.long RenderBlankLine
	.long RenderBmp				;@ 3
	.long RenderBlankLine
	.long RenderTilesECM		;@ 5
	.long RenderBlankLine
	.long RenderBlankLine		;@ 7
	.long RenderBlankLine
	.long RenderTilesMCM		;@ 9
	.long RenderBlankLine
	.long RenderBmpMCM			;@ 11
	.long RenderBlankLine
	.long RenderBlankLine
	.long RenderBlankLine
	.long RenderBlankLine
;@----------------------------------------------------------------------------
newframe:	;@ Called before line 0	(r0-r9 safe to use)
;@----------------------------------------------------------------------------
	mov r0,#-1				;@ Rambo checks for IRQ on line 0
	str r0,[r10,#scanline]	;@ Reset scanline count

	ldr r0,[r10,#frame]
	and r0,r0,#1
	mov r0,r0,lsl#7
	orr r0,r0,r0,lsl#8
	orr r0,r0,r0,lsl#16
	ldr r1,=obj_counter
	str r0,[r1]
	str r0,[r1,#4]


	ldr r1,=obj_buf_ptr0
	ldr r1,[r1]
	mov r0,#0x2c0		;@ Double, y=191
	mov r2,#128
spr_clr_loop:
	str r0,[r1],#8
	subs r2,r2,#1
	bne spr_clr_loop

	mov r0,#0
	str r0,scrollXline
	mov r0,#8
	str r0,line_y_offset
	mov r0,#-8
	str r0,row_y_offset

	bx lr

;@----------------------------------------------------------------------------
endframe:	;@ Called just before screen end (~line 240)	(r0-r2 safe to use)
;@----------------------------------------------------------------------------
	stmfd sp!,{r3-r9,lr}

;@--------------------------
//	bl sprDMA_do
;@--------------------------
	bl PaletteTxAll
;@--------------------------
	ldrb r0,[r10,#vicctrl2]
	bl VIC_ctrl2_W

//	mrs r4,cpsr
//	orr r1,r4,#0x80			;@ --> Disable IRQ.
//	msr cpsr_cf,r1

	ldr r2,=obj_buf_ptr0	;@ Switch obj buffers
	ldmia r2,{r0,r1}
	str r0,[r2,#4]
	str r1,[r2]

	ldr r2,=bg2_ptr0		;@ Switch bg2 buffers
	ldmia r2,{r0,r1}
	str r0,[r2,#4]
	str r1,[r2]

	ldr r2,=scroll_ptr0		;@ Switch scroll buffers
	ldmia r2,{r0,r1}
	str r0,[r2,#4]
	str r1,[r2]

//	mov r0,#1
//	str r0,oambufferready


//	msr cpsr_cf,r4			;@ --> restore mode,Enable IRQ.


	ldmfd sp!,{r3-r9,lr}
	bx lr
;@----------------------------------------------------------------------------
PaletteTxAll:		;@ Called from ui.c
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r7,r10,lr}
	ldr globalptr,=wram_global_base
	ldr r2,=c64_palette_mod
	ldr r3,=pal_buffer
	mov r7,#0x1E
	ldrb r0,[r10,#vicbrdcol]
	and r0,r7,r0,lsl#1
	ldrh r0,[r2,r0]
	strh r0,[r3,#0x1E]		;@ Set sideborder color (plane1)
	strh r0,[r3],#2

	ldrb r4,[r10,#vicbgr1col]
	and r4,r7,r4,lsl#1
	ldrh r4,[r2,r4]
	ldrb r5,[r10,#vicbgr2col]
	and r5,r7,r5,lsl#1
	ldrh r5,[r2,r5]


	mov r1,#0
c64loop1:					;@ Normal BG tile colors
	ldrh r0,[r2,r1]
	strh r4,[r3],#0x02
	strh r5,[r3],#0x02
	strh r0,[r3],#0x1C
	add r1,r1,#2
	cmp r1,#0x20
	bne c64loop1



	ldr r3,=pal_buffer+0x202

	ldrb r4,[r10,#vicsprm0col]
	and r4,r7,r4,lsl#1
	ldrh r4,[r2,r4]
	ldrb r5,[r10,#vicsprm1col]
	and r5,r7,r5,lsl#1
	ldrh r5,[r2,r5]
	ldr r6,=vicspr0col
	add r6,r6,r10

	mov r1,#0
c64loop3:					;@ Sprite colors.
	ldrb r0,[r6],#1
	and r0,r7,r0,lsl#1
	ldrh r0,[r2,r0]
	strh r4,[r3],#0x02
	strh r0,[r3],#0x02
	strh r5,[r3],#0x1C
	add r1,r1,#2
	cmp r1,#0x10
	bne c64loop3

	ldmfd sp!,{r4-r7,r10,lr}
	bx lr

;@----------------------------------------------------------------------------
RenderLine:			;@ r0=?, r1=scanline.
;@----------------------------------------------------------------------------
	stmfd sp!,{r1-r11,lr}
	bl RenderSprites

	subs r1,r1,#0x30			;@ This is where the VIC starts looking for background data.
	bmi exit_line_render
	cmp r1,#208
	bpl exit_line_render
//	cmp r1,#3
//	blpl RenderBorder
	bl RenderBorder

	ldr r9,=bg2_ptr0
	ldr r9,[r9]					;@ Background base-address.
	add r9,r9,r1,lsl#9			;@ Y-offset

	ldr r2,line_y_offset
	ldr r3,row_y_offset
	cmp r2,#8
	bmi no_new_tile_row

	ldrb r0,[r10,#vicctrl1]
	sub r4,r1,r0
	ands r4,r4,#7				;@ Do we have a new tile row?
//	bne no_new_tile_row
	bne RenderBlankLine

	mov r2,r4
	add r3,r3,#8
	str r3,row_y_offset
	ldr r8,[sp,#7*4]
	eatcycles 40
	str r8,[sp,#7*4]
no_new_tile_row:
	add r0,r2,#1
	str r0,line_y_offset
	add r1,r3,r2


	bic r0,r1,#0x07
	and r1,r1,#0x07
	add r0,r0,r0,lsl#2

	ldr pc,RenderModePtr

RenderModePtr:
	.long RenderTiles

exit_line_render:
//	cmp r1,#-1
//	ldreqb r0,[r10,#vicctrl1]
//	andeq r0,r0,#7
//	rsbeq r0,r0,#3
//	streq r0,main_y_offset

	ldmfd sp!,{r1-r11,lr}
	bx lr
row_y_offset:
	.long 0
line_y_offset:
	.long 0
;@----------------------------------------------------------------------------
RenderTiles:
;@----------------------------------------------------------------------------

//	mov r11,r11
	ldr r2,=c64_map_base
	ldr r5,[r2]
	sub r6,m6502zpage,#0x400		;@ Bg colormap
	add r5,r5,r0
	add r6,r6,r0

	ldr r0,=c64_chr_base
	ldr r7,[r0]					;@ Bg tile bitmap
	ldr r12,=chr_decode_3
	add r7,r7,r1

	ldr r11,=0x03030303
	mov lr,#0xFF
	mov r8,#10					;@ Width/4 of C64 screen
bgrdloop:
	ldr r0,[r5],#4				;@ Read from C64 Tilemap RAM
	ldr r1,[r6],#4				;@ Read from C64 Colormap RAM
	orr r1,r11,r1,lsl#4

	and r3,r0,#0x000000FF
	ldrb r3,[r7,r3,lsl#3]		;@ Read bitmap data
	and r10,lr,r1
	add r3,r12,r3,lsl#3

	ldmia r3,{r2,r3}
	mul r4,r2,r10
	mul r10,r3,r10
	stmia r9!,{r4,r10}


	and r3,r0,#0x0000FF00
	ldrb r3,[r7,r3,lsr#5]		;@ Read bitmap data
	and r10,lr,r1,lsr#8
	add r3,r12,r3,lsl#3

	ldmia r3,{r2,r3}
	mul r4,r2,r10
	mul r10,r3,r10
	stmia r9!,{r4,r10}


	and r3,r0,#0x00FF0000
	ldrb r3,[r7,r3,lsr#13]		;@ Read bitmap data
	and r10,lr,r1,lsr#16
	add r3,r12,r3,lsl#3

	ldmia r3,{r2,r3}
	mul r4,r2,r10
	mul r10,r3,r10
	stmia r9!,{r4,r10}


	and r3,r0,#0xFF000000
	ldrb r3,[r7,r3,lsr#21]		;@ Read bitmap data
	mov r10,r1,lsr#24
	add r3,r12,r3,lsl#3

	ldmia r3,{r2,r3}
	mul r4,r2,r10
	mul r10,r3,r10
	stmia r9!,{r4,r10}

	subs r8,r8,#1
	bne bgrdloop

	ldr globalptr,=wram_global_base
	ldrb r0,[r10,#vicbgr0col]	;@ Background color
	and r0,r0,#0x0F
	orr r0,r11,r0,lsl#4
	orr r0,r0,r0,lsl#8
	orr r0,r0,r0,lsl#16
	str r0,[r9],#4
	str r0,[r9],#4
	str r0,[r9],#4
	str r0,[r9],#4
	str r0,[r9],#4
	str r0,[r9],#4
	str r0,[r9],#4
	str r0,[r9],#4
	str r0,[r9],#4
	str r0,[r9],#4

	ldmfd sp!,{r1-r11,lr}
	bx lr

;@----------------------------------------------------------------------------
RenderTilesECM:					;@ ExtendedColorMode
;@----------------------------------------------------------------------------

	ldr r2,=c64_map_base
	ldr r5,[r2]
	sub r6,m6502zpage,#0x400		;@ Bg colormap
	add r5,r5,r0
	add r6,r6,r0

	ldr r0,=c64_chr_base
	ldr r7,[r0]					;@ Bg tile bitmap
	ldr r12,=chr_decode_3
	add r7,r7,r1

	ldrb r0,[r10,#vicbgr0col]!
	add lr,r9,#320

	ldr r11,=0x03030303
	mov r8,#10					;@ Width/4 of C64 screen
bgrdloop1:
	ldr r0,[r5],#4				;@ Read from C64 Tilemap RAM
	ldr r1,[r6],#4				;@ Read from C64 Colormap RAM
	orr r1,r11,r1,lsl#4

	and r3,r0,#0x0000003F
	ldrb r3,[r7,r3,lsl#3]		;@ Read bitmap data
	and r4,r1,#0x000000FF
	add r3,r12,r3,lsl#3

	ldmia r3,{r2,r3}
	mul r2,r4,r2
	mul r4,r3,r4
	stmia r9!,{r2,r4}


	and r3,r0,#0x00003F00
	ldrb r3,[r7,r3,lsr#5]		;@ Read bitmap data
	and r4,r1,#0x0000FF00
	add r3,r12,r3,lsl#3

	ldmia r3,{r2,r3}
	mov r4,r4,lsr#8
	mul r2,r4,r2
	mul r4,r3,r4
	stmia r9!,{r2,r4}


	and r3,r0,#0x003F0000
	ldrb r3,[r7,r3,lsr#13]		;@ Read bitmap data
	and r4,r1,#0x00FF0000
	add r3,r12,r3,lsl#3

	ldmia r3,{r2,r3}
	mov r4,r4,lsr#16
	mul r2,r4,r2
	mul r4,r3,r4
	stmia r9!,{r2,r4}


	and r3,r0,#0x3F000000
	ldrb r3,[r7,r3,lsr#21]		;@ Read bitmap data
	mov r4,r1,lsr#24
	add r3,r12,r3,lsl#3

	ldmia r3,{r2,r3}
	mul r1,r2,r4
	mul r4,r3,r4
	stmia r9!,{r1,r4}


	and r2,r0,#0x000000C0		;@ Background color.
	ldrb r3,[r10,r2,lsr#6]
	and r2,r0,#0x0000C000
	ldrb r2,[r10,r2,lsr#14]
	orr r3,r3,r2,lsl#8
	and r2,r0,#0x00C00000
	ldrb r2,[r10,r2,lsr#22]
	orr r3,r3,r2,lsl#16
	and r2,r0,#0xC0000000
	ldrb r2,[r10,r2,lsr#30]
	orr r3,r3,r2,lsl#24
	orr r3,r11,r3,lsl#4
	bic r3,r3,r11,lsl#2
	str r3,[lr],#4

	subs r8,r8,#1
	bne bgrdloop1

	ldmfd sp!,{r1-r11,lr}
	bx lr
;@----------------------------------------------------------------------------
RenderTilesMCM:					;@ MultiColorMode
;@----------------------------------------------------------------------------

	ldr r2,=c64_map_base
	ldr r5,[r2]
	sub r6,m6502zpage,#0x400		;@ Bg colormap
	add r5,r5,r0
	add r6,r6,r0

	ldr r0,=c64_chr_base
	ldr r7,[r0]					;@ Bg tile bitmap
	ldr lr,=chr_decode_3		;@ Mono
	add r7,r7,r1

	ldr r11,=0x03030300
	ldrb r0,[r10,#vicbgr1col]
	and r0,r0,#0x0F
	orr r11,r11,r0,lsl#12
	ldrb r0,[r10,#vicbgr2col]
	and r0,r0,#0x0F
	orr r11,r11,r0,lsl#20

	mov r12,#0x18
	mov r10,#0xFF
	mov r8,#40					;@ Width of C64 screen
bgrdloop2:
	ldrb r0,[r5],#1				;@ Read from C64 Tilemap RAM
	ldrb r1,[r6],#1				;@ Read from C64 Color RAM (color 3)
	
	bic r11,r11,#0xF0000000
	orrs r11,r11,r1,lsl#28
	bic r11,r11,#0x80000000				;@ Clear multi color bit
	ldrb r0,[r7,r0,lsl#3]				;@ Read bitmap data

	andmi r1,r12,r0,lsr#3
	andmi r3,r10,r11,lsr r1
	andmi r1,r12,r0,lsr#1
	andmi r1,r10,r11,lsr r1
	orrmi r3,r3,r1,lsl#16
	andmi r1,r12,r0,lsl#1
	andmi r4,r10,r11,lsr r1
	andmi r1,r12,r0,lsl#3
	andmi r1,r10,r11,lsr r1
	orrmi r4,r4,r1,lsl#16
	orrmi r3,r3,r3,lsl#8
	orrmi r4,r4,r4,lsl#8

	addpl r0,lr,r0,lsl#3
	ldmplia r0,{r1,r2}
	movpl r4,r11,lsr#24
	mulpl r3,r1,r4
	mulpl r4,r2,r4

	stmia r9!,{r3,r4}

	subs r8,r8,#1
	bne bgrdloop2

	ldr globalptr,=wram_global_base
	ldrb r0,[r10,#vicbgr0col]	;@ Background color
	and r0,r0,#0x0F
	orr r0,r0,#0x30000000
	mov r0,r0,ror#28
	orr r0,r0,r0,lsl#8
	orr r0,r0,r0,lsl#16
	str r0,[r9],#4
	str r0,[r9],#4
	str r0,[r9],#4
	str r0,[r9],#4
	str r0,[r9],#4
	str r0,[r9],#4
	str r0,[r9],#4
	str r0,[r9],#4
	str r0,[r9],#4
	str r0,[r9],#4

	ldmfd sp!,{r1-r11,lr}
	bx lr
;@----------------------------------------------------------------------------
RenderBmp:
;@----------------------------------------------------------------------------
	ldr r2,=c64_map_base
	ldr r5,[r2]
	add r5,r5,r0

	ldr r2,=c64_bmp_base
	ldr r6,[r2]					;@ Bg tile bitmap
	ldr r12,=chr_decode_3
	add r6,r6,r0,lsl#3
	add r6,r6,r1

	add r10,r9,#320

	ldr r7,=0x0F0F0F0F
	ldr r11,=0x03030303
	mov r8,#10					;@ Width/4 of C64 screen
bgrdloop4:
	ldr r0,[r5],#4				;@ Read from C64 Tilemap RAM (color)
	and r1,r0,r7
	and r0,r0,r7,lsl#4
	orr r0,r11,r0

	ldrb r3,[r6],#8				;@ Read bitmap data
	and r4,r0,#0x000000FF
	add r3,r12,r3,lsl#3

	ldmia r3,{r2,r3}
	mul r2,r4,r2
	mul r4,r3,r4
	stmia r9!,{r2,r4}


	ldrb r3,[r6],#8				;@ Read bitmap data
	and r4,r0,#0x0000FF00
	add r3,r12,r3,lsl#3

	ldmia r3,{r2,r3}
	mov r4,r4,lsr#8
	mul r2,r4,r2
	mul r4,r3,r4
	stmia r9!,{r2,r4}


	ldrb r3,[r6],#8				;@ Read bitmap data
	and r4,r0,#0x00FF0000
	add r3,r12,r3,lsl#3

	ldmia r3,{r2,r3}
	mov r4,r4,lsr#16
	mul r2,r4,r2
	mul r4,r3,r4
	stmia r9!,{r2,r4}


	ldrb r3,[r6],#8				;@ Read bitmap data
	mov r4,r0,lsr#24
	add r3,r12,r3,lsl#3

	ldmia r3,{r2,r3}
	mul r0,r2,r4
	mul r4,r3,r4
	stmia r9!,{r0,r4}
	
	orr r1,r11,r1,lsl#4
	str r1,[r10],#4				;@ Background color

	subs r8,r8,#1
	bne bgrdloop4

	ldmfd sp!,{r1-r11,lr}
	bx lr
;@----------------------------------------------------------------------------
RenderBmpMCM:					;@ MultiColorMode
;@----------------------------------------------------------------------------

	ldr r2,=c64_map_base
	ldr r4,[r2]
	sub r5,m6502zpage,#0x400		;@ Bg colormap
	add r4,r4,r0
	add r5,r5,r0

	ldr r2,=c64_bmp_base
	ldr r6,[r2]					;@ Bg tile bitmap
	add r6,r6,r0,lsl#3
	add r6,r6,r1

	mov r12,#0x18
	mov r10,#0xFF
	ldr r11,=0x03030300
	mov r8,#40					;@ Width of C64 screen
bgrdloop5:
	ldrb r0,[r4],#1				;@ Read from C64 Tilemap RAM (color 1,2)
	ldrb r1,[r5],#1				;@ Read from C64 Color RAM (color 3)
	
	mov r0,r0,ror#4
	orr r1,r11,r1,lsl#28
	ldrb r2,[r6],#8				;@ Read bitmap data
	orr r1,r1,r0,lsl#12
	orr r0,r1,r0,lsr#8


	and r1,r12,r2,lsr#3
	and r3,r10,r0,lsr r1

	and r1,r12,r2,lsr#1
	and r1,r10,r0,lsr r1
	orr r3,r3,r1,lsl#16

	and r1,r12,r2,lsl#1
	and r7,r10,r0,lsr r1

	and r1,r12,r2,lsl#3
	and r1,r10,r0,lsr r1
	orr r7,r7,r1,lsl#16

	orr r3,r3,r3,lsl#8
	orr r7,r7,r7,lsl#8

	stmia r9!,{r3,r7}


	subs r8,r8,#1
	bne bgrdloop5

	ldr globalptr,=wram_global_base
	ldrb r0,[r10,#vicbgr0col]	;@ Background color
	and r0,r0,#0x0F
	orr r0,r11,r0,lsl#12
	orr r0,r0,r0,lsr#8
	orr r0,r0,r0,lsl#16
	str r0,[r9],#4
	str r0,[r9],#4
	str r0,[r9],#4
	str r0,[r9],#4
	str r0,[r9],#4
	str r0,[r9],#4
	str r0,[r9],#4
	str r0,[r9],#4
	str r0,[r9],#4
	str r0,[r9],#4

	ldmfd sp!,{r1-r11,lr}
	bx lr
;@----------------------------------------------------------------------------
RenderBlankLine:
;@----------------------------------------------------------------------------

	ldrb r0,[r10,#vicbrdcol]	;@ Border color
	and r0,r0,#0x0F
	mov r0,r0,lsl#4
	orr r0,r0,#3
	orr r0,r0,r0,lsl#8
	orr r0,r0,r0,lsl#16
	mov r1,#90					;@ Screen plus background
blankloop:
	str r0,[r9],#4
	subs r1,r1,#1
	bne blankloop

	ldmfd sp!,{r1-r11,lr}
	bx lr
;@----------------------------------------------------------------------------
RenderBorder:
;@----------------------------------------------------------------------------
//	stmfd sp!,{r1-r2}
	ldr r2,=tile_base
	ldr r2,[r2]
	add r2,r2,#0x840			;@ Tile 66
	ldrb r0,[r10,#vicctrl2]
	ands r0,r0,#0x08
	moveq r0,#0x00FFFFFF
	movne r0,#0x00000000
	str r0,[r2,r1,lsl#2]

//	ldmfd sp!,{r1-r2}
	bx lr

#define PRIORITY 0x0400
;@----------------------------------------------------------------------------
RenderSprites:			;@ r0=?, r1=scanline.
;@----------------------------------------------------------------------------
	stmfd sp!,{r1,lr}

//	sub r1,r1,#1				;@ "tp8 results" breaks with this, fixes StarPaws.
	and r1,r1,#0xFF
	add r3,r10,#vic_base_offset
	ldr r7,=obj_buf_ptr0
	ldr r7,[r7]
//	ldr r0,=obj_counter
//	ldr r0,[r0]
//	and r0,r0,#0x7f
//	add r7,r7,r0,lsl#3

	ldrb r9,[r10,#vicsprenable]


	mov r8,#0
spr_loop:
	ldrh r0,[r3],#2
	cmp r1,r0,lsr#8
	bne next_spr
	mov r4,#1
	tst r9,r4,lsl r8
	beq next_spr

	mov r2,r0,lsr#8			;@ Y-pos
	ldr r5,=0xF5C2
	mul r2,r5,r2
	mov r2,r2,lsr#16

	and r0,r0,#0xFF			;@ X-pos
	ldrb r5,[r10,#vicsprxpos]
	tst r5,r4,lsl r8
	orrne r0,r0,#0x100

	mov r6,#0x00000100		;@ Use scaling
	orr r6,r6,#0x80000000	;@ 32x32 size

	ldrb r5,[r10,#vicsprprio]
	tst r5,r4,lsl r8
	orrne r6,r6,#0x00000400

	ldrb r5,[r10,#vicsprexpx]
	tst r5,r4,lsl r8
	orrne r6,r6,#0x02000000
	ldrb r5,[r10,#vicsprexpy]
	tst r5,r4,lsl r8
	orrne r6,r6,#0x04000000
	tst r6,#0x06000000		;@ Expand X or Y?
	beq noexpand
	orrne r6,r6,#0x00000200	;@ Use double size
	tst r6,#0x02000000
	subeq r0,r0,#20
	tst r6,#0x04000000
	subeq r2,r2,#16
noexpand:
	sub r2,r2,#48			;@ (50) fix up Y-pos
	and r2,r2,#0xff
	orr r2,r2,r6

	ldr r5,=0xCCCC
	mul r0,r5,r0
//	sub r0,r0,#0x18			;@ Fix up X-pos
	sub r0,r0,#0x150000		;@ Was 0x140000 (now +3)
	tst r6,#0x02000000		;@ X expand?
	subne r0,r0,#0x030000	;@ Another +3 for X expanded.
	ldr r6,=0x1ff
	and r0,r6,r0,lsr#16

	orr r6,r2,r0,lsl#16

	bl VRAM_spr				;@ Jump to spr copy
ret01:
	ldr r4,=obj_counter
	ldrb r2,[r4,r8]
	add r5,r2,#1
	strb r5,[r4,r8]
	add r2,r2,r8,lsl#4
	mov r0,r2,lsl#2			;@ Tile nr.
	and r2,r2,#0x7F
	add r5,r7,r2,lsl#3
	orr r0,r0,r8,lsl#12		;@ Color
	orr r0,r0,#PRIORITY		;@ Priority
	str r6,[r5],#4			;@ Store OBJ Atr 0,1. Xpos, ypos, xflip, scale/rot, size, shape.
	strh r0,[r5]			;@ Store OBJ Atr 2. Pattern, palette.

next_spr:

	add r8,r8,#1
	cmp r8,#8
	bne spr_loop

exit_sprite_render:
	ldmfd sp!,{r1,lr}
	bx lr

;@----------------------------------------------------------------------------
VRAM_spr:
;@----------------------------------------------------------------------------
	stmfd sp!,{r1}

	ldr r5,=obj_base
	ldr r5,[r5]
	ldr r0,=obj_counter
	ldrb r0,[r0,r8]
	add r0,r0,r8,lsl#4
	add r5,r5,r0,lsl#9

	ldr r0,=c64_map_base
	ldr r12,[r0]					;@ Spr tile bitmap
	add r12,r12,#0x3F8
	ldrb r0,[r12,r8]				;@ Tile nr.

	ldrb r2,[r10,#cia2porta]		;@ VIC bank
	eor r2,r2,#0x03
	and r2,r2,#0x03
	add r12,m6502zpage,r2,lsl#14
	add r12,r12,r0,lsl#6

	ldrb r0,[r10,#vicsprmode]
	tst r0,r4,lsl r8
	beq VRAM_spr_mono


	ldr r1,=chr_decode_2
	
	mov r4,#24
	mov r2,#0
spr_loop2:
	ldrb r0,[r12],#1
	ldr r0,[r1,r0,lsl#2]
	str r0,[r5],#32
	ldrb r0,[r12],#1
	ldr r0,[r1,r0,lsl#2]
	str r0,[r5],#32
	ldrb r0,[r12],#1
	ldr r0,[r1,r0,lsl#2]
	str r0,[r5],#32
	str r2,[r5],#-92
	sub r4,r4,#1
	tst r4,#7
	addeq r5,r5,#96
	cmp r4,#3
	bne spr_loop2

	ldmfd sp!,{r1}
	bx lr
;@----------------------------------------------------------------------------
VRAM_spr_mono:
;@----------------------------------------------------------------------------

	ldr r1,=chr_decode
	
	mov r4,#24
	mov r2,#0
spr_loop3:
	ldrb r0,[r12],#1
	ldr r0,[r1,r0,lsl#2]
	mov r0,r0,lsl#1
	str r0,[r5],#32
	ldrb r0,[r12],#1
	ldr r0,[r1,r0,lsl#2]
	mov r0,r0,lsl#1
	str r0,[r5],#32
	ldrb r0,[r12],#1
	ldr r0,[r1,r0,lsl#2]
	mov r0,r0,lsl#1
	str r0,[r5],#32
	str r2,[r5],#-92
	sub r4,r4,#1
	tst r4,#7
	addeq r5,r5,#96
	cmp r4,#3
	bne spr_loop3

	ldmfd sp!,{r1}
	bx lr
;@----------------------------------------------------------------------------





	.section .bss
	.align 2
//chr_decode_new			; 16*16*16*16*4
//	.space 0x40000
chr_decode:
	.space 256*4
chr_decode_2:
	.space 256*4
chr_decode_3:
	.space 256*8
chr_decode_4:
	.space 256*8
pal_buffer:
	.space 512*2
obj_buffer0:
	.space 128*8
obj_buffer1:
	.space 128*8
dma_buffer0:
	.space 192*4*2
scroll_buffer0:
	.space 256
scroll_buffer1:
	.space 256
c64_palette_mod:
	.space 16*2
EMUPALBUFF:
	.space 0x400*2				;@ For both main & sub screens

tile_base:
	.long 0
obj_base:
	.long 0
bg2_ptr0:
	.long 0
bg2_ptr1:
	.long 0
scroll_ptr0:
	.long 0
scroll_ptr1:
	.long 0
obj_buf_ptr0:
	.long 0
obj_buf_ptr1:
	.long 0
obj_counter:
	.long 0,0

c64_map_base:
	.long 0
c64_chr_base:
	.long 0
c64_bmp_base:
	.long 0

#ifdef NDS
	.section .dtcm, "ax", %progbits				;@ For the NDS
#elif GBA
	.section .iwram, "ax", %progbits			;@ For the GBA
#else
	.section .text
#endif
	.align 2
					;@ !!! Something MUST be referenced here, otherwise the compiler scraps it !!!
VICState:
	.byte 0 ;@ vicspr0x			;0xD000
	.byte 0 ;@ vicspr0y
	.byte 0 ;@ vicspr1x
	.byte 0 ;@ vicspr1y
	.byte 0 ;@ vicspr2x
	.byte 0 ;@ vicspr2y
	.byte 0 ;@ vicspr3x
	.byte 0 ;@ vicspr3y
	.byte 0 ;@ vicspr4x
	.byte 0 ;@ vicspr4y
	.byte 0 ;@ vicspr5x
	.byte 0 ;@ vicspr5y
	.byte 0 ;@ vicspr6x
	.byte 0 ;@ vicspr6y
	.byte 0 ;@ vicspr7x
	.byte 0 ;@ vicspr7y
	.byte 0 ;@ vicsprxpos		;0xD010
	.byte 0 ;@ vicctrl1			;0xD011
	.byte 0 ;@ vicraster
	.byte 0 ;@ viclightpenx
	.byte 0 ;@ viclightpeny
	.byte 0 ;@ vicsprenable		;0xD015
	.byte 0 ;@ vicctrl2
	.byte 0 ;@ vicsprexpy
	.byte 0 ;@ vicmemctrl		;0xD018
	.byte 0 ;@ vicirqflag		;0xD019
	.byte 0 ;@ vicirqenable		;0xD01A
	.byte 0 ;@ vicsprprio		;0xD01B
	.byte 0 ;@ vicsprmode		;0xD01C
	.byte 0 ;@ vicsprexpx		;0xD01D
	.byte 0 ;@ vicsprsprcol		;0xD01E
	.byte 0 ;@ vicsprbgrcol		;0xD01F
	.byte 0 ;@ vicbrdcol		;0xD020
	.byte 0 ;@ vicbgr0col		;0xD021
	.byte 0 ;@ vicbgr1col		;0xD022
	.byte 0 ;@ vicbgr2col		;0xD023
	.byte 0 ;@ vicbgr3col		;0xD024
	.byte 0 ;@ vicsprm0col		;0xD025
	.byte 0 ;@ vicsprm1col		;0xD026
	.byte 0 ;@ vicspr0col		;0xD027
	.byte 0 ;@ vicspr1col		;0xD028
	.byte 0 ;@ vicspr2col		;0xD029
	.byte 0 ;@ vicspr3col		;0xD02A
	.byte 0 ;@ vicspr4col		;0xD02B
	.byte 0 ;@ vicspr5col		;0xD02C
	.byte 0 ;@ vicspr6col		;0xD02D
	.byte 0 ;@ vicspr7col		;0xD02E
	.byte 0 ;@ vicempty0		;0xD02F

