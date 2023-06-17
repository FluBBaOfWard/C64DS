#include "Shared/nds_asm.h"
#include "Shared/EmuSettings.h"
#include "equates.h"
#include "memory.h"
#include "ARM6526/ARM6526.i"
#include "ARM6569/ARM6569.i"
#include "ARM6502/M6502mac.h"

	.global vblIrqHandler
	.global gfxInit
	.global gfxReset
	.global newFrame
	.global endFrame
	.global RenderLine
	.global SetC64GfxMode

	.global gScaling
	.global gTwitch
	.global gFlicker
	.global gGfxMask
	.global EMUPALBUFF
	.global tile_base
	.global obj_base
	.global scroll_ptr0

	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
gfxInit:	;@ (called from main.c) only need to call once
	.type gfxInit STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r10,lr}

	mov r0,#BG_GFX
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
	add r1,r1,#0x1000			;@ Offset the background so we have space for a tilemaped mode.
	ldr r0,=bg2_ptr0
	str r1,[r0],#4
	add r1,r1,#0x20000
	str r1,[r0]

	mov r2,#0xffffff00			;@ Build bg tile decode tbl
	ldr r3,=chrDecode
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

	mov r2,#0xffffff00			;@ Build bg tile decode tbl
	ldr r3,=chrDecode2
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

	mov r2,#0xffffff00			;@ Build bg tile decode tbl
	ldr r3,=chrDecode3
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

	mov r2,#0xffffff00			;@ Build bg tile decode tbl
	ldr r3,=chrDecode4
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

