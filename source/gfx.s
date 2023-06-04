	.include "equates.h"
	.include "memory.h"

;	.extern Chargen
	.extern _binary_chargen_rom
	.extern tile_base
	.extern obj_base
	.extern wram_global_base
	.extern keyb_pos
	.extern film_pos

	.text gfx_routines
	.global asm_vblank
	.global GFX_init
	.global GFX_reset
	.global VIC_R
	.global VIC_W
	.global VICState
	.global newframe
	.global endframe
	.global RenderLine
	.global SetC64GfxBases

	.include "nitro/hw/ARM9/ioreg_MI.h"
	.include "nitro/hw/ARM9/ioreg_G2.h"
	.include "nitro/hw/ARM9/mmap_global.h"

;----------------------------------------------------------------------------
GFX_init	;(called from main.c) only need to call once
;----------------------------------------------------------------------------
	stmfd sp!,{lr}

	mov r0,#NTR_VRAM
	mov r1,#0
	mov r2,#0xE0
	bl memset_					;clear
	
	ldr r0,=obj_base
	ldr r0,[r0]
	mov r2,#0x8000
	bl memset_					;clear all Main VRAM

	ldr r0,=0x06200000
	mov r2,#0x8000
	bl memset_					;clear all Sub VRAM

	ldr r0,=obj_buf_ptr0
	ldr r1,=obj_buffer0
	str r1,[r0],#4
	add r1,r1,#128*8
	str r1,[r0]

	ldr r1,=tile_base
	ldr r1,[r1]
	ldr r0,=bg2_ptr0
	str r1,[r0],#4
	add r1,r1,#0x20000
	str r1,[r0]

	mov r2,#0xffffff00		;build bg tile decode tbl
	ldr r3,=chr_decode
ppi0
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

	mov r2,#0xffffff00		;build bg tile decode tbl
	ldr r3,=chr_decode_2
ppi2
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

	mov r2,#0xffffff00		;build bg tile decode tbl
	ldr r3,=chr_decode_3
ppi3
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

	mov r2,#0xffffff00		;build bg tile decode tbl
	ldr r3,=chr_decode_4
ppi4
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

;	mov r2,#0xffffff00		;build bg tile decode tbl
;	ldr r3,=chr_decode_new
;ppi5
;	mov r0,#0
;	mov r1,#0
;	and r12,r2,#0x00000030
;	orr r0,r0,r12,lsl#20
;	orr r0,r0,r12,lsl#12
;	and r12,r2,#0x000000C0
;	orr r0,r0,r12,lsl#2
;	orr r0,r0,r12,lsr#6
;	and r12,r2,#0x00000003
;	orr r1,r1,r12,lsl#24
;	orr r1,r1,r12,lsl#16
;	and r12,r2,#0x0000000C
;	orr r1,r1,r12,lsl#6
;	orr r1,r1,r12,lsr#2
;	stmia r3!,{r0-r1}
;	adds r2,r2,#1
;	bne ppi5

	ldmfd sp!,{lr}
	bx lr
