#ifdef __cplusplus
extern "C" {
#endif

BOOL InitSoundManager(void);
int FM_CountFiles(const char *a_dir_name);
void audio_alarm_handler(void *);

#ifdef __cplusplus
}
#endif