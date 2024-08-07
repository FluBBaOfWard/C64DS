#include <nds.h>

#include "Gui.h"
#include "Shared/EmuMenu.h"
#include "Shared/EmuSettings.h"
#include "Main.h"
#include "C64Keyboard.h"
#include "FileHandling.h"
//#include "Cart.h"
#include "Gfx.h"
#include "io.h"
#include "cpu.h"
#include "ARM6502/Version.h"
#include "ARM6526/Version.h"
#include "ARM6569/Version.h"
#include "ARM6581/Version.h"

#define EMUVERSION "V0.2.1 2024-07-31"

#define ENABLE_LIVE_UI		(1<<12)
#define ALLOW_SPEED_HACKS	(1<<17)
#define ALLOW_REFRESH_CHG	(1<<19)

void machineReset(void);
void hacksInit(void);

static void nullUIC64(int key);
static void setupC64Background(void);

static void paletteChange(void);
static void machineSet(void);
static void speedHackSet(void);
static void refreshChgSet(void);
static void borderSet(void);

static void uiMachine(void);
static void uiDebug(void);
static void updateGameInfo(void);

const fptr fnMain[] = {nullUI, subUI, subUI, subUI, subUI, subUI, subUI, subUI, subUI, subUI};

const fptr fnList0[] = {uiDummy};
const fptr fnList1[] = {selectGame, loadState, saveState, loadNVRAM, saveNVRAM, saveSettings, resetGame, ui9};
const fptr fnList2[] = {ui4, ui5, ui6, ui7, ui8};
const fptr fnList3[] = {uiDummy};
const fptr fnList4[] = {autoBSet, autoASet, controllerSet, swapABSet};
const fptr fnList5[] = {scalingSet, flickSet, gammaSet, contrastSet, borderSet};
const fptr fnList6[] = {machineSet, selectBnWBios, selectColorBios, selectCrystalBios /*languageSet*/};
const fptr fnList7[] = {speedSet, refreshChgSet, autoStateSet, autoNVRAMSet, autoSettingsSet, autoPauseGameSet, powerSaveSet, screenSwapSet, sleepSet};
const fptr fnList8[] = {debugTextSet, bgrLayerSet, sprLayerSet, stepFrame};
const fptr fnList9[] = {exitEmulator, backOutOfMenu};
const fptr fnList10[] = {uiDummy};
const fptr *const fnListX[] = {fnList0, fnList1, fnList2, fnList3, fnList4, fnList5, fnList6, fnList7, fnList8, fnList9, fnList10};
u8 menuXItems[] = {ARRSIZE(fnList0), ARRSIZE(fnList1), ARRSIZE(fnList2), ARRSIZE(fnList3), ARRSIZE(fnList4), ARRSIZE(fnList5), ARRSIZE(fnList6), ARRSIZE(fnList7), ARRSIZE(fnList8), ARRSIZE(fnList9), ARRSIZE(fnList10)};
const fptr drawUIX[] = {uiNullNormal, uiFile, uiOptions, uiAbout, uiController, uiDisplay, uiMachine, uiSettings, uiDebug, uiDummy, uiDummy};

u8 gGammaValue = 0;
u8 gContrastValue = 3;
u8 gBorderEnable = 1;
char gameInfoString[32];

const char *const autoTxt[]  = {"Off", "On", "With R"};
const char *const speedTxt[] = {"Normal", "200%", "Max", "50%"};
const char *const brighTxt[] = {"I", "II", "III", "IIII", "IIIII"};
const char *const sleepTxt[] = {"5min", "10min", "30min", "Off"};
const char *const ctrlTxt[]  = {"Port 1", "Port 2"};
const char *const dispTxt[]  = {"Unscaled", "Scaled"};
const char *const flickTxt[] = {"No Flicker", "Flicker"};

const char *const machTxt[]  = {"Auto", "C64", "C64GS", "C64EX", "C64NTSC"};
const char *const bordTxt[]  = {"Black", "Border Color", "None"};
const char *const palTxt[]   = {"Classic", "Black & White", "Red", "Green", "Blue", "Green-Blue", "Blue-Green", "Puyo Puyo Tsu"};
const char *const langTxt[]  = {"Japanese", "English"};


void setupGUI() {
	emuSettings = AUTOPAUSE_EMULATION | AUTOLOAD_NVRAM | AUTOSLEEP_OFF | ENABLE_LIVE_UI;
	keysSetRepeat(25, 4);	// Delay, repeat.
	menuXItems[1] = ARRSIZE(fnList1) - (enableExit?0:1);
	openMenu();
}

