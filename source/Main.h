#ifndef MAIN_HEADER
#define MAIN_HEADER

#ifdef __cplusplus
extern "C" {
#endif

extern bool gameInserted;
extern uint16 *map0sub;

void waitVBlank(void);

/**
 * Waits the specified number of frames before returning.
 * @param  count: Number of frames to wait.
 * @deprecated Don't use, solve it some other way.
 */
void pausVBlank(int count);

void setEmuSpeed(int speed);
void setupMenuPalette(void);

/// This runs all save state functions for each chip.
int packState(void *statePtr);

/// This runs all load state functions for each chip.
void unpackState(const void *statePtr);

/// Gets the total state size in bytes.
int getStateSize(void);


#ifdef __cplusplus
} // extern "C"
#endif

#endif // MAIN_HEADER
