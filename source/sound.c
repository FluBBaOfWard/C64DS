#include "sound.h"

#define ALARM_NUM 0
#define CHANNEL_NUM 4
//#define AUDIO_BUFFER_PAGESIZE 312
#define AUDIO_BUFFER_PAGESIZE 528
#define AUDIO_BUFFER_PAGES 4
#define AUDIO_BUFFER_SIZE AUDIO_BUFFER_PAGESIZE * AUDIO_BUFFER_PAGES
//#define AUDIO_SAMPLE_RATE 15600
#define AUDIO_SAMPLE_RATE 31200

u16 audio_buffer[AUDIO_BUFFER_SIZE];
u32 m_mixing_page = 2;
extern void SID_StartMixer(void*);

BOOL InitSoundManager()
{
	// Timer Values
	// It's fairly critical that these are calculated like this since the
	// audio timer has a different resolution to the alarm timer
//	int base_period = SND_TIMER_CLOCK;
	u32 base_period = (SND_TIMER_CLOCK / AUDIO_SAMPLE_RATE) >> 5;
	int channel_period = (s32)(base_period << 5);
	u32 alarm_period = base_period * AUDIO_BUFFER_PAGESIZE;
	m_mixing_page = 2;

	// Volume on
	SND_SetMasterVolume(127);
	SND_FlushCommand(SND_COMMAND_NOBLOCK);

	// Allocation PCM channel 
	SND_LockChannel(1 << CHANNEL_NUM, 0);

	// Setup channel as repeating sample
	SND_SetupChannelPcm(CHANNEL_NUM,
		SND_WAVE_FORMAT_PCM16,
		&audio_buffer[0],
		SND_CHANNEL_LOOP_REPEAT,
		0,
		AUDIO_BUFFER_SIZE*2 / sizeof(u32),
		127,
		SND_CHANNEL_DATASHIFT_NONE,
		channel_period,
		64);
 
	// Setup audio alarm timer
	SND_SetupAlarm(ALARM_NUM, alarm_period, alarm_period, audio_alarm_handler, 0);

	// Start audio and alarm timer simulateously
	SND_StartTimer(1<<CHANNEL_NUM, 0, 1<<ALARM_NUM, 0);
	(void)SND_FlushCommand(SND_COMMAND_NOBLOCK);
	return TRUE;
}


void audio_alarm_handler(void *)
{
	// Increment the mixing buffer and wake up the emulation/mixing thread
	m_mixing_page = (m_mixing_page + 1)&3;
	SID_StartMixer(&audio_buffer[m_mixing_page*AUDIO_BUFFER_PAGESIZE]);
}


