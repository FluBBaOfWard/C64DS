#ifdef __cplusplus
extern "C" {
#endif

extern u8 gFlicker;
extern u8 gTwitch;
extern u8 gScaling;
extern u8 gGfxMask;

extern u16 EMUPALBUFF[0x400];
extern void *tile_base;
extern void *obj_base;

void vblIrqHandler(void);
void gfxInit(void);

#ifdef __cplusplus
}
#endif