//	mov r2,#0xffffff00			;@ Build bg tile decode tbl
//	ldr r3,=chrDecodeNew
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

	ldr vic2ptr,=wram_global_base
	bl m6569Init
	ldr r1,=setVicIrq
	str r1,[vic2ptr,#vicIrqFunc]
	ldmfd sp!,{r10,lr}
	bx lr
;@----------------------------------------------------------------------------
gfxReset:	;@ Called with CPU reset
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

//	mov r1,#0
//	str r1,windowtop
//	strb r1,ystart

//	ldr r0,=gfxstate
//	mov r2,#5					;@ 5*4
//	bl memset_					;@ Clear GFX regs

//	mov r0,#1
//	strb r0,sprmemreload

//	mov r0,#-1
//	strb r0,oldchrbase

	bl m6569Reset
	bl gfxSetTVSystem

	mov r1,#REG_BASE
	mov r0,#0x0140				;@ X-delta
	strh r0,[r1,#REG_BG2PA]
//	mov r0,#0x0001				;@ X-delta
	mov r0,#0x0028				;@ X-delta
	strh r0,[r1,#REG_BG3PA]
	ldr r0,=0x010B				;@ Y-delta
	strh r0,[r1,#REG_BG2PD]
	strh r0,[r1,#REG_BG3PD]

	mov r3,#0x0410
	strh r3,[r1,#REG_BLDCNT]	;@ OBJ blend to BG0
	mov r3,#0x1000				;@ BG0=16, OBJ=0
	strh r3,[r1,#REG_BLDALPHA]	;@ Alpha values

//	mov r0,#AGB_OAM
//	mov r1,#0x2c0
//	mov r2,#0x100
//	bl memset_					;@ No stray sprites please
//	ldr r0,=obj_buffer0
//	mov r2,#0x180
//	bl memset_

	bl BorderInit
//	bl InitBGTiles
	bl SpriteScaleInit
	bl paletteinit				;@ do palette mapping
	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
gfxSetTVSystem:			;@ r0 = PAL/NTSC
;@----------------------------------------------------------------------------
	ldr r2,=wram_global_base
	mov r0,#PALTIMING
	strb r0,[r2,#vicTVSystem]
	tst r0,#PALTIMING
	ldrne r1,=63				;@ PAL=63
	ldreq r1,=64				;@ NTSC=64/65
//	str r1,[r2,#cyclesperscanline]
	ldrne r1,=311				;@ PAL=311. number of lines=last+1
	ldreq r1,=262				;@ NTSC=262. number of lines=last+1
	str r1,[r2,#lastscanline]

	movne r0,#50
	moveq r0,#60
	subne r2,r0,#1
	ldr r1,=fpsNominal
	strb r2,[r1]
	b setLCDFPS
;@----------------------------------------------------------------------------
BorderInit:
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r5,lr}
	ldr r5,=tile_base
	ldr r5,[r5]
	mov r0,#64					;@ First free tile after map
	mov r1,#66					;@ First border tile
	orr r2,r1,#0x0400			;@ X flip
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

	adr r7,C64Palette
	ldr r6,=c64_palette_mod
//	ldrb r1,gammavalue			;@ Gamma value = 0 -> 4
	mov r1,#1					;@ Gamma value = 0 -> 4
	mov r4,#15					;@
nomap:							;@ Map rrrrrrrrggggggggbbbbbbbb  ->  0bbbbbgggggrrrrr
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
C64Palette:
	.byte 0x00,0x00,0x00, 0xFF,0xFF,0xFF, 0x89,0x40,0x36, 0x7A,0xBF,0xC7
	.byte 0x8A,0x46,0xAE, 0x68,0xA9,0x41, 0x3E,0x31,0xA2, 0xD0,0xDC,0x71
	.byte 0x90,0x5F,0x25, 0x5C,0x47,0x00, 0xBB,0x77,0x6D, 0x55,0x55,0x55
	.byte 0x80,0x80,0x80, 0xAC,0xEA,0x88, 0x7C,0x70,0xDA, 0xAB,0xAB,0xAB
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
	adr r5,scaleparms			;@ Set sprite scaling params
	ldmia r5,{r0-r5}

	mov r6,#2
scaleLoop:
	strh r1,[r5],#8				;@ Buffer1, buffer2. normal sprites
	strh r0,[r5],#8
	strh r0,[r5],#8
	strh r2,[r5],#8
		strh r3,[r5],#8			;@ Horizontaly expanded sprites
		strh r0,[r5],#8
		strh r0,[r5],#8
		strh r2,[r5],#8
			strh r1,[r5],#8		;@ Verticaly expanded sprites
			strh r0,[r5],#8
			strh r0,[r5],#8
			strh r4,[r5],#8
				strh r3,[r5],#8	;@ Double sprites
				strh r0,[r5],#8
				strh r0,[r5],#8
				strh r4,[r5],#136
		add r5,r5,#0x300
	subs r6,r6,#1
	bne scaleLoop
	ldmfd sp!,{r4-r6}
	bx lr

;@----------------------------------------------------------------------------
vblIrqHandler:
	.type vblIrqHandler STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
	bl calculateFPS

	ldr r6,gFlicker
	eors r6,r6,r6,lsl#31
	str r6,gFlicker

	ldr r3,=scroll_ptr1
	ldr r3,[r3]
	ldr r4,=dma_buffer0

	ldr r1,=0x010B				;@ Y-delta
	mov r5,#0
	moveq r5,#0x000B
//	mov r7,r5					;@ Y-Offset
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
	mov r0,#0x0B00				;@ 11 pixels offset.
	addeq r0,r0,#0x000B
	strh r0,[r12,#REG_BG2Y]
	strh r0,[r12,#REG_BG3Y]
	mov r0,#0x14000				;@ 320<<8
	addeq r0,r0,#0x00008
	str r0,[r12,#REG_BG3X]

	ldr r0,=bg2_ptr1
	ldr r0,[r0]
	and r0,r0,#0x20000
	ldrh r1,[r12,#REG_BG2CNT]	;@ Switch bg2 buffers
	bic r1,r1,#0x800
	orr r1,r1,r0,lsr#6
	strh r1,[r12,#REG_BG2CNT]
	strh r1,[r12,#REG_BG3CNT]

	mov r0,#0
	str r0,[r12,#REG_DMA2CNT]	;@ Stop DMA2

	add r1,r12,#REG_DMA3SAD
	ldr r2,=obj_buf_ptr1
	ldr r2,[r2]
	mov r3,#OAM					;@ DMA3 dst
	mov r4,#0x84000000			;@ noIRQ 32bit incsrc incdst
	orr r4,r4,#128*2			;@ 128 sprites * 2 longwords
	stmia r1,{r2-r4}			;@ DMA3 go

	ldr r1,=dma_buffer0
	add r2,r12,#REG_BG2X
	ldr r3,=0x96600001			;@ 1 word(s)
	ldr r0,[r1],#4				;@ Change this if you change number of words transfered!
	str r0,[r2]
	str r1,[r12,#REG_DMA2SAD]
	str r2,[r12,#REG_DMA2DAD]
	str r3,[r12,#REG_DMA2CNT]	;@ DMA2 Go!

;@----------------- GUI screen -------------------
	add r12,r12,#0x1000			;@ SUB gfx
//	ldr r0,=film_pos
	ldr r0,=0
	strh r0,[r12,#REG_BG0VOFS]
	ldr r0,=keyb_pos
	ldr r0,[r0]
	strh r0,[r12,#REG_BG1VOFS]

	blx scanKeys
	mov r6,#REG_BASE
	ldr r2,=wram_global_base
	ldrb r0,[r2,#vicTVSystem]
	tst r0,#PALTIMING
	beq exitVbl
	ldr r0,=pauseEmulation
	ldr r0,[r0]
	cmp r0,#0
	bne exitVbl
hz50Start:
	mov r0,#5
hz50Loop0:
	ldrh r1,[r6,#REG_VCOUNT]
	cmp r1,#212
	beq hz50Loop0
hz50Loop1:
	ldrh r1,[r6,#REG_VCOUNT]
	cmp r1,#212
	bmi hz50Loop1
	mov r1,#202
	strh r1,[r6,#REG_VCOUNT]
	subs r0,r0,#1
	bne hz50Loop0
exitVbl:
	ldmfd sp!,{r4-r11,pc}

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
SetC64GfxMode:
;@----------------------------------------------------------------------------
	stmfd sp!,{r0,r12}

	ldrb r0,[vic2ptr,#vicCtrl1]	;@ VIC control 1
	ldrb r1,[vic2ptr,#vicCtrl2]	;@ VIC control 2

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
newFrame:	;@ Called before line 0	(r0-r9 safe to use)
;@----------------------------------------------------------------------------
	mov r0,#-1					;@ Rambo checks for IRQ on line 0
	str r0,[vic2ptr,#scanline]	;@ Reset scanline count

	ldr r0,=frameTotal
	ldr r0,[r0]
	and r0,r0,#1				;@ Why should this flicker?
	mov r0,r0,lsl#7
	orr r0,r0,r0,lsl#8
	orr r0,r0,r0,lsl#16
	ldr r1,=obj_counter
	str r0,[r1]
	str r0,[r1,#4]


	ldr r1,=obj_buf_ptr0
	ldr r1,[r1]
	mov r0,#0x2c0				;@ Double, y=191
	mov r2,#128
sprClrLoop:
	str r0,[r1],#8
	subs r2,r2,#1
	bne sprClrLoop

	mov r0,#0
	str r0,[r10,#scrollXLine]
	mov r0,#8
	str r0,line_y_offset
	mov r0,#-8
	str r0,row_y_offset

	bx lr

;@----------------------------------------------------------------------------
endFrame:	;@ Called just before screen end (~line 240)	(r0-r2 safe to use)
;@----------------------------------------------------------------------------
	stmfd sp!,{r3-r9,lr}

;@--------------------------
//	bl sprDMA_do
;@--------------------------
	bl PaletteTxAll
;@--------------------------
	ldrb r0,[vic2ptr,#vicCtrl2]
	bl VIC_ctrl2_W

//	mrs r4,cpsr
//	orr r1,r4,#0x80				;@ --> Disable IRQ.
//	msr cpsr_cf,r1

	ldr r2,=obj_buf_ptr0		;@ Switch obj buffers
	ldmia r2,{r0,r1}
	str r0,[r2,#4]
	str r1,[r2]

	ldr r2,=bg2_ptr0			;@ Switch bg2 buffers
	ldmia r2,{r0,r1}
	str r0,[r2,#4]
	str r1,[r2]

	ldr r2,=scroll_ptr0			;@ Switch scroll buffers
	ldmia r2,{r0,r1}
	str r0,[r2,#4]
	str r1,[r2]

//	mov r0,#1
//	str r0,oambufferready


//	msr cpsr_cf,r4				;@ --> restore mode,Enable IRQ.

	ldmfd sp!,{r3-r9,lr}
	bx lr
;@----------------------------------------------------------------------------
PaletteTxAll:		;@ Called from ui.c
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r7,r10,lr}
	ldr vic2ptr,=wram_global_base
	ldr r2,=c64_palette_mod
	ldr r3,=pal_buffer
	mov r7,#0x1E
	ldrb r0,[vic2ptr,#vicBrdCol]
	and r0,r7,r0,lsl#1
	ldrh r0,[r2,r0]
	strh r0,[r3,#0x1E]			;@ Set sideborder color (plane1)
	strh r0,[r3],#2

	ldrb r4,[vic2ptr,#vicBgr1Col]
	and r4,r7,r4,lsl#1
	ldrh r4,[r2,r4]
	ldrb r5,[vic2ptr,#vicBgr2Col]
	and r5,r7,r5,lsl#1
	ldrh r5,[r2,r5]

	mov r1,#0
c64loop1:						;@ Normal BG tile colors
	ldrh r0,[r2,r1]
	strh r4,[r3],#0x02
	strh r5,[r3],#0x02
	strh r0,[r3],#0x1C
	add r1,r1,#2
	cmp r1,#0x20
	bne c64loop1

	ldr r3,=pal_buffer+0x202

	ldrb r4,[vic2ptr,#vicSprM0Col]
	and r4,r7,r4,lsl#1
	ldrh r4,[r2,r4]
	ldrb r5,[vic2ptr,#vicSprM1Col]
	and r5,r7,r5,lsl#1
	ldrh r5,[r2,r5]
	ldr r6,=vicSpr0Col
	add r6,r6,r10

	mov r1,#0
c64loop3:						;@ Sprite colors.
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
RenderLine:					;@ r0=?, r1=scanline.
;@----------------------------------------------------------------------------
	stmfd sp!,{r1-r11,lr}
	bl RenderSprites

	mov r11,r11
	subs r1,r1,#0x30			;@ This is where the VIC starts looking for background data.
	bmi exitLineRender
	cmp r1,#208
	bpl exitLineRender
//	cmp r1,#3
//	blpl RenderBorder
	bl RenderBorder

	ldr r9,=bg2_ptr0
	ldr r9,[r9]					;@ Background base-address.
	add r9,r9,r1,lsl#9			;@ Y-offset

	ldr r2,line_y_offset
	ldr r3,row_y_offset
	cmp r2,#8
	bmi noNewTileRow

	ldrb r0,[vic2ptr,#vicCtrl1]
	sub r4,r1,r0
	ands r4,r4,#7				;@ Do we have a new tile row?
//	bne noNewTileRow
	bne RenderBlankLine

	mov r2,r4
	add r3,r3,#8
	str r3,row_y_offset
	ldr r8,[sp,#7*4]
	eatcycles 40
	str r8,[sp,#7*4]
noNewTileRow:
	add r0,r2,#1
	str r0,line_y_offset
	add r1,r3,r2


	bic r0,r1,#0x07
	and r1,r1,#0x07
	add r0,r0,r0,lsl#2			;@ x5

	ldr pc,RenderModePtr

RenderModePtr:
	.long RenderTiles

exitLineRender:
//	cmp r1,#-1
//	ldrbeq r0,[vic2ptr,#vicCtrl1]
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
	ldr r5,[vic2ptr,#vicMapBase]
	sub r6,m6502zpage,#0x400	;@ Bg colormap
	add r5,r5,r0
	add r6,r6,r0

	ldr r7,[vic2ptr,#vicChrBase]	;@ Bg tile bitmap
	ldr r12,=chrDecode3
	add r7,r7,r1

	ldr r11,=0x03030303
	mov lr,#0xFF
	mov r8,#10					;@ Width/4 of C64 screen
bgrdLoop:
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
	bne bgrdLoop

	ldr vic2ptr,=wram_global_base
	ldrb r0,[vic2ptr,#vicBgr0Col]	;@ Background color
	and r0,r0,#0x0F
	orr r0,r11,r0,lsl#4
	orr r0,r0,r0,lsl#8
	orr r0,r0,r0,lsl#16
	mov r1,r0
	stmia r9!,{r0,r1}
	stmia r9!,{r0,r1}
	stmia r9!,{r0,r1}
	stmia r9!,{r0,r1}
	stmia r9!,{r0,r1}

	ldmfd sp!,{r1-r11,lr}
	bx lr

;@----------------------------------------------------------------------------
RenderTilesECM:				;@ ExtendedColorMode
;@----------------------------------------------------------------------------

	ldr r5,[vic2ptr,#vicMapBase]
	sub r6,m6502zpage,#0x400	;@ Bg colormap
	add r5,r5,r0
	add r6,r6,r0

	ldr r7,[vic2ptr,#vicChrBase]	;@ Bg tile bitmap
	ldr r12,=chrDecode3
	add r7,r7,r1

	ldrb r0,[vic2ptr,#vicBgr0Col]!
	add lr,r9,#320

	ldr r11,=0x03030303
	mov r8,#10					;@ Width/4 of C64 screen
bgrdLoop1:
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
	bne bgrdLoop1

	ldmfd sp!,{r1-r11,lr}
	bx lr
;@----------------------------------------------------------------------------
RenderTilesMCM:				;@ MultiColorMode
;@----------------------------------------------------------------------------

	ldr r5,[vic2ptr,#vicMapBase]
	sub r6,m6502zpage,#0x400	;@ Bg colormap
	add r5,r5,r0
	add r6,r6,r0

	ldr r7,[vic2ptr,#vicChrBase]	;@ Bg tile bitmap
	ldr lr,=chrDecode3			;@ Mono
	add r7,r7,r1

	ldr r11,=0x03030300
	ldrb r0,[vic2ptr,#vicBgr1Col]
	and r0,r0,#0x0F
	orr r11,r11,r0,lsl#12
	ldrb r0,[vic2ptr,#vicBgr2Col]
	and r0,r0,#0x0F
	orr r11,r11,r0,lsl#20

	mov r12,#0x18
	mov r10,#0xFF
	mov r8,#40					;@ Width of C64 screen
bgrdLoop2:
	ldrb r0,[r5],#1				;@ Read from C64 Tilemap RAM
	ldrb r1,[r6],#1				;@ Read from C64 Color RAM (color 3)
	
	bic r11,r11,#0xF0000000
	orrs r11,r11,r1,lsl#28
	bic r11,r11,#0x80000000		;@ Clear multi color bit
	ldrb r0,[r7,r0,lsl#3]		;@ Read bitmap data

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
	ldmiapl r0,{r1,r2}
	movpl r4,r11,lsr#24
	mulpl r3,r1,r4
	mulpl r4,r2,r4

	stmia r9!,{r3,r4}

	subs r8,r8,#1
	bne bgrdLoop2

	ldr vic2ptr,=wram_global_base
	ldrb r0,[vic2ptr,#vicBgr0Col]	;@ Background color
	and r0,r0,#0x0F
	orr r0,r0,#0x30000000
	mov r0,r0,ror#28
	orr r0,r0,r0,lsl#8
	orr r0,r0,r0,lsl#16
	mov r1,r0
	stmia r9!,{r0,r1}
	stmia r9!,{r0,r1}
	stmia r9!,{r0,r1}
	stmia r9!,{r0,r1}
	stmia r9!,{r0,r1}

	ldmfd sp!,{r1-r11,lr}
	bx lr
;@----------------------------------------------------------------------------
RenderBmp:
;@----------------------------------------------------------------------------
	ldr r5,[vic2ptr,#vicMapBase]
	add r5,r5,r0

	ldr r6,[vic2ptr,#vicBmpBase]	;@ Bg tile bitmap
	ldr r12,=chrDecode3
	add r6,r6,r0,lsl#3
	add r6,r6,r1

	add r10,r9,#320

	ldr r7,=0x0F0F0F0F
	ldr r11,=0x03030303
	mov r8,#10					;@ Width/4 of C64 screen
bgrdLoop4:
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
	bne bgrdLoop4

	ldmfd sp!,{r1-r11,lr}
	bx lr
;@----------------------------------------------------------------------------
RenderBmpMCM:				;@ MultiColorMode
;@----------------------------------------------------------------------------

	ldr r4,[vic2ptr,#vicMapBase]
	sub r5,m6502zpage,#0x400	;@ Bg colormap
	add r4,r4,r0
	add r5,r5,r0

	ldr r6,[vic2ptr,#vicBmpBase]	;@ Bg tile bitmap
	add r6,r6,r0,lsl#3
	add r6,r6,r1

	mov r12,#0x18
	mov r10,#0xFF
	ldr r11,=0x03030300
	mov r8,#40					;@ Width of C64 screen
bgrdLoop5:
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
	bne bgrdLoop5

	ldr vic2ptr,=wram_global_base
	ldrb r0,[vic2ptr,#vicBgr0Col]	;@ Background color
	and r0,r0,#0x0F
	orr r0,r11,r0,lsl#12
	orr r0,r0,r0,lsr#8
	orr r0,r0,r0,lsl#16
	mov r1,r0
	stmia r9!,{r0,r1}
	stmia r9!,{r0,r1}
	stmia r9!,{r0,r1}
	stmia r9!,{r0,r1}
	stmia r9!,{r0,r1}

	ldmfd sp!,{r1-r11,lr}
	bx lr
;@----------------------------------------------------------------------------
RenderBlankLine:
;@----------------------------------------------------------------------------

	ldrb r0,[r10,#vicBrdCol]	;@ Border color
	and r0,r0,#0x0F
	mov r0,r0,lsl#4
	orr r0,r0,#3
	orr r0,r0,r0,lsl#8
	orr r0,r0,r0,lsl#16
	mov r1,r0
	mov r2,#45					;@ Screen plus border
blankLoop:
	stmia r9!,{r0,r1}
	subs r2,r2,#1
	bne blankLoop

	ldmfd sp!,{r1-r11,lr}
	bx lr
;@----------------------------------------------------------------------------
RenderBorder:
;@----------------------------------------------------------------------------
//	stmfd sp!,{r1-r2}
	ldr r2,=tile_base
	ldr r2,[r2]
	add r2,r2,#0x840			;@ Tile 66
	ldrb r0,[r10,#vicCtrl2]
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
	add r3,vic2ptr,#m6569Registers
	ldr r7,=obj_buf_ptr0
	ldr r7,[r7]
//	ldr r0,=obj_counter
//	ldr r0,[r0]
//	and r0,r0,#0x7f
//	add r7,r7,r0,lsl#3

	ldrb r9,[vic2ptr,#vicSprEnable]

	mov r8,#0
sprLoop:
	ldrh r0,[r3],#2
	cmp r1,r0,lsr#8
	bne nextSpr
	mov r4,#1
	tst r9,r4,lsl r8
	beq nextSpr

	mov r2,r0,lsr#8				;@ Y-pos
	ldr r5,=0xF5C2
	mul r2,r5,r2
	mov r2,r2,lsr#16

	and r0,r0,#0xFF				;@ X-pos
	ldrb r5,[vic2ptr,#vicSprXPos]
	tst r5,r4,lsl r8
	orrne r0,r0,#0x100

	mov r6,#0x00000100			;@ Use scaling
	orr r6,r6,#0x80000000		;@ 32x32 size

	ldrb r5,[vic2ptr,#vicSprPrio]
	tst r5,r4,lsl r8
	orrne r6,r6,#0x00000400

	ldrb r5,[vic2ptr,#vicSprExpX]
	tst r5,r4,lsl r8
	orrne r6,r6,#0x02000000
	ldrb r5,[vic2ptr,#vicSprExpY]
	tst r5,r4,lsl r8
	orrne r6,r6,#0x04000000
	tst r6,#0x06000000			;@ Expand X or Y?
	beq noExpand
	orrne r6,r6,#0x00000200		;@ Use double size
	tst r6,#0x02000000
	subeq r0,r0,#20
	tst r6,#0x04000000
	subeq r2,r2,#16
noExpand:
	sub r2,r2,#48				;@ (50) fix up Y-pos
	and r2,r2,#0xff
	orr r2,r2,r6

	ldr r5,=0xCCCC
	mul r0,r5,r0
//	sub r0,r0,#0x18				;@ Fix up X-pos
	sub r0,r0,#0x150000			;@ Was 0x140000 (now +3)
	tst r6,#0x02000000			;@ X expand?
	subne r0,r0,#0x030000		;@ Another +3 for X expanded.
	ldr r6,=0x1ff
	and r0,r6,r0,lsr#16

	orr r6,r2,r0,lsl#16

	bl VRAM_spr					;@ Jump to spr copy
ret01:
	ldr r4,=obj_counter
	ldrb r2,[r4,r8]
	add r5,r2,#1
	strb r5,[r4,r8]
	add r2,r2,r8,lsl#4
	mov r0,r2,lsl#2				;@ Tile nr.
	and r2,r2,#0x7F
	add r5,r7,r2,lsl#3
	orr r0,r0,r8,lsl#12			;@ Color
	orr r0,r0,#PRIORITY			;@ Priority
	str r6,[r5],#4				;@ Store OBJ Atr 0,1. Xpos, ypos, xflip, scale/rot, size, shape.
	strh r0,[r5]				;@ Store OBJ Atr 2. Pattern, palette.

nextSpr:
	add r8,r8,#1
	cmp r8,#8
	bne sprLoop

exitSpriteRenderer:
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

	ldr r12,[vic2ptr,#vicMapBase]	;@ Spr tile bitmap
	add r12,r12,#0x3F8
	ldrb r0,[r12,r8]			;@ Tile nr.

	ldrb r2,[vic2ptr,#vicMemoryBank]
	add r12,m6502zpage,r2,lsl#14
	add r12,r12,r0,lsl#6

	ldrb r0,[vic2ptr,#vicSprMode]
	tst r0,r4,lsl r8
	beq VRAM_spr_mono

	ldr r1,=chrDecode2

	mov r4,#24
	mov r2,#0
sprLoop2:
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
	bne sprLoop2

	ldmfd sp!,{r1}
	bx lr
;@----------------------------------------------------------------------------
VRAM_spr_mono:
;@----------------------------------------------------------------------------

	ldr r1,=chrDecode
	
	mov r4,#24
	mov r2,#0
sprLoop3:
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
	bne sprLoop3

	ldmfd sp!,{r1}
	bx lr
;@----------------------------------------------------------------------------


	.section .bss
	.align 2
//chrDecodeNew					;@ 16*16*16*16*4
//	.space 0x40000
chrDecode:
	.space 256*4
chrDecode2:
	.space 256*4
chrDecode3:
	.space 256*8
chrDecode4:
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

#ifdef NDS
	.section .dtcm, "ax", %progbits				;@ For the NDS
#elif GBA
	.section .iwram, "ax", %progbits			;@ For the GBA
#else
	.section .text
#endif
	.align 2

