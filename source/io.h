#ifndef IO_HEADER
#define IO_HEADER

#ifdef __cplusplus
extern "C" {
#endif

#include "ARM6526/ARM6526.h"

extern M6526 cia1Base;
extern M6526 cia2Base;
extern u32 joyCfg;
extern u32 EMUinput;

void SetC64Key(int x, int y, bool touch);

/**
 * Convert device input keys to target keys.
 * @param input NDS/GBA keys
 * @return The converted input.
 */
int convertInput(int input);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // IO_HEADER
