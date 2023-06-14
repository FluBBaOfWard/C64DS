#include <nds.h>
#include <stdio.h>
#include <string.h>

#include "FileHandling.h"
#include "Shared/EmuMenu.h"
#include "Shared/EmuSettings.h"
#include "Shared/FileHelper.h"
#include "Shared/AsmExtra.h"
#include "Main.h"
#include "Gui.h"
//#include "Cart.h"
#include "cpu.h"
#include "Gfx.h"
#include "io.h"
#include "Memory.h"

static const char *const folderName = "c64ds";
static const char *const settingName = "settings.cfg";

extern u8 c64Program[];
int sramSize = 0;
ConfigData cfg;

//---------------------------------------------------------------------------------
int initSettings() {
	cfg.config = 0;
	cfg.palette = 0;
	cfg.gammaValue = 0x30;
	cfg.emuSettings = AUTOPAUSE_EMULATION | AUTOLOAD_NVRAM;
	cfg.sleepTime = 60*60*5;
	cfg.controller = 0;					// Don't swap A/B
	cfg.language = (PersonalData->language == 0) ? 0 : 1;

	return 0;
}

int loadSettings() {
	FILE *file;

	if (findFolder(folderName)) {
		return 1;
	}
	if ( (file = fopen(settingName, "r")) ) {
		fread(&cfg, 1, sizeof(ConfigData), file);
		fclose(file);
		if (!strstr(cfg.magic,"cfg")) {
			infoOutput("Error in settings file.");
			return 1;
		}
	}
	else {
		infoOutput("Couldn't open file:");
		infoOutput(settingName);
		return 1;
	}

	gBorderEnable = (cfg.config & 1) ^ 1;
//	gPaletteBank  = cfg.palette;
	gGammaValue   = cfg.gammaValue & 0xF;
	gContrastValue = (cfg.gammaValue>>4) & 0xF;
	emuSettings   = cfg.emuSettings & ~EMUSPEED_MASK;	// Clear speed setting.
	sleepTime     = cfg.sleepTime;
	joyCfg        = (joyCfg & ~0x400)|((cfg.controller & 1)<<10);
	strlcpy(currentDir, cfg.currentPath, sizeof(currentDir));

	infoOutput("Settings loaded.");
	return 0;
}

void saveSettings() {
	FILE *file;

	strcpy(cfg.magic,"cfg");
	cfg.config      = (gBorderEnable & 1) ^ 1;
//	cfg.palette     = gPaletteBank;
	cfg.gammaValue  = (gGammaValue & 0xF) | (gContrastValue<<4);
	cfg.emuSettings = emuSettings & ~EMUSPEED_MASK;		// Clear speed setting.
	cfg.sleepTime   = sleepTime;
	cfg.controller  = (joyCfg>>10)&1;
	strlcpy(cfg.currentPath, currentDir, sizeof(cfg.currentPath));

	if (findFolder(folderName)) {
		return;
	}
	if ( (file = fopen(settingName, "w")) ) {
		fwrite(&cfg, 1, sizeof(ConfigData), file);
		fclose(file);
		infoOutput("Settings saved.");
	}
	else {
		infoOutput("Couldn't open file:");
		infoOutput(settingName);
	}
//	saveIntEeproms();
}

void loadNVRAM() {
	FILE *wssFile;
	char nvRamName[FILENAMEMAXLENGTH];
	int saveSize = 0;
	void *nvMem = NULL;

	if (sramSize > 0) {
		saveSize = sramSize;
//		nvMem = wsSRAM;
		setFileExtension(nvRamName, currentFilename, ".ram", sizeof(nvRamName));
	}
	else {
		return;
	}
	if (findFolder(folderName)) {
		return;
	}
	if ( (wssFile = fopen(nvRamName, "r")) ) {
		if (fread(nvMem, 1, saveSize, wssFile) != saveSize) {
			infoOutput("Bad NVRAM file:");
			infoOutput(nvRamName);
		}
		fclose(wssFile);
		infoOutput("Loaded NVRAM.");
	}
	else {
//		memset(nvMem, 0, saveSize);
		infoOutput("Couldn't open NVRAM file:");
		infoOutput(nvRamName);
	}
}

void saveNVRAM() {
	FILE *wssFile;
	char nvRamName[FILENAMEMAXLENGTH];
	int saveSize = 0;
	void *nvMem = NULL;

	if (sramSize > 0) {
		saveSize = sramSize;
//		nvMem = wsSRAM;
		setFileExtension(nvRamName, currentFilename, ".ram", sizeof(nvRamName));
	}
	else {
		return;
	}
	if (findFolder(folderName)) {
		return;
	}
	if ( (wssFile = fopen(nvRamName, "w")) ) {
		if (fwrite(nvMem, 1, saveSize, wssFile) != saveSize) {
			infoOutput("Couldn't write correct number of bytes.");
		}
		fclose(wssFile);
		infoOutput("Saved NVRAM.");
	}
	else {
		infoOutput("Couldn't open NVRAM file:");
		infoOutput(nvRamName);
	}
}

void loadState() {
//	loadDeviceState(folderName);
}

void saveState() {
//	saveDeviceState(folderName);
}

/// Reset and wait for C64 to boot.
static void waitForReBoot(void) {
	int i;
	machineReset();
	for (i = 0; i < 150; i++ ) {
		stepFrame();
	}
	SetC64Key(9, 15, 1);
	stepFrame();
	SetC64Key(9, 15, 0);
	SetC64Key(15, 15, 1);
	stepFrame();
	SetC64Key(15, 15, 0);
	SetC64Key(15, 19, 1);
	stepFrame();
	SetC64Key(15, 19, 0);
	stepFrame();
	stepFrame();
	SetC64Key(29, 17, 1);
	stepFrame();
	SetC64Key(29, 17, 0);
}

