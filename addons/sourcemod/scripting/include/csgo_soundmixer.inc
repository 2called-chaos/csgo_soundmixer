#if defined _soundmixer_natives_included_
  #endinput
#endif
#define _soundmixer_natives_included_

#define SMIX_MAXSOUNDS 100
#define SMIX_VERSION "1.0.1"

forward void      SMix_OnPlayerChange(int client, int oldValue, int newValue);
native  int       SMix_ClientState(int client);
native  void      SMix_ForceClientCheck(int client);
native  void      SMix_ForceFormatAll(int forceFormat);
native  void      SMix_ClearAllSounds();
native  SMixSound SMix_CreateSound(char[] name, char[] sample, float volume = 1.0, bool precache = true, int forceFormat = 0);
native  SMixSound SMix_FindSound(char[] name);
// use methodmap
native  void      SMix_Sound_WavSample(int soundIndex, char[] sample, int length);
native  void      SMix_Sound_Mp3Sample(int soundIndex, char[] sample, int length);
native  float     SMix_Sound_Volume(int soundIndex);
native  void      SMix_Sound_SetVolume(int soundIndex, float newVolume);
native  bool      SMix_Sound_Precache(int soundIndex);
native  void      SMix_Sound_SetPrecache(int soundIndex, bool shouldPrecache);
native  int       SMix_Sound_ForceFormat(int soundIndex);
native  void      SMix_Sound_SetForceFormat(int soundIndex, int forceFormat);

native  void      SMix_Sound_EmitToAll(int   soundIndex,
                                       int   entity = SOUND_FROM_PLAYER,
                                       int   channel = SNDCHAN_AUTO,
                                       int   level = SNDLEVEL_NORMAL,
                                       int   flags = SND_NOFLAGS,
                                       float volume = SNDVOL_NORMAL,
                                       int   pitch = SNDPITCH_NORMAL,
                                       int   speakerentity = -1,
                                       float origin[3] = NULL_VECTOR,
                                       float dir[3] = NULL_VECTOR,
                                       bool  updatePos = true,
                                       float soundtime = 0.0);

native  void      SMix_Sound_EmitToClient(int   client,
                                          int   soundIndex,
                                          int   entity = SOUND_FROM_PLAYER,
                                          int   channel = SNDCHAN_AUTO,
                                          int   level = SNDLEVEL_NORMAL,
                                          int   flags = SND_NOFLAGS,
                                          float volume = SNDVOL_NORMAL,
                                          int   pitch = SNDPITCH_NORMAL,
                                          int   speakerentity = -1,
                                          float origin[3] = NULL_VECTOR,
                                          float dir[3] = NULL_VECTOR,
                                          bool  updatePos = true,
                                          float soundtime = 0.0);

native  void      SMix_EmitSoundToAll(const char[] name,
                                      int   entity = SOUND_FROM_PLAYER,
                                      int   channel = SNDCHAN_AUTO,
                                      int   level = SNDLEVEL_NORMAL,
                                      int   flags = SND_NOFLAGS,
                                      float volume = SNDVOL_NORMAL,
                                      int   pitch = SNDPITCH_NORMAL,
                                      int   speakerentity = -1,
                                      float origin[3] = NULL_VECTOR,
                                      float dir[3] = NULL_VECTOR,
                                      bool  updatePos = true,
                                      float soundtime = 0.0);

native  void      SMix_EmitSoundToClient(int   client,
                                         const char[] name,
                                         int   entity = SOUND_FROM_PLAYER,
                                         int   channel = SNDCHAN_AUTO,
                                         int   level = SNDLEVEL_NORMAL,
                                         int   flags = SND_NOFLAGS,
                                         float volume = SNDVOL_NORMAL,
                                         int   pitch = SNDPITCH_NORMAL,
                                         int   speakerentity = -1,
                                         float origin[3] = NULL_VECTOR,
                                         float dir[3] = NULL_VECTOR,
                                         bool  updatePos = true,
                                         float soundtime = 0.0);

methodmap SMixSound __nullable__
{
   public SMixSound(int index)
   {
      return view_as<SMixSound>(index);
   }

   property int index
   {
      public get()
      {
         return view_as<int>(this);
      }
   }

   property float Volume
   {
      public get()
      {
         return SMix_Sound_Volume(this.index);
      }
      public set(float newVolume)
      {
         return SMix_Sound_SetVolume(this.index, newVolume);
      }
   }

   property bool Precache
   {
      public get()
      {
         return SMix_Sound_Precache(this.index);
      }
      public set(bool newPrecache)
      {
         return SMix_Sound_SetPrecache(this.index, newPrecache);
      }
   }

   property int ForceFormat
   {
      public get()
      {
         return SMix_Sound_ForceFormat(this.index);
      }
      public set(int newForceFormat)
      {
         return SMix_Sound_SetForceFormat(this.index, newForceFormat);
      }
   }

   public void GetWavSample(char[] sample, int length)
   {
      return SMix_Sound_WavSample(this.index, sample, length);
   }

   public void GetMp3Sample(char[] sample, int length)
   {
      return SMix_Sound_Mp3Sample(this.index, sample, length);
   }

   public void EmitToAll()
   {
      return SMix_Sound_EmitToAll(this.index);
   }

   public void EmitToClient(int client)
   {
      return SMix_Sound_EmitToClient(this.index, client);
   }
}

public SharedPlugin __pl_csgo_soundmixer =
{
   name = "csgo_soundmixer",
   file = "csgo_soundmixer.smx",
#if defined REQUIRE_PLUGIN
   required = 1
#else
   required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_csgo_soundmixer_SetNTVOptional()
{
  MarkNativeAsOptional("SMix_ClearAllSounds");
  MarkNativeAsOptional("SMix_ForceFormatAll");
  MarkNativeAsOptional("SMix_CreateSound");
  MarkNativeAsOptional("SMix_FindSound");
  MarkNativeAsOptional("SMix_ClientState");
  MarkNativeAsOptional("SMix_ForceClientCheck");
  MarkNativeAsOptional("SMix_EmitSoundToAll");
  MarkNativeAsOptional("SMix_EmitSoundToClient");
  MarkNativeAsOptional("SMix_Sound_WavSample");
  MarkNativeAsOptional("SMix_Sound_Mp3Sample");
  MarkNativeAsOptional("SMix_Sound_Volume");
  MarkNativeAsOptional("SMix_Sound_SetVolume");
  MarkNativeAsOptional("SMix_Sound_Precache");
  MarkNativeAsOptional("SMix_Sound_SetPrecache");
  MarkNativeAsOptional("SMix_Sound_ForceFormat");
  MarkNativeAsOptional("SMix_Sound_SetForceFormat");
  MarkNativeAsOptional("SMix_Sound_EmitToAll");
  MarkNativeAsOptional("SMix_Sound_EmitToClient");
}
#endif
