#ifdef __cplusplus
extern "C" {
#endif

BOOL InitFileManager(void);
BOOL FM_LoadGame(const char *a_file_name);
BOOL FM_LoadFile(const char *a_file_name);
int FM_GetGameList(char *a_dir_list,int pos);
int FM_GetFileList(const char *a_dir_name,char *a_dir_list,int pos);
int FM_CountFiles(const char *a_dir_name);
int FM_CountGameFiles(void);

#ifdef __cplusplus
}
#endif