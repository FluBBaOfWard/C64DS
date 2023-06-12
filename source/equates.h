
;@----------------------------------------------------------------------------

globalptr	.req r10

;@----------------------------------------------------------------------------


;@-----------------------------------------------------------cartflags
#define SRAM		0x02	//;@ save SRAM
;@-----------------------------------------------------------emuflags
#define PALTIMING	1	//;@ PAL timing =)
#define EXPORTFLAG	2	//;@ JAP/Rest of world
#define COUNTRY		4	//;@ 0=US 1=JAP

				;@ Bits 8-15=scale type

#define UNSCALED_NOAUTO	0	//;@ display types
#define UNSCALED_AUTO	1
#define SCALED			2
#define SCALED_SPRITES	3

