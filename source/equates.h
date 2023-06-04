#define SDK_ASM


;----------------------------------------------------------------------------


AGB_IRQVECT		= 0x03007FFC
AGB_PALETTE		= 0x05000000
NTR_VRAM		= 0x06000000
AGB_OAM			= 0x07000000
AGB_SRAM		= 0x0A000000
DEBUGSCREEN		= NTR_VRAM+0x3800


		//r0,r1,r2=temp regs
#define m6502_nz	r3//bit 31=N, Z=1 if bits 0-7=0
#define m6502_rmem	r4//readmem_tbl
#define m6502_a		r5//bits 0-23=0, also used to clear bytes in memory
#define m6502_x		r6//bits 0-23=0
#define m6502_y		r7//bits 0-23=0
#define cycles		r8//also VDIC flags
#define m6502_pc	r9
#define globalptr	r10//=wram_globals* ptr
#define m6502_optbl	r10
#define cpu_zpage	r11//=CPU_RAM
#define addy		r12//keep this at r12 (scratch for APCS)
		;r13=SP
		;r14=LR
		;r15=PC
;----------------------------------------------------------------------------

; MAP 0,cpu_zpage
;chr_decode2 # 0x400
;oam_buffer1 # 0x300
;oam_buffer2 # 0x300
;yscale_extra # 0x50	;(240-160) extra 80 is for scrolling unscaled sprites
;yscale_lookup # 0x100	;sprite Y LUT

;everything in wram_globals* areas:

; MAP 0,globalptr	;6510.s
;	.section offset_name, 4
; .offset
#define opz 0
#define readmem_tbl		256*4
#define writemem_tbl	264*4
#define memmap_tbl		272*4
#define mapperdata		280*4
#define cpuregs			282*4
#define m6502_s			289*4
#define lastbank		290*4
#define nexttimeout		291*4
#define nexttimeout_	292*4
#define oldcycles		293*4
#define scanline		294*4
#define scanlinehook	295*4
#define cyclesperscanline 296*4
#define lastscanline	297*4
#define hackflags		298*4
#define frame			299*4
#define irqPending		300*4


			;gfx.s
#define vic_base_offset 0x4C0

#define vicspr0x		vic_base_offset
#define vicspr0y		vic_base_offset +1
#define vicspr1x		vic_base_offset +2
#define vicspr1y		vic_base_offset +3
#define vicspr2x		vic_base_offset +4
#define vicspr2y		vic_base_offset +5
#define vicspr3x		vic_base_offset +6
#define vicspr3y		vic_base_offset +7
#define vicspr4x		vic_base_offset +8
#define vicspr4y		vic_base_offset +9
#define vicspr5x		vic_base_offset +10
#define vicspr5y		vic_base_offset +11
#define vicspr6x		vic_base_offset +12
#define vicspr6y		vic_base_offset +13
#define vicspr7x		vic_base_offset +14
#define vicspr7y		vic_base_offset +15
#define vicsprxpos		vic_base_offset +16
#define vicctrl1		vic_base_offset +17
#define vicraster		vic_base_offset +18
#define viclightpenx	vic_base_offset +19
#define viclightpeny	vic_base_offset +20
#define vicsprenable	vic_base_offset +21
#define vicctrl2		vic_base_offset +22
#define vicsprexpy		vic_base_offset +23
#define vicmemctrl		vic_base_offset +24
#define vicirqflag		vic_base_offset +25
#define vicirqenable	vic_base_offset +26
#define vicsprprio		vic_base_offset +27
#define vicsprmode		vic_base_offset +28
#define vicsprexpx		vic_base_offset +29
#define vicsprsprcol	vic_base_offset +30
#define vicsprbgrcol	vic_base_offset +31
#define vicbrdcol		vic_base_offset +32
#define vicbgr0col		vic_base_offset +33
#define vicbgr1col		vic_base_offset +34
#define vicbgr2col		vic_base_offset +35
#define vicbgr3col		vic_base_offset +36
#define vicsprm0col		vic_base_offset +37
#define vicsprm1col		vic_base_offset +38
#define vicspr0col		vic_base_offset +39
#define vicspr1col		vic_base_offset +40
#define vicspr2col		vic_base_offset +41
#define vicspr3col		vic_base_offset +42
#define vicspr4col		vic_base_offset +43
#define vicspr5col		vic_base_offset +44
#define vicspr6col		vic_base_offset +45
#define vicspr7col		vic_base_offset +46
#define vicempty0		vic_base_offset +47

			;io.s
