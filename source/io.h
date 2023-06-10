#ifndef IO_HEADER
#define IO_HEADER

#ifdef __cplusplus
extern "C" {
#endif

extern u32 joyCfg;
extern u32 EMUinput;

void SetC64Key(int x, int y, bool touch);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // IO_HEADER
