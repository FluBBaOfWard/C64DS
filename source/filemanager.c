#include "string.h"
#include "filemanager.h"

extern unsigned char *emu_ram_base;
const char game_dir[] = "/games/";
//const char game_dir[] = "/Alten8/";
//const char game_dir[] = "/Test1/";
//const char game_dir[] = "/Test2/";
//const char game_dir[] = "/Demos/";

BOOL InitFileManager()
{
	if(!FS_IsAvailable())
	{		
		// initialize the filesystem (don't use dma for filesystem access)
		FS_Init(FS_DMA_NOT_USE);
		if(FS_IsAvailable())
			return TRUE;
		return FALSE;
	}
	else
	{
		return TRUE;
	}
}

BOOL FM_LoadGame(const char *a_file_name)
{
	char namebuf[FS_FILE_NAME_MAX+1];
	strcpy(namebuf,game_dir);
	strcat(namebuf,a_file_name);
	return FM_LoadFile(namebuf);
}
BOOL FM_LoadFile(const char *a_file_name)
{
	int file_len, file_end;
	u16 file_start;

	if(FS_IsAvailable())
	{

		FSFile file;
		FS_InitFile(&file);

		if(FS_OpenFile(&file, a_file_name))
		{
			file_len = (int)(FS_GetLength(&file) - 2);
			FS_ReadFile(&file, &file_start, 2);
			
			FS_ReadFile(&file, &emu_ram_base[file_start], (long)file_len);
			FS_CloseFile(&file);
			file_end = file_start + file_len;
			emu_ram_base[0x2d] = emu_ram_base[0x2f] = emu_ram_base[0x31] = emu_ram_base[0xAE] = (unsigned char)file_end;
			emu_ram_base[0x2e] = emu_ram_base[0x30] = emu_ram_base[0x32] = emu_ram_base[0xAF] = (unsigned char)(file_end>>8);
			return TRUE;
		}
	}
	return FALSE;
}



int FM_GetGameList(char *a_dir_list,int pos)
{
	return FM_GetFileList(game_dir, a_dir_list, pos);
}
int FM_GetFileList(const char *a_dir_name,char *a_dir_list,int pos)
{
	int i=0;

	if(FS_IsAvailable())
	{

		FSFile file;
		FS_InitFile(&file);

		if(FS_FindDir(&file, a_dir_name))
		{
			FSDirEntry dir;

			for(i=0;i<12+pos;i++)
			{
				if(FS_ReadDir(&file, &dir))
				{
					if(i >= pos)
						strncpy(&a_dir_list[(i-pos)*32], dir.name, 32);
					
				}
				else
				{
					break;
				}
			}
			i -= pos;

		}

	}
	return i;
}

int FM_CountGameFiles(void)
{
	return FM_CountFiles(game_dir);
}
int FM_CountFiles(const char *a_dir_name)
{
	int i=0;

	if(FS_IsAvailable())
	{
		FSFile file;
		FS_InitFile(&file);

		if(FS_FindDir(&file, a_dir_name))
		{
			FSDirEntry dir;
			while(FS_ReadDir(&file, &dir)) i++;
		}

	}
	return i;
}