/// This is called when going from emu to ui.
void enterGUI() {
	if (emuSettings & AUTOSAVE_SETTINGS) {
		saveSettings();
		settingsChanged = false;
	}
}

/// This is called going from ui to emu.
void exitGUI() {
}

void quickSelectGame(void) {
	openMenu();
	selectGame();
	closeMenu();
}

void uiNullNormal() {
//	if (gMachine == HW_C64) {
		setupC64Background();
//	} else {
//		uiNullDefault();
//		return;
//	}
	drawItem("Menu",27,1,0);
}

void uiFile() {
	setupMenu();
	drawMenuItem("Load Game");
	drawMenuItem("Load State");
	drawMenuItem("Save State");
	drawMenuItem("Load NVRAM");
	drawMenuItem("Save NVRAM");
	drawMenuItem("Save Settings");
	drawMenuItem("Reset Console");
	if (enableExit) {
		drawMenuItem("Quit Emulator");
	}
}

void uiOptions() {
	setupMenu();
	drawMenuItem("Controller");
	drawMenuItem("Display");
	drawMenuItem("Machine");
	drawMenuItem("Settings");
	drawMenuItem("Debug");
}

void uiAbout() {
	cls(1);
	updateGameInfo();
	drawTabs();
	drawMenuText("B:        WS B button", 4, 0);
	drawMenuText("A:        WS A button", 5, 0);
	drawMenuText("Select:   Sound button", 6, 0);
	drawMenuText("Start:    Start button", 7, 0);

	drawMenuText(gameInfoString, 9, 0);

	drawMenuText("C64DS        " EMUVERSION, 18, 0);
	drawMenuText("ARM6502      " ARM6502VERSION, 19, 0);
	drawMenuText("ARM6526      " ARM6526VERSION, 20, 0);
	drawMenuText("ARM6569      " ARM6569VERSION, 21, 0);
	drawMenuText("ARM6581      " ARM6581VERSION, 22, 0);
}

void uiController() {
	setupSubMenu("Controller Settings");
	drawSubItem("B Autofire:", autoTxt[autoB]);
	drawSubItem("A Autofire:", autoTxt[autoA]);
	drawSubItem("Controller:", ctrlTxt[(joyCfg>>29)&1]);
	drawSubItem("Swap A-B:  ", autoTxt[(joyCfg>>10)&1]);
}

void uiDisplay() {
	setupSubMenu("Display Settings");
	drawSubItem("Display:", dispTxt[gScaling&SCALED]);
	drawSubItem("Scaling:", flickTxt[gFlicker]);
	drawSubItem("Gamma:", brighTxt[gGammaValue]);
	drawSubItem("Contrast:", brighTxt[gContrastValue]);
	drawSubItem("Border:", autoTxt[gBorderEnable]);
}

static void uiMachine() {
	setupSubMenu("Machine Settings");
	drawSubItem("Machine:", machTxt[0]);
	drawSubItem("Select Kernal ->", NULL);
	drawSubItem("Select Basic ->", NULL);
	drawSubItem("Select Chargen ->", NULL);
//	drawSubItem("Language: ", langTxt[gLang]);
}

void uiSettings() {
	setupSubMenu("Settings");
	drawSubItem("Speed:", speedTxt[(emuSettings>>6)&3]);
	drawSubItem("Allow Refresh Change:", autoTxt[(emuSettings&ALLOW_REFRESH_CHG)>>19]);
	drawSubItem("Autoload State:", autoTxt[(emuSettings>>2)&1]);
	drawSubItem("Autoload NVRAM:", autoTxt[(emuSettings>>10)&1]);
	drawSubItem("Autosave Settings:", autoTxt[(emuSettings>>9)&1]);
	drawSubItem("Autopause Game:", autoTxt[emuSettings&1]);
	drawSubItem("Powersave 2nd Screen:",autoTxt[(emuSettings>>1)&1]);
	drawSubItem("Emulator on Bottom:", autoTxt[(emuSettings>>8)&1]);
	drawSubItem("Autosleep:", sleepTxt[(emuSettings>>4)&3]);
}

void uiDebug() {
	setupSubMenu("Debug");
	drawSubItem("Debug Output:", autoTxt[gDebugSet&1]);
	drawSubItem("Disable Background:", autoTxt[gGfxMask&1]);
	drawSubItem("Disable Sprites:", autoTxt[(gGfxMask>>4)&1]);
	drawSubItem("Step Frame", NULL);
}


void nullUINormal(int key) {
	if (!(emuSettings & ENABLE_LIVE_UI)) {
		nullUIDebug(key);		// Just check touch, open menu.
		return;
	}
	nullUIC64(key);
//	if (key & KEY_TOUCH) {
//		openMenu();
//	}
}

