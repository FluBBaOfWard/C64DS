#ifndef MACHINE_HEADER
#define MACHINE_HEADER

#ifdef __cplusplus
extern "C" {
#endif

extern u8 gMachine;

extern u8 *c64Ram;

void machineReset(void);
#ifdef __cplusplus
} // extern "C"
#endif

#endif // MACHINE_HEADER
