/*
 * File:		main.c
 * Purpose:		sample C Stationery program
 *
 */

#include <nitro.h>
#include <nitro/fs.h>
#include <nitro/types.h>
#include <nitro/mi.h>
#include <nitro/os/common/systemCall.h>

#include "ula.h"
#include "gfx.h"
#include "sound.h"
#include "gui.h"

extern char _binary_font_lz77[];
extern char _binary_sub_tiles_lz77[];
extern char _binary_deskmap_raw[];
extern char _binary_keybmap_raw[];
extern char _binary_fontpal_bin[];

extern void Machine_reset(void);
extern void Machine_run(void);
extern void CalibrateTouch(u32*);
extern u32 mytouch_x;
extern u32 mytouch_y;
extern u32 mytouch_press;
extern void CIA_TOD_Init(void);
extern void CIA_TOD_Count(void);

#define PALTicks OS_MilliSecondsToTicks( 20 )

//==========================================================================

#define STACK_SIZE 1024

//==========================================================================

unsigned char *emu_ram_alloc;
unsigned char *emu_ram_base;
void *tile_base;
void *obj_base;
void *sub_tiles_base;
//void *desk_base;

OSAlarm alarm;

//==========================================================================

//OSThread thread_emulate;
//u64 thread_emulate_stack[STACK_SIZE / sizeof(u64)];

void emulate(void);
void vhandler(void);

//==========================================================================