;----------------------------------------------------------------------------
GFX_reset	;called with CPU reset
;----------------------------------------------------------------------------
	str lr,[sp,#-4]!

;	mov r1,#0
;	str r1,windowtop
;	strb r1,ystart

;	ldr r0,=gfxstate
;	mov r2,#5				;5*4
;	bl memset_				;clear GFX regs

;	mov r0,#1
;	strb r0,sprmemreload

;	mov r0,#-1
;	strb r0,oldchrbase

	mov r1,#HW_REG_BASE
	mov r0,#0x0140			; X-delta
	strh r0,[r1,#REG_BG2PA_OFFSET]
;	mov r0,#0x0001			; X-delta
	mov r0,#0x0028			; X-delta
	strh r0,[r1,#REG_BG3PA_OFFSET]
	ldr r0,=0x010B			; Y-delta
	strh r0,[r1,#REG_BG2PD_OFFSET]
	strh r0,[r1,#REG_BG3PD_OFFSET]


;	mov r0,#AGB_OAM
;	mov r1,#0x2c0
;	mov r2,#0x100
;	bl memset_		;no stray sprites please
;	ldr r0,=OAM_BUFFER1
;	mov r2,#0x180
;	bl memset_

;	bl InitBGTiles
	bl paletteinit	;do palette mapping
	ldr pc,[sp],#4
;----------------------------------------------------------------------------
paletteinit;	r0-r3 modified.
;called by ui.c:  void map_palette(char gammavalue)
;----------------------------------------------------------------------------
	stmfd sp!,{r4-r7,lr}

	adr r7,C64_Palette
	ldr r6,=c64_palette_mod
;	ldrb r1,gammavalue	;gamma value = 0 -> 4
	mov r1,#1			;gamma value = 0 -> 4
	mov r4,#15			;
nomap					;map rrrrrrrrggggggggbbbbbbbb  ->  0bbbbbgggggrrrrr
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

;----------------------------------------------------------------------------
C64_Palette
	.byte 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0x89, 0x40, 0x36, 0x7A, 0xBF, 0xC7, 0x8A, 0x46, 0xAE, 0x68
	.byte 0xA9, 0x41, 0x3E, 0x31, 0xA2, 0xD0, 0xDC, 0x71, 0x90, 0x5F, 0x25, 0x5C, 0x47, 0x00, 0xBB, 0x77
	.byte 0x6D, 0x55, 0x55, 0x55, 0x80, 0x80, 0x80, 0xAC, 0xEA, 0x88, 0x7C, 0x70, 0xDA, 0xAB, 0xAB, 0xAB
;----------------------------------------------------------------------------
gprefix
	orr r0,r0,r0,lsr#4
;----------------------------------------------------------------------------
gammaconvert;	takes value in r0(0-0xFF), gamma in r1(0-4),returns new value in r0=0x1F
;----------------------------------------------------------------------------
	rsb r2,r0,#0x100
	mul r3,r2,r2
	rsbs r2,r3,#0x10000
	rsb r3,r1,#4
	orr r0,r0,r0,lsl#8
	mul r2,r1,r2
	mla r0,r3,r0,r2
	mov r0,r0,lsr#13

	bx lr

;----------------------------------------------------------------------------
asm_vblank:
;----------------------------------------------------------------------------

	;@ r0 = address of ula memory


	stmdb sp!,{r4-r11,lr}  ;@ save registers on stack


	ldr r6,flicker_cnt
	eors r6,r6,#1
	str r6,flicker_cnt

	ldr r3,=scroll_buffer0
	ldr r4,=dma_buffer0
	
	ldr r1,=0x010B			; Y-delta
	mov r5,#0
	moveq r5,#0x000B
	mov r8,#0
	moveq r8,#0x0040
	mov r7,#0x0040			; X-delta
	mov r2,#192
loop0
	ldrb r0,[r3,r5,lsr#8]
	sub r0,r8,r0,lsl#8
	str r0,[r4],#4
	add r5,r5,r1
	subs r2,r2,#1
	bne loop0



	ldr r2,=pal_buffer
;	ldr r3,=HW_DB_BG_PLTT
	ldr r3,=HW_BG_PLTT
	
	mov r4,#512
loop1
	ldr r0,[r2],#4
	str r0,[r3],#4
	subs r4,r4,#2
	bne loop1

	mov r12,#HW_REG_BASE
	tst r6,#1
	mov r0,#0
	moveq r0,#0x000B
	strh r0,[r12,#REG_BG2Y_OFFSET]
	mov r0,#0x14000							;320<<8
	str r0,[r12,#REG_BG3X_OFFSET]

	ldr r0,=bg2_ptr1
	ldr r0,[r0]
	and r0,r0,#0x20000
	ldrh r1,[r12,#REG_BG2CNT_OFFSET]		;switch bg2 buffers
	bic r1,r1,#0x800
	orr r1,r1,r0,lsr#6
	strh r1,[r12,#REG_BG2CNT_OFFSET]

	mov r0,#0
	str r0,[r12,#REG_DMA2CNT_OFFSET]		;@ Stop DMA2

	ldr r1,=obj_buf_ptr1
	ldr r1,[r1]
	ldr r2,=0x07000000
	ldr r3,=0x84000100
	str r1,[r12,#REG_DMA3SAD_OFFSET]
	str r2,[r12,#REG_DMA3DAD_OFFSET]
	str r3,[r12,#REG_DMA3CNT_OFFSET]		;@ DMA3 Go!

	ldr r1,=dma_buffer0
	add r2,r12,#REG_BG2X_OFFSET
	ldr r3,=0x96600001
	ldr r0,[r1],#4
	str r0,[r2]
	str r1,[r12,#REG_DMA2SAD_OFFSET]
	str r2,[r12,#REG_DMA2DAD_OFFSET]
	str r3,[r12,#REG_DMA2CNT_OFFSET]		;@ DMA2 Go!


	add r12,r12,#0x1000							;SUB gfx
	ldr r0,=film_pos
	ldr r0,[r0]
	strh r0,[r12,#REG_BG0VOFS_OFFSET]
	ldr r0,=keyb_pos
	ldr r0,[r0]
	strh r0,[r12,#REG_BG1VOFS_OFFSET]

	ldmia sp!,{r4-r11,pc}  ;@ restore registers from stack and return to C code

;----------------------------------------------------------------------------
flicker_cnt
	.word 0
;----------------------------------------------------------------------------
VIC_R
;----------------------------------------------------------------------------
	and r1,addy,#0x3F
	cmp r1,#0x11
	beq VIC_ctrl1_R
	cmp r1,#0x12
	beq VIC_scanline_R
	cmp r1,#0x19
	beq VIC_irqflag_R
	cmp r1,#0x2F
	bpl VIC_empty_R
	b VIC_new_R
;	ldr pc,[pc,r1,lsl#2]
;---------------------------
;	DCD 0
;vic_read_tbl
;	DCD VIC_empty_R	;0xD000

VIC_new_R
;	mov r11,r11
	add r2,r10,#vic_base_offset
	ldrb r0,[r2,r1]
	bx lr
	ldr r2,=VICState

;----------------------------------------------------------------------------
VIC_ctrl1_R;		0xD011
;----------------------------------------------------------------------------
	ldr r1,[r10,#scanline]
	and r1,r1,#0x100
	ldrb r0,[r10,#vicctrl1]
	and r0,r0,#0x7F
	orr r0,r0,r1,lsr#1
	bx lr
;----------------------------------------------------------------------------
VIC_scanline_R;		0xD012
;----------------------------------------------------------------------------
	ldrb r0,[r10,#scanline]
	bx lr
;----------------------------------------------------------------------------
VIC_irqflag_R;		0xD019
;----------------------------------------------------------------------------
;	mov r11,r11
	ldrb r0,[r10,#vicirqflag]
	ands r0,r0,#0x0F
	orrne r0,r0,#0x80
	bx lr
;----------------------------------------------------------------------------
VIC_empty_R;		0xD02F - 0xD03F
;----------------------------------------------------------------------------
	mov r0,#0xFF
	bx lr

;----------------------------------------------------------------------------
VIC_W
;----------------------------------------------------------------------------
	and r1,addy,#0x3F
	cmp r1,#0x19
	beq VIC_irqflag_W
	cmp r1,#0x18
	beq VIC_memctrl_W
	cmp r1,#0x16
	beq VIC_ctrl2_W
	cmp r1,#0x11
	beq VIC_ctrl1_W
	cmp r1,#0x2F
	bxpl lr

	b VIC_empty_W
;	ldr pc,[pc,r1,lsl#2]
;---------------------------
;	DCD 0
;vic_write_tbl
;	DCD VIC_empty_W		;0xD000
;	DCD VIC_empty_W		;0xD001
;	DCD VIC_empty_W		;0xD002
;	DCD VIC_empty_W		;0xD003
;	DCD VIC_empty_W		;0xD004
;	DCD VIC_empty_W		;0xD005
;	DCD VIC_empty_W		;0xD006
;	DCD VIC_empty_W		;0xD007
;	DCD VIC_empty_W		;0xD008
;	DCD VIC_empty_W		;0xD009
;	DCD VIC_empty_W		;0xD00A
;	DCD VIC_empty_W		;0xD00B
;	DCD VIC_empty_W		;0xD00C
;	DCD VIC_empty_W		;0xD00D
;	DCD VIC_empty_W		;0xD00E
;	DCD VIC_empty_W		;0xD00F
;	DCD VIC_empty_W		;0xD010
;	DCD VIC_ctrl1_W		;0xD011
;	DCD VIC_empty_W		;0xD012
;	DCD VIC_empty_W		;0xD013
;	DCD VIC_empty_W		;0xD014
;	DCD VIC_empty_W		;0xD015
;	DCD VIC_ctrl2_W		;0xD016
;	DCD VIC_empty_W		;0xD017
;	DCD VIC_memctrl_W	;0xD018
;	DCD VIC_irqflag_W	;0xD019
;	DCD VIC_empty_W		;0xD01A
;	DCD VIC_empty_W		;0xD01B
;	DCD VIC_empty_W		;0xD01C
;	DCD VIC_empty_W		;0xD01D
;	DCD VIC_empty_W		;0xD01E
;	DCD VIC_empty_W		;0xD01F
;	DCD VIC_empty_W		;0xD020
;	DCD VIC_empty_W		;0xD021
;	DCD VIC_empty_W		;0xD022
;	DCD VIC_empty_W		;0xD023
;	DCD VIC_empty_W		;0xD024
;	DCD VIC_empty_W		;0xD025
;	DCD VIC_empty_W		;0xD026
;	DCD VIC_empty_W		;0xD027
;	DCD VIC_empty_W		;0xD028
;	DCD VIC_empty_W		;0xD029
;	DCD VIC_empty_W		;0xD02A
;	DCD VIC_empty_W		;0xD02B
;	DCD VIC_empty_W		;0xD02C
;	DCD VIC_empty_W		;0xD02D
;	DCD VIC_empty_W		;0xD02E
;	DCD VIC_empty_W		;0xD02F

VIC_empty_W
;	mov r11,r11
;	ldr r2,=0x81C
	add r2,r10,#vic_base_offset
;	ldr r2,=VICState
	strb r0,[r2,r1]
	bx lr


;----------------------------------------------------------------------------
VIC_ctrl1_W;		0xD011
;----------------------------------------------------------------------------
	strb r0,[r10,#vicctrl1]
	b SetC64GfxMode
;----------------------------------------------------------------------------
VIC_ctrl2_W;		0xD016
;----------------------------------------------------------------------------
	stmfd sp!,{r0,r12}
	ldrb r1,[r10,#vicctrl2]
	strb r0,[r10,#vicctrl2]
	and r1,r1,#7

	ldr addy,[r10,#scanline]			;addy=scanline
	subs addy,addy,#51
	bmi exit_sx
	cmp addy,#200
	movhi addy,#200
	ldr r0,scrollXline
	cmp r0,addy
	bhi exit_sx
	str addy,scrollXline

	ldr r2,=scroll_buffer0
	add r0,r2,r0
	add r2,r2,addy
sx1
	strb r1,[r2],#-1			;fill backwards from scanline to lastline
	cmp r2,r0
	bpl sx1
exit_sx
	ldmfd sp!,{r0,r12}
	b SetC64GfxMode
;	bx lr

scrollXline .word 0 ;..was when?
;----------------------------------------------------------------------------
VIC_memctrl_W;		0xD018
;----------------------------------------------------------------------------
	strb r0,[r10,#vicmemctrl]
	b SetC64GfxBases
;----------------------------------------------------------------------------
VIC_irqflag_W;		0xD019
;----------------------------------------------------------------------------
;	mov r11,r11
	ldrb r1,[r10,#vicirqflag]
	bic r1,r1,r0
	strb r1,[r10,#vicirqflag]
	bx lr

;----------------------------------------------------------------------------
SetC64GfxBases
;----------------------------------------------------------------------------
	stmfd sp!,{r0,r12}

	ldrb r0,[r10,#cia2porta]	;VIC bank
	eor r0,r0,#0x03
	and r0,r0,#0x03
	ldrb r2,[r10,#vicmemctrl]
	and r1,r2,#0xF0
	orr r1,r1,r0,lsl#8
	add r1,cpu_zpage,r1,lsl#6

	ldr r12,=c64_map_base
	str r1,[r12]

	and r1,r2,#0x0E
	orr r0,r1,r0,lsl#4

	and r1,r0,#0x3C
	cmp r1,#0x04				;0x1000
	cmpne r1,#0x24				;0x9000
	ldreq r2,=Chargen			;r1 = CHRROM
	movne r2,cpu_zpage			;r1 = RAM

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
;----------------------------------------------------------------------------
SetC64GfxMode
;----------------------------------------------------------------------------
	stmfd sp!,{r0,r12}

	mov r11,r11
	ldrb r0,[r10,#vicctrl1]		;VIC control 1
	ldrb r1,[r10,#vicctrl2]		;VIC control 2

	mov r0,r0,lsr#4
	and r0,r0,#0x07
	and r1,r1,#0x10
	orr r0,r0,r1,lsr#1
	adr r1,RenderModeTbl
	ldr r1,[r1,r0,lsl#2]
	str r1,RenderModePtr

	ldmfd sp!,{r0,r12}
	bx lr

RenderModeTbl
	.word RenderBlankLine
	.word RenderTiles			;1
	.word RenderBlankLine
	.word RenderBmp				;3
	.word RenderBlankLine
	.word RenderTilesECM		;5
	.word RenderBlankLine
	.word RenderBlankLine		;7
	.word RenderBlankLine
	.word RenderTilesMCM		;9
	.word RenderBlankLine
	.word RenderBmpMCM			;11
	.word RenderBlankLine
	.word RenderBlankLine
	.word RenderBlankLine
	.word RenderBlankLine
;----------------------------------------------------------------------------
newframe	;called before line 0	(r0-r9 safe to use)
;----------------------------------------------------------------------------
	mov r0,#0
	str r0,[r10,#scanline]	;reset scanline count

	ldr r0,[r10,#frame]
	and r0,r0,#1
	mov r0,r0,lsl#7
	ldr r1,=obj_counter
	str r0,[r1]

; !! Add dublebuffering of background as well !!


	ldr r1,=obj_buf_ptr0
	ldr r1,[r1]
	mov r0,#0x2c0		;double, y=191
	mov r2,#128
spr_clr_loop
	str r0,[r1],#8
	subs r2,r2,#1
	bne spr_clr_loop

	mov r0,#0
	str r0,scrollXline

	bx lr

;----------------------------------------------------------------------------
endframe	;called just before screen end (~line 240)	(r0-r2 safe to use)
;----------------------------------------------------------------------------
	stmfd sp!,{r3-r9,lr}

;	bl bg_finish
;	bl bgchrfinish
;--------------------------
;	bl UpdateBGTiles
;--------------------------
;	bl sprDMA_do
;--------------------------
	bl PaletteTxAll
;--------------------------
	ldrb r0,[r10,#vicctrl2]
	bl VIC_ctrl2_W

;	mrs r4,cpsr
;	orr r1,r4,#0x80			;--> Disable IRQ.
;	msr cpsr_cf,r1

	ldr r2,=obj_buf_ptr0	;switch obj buffers
	ldmia r2,{r0,r1}
	str r0,[r2,#4]
	str r1,[r2]

	ldr r2,=bg2_ptr0		;switch bg2 buffers
	ldmia r2,{r0,r1}
	str r0,[r2,#4]
	str r1,[r2]

	ldr r2,=scr_ptr0		;switch scroll buffers
	ldmia r2,{r0,r1}
	str r0,[r2,#4]
	str r1,[r2]

;	mov r0,#1
;	str r0,oambufferready


;	msr cpsr_cf,r4			;--> restore mode,Enable IRQ.


	ldmfd sp!,{r3-r9,lr}
	bx lr
;----------------------------------------------------------------------------
PaletteTxAll		; Called from ui.c
;----------------------------------------------------------------------------
	stmfd sp!,{r4-r7,r10,lr}
	ldr globalptr,=wram_global_base
	ldr r2,=c64_palette_mod
	ldr r3,=pal_buffer
	mov r7,#0x1E
	ldrb r0,[r10,#vicbrdcol]
	and r0,r7,r0,lsl#1
	ldrh r0,[r2,r0]
	strh r0,[r3],#2

	ldrb r4,[r10,#vicbgr1col]
	and r4,r7,r4,lsl#1
	ldrh r4,[r2,r4]
	ldrb r5,[r10,#vicbgr2col]
	and r5,r7,r5,lsl#1
	ldrh r5,[r2,r5]


	mov r1,#0
c64loop1					;normal BG tile colors
	ldrh r0,[r2,r1]
	strh r4,[r3],#0x02
	strh r5,[r3],#0x02
	strh r0,[r3],#0x1C
	add r1,r1,#2
	cmp r1,#0x20
	bne c64loop1

	ldrb r0,[r10,#vicctrl1]		;check for multicolor/bitmap
	tst r0,#0x20
	ldrneb r0,[r10,#vicctrl2]
	tstne r0,#0x10
	beq PaletteTxEnd


	sub r3,r3,#2
	sub r3,r3,#0x1A0
	mov r1,#30
c64loop2
	ldrh r0,[r2,r1]
	strh r0,[r3,r1]
	subs r1,r1,#2
	bpl c64loop2
PaletteTxEnd

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
c64loop3					;sprite colors.
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

;----------------------------------------------------------------------------
RenderLine;			r0=?, r1=scanline.
;----------------------------------------------------------------------------
	stmfd sp!,{r1-r11,lr}
	bl RenderSprites

	subs r1,r1,#51
	bmi exit_tile_render
	cmp r1,#200
	bpl exit_tile_render

	ldr r9,=bg2_ptr0
	ldr r9,[r9]					;background base-address.
	add r9,r9,r1,lsl#9			;y-offset

	bic r0,r1,#0x07
	and r1,r1,#0x07
	add r0,r0,r0,lsl#2

	ldr pc,RenderModePtr

RenderModePtr
	.word RenderTiles

;----------------------------------------------------------------------------
RenderTiles
;----------------------------------------------------------------------------

;	mov r11,r11
	ldr r2,=c64_map_base
	ldr r5,[r2]
	sub r6,cpu_zpage,#0x400		;bg colormap
	add r5,r5,r0
	add r6,r6,r0

	ldr r0,=c64_chr_base
	ldr r7,[r0]					;bg tile bitmap
	ldr r12,=chr_decode_3
	add r7,r7,r1

	ldr r11,=0x03030303
	mov r8,#10					;width/4 of C64 screen
bgrdloop
	ldr r0,[r5],#4				;Read from C64 Tilemap RAM
	ldr r1,[r6],#4				;Read from C64 Colormap RAM
	orr r1,r11,r1,lsl#4

	and r3,r0,#0x000000FF
	ldrb r3,[r7,r3,lsl#3]		;read bitmap data
	and r10,r1,#0x000000FF
	add r3,r12,r3,lsl#3

	ldmia r3,{r2,r3}
	mul r4,r2,r10
	mul r10,r3,r10
	stmia r9!,{r4,r10}


	and r3,r0,#0x0000FF00
	ldrb r3,[r7,r3,lsr#5]		;read bitmap data
	and r10,r1,#0x0000FF00
	add r3,r12,r3,lsl#3

	ldmia r3,{r2,r3}
	mov r10,r10,lsr#8
	mul r4,r2,r10
	mul r10,r3,r10
	stmia r9!,{r4,r10}


	and r3,r0,#0x00FF0000
	ldrb r3,[r7,r3,lsr#13]		;read bitmap data
	and r10,r1,#0x00FF0000
	add r3,r12,r3,lsl#3

	ldmia r3,{r2,r3}
	mov r10,r10,lsr#16
	mul r4,r2,r10
	mul r10,r3,r10
	stmia r9!,{r4,r10}


	and r3,r0,#0xFF000000
	ldrb r3,[r7,r3,lsr#21]		;read bitmap data
	mov r10,r1,lsr#24
	add r3,r12,r3,lsl#3

	ldmia r3,{r2,r3}
	mul r4,r2,r10
	mul r10,r3,r10
	stmia r9!,{r4,r10}

	subs r8,r8,#1
	bne bgrdloop

	ldr globalptr,=wram_global_base
	ldrb r0,[r10,#vicbgr0col]	;background color
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

exit_tile_render
	ldmfd sp!,{r1-r11,lr}
	bx lr

;----------------------------------------------------------------------------
RenderTilesECM;					ExtendedColorMode
;----------------------------------------------------------------------------

	ldr r2,=c64_map_base
	ldr r5,[r2]
	sub r6,cpu_zpage,#0x400		;bg colormap
	add r5,r5,r0
	add r6,r6,r0

	ldr r0,=c64_chr_base
	ldr r7,[r0]					;bg tile bitmap
	ldr r12,=chr_decode_3
	add r7,r7,r1

;	add r10,r9,#320

	ldr r11,=0x03030303
	mov r8,#10					;width/4 of C64 screen
bgrdloop1
	ldr r0,[r5],#4				;Read from C64 Tilemap RAM
	ldr r1,[r6],#4				;Read from C64 Colormap RAM
	orr r1,r11,r1,lsl#4

	and r3,r0,#0x0000003F
	ldrb r3,[r7,r3,lsl#3]		;read bitmap data
	and r4,r1,#0x000000FF
	add r3,r12,r3,lsl#3

	ldmia r3,{r2,r3}
	mul r2,r4,r2
	mul r3,r4,r3
	stmia r9!,{r2,r3}


	and r3,r0,#0x00003F00
	ldrb r3,[r7,r3,lsr#5]		;read bitmap data
	and r4,r1,#0x0000FF00
	add r3,r12,r3,lsl#3

	ldmia r3,{r2,r3}
	mov r4,r4,lsr#8
	mul r2,r4,r2
	mul r3,r4,r3
	stmia r9!,{r2,r3}


	and r3,r0,#0x003F0000
	ldrb r3,[r7,r3,lsr#13]		;read bitmap data
	and r4,r1,#0x00FF0000
	add r3,r12,r3,lsl#3

	ldmia r3,{r2,r3}
	mov r4,r4,lsr#16
	mul r2,r4,r2
	mul r3,r4,r3
	stmia r9!,{r2,r3}


	and r3,r0,#0x3F000000
	ldrb r3,[r7,r3,lsr#21]		;read bitmap data
	mov r4,r1,lsr#24
	add r3,r12,r3,lsl#3

	ldmia r3,{r2,r3}
	mul r2,r4,r2
	mul r3,r4,r3
	stmia r9!,{r2,r3}

	subs r8,r8,#1
	bne bgrdloop1

	ldr globalptr,=wram_global_base
	ldrb r0,[r10,#vicbgr0col]	;background color
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
;----------------------------------------------------------------------------
RenderTilesMCM;					MultiColorMode
;----------------------------------------------------------------------------

	ldr r2,=c64_map_base
	ldr r5,[r2]
	sub r6,cpu_zpage,#0x400		;bg colormap
	add r5,r5,r0
	add r6,r6,r0

	ldr r0,=c64_chr_base
	ldr r7,[r0]					;bg tile bitmap
	ldr r12,=chr_decode_3
	ldr lr,=chr_decode_4
	add r7,r7,r1

	ldr r11,=0x03030303
	mov r8,#10					;width/4 of C64 screen
bgrdloop2
	ldr r0,[r5],#4				;Read from C64 Tilemap RAM
	ldr r1,[r6],#4				;Read from C64 Colormap RAM
	orr r1,r11,r1,lsl#4

	and r3,r0,#0x000000FF
	ldrb r3,[r7,r3,lsl#3]		;read bitmap data
	movs r4,r1,lsl#25
	addcc r3,r12,r3,lsl#3
	addcs r3,lr,r3,lsl#3

	ldmia r3,{r2,r3}
	mov r4,r4,lsr#25

	andcs r10,r2,r2,lsr#1
	mulcs r10,r4,r10
	orrcs r2,r2,r10
	andcs r10,r3,r3,lsr#1
	mulcs r10,r4,r10
	orrcs r3,r3,r10

	mulcc r2,r4,r2
	mulcc r3,r4,r3
	stmia r9!,{r2,r3}


	and r3,r0,#0x0000FF00
	ldrb r3,[r7,r3,lsr#5]		;read bitmap data
	movs r4,r1,lsl#17
	addcc r3,r12,r3,lsl#3
	addcs r3,lr,r3,lsl#3

	ldmia r3,{r2,r3}
	mov r4,r4,lsr#25

	andcs r10,r2,r2,lsr#1
	mulcs r10,r4,r10
	orrcs r2,r2,r10
	andcs r10,r3,r3,lsr#1
	mulcs r10,r4,r10
	orrcs r3,r3,r10

	mulcc r2,r4,r2
	mulcc r3,r4,r3
	stmia r9!,{r2,r3}


	and r3,r0,#0x00FF0000
	ldrb r3,[r7,r3,lsr#13]		;read bitmap data
	movs r4,r1,lsl#9
	addcc r3,r12,r3,lsl#3
	addcs r3,lr,r3,lsl#3

	ldmia r3,{r2,r3}
	mov r4,r4,lsr#25

	andcs r10,r2,r2,lsr#1
	mulcs r10,r4,r10
	orrcs r2,r2,r10
	andcs r10,r3,r3,lsr#1
	mulcs r10,r4,r10
	orrcs r3,r3,r10

	mulcc r2,r4,r2
	mulcc r3,r4,r3
	stmia r9!,{r2,r3}


	and r3,r0,#0xFF000000
	ldrb r3,[r7,r3,lsr#21]		;read bitmap data
	movs r4,r1,lsl#1
	addcc r3,r12,r3,lsl#3
	addcs r3,lr,r3,lsl#3

	ldmia r3,{r2,r3}
	mov r4,r4,lsr#25

	andcs r10,r2,r2,lsr#1
	mulcs r10,r4,r10
	orrcs r2,r2,r10
	andcs r10,r3,r3,lsr#1
	mulcs r10,r4,r10
	orrcs r3,r3,r10

	mulcc r2,r4,r2
	mulcc r3,r4,r3
	stmia r9!,{r2,r3}

	subs r8,r8,#1
	bne bgrdloop2

	ldr globalptr,=wram_global_base
	ldrb r0,[r10,#vicbgr0col]	;background color
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

exit_tilemcm_render
	ldmfd sp!,{r1-r11,lr}
	bx lr
;----------------------------------------------------------------------------
RenderBmp
;----------------------------------------------------------------------------
	ldr r2,=c64_map_base
	ldr r5,[r2]
	add r5,r5,r0

	ldr r2,=c64_bmp_base
	ldr r6,[r2]					;bg tile bitmap
	ldr r12,=chr_decode_3
	add r6,r6,r0,lsl#3
	add r6,r6,r1

	add r10,r9,#320
	mov r11,r11

	ldr r7,=0x0F0F0F0F
	ldr r11,=0x03030303
	mov r8,#10					;width/4 of C64 screen
bgrdloop4
	ldr r0,[r5],#4				;Read from C64 Tilemap RAM (color)
	and r1,r0,r7
	and r0,r0,r7,lsl#4
	orr r0,r11,r0

	ldrb r3,[r6],#8				;read bitmap data
	and r4,r0,#0x000000FF
	add r3,r12,r3,lsl#3

	ldmia r3,{r2,r3}
	mul r2,r4,r2
	mul r4,r3,r4
	stmia r9!,{r2,r4}


	ldrb r3,[r6],#8				;read bitmap data
	and r4,r0,#0x0000FF00
	add r3,r12,r3,lsl#3

	ldmia r3,{r2,r3}
	mov r4,r4,lsr#8
	mul r2,r4,r2
	mul r4,r3,r4
	stmia r9!,{r2,r4}


	ldrb r3,[r6],#8				;read bitmap data
	and r4,r0,#0x00FF0000
	add r3,r12,r3,lsl#3

	ldmia r3,{r2,r3}
	mov r4,r4,lsr#16
	mul r2,r4,r2
	mul r4,r3,r4
	stmia r9!,{r2,r4}


	ldrb r3,[r6],#8				;read bitmap data
	mov r4,r0,lsr#24
	add r3,r12,r3,lsl#3

	ldmia r3,{r2,r3}
	mul r0,r2,r4
	mul r4,r3,r4
	stmia r9!,{r0,r4}
	
	orr r1,r11,r1,lsl#4
	str r1,[r10],#4				;background color

	subs r8,r8,#1
	bne bgrdloop4

exit_bmp_render
	ldmfd sp!,{r1-r11,lr}
	bx lr
;----------------------------------------------------------------------------
RenderBmpMCM;					MultiColorMode
;----------------------------------------------------------------------------

	ldr r2,=c64_map_base
	ldr r4,[r2]
	sub r5,cpu_zpage,#0x400		;bg colormap
	add r4,r4,r0
	add r5,r5,r0

	ldr r2,=c64_bmp_base
	ldr r6,[r2]					;bg tile bitmap
	add r6,r6,r0,lsl#3
	add r6,r6,r1

	mov r12,#0x18
	mov r10,#0xFF
	ldr r11,=0x03030300
	mov r8,#40					;width of C64 screen
bgrdloop5
	ldrb r0,[r4],#1				;Read from C64 Tilemap RAM (color 1,2)
	ldrb r1,[r5],#1				;Read from C64 Color RAM (color 3)
	
	mov r0,r0,ror#4
	orr r1,r11,r1,lsl#28
	ldrb r2,[r6],#8				;read bitmap data
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
	ldrb r0,[r10,#vicbgr0col]	;background color
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

exit_bmpcmc_render
	ldmfd sp!,{r1-r11,lr}
	bx lr
;----------------------------------------------------------------------------
RenderBlankLine;
;----------------------------------------------------------------------------

	ldrb r0,[r10,#vicbrdcol]	;border color
	and r0,r0,#0x0F
	mov r0,r0,lsl#4
	orr r0,r0,#3
	orr r0,r0,r0,lsl#8
	orr r0,r0,r0,lsl#16
	mov r1,#90					;screen plus background
blankloop
	str r0,[r9],#4
	subs r1,r1,#1
	bne blankloop

exit_blank_render
	ldmfd sp!,{r1-r11,lr}
	bx lr
;----------------------------------------------------------------------------


;----------------------------------------------------------------------------
RenderSprites;			r0=?, r1=scanline.
;----------------------------------------------------------------------------
	stmfd sp!,{r1,lr}

	add r3,r10,#vic_base_offset
	ldr r7,=obj_buf_ptr0
	ldr r7,[r7]
	ldr r0,=obj_counter
	ldr r0,[r0]
	and r0,r0,#0x7f
	add r7,r7,r0,lsl#3

	ldrb r9,[r10,#vicsprenable]

	mov r8,#0
spr_loop
	ldrh r0,[r3],#2
	cmp r1,r0,lsr#8
	bne next_spr
	mov r4,#1
	tst r9,r4,lsl r8
	beq next_spr

	ldr r6,=0x1ff
	mov r2,r0,lsr#8			;y-pos
	ldr r5,=0xF5C2
	mul r2,r5,r2
	mov r2,r2,lsr#16
	sub r2,r2,#48			;(50)
	and r2,r2,#0xff


	and r0,r0,#0xFF			;x-pos
	ldrb r5,[r10,#vicsprxpos]
	tst r5,r4,lsl r8
	orrne r0,r0,#0x100
	ldr r5,=0xCCCC
	mul r0,r5,r0

;	sub r0,r0,#0x18			;fix up X
	sub r0,r0,#0x140000
	and r0,r6,r0,lsr#16


	orr r0,r0,#0x8000		;32x32 size
	orr r0,r2,r0,lsl#16
	str r0,[r7],#4			;store OBJ Atr 0,1. Xpos, ypos, xflip, scale/rot, size, shape.

	bl VRAM_spr				;jump to spr copy
ret01
	ldr r4,=obj_counter
	ldr r2,[r4]
	mov r0,r2,lsl#2			;tile nr.
	orr r0,r0,r8,lsl#12		;color
;	orr r0,r0,#PRIORITY		;priority
	strh r0,[r7],#4			;store OBJ Atr 2. Pattern, palette.
	add r2,r2,#1
;	cmp r2,#0x100
;	movpl r2,#0
	str r2,[r4]

next_spr

	add r8,r8,#1
	cmp r8,#8
	bne spr_loop

exit_sprite_render
	ldmfd sp!,{r1,lr}
	bx lr

;----------------------------------------------------------------------------
VRAM_spr
;----------------------------------------------------------------------------
	stmfd sp!,{r1}

	ldr r5,=obj_base
	ldr r5,[r5]
	ldr r0,=obj_counter
	ldr r0,[r0]
	add r5,r5,r0,lsl#9

	ldr r0,=c64_map_base
	ldr r12,[r0]					;spr tile bitmap
	add r12,r12,#0x3F8
	ldrb r0,[r12,r8]				;tile nr.

	ldrb r2,[r10,#cia2porta]		;VIC bank
	eor r2,r2,#0x03
	and r2,r2,#0x03
	add r12,cpu_zpage,r2,lsl#14
	add r12,r12,r0,lsl#6

	mov r11,r11
	ldrb r0,[r10,#vicsprmode]
	tst r0,r4,lsl r8
	beq VRAM_spr_mono


	ldr r1,=chr_decode_2
	
	mov r4,#24
	mov r2,#0
spr_loop2
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
;----------------------------------------------------------------------------
VRAM_spr_mono
;----------------------------------------------------------------------------

	ldr r1,=chr_decode
	
	mov r4,#24
	mov r2,#0
spr_loop3
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
;----------------------------------------------------------------------------





 .bss
;chr_decode_new			; 16*16*16*16*4
; .space 0x40000
chr_decode
 .space 256*4
chr_decode_2
 .space 256*4
chr_decode_3
 .space 256*8
chr_decode_4
 .space 256*8
pal_buffer
 .space 512*2
obj_buffer0
 .space 128*8
obj_buffer1
 .space 128*8
dma_buffer0
 .space 192*4
scroll_buffer0
 .space 256
scroll_buffer1
 .space 256
c64_palette_mod
 .space 16*2

bg2_ptr0
 .word 0
bg2_ptr1
 .word 0
scr_ptr0
 .word 0
scr_ptr1
 .word 0
obj_buf_ptr0
 .word 0
obj_buf_ptr1
 .word 0
obj_counter
 .word 0

c64_map_base
 .word 0
c64_chr_base
 .word 0
c64_bmp_base
 .word 0

 .section .dtcm
					;!!! Something MUST be referenced here, otherwise the compiler scraps it !!!
VICState
	.byte 0 ; vicspr0x			;0xD000
	.byte 0 ; vicspr0y
	.byte 0 ; vicspr1x
	.byte 0 ; vicspr1y
	.byte 0 ; vicspr2x
	.byte 0 ; vicspr2y
	.byte 0 ; vicspr3x
	.byte 0 ; vicspr3y
	.byte 0 ; vicspr4x
	.byte 0 ; vicspr4y
	.byte 0 ; vicspr5x
	.byte 0 ; vicspr5y
	.byte 0 ; vicspr6x
	.byte 0 ; vicspr6y
	.byte 0 ; vicspr7x
	.byte 0 ; vicspr7y
	.byte 0 ; vicsprxpos		;0xD010
	.byte 0 ; vicctrl1			;0xD011
	.byte 0 ; vicraster
	.byte 0 ; viclightpenx
	.byte 0 ; viclightpeny
	.byte 0 ; vicsprenable		;0xD015
	.byte 0 ; vicctrl2
	.byte 0 ; vicsprexpy
	.byte 0 ; vicmemctrl		;0xD018
	.byte 0 ; vicirqflag		;0xD019
	.byte 0 ; vicirqenable		;0xD01A
	.byte 0 ; vicsprprio		;0xD01B
	.byte 0 ; vicsprmode		;0xD01C
	.byte 0 ; vicsprexpx		;0xD01D
	.byte 0 ; vicsprsprcol		;0xD01E
	.byte 0 ; vicsprbgrcol		;0xD01F
	.byte 0 ; vicbrdcol			;0xD020
	.byte 0 ; vicbgr0col		;0xD021
	.byte 0 ; vicbgr1col		;0xD022
	.byte 0 ; vicbgr2col		;0xD023
	.byte 0 ; vicbgr3col		;0xD024
	.byte 0 ; vicsprm0col		;0xD025
	.byte 0 ; vicsprm1col		;0xD026
	.byte 0 ; vicspr0col		;0xD027
	.byte 0 ; vicspr1col		;0xD028
	.byte 0 ; vicspr2col		;0xD029
	.byte 0 ; vicspr3col		;0xD02A
	.byte 0 ; vicspr4col		;0xD02B
	.byte 0 ; vicspr5col		;0xD02C
	.byte 0 ; vicspr6col		;0xD02D
	.byte 0 ; vicspr7col		;0xD02E
	.byte 0 ; vicempty0			;0xD02F