void nullUIDebug(int key) {
	if (key & KEY_TOUCH) {
		openMenu();
	}
}

void updateGameInfo() {
	char catalog[8];
//	char2HexStr(catalog, gGameID);
	strlMerge(gameInfoString, "Game #: 0x", catalog, sizeof(gameInfoString));
}
//---------------------------------------------------------------------------------
void debugIO(u16 port, u8 val, const char *message) {
	char debugString[32];

	debugString[0] = 0;
	strlcat(debugString, message, sizeof(debugString));
	short2HexStr(&debugString[strlen(debugString)], port);
	strlcat(debugString, " val:", sizeof(debugString));
	char2HexStr(&debugString[strlen(debugString)], val);
	debugOutput(debugString);
}
//---------------------------------------------------------------------------------
void debugIOUnmappedR(u16 port, u8 val) {
	debugIO(port, val, "Unmapped R port:");
}
void debugIOUnmappedW(u16 port, u8 val) {
	debugIO(port, val, "Unmapped W port:");
}
void debugUndefinedInstruction() {
	debugOutput("Undocumented Instruction.");
}
void debugCrashInstruction() {
	debugOutput("CPU Crash! (JAM/KIL)");
}

void nullUIC64(int key) {
	int xpos, ypos;

	if (EMUinput & KEY_TOUCH) {
		touchPosition myTouch;
		touchRead(&myTouch);
		xpos = (myTouch.px>>2);
		ypos = (myTouch.py>>4);
		if ( (xpos > 51) && (ypos < 2) ) {
			openMenu();
		}
		else {
			SetC64Key((myTouch.px>>3), (myTouch.py>>3), 1);
		}
//		else if ((ypos > 4 && ypos < 6) && (xpos > 21 && xpos < 43)) {	// Cartridge port
//			cartridgePortTouched(keyHit);
//		}
//		else if ((ypos == 10) && (xpos > 46 && xpos < 52)) {	// Hold button
//			EMUinput |= KEY_START;
//		}
	}
	else {
		SetC64Key(0, 0, 0);
	}
}

//---------------------------------------------------------------------------------
void setupC64Background(void) {
	setupCompressedBackground(C64KeyboardTiles, C64KeyboardMap, 9);
	memcpy(BG_PALETTE_SUB+0x80, C64KeyboardPal, C64KeyboardPalLen);
}

void resetGame() {
	machineReset();
//	loadCart();
}

//---------------------------------------------------------------------------------
/// Switch between Player 1 & Player 2 controls
void controllerSet() {				// See io.s: refreshEMUjoypads
	joyCfg ^= 0x20000000;
}

/// Swap A & B buttons
void swapABSet() {
	joyCfg ^= 0x400;
}

/// Turn on/off scaling
void scalingSet(){
	gScaling ^= SCALED;
//	refreshGfx();
}

/// Change gamma (brightness)
void gammaSet() {
	gGammaValue++;
	if (gGammaValue > 4) gGammaValue = 0;
//	paletteInit(gGammaValue, gContrastValue);
//	paletteTxAll();					// Make new palette visible
//	setupEmuBorderPalette();
	setupMenuPalette();
	settingsChanged = true;
}

/// Change contrast
void contrastSet() {
	gContrastValue++;
	if (gContrastValue > 4) gContrastValue = 0;
//	paletteInit(gGammaValue, gContrastValue);
//	paletteTxAll();					// Make new palette visible
//	setupEmuBorderPalette();
	settingsChanged = true;
}

/// Turn on/off rendering of background
void bgrLayerSet() {
	gGfxMask ^= 0x01;
}
/// Turn on/off rendering of sprites
void sprLayerSet() {
	gGfxMask ^= 0x10;
}

void paletteChange() {
/*	gPaletteBank++;
	if (gPaletteBank > 7) {
		gPaletteBank = 0;
	}
	monoPalInit(gGammaValue, gContrastValue);
	paletteTxAll();
	setupEmuBorderPalette();*/
	settingsChanged = true;
}

void borderSet() {
	gBorderEnable ^= 0x01;
//	setupEmuBorderPalette();
}

void machineSet() {
//	gMachine++;
//	if (gMachine >= HW_SELECT_END) {
//		gMachine = 0;
//	}
}

void speedHackSet() {
	emuSettings ^= ALLOW_SPEED_HACKS;
//	hacksInit();
}

void refreshChgSet() {
	emuSettings ^= ALLOW_REFRESH_CHG;
//	updateLCDRefresh();
}