void NitroMain ()
{	

	void *nstart;
	void *heapStart;
	OSHeapHandle handle;



	// os
	OS_Init();
	
	
	// init thread system
//	OS_InitThread();
//	OS_CreateThread(&thread_emulate, emulate, NULL, thread_emulate_stack + STACK_SIZE / sizeof(u64), STACK_SIZE, 1);
	
	
	// init gx system
	FX_Init();
	GX_Init();
	
	
	// init audio
	SND_Init();
	
	
	// gx/gxs off
	GX_DispOff();
	GXS_DispOff();


	// allocate some RAM to sub & main bg
	GX_SetBankForBG(GX_VRAM_BG_256_BD);
	GX_SetBankForOBJ(GX_VRAM_OBJ_128_A);
	GX_SetBankForSubBG(GX_VRAM_SUB_BG_128_C);


	// upper screen is main
	GX_SetDispSelect(GX_DISP_SELECT_MAIN_SUB);


	// set sub & main background mode
	GX_SetGraphicsMode(GX_DISPMODE_GRAPHICS, GX_BGMODE_5, GX_BG0_AS_2D);
	GXS_SetGraphicsMode(GX_BGMODE_0);
	GX_SetOBJVRamModeChar(GX_OBJVRAMMODE_CHAR_1D_128K);

	// setup main bg0
//	G2_SetBG0Control(GX_BG_SCRSIZE_TEXT_512x256, GX_BG_COLORMODE_16, GX_BG_SCRBASE_0x0000, GX_BG_CHARBASE_0x04000, GX_BG_EXTPLTT_01);
//	G2_SetBG0Priority(0);
//	G2_BG0Mosaic(FALSE);
	//	bg0 is visible
//	GX_SetVisiblePlane(GX_PLANEMASK_BG0);
//	tile_base = G2_GetBG0CharPtr();

	// setup main bg1
	G2_SetBG1Control(GX_BG_SCRSIZE_TEXT_256x256, GX_BG_COLORMODE_16, GX_BG_SCRBASE_0x0000, GX_BG_CHARBASE_0x00000, GX_BG_EXTPLTT_01);
	G2_SetBG1Priority(0);
	G2_BG1Mosaic(FALSE);
	// setup main bg2
	G2_SetBG2Control256Bmp(GX_BG_SCRSIZE_256BMP_512x256, GX_BG_AREAOVER_XLU, GX_BG_BMPSCRBASE_0x00000);
	G2_SetBG2Priority(1);
	G2_BG2Mosaic(FALSE);
	// setup main bg3
	G2_SetBG3Control256Bmp(GX_BG_SCRSIZE_256BMP_512x256, GX_BG_AREAOVER_XLU, GX_BG_BMPSCRBASE_0x00000);
	G2_SetBG3Priority(1);
	G2_BG3Mosaic(FALSE);
	//	bg1,bg2,bg3 & obj is visible
	GX_SetVisiblePlane(GX_PLANEMASK_BG1 | GX_PLANEMASK_BG2 | GX_PLANEMASK_BG3 | GX_PLANEMASK_OBJ);
	tile_base = G2_GetBG2ScrPtr();
	
	obj_base = G2_GetOBJCharPtr();

	// setup sub bg0
	G2S_SetBG0Control(GX_BG_SCRSIZE_TEXT_256x512, GX_BG_COLORMODE_16, GX_BG_SCRBASE_0x0000, GX_BG_CHARBASE_0x08000, GX_BG_EXTPLTT_01);
	G2S_SetBG0Priority(0);
	G2S_BG0Mosaic(FALSE);

	// setup sub bg1
	G2S_SetBG1Control(GX_BG_SCRSIZE_TEXT_256x512, GX_BG_COLORMODE_16, GX_BG_SCRBASE_0x1000, GX_BG_CHARBASE_0x04000, GX_BG_EXTPLTT_01);
	G2S_SetBG1Priority(0);
	G2S_BG1Mosaic(FALSE);
	sub_tiles_base = G2S_GetBG1CharPtr();

	// setup sub bg2
	G2S_SetBG2ControlText(GX_BG_SCRSIZE_TEXT_256x256, GX_BG_COLORMODE_16, GX_BG_SCRBASE_0x2000, GX_BG_CHARBASE_0x04000);
	G2S_SetBG2Priority(0);
	G2S_BG2Mosaic(FALSE);

	//	bg0,1 & 2 is visible
	GXS_SetVisiblePlane(GX_PLANEMASK_BG0|GX_PLANEMASK_BG1|GX_PLANEMASK_BG2);
	//GXS_SetVisiblePlane(GX_PLANEMASK_BG0|GX_PLANEMASK_BG1);


	// gx/gxs on
	GX_DispOn();
	GXS_DispOn();


	// allocate heap(s) from main memory
	nstart = OS_InitAlloc(OS_ARENA_MAIN, OS_GetMainArenaLo(), OS_GetMainArenaHi(), 1);

	// move arena lo boundry to start of heap
	OS_SetMainArenaLo(nstart);

	// allocate 0x40000 bytes for the heap
	heapStart = OS_AllocFromMainArenaLo(0x40000, 32);

	// create heap
	handle = OS_CreateHeap(OS_ARENA_MAIN, heapStart, (void *)((u32)heapStart + 0x40000));

	// set current heap
	(void)OS_SetCurrentHeap(OS_ARENA_MAIN, handle);

	// allocate C64 ram from the heap
	emu_ram_alloc = OS_AllocFromHeap(OS_ARENA_MAIN, handle, 0x30600);
	emu_ram_base = emu_ram_alloc + 0x400;

	//Clear DS VRAM and calculate LUTs.
	GFX_init();

	// initialize the filesystem (don't use dma for filesystem access)
	FS_Init(FS_DMA_NOT_USE);
/*	if(FS_IsAvailable())
	{

		FSFile file;

		FS_InitFile(&file);

		//if(FS_OpenFile(&file, "starquak.sna"))
		//{
			// skip the SNA header
		//	FS_SeekFile(&file, 27, FS_SEEK_SET);
		//	FS_ReadFile(&file, &emu_ram_base[0x20000], (long)FS_GetLength(&file));
		//	FS_CloseFile(&file);
		//}
	}
*/
	MI_UncompressLZ16(_binary_sub_tiles_lz77, sub_tiles_base);
	MI_CpuCopy16(_binary_keybmap_raw, (void*)((int)G2S_GetBG1ScrPtr() + 64*9), 0x3C0);
	MI_CpuCopy16(_binary_deskmap_raw, (void*)((int)G2S_GetBG2ScrPtr()), 0x600);
	MI_UncompressLZ16(_binary_font_lz77, (void*)((int)sub_tiles_base + 0x4400));

	InitSoundManager();
	CIA_TOD_Init();

	// inz spectrum ula
	inz_ula();

	// VBL irq
	OS_SetIrqFunction(OS_IE_V_BLANK, vhandler);
	GX_VBlankIntr(TRUE);						//GPU vblank irq
	OS_EnableIrqMask(OS_IE_V_BLANK);			//IE vblank
	OS_EnableIrq();								//IME
	OS_EnableInterrupts();						//CPU irq

	// Timer1 irq
	OS_InitTick();
	OS_InitAlarm();
	if(OS_IsAlarmAvailable())
	{
		OS_CreateAlarm(&alarm);
		//OS_SetAlarm( &alarm, PALTicks, NULL, (void*)NULL );
		OS_SetPeriodicAlarm( &alarm, PALTicks, PALTicks, NULL, (void*)NULL );
	
	}

	GUI_Init();
	emulate();
	OS_Terminate();
}


void vhandler( void )	// V-Blank interrupt process
{
	OS_SetIrqCheckFlag( OS_IE_V_BLANK );
	//DC_FlushAll();
	asm_vblank();
	CIA_TOD_Count();
}


void emulate(void)
{
	static u16 *ULA_pallete = (u16 *)HW_DB_BG_PLTT;
//	int i;

	TPData touch_key;
	TP_Init();

	Machine_reset();
	while(TRUE)
	{
		ULA_pallete[0] = 0x0000;

		//TP_RequestRawSampling(&touch_key);
		TP_RequestCalibratedSampling(&touch_key);
		if(touch_key.touch) {
			mytouch_press = 1;
			if(touch_key.validity == TP_VALIDITY_VALID) {
				mytouch_x = touch_key.x;
				mytouch_y = touch_key.y;
				CalibrateTouch(&mytouch_x);
			}
		}
		else
		{
		  	mytouch_press = 0;
		}

		GUI_Manage();
		Machine_run();


		ULA_pallete[0] = 0x7c1f;
		//OS_WaitInterrupt(TRUE, OS_IE_V_BLANK);		//60Hz
		OS_WaitInterrupt(TRUE, OS_IE_TIMER1);		//50Hz
	}
}