//---------------------------------------------------------------------------------
int loadC64ROM(const char *fileName) {
	int size = 0;
	int fileEnd;
	u16 fileStart;
	FILE *file;

	if ((file = fopen(fileName, "r"))) {
		fseek(file, 0, SEEK_END);
		size = ftell(file) - 2;
		if (size > 0xF000) {
			infoOutput("File too large!");
			size = 0;
		}
		else {
			waitForReBoot();
			fseek(file, 0, SEEK_SET);
			fread(&fileStart, 1 , 2, file);
			fread(&emu_ram_base[fileStart], 1, size, file);
			fileEnd = fileStart + size;
			emu_ram_base[0x2d] = emu_ram_base[0x2f] = emu_ram_base[0x31] = emu_ram_base[0xAE] = (unsigned char)fileEnd;
			emu_ram_base[0x2e] = emu_ram_base[0x30] = emu_ram_base[0x32] = emu_ram_base[0xAF] = (unsigned char)(fileEnd>>8);
			strlcpy(currentFilename, fileName, sizeof(currentFilename));
		}
		fclose(file);
	}
	else {
		infoOutput("Couldn't open file:");
		infoOutput(fileName);
	}
	return size;
}

int loadC64PrgFake(const u8 *program) {
	int size = 48*1024;
	int fileEnd;
	u16 fileStart;

	fileStart = *(u16 *)program;
	memcpy(&emu_ram_base[fileStart], &program[2], size);
	fileEnd = fileStart + size;
	emu_ram_base[0x2d] = emu_ram_base[0x2f] = emu_ram_base[0x31] = emu_ram_base[0xAE] = (unsigned char)fileEnd;
	emu_ram_base[0x2e] = emu_ram_base[0x30] = emu_ram_base[0x32] = emu_ram_base[0xAF] = (unsigned char)(fileEnd>>8);

	return size;
}

//---------------------------------------------------------------------------------
bool loadGame(const char *gameName) {
	if ( gameName ) {
		cls(0);
		drawText("     Please wait, loading.", 11, 0);
//		gRomSize = loadROM(romSpacePtr, gameName, maxRomSize);
		loadC64ROM(gameName);
//		if ( gRomSize ) {
			setEmuSpeed(0);
//			loadCart();
//			gameInserted = true;
//			if ( emuSettings & AUTOLOAD_NVRAM ) {
//				loadNVRAM();
//			}
//			if ( emuSettings & AUTOLOAD_STATE ) {
//				loadState();
//			}
			closeMenu();
			return false;
//		}
	}
	return true;
}

void selectGame() {
	pauseEmulation = true;
	ui10();
//	loadC64PrgFake( c64Program );
	const char *gameName = browseForFileType(FILEEXTENSIONS".zip");
	if ( loadGame(gameName) ) {
		backOutOfMenu();
	}
}

//---------------------------------------------------------------------------------
static int loadBIOS(void *dest, const char *fPath, const int maxSize) {
	char tempString[FILEPATHMAXLENGTH];
	char *sPtr;

	cls(0);
	strlcpy(tempString, fPath, sizeof(tempString));
	if ( (sPtr = strrchr(tempString, '/')) ) {
		sPtr[0] = 0;
		sPtr += 1;
		chdir("/");
		chdir(tempString);
		return loadROM(dest, sPtr, maxSize);
	}
	return 0;
}
/*
int loadBnWBIOS(void) {
	if ( loadBIOS(biosSpace, cfg.monoBiosPath, sizeof(biosSpace)) ) {
		g_BIOSBASE_BNW = biosSpace;
		return 1;
	}
	g_BIOSBASE_BNW = NULL;
	return 0;
}

int loadColorBIOS(void) {
	if ( loadBIOS(biosSpaceColor, cfg.colorBiosPath, sizeof(biosSpaceColor)) ) {
		g_BIOSBASE_COLOR = biosSpaceColor;
		return 1;
	}
	g_BIOSBASE_COLOR = NULL;
	return 0;
}

int loadCrystalBIOS(void) {
	if ( loadBIOS(biosSpaceCrystal, cfg.crystalBiosPath, sizeof(biosSpaceCrystal)) ) {
		g_BIOSBASE_CRYSTAL = biosSpaceCrystal;
		return 1;
	}
	g_BIOSBASE_CRYSTAL = NULL;
	return 0;
}
*/
static bool selectBios(char *dest, const char *fileTypes) {
	const char *biosName = browseForFileType(fileTypes);

	if ( biosName ) {
		strlcpy(dest, currentDir, FILEPATHMAXLENGTH);
		strlcat(dest, "/", FILEPATHMAXLENGTH);
		strlcat(dest, biosName, FILEPATHMAXLENGTH);
		return true;
	}
	return false;
}

void selectBnWBios() {
	if ( selectBios(cfg.monoBiosPath, ".ws.rom.zip") ) {
//		loadBnWBIOS();
	}
	cls(0);
}

void selectColorBios() {
	if ( selectBios(cfg.colorBiosPath, ".ws.wsc.rom.zip") ) {
//		loadColorBIOS();
	}
	cls(0);
}

void selectCrystalBios() {
	if ( selectBios(cfg.crystalBiosPath, ".ws.wsc.rom.zip") ) {
//		loadCrystalBIOS();
	}
	cls(0);
}