#define cia_base_offset 0x4F0
			
#define cia1porta		cia_base_offset
#define cia1portb		cia_base_offset +1
#define cia1ddra		cia_base_offset +2
#define cia1ddrb		cia_base_offset +3
#define cia1timeral		cia_base_offset +4
#define cia1timerah		cia_base_offset +5
#define cia1timerbl		cia_base_offset +6
#define cia1timerbh		cia_base_offset +7
#define cia1tod0		cia_base_offset +8
#define cia1tod1		cia_base_offset +9
#define cia1tod2		cia_base_offset +10
#define cia1tod3		cia_base_offset +11
#define cia1sioport		cia_base_offset +12
#define cia1irqctrl		cia_base_offset +13
#define cia1ctrla		cia_base_offset +14
#define cia1ctrlb		cia_base_offset +15
#define timer1a			cia_base_offset +16
#define timer1b			cia_base_offset +20

#define cia2porta		cia_base_offset +24
#define cia2portb		cia_base_offset +25
#define cia2ddra		cia_base_offset +26
#define cia2ddrb		cia_base_offset +27
#define cia2timeral		cia_base_offset +28
#define cia2timerah		cia_base_offset +29
#define cia2timerbl		cia_base_offset +30
#define cia2timerbh		cia_base_offset +31
#define cia2tod0		cia_base_offset +32
#define cia2tod1		cia_base_offset +33
#define cia2tod2		cia_base_offset +34
#define cia2tod3		cia_base_offset +35
#define cia2sioport		cia_base_offset +36
#define cia2irqctrl		cia_base_offset +37
#define cia2ctrla		cia_base_offset +38
#define cia2ctrlb		cia_base_offset +39
#define timer2a			cia_base_offset +40
#define timer2b			cia_base_offset +44

#define cia1irq			cia_base_offset +48
#define cia2nmi			cia_base_offset +49
;align1_ # 2

			;cart.s (wram_globals2)
;rombase # 4
;romnumber # 4
;emuflags # 4
;BGmirror # 4

;romsize # 4
;SIDInitAddress # 4
;SIDPlayAddress # 4

;cartflags # 4
;	.section old_name, 4

;----------------------------------------------------------------------------
#define IRQ_VECTOR	0xfffe	//;@ IRQ/BRK interrupt vector address
#define RST_VECTOR	0xfffc	//;@ RESET interrupt vector address
#define NMI_VECTOR	0xfffa	//;@ NMI interrupt vector address
;-----------------------------------------------------------cartflags
#define SRAM		0x02	//;@ save SRAM
;-----------------------------------------------------------emuflags
#define PALTIMING	1	//;@ PAL timing =)
#define EXPORTFLAG	2	//;@ JAP/Rest of world
#define COUNTRY		4	//;@ 0=US 1=JAP
;?					16
#define FOLLOWMEM   32	//;@ 0=follow sprite, 1=follow mem

				;bits 8-15=scale type

#define UNSCALED_NOAUTO	0	//;@ display types
#define UNSCALED_AUTO	1
#define SCALED			2
#define SCALED_SPRITES	3

				;bits 16-31=sprite follow val

;----------------------------------------------------------------------------
#define CYC_SHIFT		8
#define CYCLE			(1<<CYC_SHIFT) //;@ one cycle (63*CYCLE cycles per scanline)

;cycle flags- (stored in cycles reg for speed)

#define CYC_C			0x01	//;@ Carry bit
#define CYC_I			0x04	//;@ IRQ mask
#define CYC_D			0x08	//;@ Decimal bit
#define CYC_V			0x40	//;@ Overflow bit
#define CYC_MASK		CYCLE-1	//;@ Mask
;----------------------------------------------------------------------------

;		END

