#define SDK_ASM


;@----------------------------------------------------------------------------

globalptr	.req r10


AGB_IRQVECT		= 0x03007FFC
AGB_PALETTE		= 0x05000000
NTR_VRAM		= 0x06000000
AGB_OAM			= 0x07000000
AGB_SRAM		= 0x0A000000
DEBUGSCREEN		= NTR_VRAM+0x3800


;@----------------------------------------------------------------------------

#define scanline		294*4
#define lastscanline	297*4
//#define irqPending		300*4

			;@ gfx.s
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

			;@ io.s
#define cia_base_offset 0x4F0

#define cia1_base_offset	cia_base_offset
#define cia1porta		cia1_base_offset
#define cia1portb		cia1_base_offset +1
#define cia1ddra		cia1_base_offset +2
#define cia1ddrb		cia1_base_offset +3
#define cia1timeral		cia1_base_offset +4
#define cia1timerah		cia1_base_offset +5
#define cia1timerbl		cia1_base_offset +6
#define cia1timerbh		cia1_base_offset +7
#define cia1tod0		cia1_base_offset +8
#define cia1tod1		cia1_base_offset +9
#define cia1tod2		cia1_base_offset +10
#define cia1tod3		cia1_base_offset +11
#define cia1sioport		cia1_base_offset +12
#define cia1irqctrl		cia1_base_offset +13
#define cia1ctrla		cia1_base_offset +14
#define cia1ctrlb		cia1_base_offset +15
#define timer1a			cia1_base_offset +16
#define timer1b			cia1_base_offset +20

#define cia2_base_offset	cia_base_offset +24
#define cia2porta		cia2_base_offset
#define cia2portb		cia2_base_offset +1
#define cia2ddra		cia2_base_offset +2
#define cia2ddrb		cia2_base_offset +3
#define cia2timeral		cia2_base_offset +4
#define cia2timerah		cia2_base_offset +5
#define cia2timerbl		cia2_base_offset +6
#define cia2timerbh		cia2_base_offset +7
#define cia2tod0		cia2_base_offset +8
#define cia2tod1		cia2_base_offset +9
#define cia2tod2		cia2_base_offset +10
#define cia2tod3		cia2_base_offset +11
#define cia2sioport		cia2_base_offset +12
#define cia2irqctrl		cia2_base_offset +13
#define cia2ctrla		cia2_base_offset +14
#define cia2ctrlb		cia2_base_offset +15
#define timer2a			cia2_base_offset +16
#define timer2b			cia2_base_offset +20

#define cia1irq			cia_base_offset +48
#define cia2nmi			cia_base_offset +49


;@-----------------------------------------------------------cartflags
#define SRAM		0x02	//;@ save SRAM
;@-----------------------------------------------------------emuflags
#define PALTIMING	1	//;@ PAL timing =)
#define EXPORTFLAG	2	//;@ JAP/Rest of world
#define COUNTRY		4	//;@ 0=US 1=JAP
;@ ?				16
#define FOLLOWMEM   32	//;@ 0=follow sprite, 1=follow mem

				;@ Bits 8-15=scale type

#define UNSCALED_NOAUTO	0	//;@ display types
#define UNSCALED_AUTO	1
#define SCALED			2
#define SCALED_SPRITES	3

				;@ Bits 16-31=sprite follow val

