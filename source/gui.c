#include "string.h"
#include "filemanager.h"
#include "gui.h"

extern u32 mytouch_x;
extern u32 mytouch_y;
extern u32 mytouch_press;
extern u32 ntr_pad_current;
extern u32 ntr_pad_down;
extern u32 ntr_pad_up;


extern void Machine_reset(void);

extern unsigned char *emu_ram_base;
void ListGamesByPos(u32 xpos, u32 ypos, u32 press);
void ManageGUIOptions(u32 xpos, u32 ypos, u32 press);
void FileScreenInit(void);

int keyb_pos;
int keyb_dir;
int film_pos;
int film_dir;

int game_files = 0;
int file_select_pos = 0;
int file_select_ofs = 0;

void GUI_Init(void)
{
	keyb_pos = 0;
	keyb_dir = 0;
	film_pos = -120;
	film_dir = 0;

	game_files = FM_CountGameFiles();
	FileScreenInit();

}

void GUI_Manage(void)
{
	u32 keyData, oldData;

	oldData = ntr_pad_current;
	keyData = PAD_Read();
	ntr_pad_current = keyData;
	ntr_pad_down = (oldData^keyData)&keyData;
	ntr_pad_up = (oldData^keyData)&~keyData;
	
	if(ntr_pad_down & PAD_BUTTON_SELECT)
	{
		Machine_reset();
	}
	ManageGUIOptions(mytouch_x, mytouch_y, mytouch_press);
	ListGamesByPos(mytouch_x, mytouch_y, mytouch_press);

}


void ManageGUIOptions(u32 xpos, u32 ypos, u32 press)
{
	int k_pos, k_dir;
	int f_pos, f_dir;
	
	k_pos = keyb_pos;
	k_dir = keyb_dir;
	f_pos = film_pos;
	f_dir = film_dir;
	if(press && ypos && (ypos < 4))
	{
		// Check for keyboardicon press
		if((xpos > 0) & (xpos < 7))
		{
			if(f_dir == 0)
			{
				if(k_pos == 0) k_dir = -4;
				if(k_pos == -120)
				{
					k_dir = 4;
					if(f_pos == 0) f_dir = -4;
				}
			}
		}
		
		// Check for filemanagericon press
		if((xpos > 8) && (xpos < 12))
		{
			if(k_dir == 0)
			{
				if(f_pos == 0) f_dir = -4;
				if(f_pos == -120)
				{
					f_dir = 4;
					if(k_pos == 0) k_dir = -4;
				}
			}
		}

	}


	k_pos += k_dir;
	if(k_pos >= 0)
	{
		k_pos = 0;
		k_dir = 0;
	}
	if(k_pos <= -120)
	{
		k_pos = -120;
		k_dir = 0;
	}
	keyb_pos = k_pos;
	keyb_dir = k_dir;

	f_pos += f_dir;
	if(f_pos >= 0)
	{
		f_pos = 0;
		f_dir = 0;
	}
	if(f_pos <= -120)
	{
		f_pos = -120;
		f_dir = 0;
	}
	film_pos = f_pos;
	film_dir = f_dir;
}



void ListGamesByPos(u32 xpos, u32 ypos, u32 press)
{
	int repaint=0;
	int i,j,k,tile;
	static char namebuf[32];
	static u16 *text_bgr;

	text_bgr = (u16*)((int)G2S_GetBG0ScrPtr() + 0x40*9);

	if(film_pos == 0)
	{
		//FileSelectList
		if(press && (xpos > 1) && (xpos < 23) && (ypos > 8) && (ypos < 21))
		{
			file_select_pos = (int)ypos - 9;
			repaint = 1;
		}
		//ScrollUp
		if(press && (xpos > 24) && (xpos < 31) && (ypos > 8) && (ypos < 13))
		{
			file_select_ofs -= 1;
			if(file_select_ofs < 0) file_select_ofs = 0;
			repaint = 1;
		}
		//ScrollDown
		if(press && (xpos > 24) && (xpos < 31) && (ypos > 13) && (ypos < 22))
		{
			file_select_ofs += 1;
			if(file_select_ofs > (game_files - 12)) file_select_ofs = game_files - 12;
			repaint = 1;
		}
		//LoadButton
		if(press && (xpos > 1) && (xpos < 23) && (ypos > 22))
		{
			film_dir = -4;
			keyb_dir = 4;
			FM_LoadGame(namebuf);
		}
	}

	if(press && (xpos > 8) && (xpos < 12) && (ypos < 4))
	{
		repaint = 1;
	}
	if(repaint)
	{
		char dirbuffer[32*32];

		k = FM_GetGameList(dirbuffer, file_select_ofs);
		for(i=0;i<k;i++)
		{
			for(j=0;j<24;j++)
			{
				tile = dirbuffer[i*32+j];
				if(i == file_select_pos) tile += 0x1000;
				else tile += 0x8000;
				text_bgr[i*32+j+2] = (u16)tile;
			}
			if(i == file_select_pos)
				strncpy(namebuf, &dirbuffer[i*32], 32);
		}
	}
	
/*	for(i=0;i<24;i++)
	{
		tile = namebuf[i];
		text_bgr[14*32+i+2] = (u16)(tile + 0x8000);
	}*/

}

void FileScreenInit(void)
{
	int color = 0x8000;
	static u16 *text_bgr;
	text_bgr = (u16*)((int)G2S_GetBG0ScrPtr() + 0x40*9);

	text_bgr[32*2+28] = (u16)('/' + color);
	text_bgr[32*2+29] = (u16)('\\' + color);
	text_bgr[32*3+27] = (u16)('/' + color);
	text_bgr[32*3+30] = (u16)('\\' + color);
		
	text_bgr[32*8+27] = (u16)('\\' + color);
	text_bgr[32*8+30] = (u16)('/' + color);
	text_bgr[32*9+28] = (u16)('\\' + color);
	text_bgr[32*9+29] = (u16)('/' + color);

	text_bgr[32*14+6] = (u16)('L' + color);
	text_bgr[32*14+8] = (u16)('O' + color);
	text_bgr[32*14+10] = (u16)('A' + color);
	text_bgr[32*14+12] = (u16)('D' + color);

}