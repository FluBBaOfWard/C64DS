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


			;@ gfx.s
#define vic_base_offset m6502Size

#define vicSpr0X		vic_base_offset
#define vicSpr0Y		vic_base_offset +1
#define vicSpr1X		vic_base_offset +2
#define vicSpr1Y		vic_base_offset +3
#define vicSpr2X		vic_base_offset +4
#define vicSpr2Y		vic_base_offset +5
#define vicSpr3X		vic_base_offset +6
#define vicSpr3Y		vic_base_offset +7
#define vicSpr4X		vic_base_offset +8
#define vicSpr4Y		vic_base_offset +9
#define vicSpr5X		vic_base_offset +10
#define vicSpr5Y		vic_base_offset +11
#define vicSpr6X		vic_base_offset +12
#define vicSpr6Y		vic_base_offset +13
#define vicSpr7X		vic_base_offset +14
#define vicSpr7Y		vic_base_offset +15
#define vicSprXPos		vic_base_offset +16
#define vicCtrl1		vic_base_offset +17
#define vicRaster		vic_base_offset +18
#define vicLightPenX	vic_base_offset +19
#define vicLightPenY	vic_base_offset +20
#define vicSprEnable	vic_base_offset +21
#define vicCtrl2		vic_base_offset +22
#define vicSprExpY		vic_base_offset +23
#define vicMemCtrl		vic_base_offset +24
#define vicIrqFlag		vic_base_offset +25
#define vicIrqEnable	vic_base_offset +26
#define vicSprPrio		vic_base_offset +27
#define vicSprMode		vic_base_offset +28
#define vicSprExpX		vic_base_offset +29
#define vicSprSprCol	vic_base_offset +30
#define vicSprBgrCol	vic_base_offset +31
#define vicBrdCol		vic_base_offset +32
#define vicBgr0Col		vic_base_offset +33
#define vicBgr1Col		vic_base_offset +34
#define vicBgr2Col		vic_base_offset +35
#define vicBgr3Col		vic_base_offset +36
#define vicSprM0Col		vic_base_offset +37
#define vicSprM1Col		vic_base_offset +38
#define vicSpr0Col		vic_base_offset +39
#define vicSpr1Col		vic_base_offset +40
#define vicSpr2Col		vic_base_offset +41
#define vicSpr3Col		vic_base_offset +42
#define vicSpr4Col		vic_base_offset +43
#define vicSpr5Col		vic_base_offset +44
#define vicSpr6Col		vic_base_offset +45
#define vicSpr7Col		vic_base_offset +46
#define vicEmpty0		vic_base_offset +47

#define scanline		vic_base_offset +48
#define lastscanline	vic_base_offset +52
#define vicSize			56

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

