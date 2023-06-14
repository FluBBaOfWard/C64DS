#include <nds.h>

#include "Commodore64.h"
#include "Machine.h"
#include "cpu.h"
#include "io.h"
#include "ARM6502/M6502.h"
#include "ARM6526/ARM6526.h"
#include "ARM6569/ARM6569.h"
#include "ARM6581/ARM6581.h"

int packState(void *statePtr) {
	int size = 0;
	memcpy(statePtr+size, c64Ram, 0x10000);
	size += 0x10000;
	size += m6502SaveState(statePtr+size, &m6502_0);
	size += m6569SaveState(statePtr+size, (M6569 *)&m6502_0);
	size += m6526SaveState(statePtr+size, &cia1Base);
	size += m6526SaveState(statePtr+size, &cia2Base);
	size += m6581SaveState(statePtr+size);
	return size;
}

void unpackState(const void *statePtr) {
	int size = 0;
	memcpy(c64Ram, statePtr+size, 0x10000);
	size += 0x10000;
	size += m6502LoadState(&m6502_0, statePtr+size);
	size += m6569LoadState((M6569 *)&m6502_0, statePtr+size);
	size += m6526LoadState(&cia1Base, statePtr+size);
	size += m6526LoadState(&cia2Base, statePtr+size);
	size += m6581LoadState(statePtr+size);
}

int getStateSize() {
	int size = 0;
	size += 0x10000;
	size += m6502GetStateSize();
	size += m6569GetStateSize();
	size += m6526GetStateSize();
	size += m6526GetStateSize();
	size += m6581GetStateSize();
	return size;
}
