# C64DS V0.1.0

<img align="right" width="220" src="./logo.png" />

This is a Commodore 64 (PAL) emulator for the Nintendo DS.

Too much stuff is still missing for it to be more than a novelty.
* Graphics is poorly emulated.
* Sound is missing ring, sync & filter emulation.
* Timer emulation is not cycle accurate, missing TA to TB chaining.
* Cpu is missing a lot of the finer cycle rules.
* There is no disc drive or tape emulation yet, just fake loading of ".prg" files.

## How to use

1. Create a folder named "c64ds" in either the root of your flash card or in
 the data folder. This is where settings and save files end up.
2. Now put .prg files into a folder where you have (C64) files.
3. Depending on your flashcart you might have to DLDI patch the emulator.

When the emulator starts, you can either press L+R or tap on the screen to open
up the menu. Now you can use the cross or touchscreen to navigate the menus, A
or double tap to select an option, B or the top of the screen to go back a step.

To select between the tabs use R & L or the touchscreen.

## Menu

### File

* Load Game: Select a game to load.
* Load State: Load a previously saved state of the currently running game.
* Save State: Save a state of the currently running game.
* Load NVRAM: Load non volatile ram (EEPROM/SRAM) for the currently running game.
* Save NVRAM: Save non volatile ram (EEPROM/SRAM) for the currently running game.
* Save Settings: Save the current settings (and internal EEPROM).
* Reset Game: Reset the currently running game.

### Options

* Controller:
  * Autofire: Select if you want autofire.
  * Controller: Which port the controller is plugged into, be prepared to switch often
  * Swap A-B: Swap which NDS button is mapped to the C64 fire button.
* Display:
  * Display: Here you can select if you want scaled or unscaled screenmode.
    * Unscaled mode: L & R buttons scroll the screen up and down.
  * Scaling: Here you can select if you want flicker or barebones lineskip.
  * Gamma: Lets you change the gamma ("brightness").
  * Contrast: Lets you change the contrast.
  * Palettes: Here you can select the palette.
* Machine Settings:
  * Machine: Select the emulated machine.
  * Select Kernal: Load a specific Kernal ROM.
  * Select Chargen: Load a specific Chargen ROM.
  * Select Basic: Load a specific Basic ROM.
  * Cpu speed hacks: Allow speed hacks.
* Settings:
  * Speed: Switch between speed modes.
    * Normal: Game runs at it's normal speed.
    * 200%: Game runs at double speed.
    * Max: Games can run up to 4 times normal speed.
    * 50%: Game runs at half speed.
  * Allow Refresh Change: Allow the Wonderswan to change NDS refresh rate.
  * Autoload State: Toggle Savestate autoloading. Automagically load the
   savestate associated with the selected game.
  * Autoload NVRAM: Toggle EEPROM/SRAM autoloading. Automagically load the
   EEPROM/SRAM associated with the selected game.
  * Autosave Settings: This will save settings when leaving menu if any
   changes are made.
  * Autopause Game: Toggle if the game should pause when opening the menu.
  * Powersave 2nd Screen: If graphics/light should be turned off for the GUI
   screen when menu is not active.
  * Emulator on Bottom: Select if top or bottom screen should be used for
   emulator, when menu is active emulator screen is allways on top.
  * Autosleep: Doesn't work.
* Debug:
  * Debug Output: Show FPS and logged text.
  * Disable Foreground: Turn on/off foreground rendering.
  * Disable Background: Turn on/off background rendering.
  * Disable Sprites: Turn on/off sprite rendering.
  * Step Frame: Emulate one frame.

### About

Some info about the emulator and game...

## Controls

There is no convention on C64 which port is player 1 and which is player 2, so
you will have to switch port a lot. Fire is right now mapped to the B button.

## Games

* Bubble Bobble actually seem to work.
* Great Giana Sisters is missing sprite collision.

## Credits

```text
Huge thanks to Loopy for the incredible PocketNES, without it this emu would probably never have been made.
Thanks to:
Dwedit for help and inspiration with a lot of things. https://www.dwedit.org
```

Fredrik Ahlström

Twitter @TheRealFluBBa

http://www.github.com/FluBBaOfWard
