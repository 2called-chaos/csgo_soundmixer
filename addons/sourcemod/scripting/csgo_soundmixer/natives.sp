void SMix_CreateNatives()
{
  CreateNative("SMix_ClearAllSounds", Native_SMix_ClearAllSounds);
  CreateNative("SMix_ForceFormatAll", Native_SMix_ForceFormatAll);
  CreateNative("SMix_CreateSound", Native_SMix_CreateSound);
  CreateNative("SMix_FindSound", Native_SMix_FindSound);
  CreateNative("SMix_ClientState", Native_SMix_ClientState);
  CreateNative("SMix_ForceClientCheck", Native_SMix_ForceClientCheck);
  CreateNative("SMix_EmitSoundToAll", Native_SMix_EmitSoundToAll);
  CreateNative("SMix_EmitSoundToClient", Native_SMix_EmitSoundToClient);
  CreateNative("SMix_Sound_WavSample", Native_SMix_Sound_WavSample);
  CreateNative("SMix_Sound_Mp3Sample", Native_SMix_Sound_Mp3Sample);
  CreateNative("SMix_Sound_Volume", Native_SMix_Sound_Volume);
  CreateNative("SMix_Sound_SetVolume", Native_SMix_Sound_SetVolume);
  CreateNative("SMix_Sound_Precache", Native_SMix_Sound_Precache);
  CreateNative("SMix_Sound_SetPrecache", Native_SMix_Sound_SetPrecache);
  CreateNative("SMix_Sound_ForceFormat", Native_SMix_Sound_ForceFormat);
  CreateNative("SMix_Sound_SetForceFormat", Native_SMix_Sound_SetForceFormat);
  CreateNative("SMix_Sound_EmitToAll", Native_SMix_Sound_EmitToAll);
  CreateNative("SMix_Sound_EmitToClient", Native_SMix_Sound_EmitToClient);
}

public int Native_SMix_ClientState(Handle plugin, int numParams)
{
  int client = GetNativeCell(1);
  return view_as<int>(g_iUserState[client]);
}

public int Native_SMix_ForceClientCheck(Handle plugin, int numParams)
{
  int client = GetNativeCell(1);
  CheckClientCvar(client);
  return client;
}

public int Native_SMix_ClearAllSounds(Handle plugin, int numParams)
{
  g_iSoundIndex = 0;
  ClearTrie(g_hSoundTrie);
}

public int Native_SMix_ForceFormatAll(Handle plugin, int numParams)
{
  // force newly created sounds to use forceFormat
  g_iGlobalForceFormat = view_as<int>(GetNativeCell(1));

  // update existing sounds
  for (int i = 0; i < g_iSoundIndex; i++)
  {
    if (i >= SMIX_MAXSOUNDS) break;
    g_iForcedFormat[i] = g_iGlobalForceFormat;
  }
}

public int Native_SMix_FindSound(Handle plugin, int numParams)
{
  int snd = -1;
  int len;
  GetNativeStringLength(1, len);
  if (len <= 0) return view_as<int>(snd);
  char[] name = new char[len + 1];
  GetNativeString(1, name, len + 1);

  int soundIndex;
  if (GetTrieValue(g_hSoundTrie, name, soundIndex))
    snd = soundIndex;

  return view_as<int>(snd);
}

public int Native_SMix_CreateSound(Handle plugin, int numParams)
{
  // arg1: char[] name
  int len;
  GetNativeStringLength(1, len);
  if (len <= 0) return false;
  char[] name = new char[len + 1];
  GetNativeString(1, name, len + 1);

  // arg2: char[] sample
  GetNativeStringLength(2, len);
  if (len <= 0) return false;
  char[] sample = new char[len + 1];
  GetNativeString(2, sample, len + 1);

  // arg3: float volume
  float volume = view_as<float>(GetNativeCell(3));

  // arg4: bool precache
  bool precache = view_as<bool>(GetNativeCell(4));

  // arg5: int forceFormat
  int forceFormat = GetNativeCell(5);
  if (g_iGlobalForceFormat > -1)
    forceFormat = g_iGlobalForceFormat;

  // check if sound exists
  int index;
  if(GetTrieValue(g_hSoundTrie, name, index))
    return ThrowNativeError(SP_ERROR_NATIVE, "[SMix] Sound with name %s already exists!", name);

  // check if array in bounds
  if(g_iSoundIndex >= SMIX_MAXSOUNDS)
    return ThrowNativeError(SP_ERROR_NATIVE, "[SMix] Exceeded SMIX_MAXSOUNDS(=%i)!", SMIX_MAXSOUNDS);

  // check format
  int format = 0;
  if (StrContains(sample, ".mp3", false) != -1)
    format = 1;
  else if (StrContains(sample, ".wav", false) != -1)
    format = 2;
  else
    return ThrowNativeError(SP_ERROR_NATIVE, "[SMix] Provided sample must be either .mp3 or .wav!");

  if(SetTrieValue(g_hSoundTrie, name, g_iSoundIndex))
  {
    strcopy(g_sSoundNames[g_iSoundIndex], sizeof(g_sSoundNames[]), name);
    g_fSoundVolumes[g_iSoundIndex] = volume;
    g_iForcedFormat[g_iSoundIndex] = forceFormat;
    g_bPrecacheSound[g_iSoundIndex] = precache;

    char samplecopy[PLATFORM_MAX_PATH];
    strcopy(samplecopy, sizeof(samplecopy), sample);

    if (format == 1)
    {
      strcopy(g_sMp3Samples[g_iSoundIndex], sizeof(g_sMp3Samples[]), sample);
      ReplaceString(samplecopy, sizeof(samplecopy), ".mp3", ".wav", false);
      strcopy(g_sWavSamples[g_iSoundIndex], sizeof(g_sWavSamples[]), samplecopy);
    }
    else
    {
      strcopy(g_sWavSamples[g_iSoundIndex], sizeof(g_sWavSamples[]), sample);
      ReplaceString(samplecopy, sizeof(samplecopy), ".wav", ".mp3", false);
      strcopy(g_sMp3Samples[g_iSoundIndex], sizeof(g_sMp3Samples[]), samplecopy);
    }

    // instant DL/precache if global loop already ran
    if (g_bGlobalPreloadDone)
    {
      AddDownloadFile(g_iSoundIndex);
      DoPrecacheSound(g_iSoundIndex);
    }

    g_iSoundIndex++;
  }

  SMixSound snd = new SMixSound(g_iSoundIndex - 1);
  return view_as<int>(snd);
}

public int Native_SMix_EmitSoundToAll(Handle plugin, int numParams)
{
  // arg1: char[] name
  int len;
  GetNativeStringLength(1, len);
  if (len <= 0) return false;
  char[] name = new char[len + 1];
  GetNativeString(1, name, len + 1);

  SMixSound snd = SMix_FindSound(name);

  if(snd.index != -1)
  {
    float origin[3], dir[3];
    GetNativeArray(9, origin, 3);
    GetNativeArray(10, dir, 3);

    SMix_Sound_EmitToAll(
      view_as<int>(snd.index),          // sound index
      view_as<int>(GetNativeCell(2)),   // int   entity = SOUND_FROM_PLAYER,
      view_as<int>(GetNativeCell(3)),   // int   channel = SNDCHAN_AUTO,
      view_as<int>(GetNativeCell(4)),   // int   level = SNDLEVEL_NORMAL,
      view_as<int>(GetNativeCell(5)),   // int   flags = SND_NOFLAGS,
      view_as<float>(GetNativeCell(6)), // float volume = SNDVOL_NORMAL,
      view_as<int>(GetNativeCell(7)),   // int   pitch = SNDPITCH_NORMAL,
      view_as<int>(GetNativeCell(8)),   // int   speakerentity = -1,
      origin,                           // float origin[3] = NULL_VECTOR,
      dir,                              // float dir[3] = NULL_VECTOR,
      view_as<bool>(GetNativeCell(11)), // bool  updatePos = true,
      view_as<float>(GetNativeCell(12)) // float soundtime = 0.0);
    );
  }

  return 0;
}

public int Native_SMix_EmitSoundToClient(Handle plugin, int numParams)
{
  // arg2: char[] name
  int len;
  GetNativeStringLength(2, len);
  if (len <= 0) return false;
  char[] name = new char[len + 1];
  GetNativeString(2, name, len + 1);

  SMixSound snd = SMix_FindSound(name);

  if(snd.index != -1)
  {
    float origin[3], dir[3];
    GetNativeArray(10, origin, 3);
    GetNativeArray(11, dir, 3);

    SMix_Sound_EmitToClient(
      view_as<int>(GetNativeCell(1)),   // int client
      view_as<int>(snd.index),          // sound index
      view_as<int>(GetNativeCell(3)),   // int   entity = SOUND_FROM_PLAYER,
      view_as<int>(GetNativeCell(4)),   // int   channel = SNDCHAN_AUTO,
      view_as<int>(GetNativeCell(5)),   // int   level = SNDLEVEL_NORMAL,
      view_as<int>(GetNativeCell(6)),   // int   flags = SND_NOFLAGS,
      view_as<float>(GetNativeCell(7)), // float volume = SNDVOL_NORMAL,
      view_as<int>(GetNativeCell(8)),   // int   pitch = SNDPITCH_NORMAL,
      view_as<int>(GetNativeCell(9)),   // int   speakerentity = -1,
      origin,                           // float origin[3] = NULL_VECTOR,
      dir,                              // float dir[3] = NULL_VECTOR,
      view_as<bool>(GetNativeCell(12)), // bool  updatePos = true,
      view_as<float>(GetNativeCell(13)) // float soundtime = 0.0);
    );
  }

  return 0;
}


// ===================
// = SOUND methodmap =
// ===================

public int Native_SMix_Sound_WavSample(Handle plugin, int numParams)
{
  int soundIndex = GetNativeCell(1);
  int length = GetNativeCell(3);
  return SetNativeString(2, g_sWavSamples[soundIndex], length, false);
}

public int Native_SMix_Sound_Mp3Sample(Handle plugin, int numParams)
{
  int soundIndex = GetNativeCell(1);
  int length = GetNativeCell(3);
  return SetNativeString(2, g_sMp3Samples[soundIndex], length, false);
}

public int Native_SMix_Sound_Volume(Handle plugin, int numParams)
{
  int soundIndex = GetNativeCell(1);
  return view_as<int>(g_fSoundVolumes[soundIndex]);
}

public int Native_SMix_Sound_SetVolume(Handle plugin, int numParams)
{
  int soundIndex = GetNativeCell(1);
  float newVolume = view_as<float>(GetNativeCell(2));
  g_fSoundVolumes[soundIndex] = newVolume;
  return view_as<int>(g_fSoundVolumes[soundIndex]);
}

public int Native_SMix_Sound_Precache(Handle plugin, int numParams)
{
  int soundIndex = GetNativeCell(1);
  return view_as<int>(g_bPrecacheSound[soundIndex]);
}

public int Native_SMix_Sound_SetPrecache(Handle plugin, int numParams)
{
  int soundIndex = GetNativeCell(1);
  bool newval = GetNativeCell(2);
  g_bPrecacheSound[soundIndex] = newval;
  return view_as<int>(g_bPrecacheSound[soundIndex]);
}

public int Native_SMix_Sound_ForceFormat(Handle plugin, int numParams)
{
  int soundIndex = GetNativeCell(1);
  return g_iForcedFormat[soundIndex];
}

public int Native_SMix_Sound_SetForceFormat(Handle plugin, int numParams)
{
  int soundIndex = GetNativeCell(1);
  int format = GetNativeCell(2);
  g_iForcedFormat[soundIndex] = format;
  return g_iForcedFormat[soundIndex];
}

public int Native_SMix_Sound_EmitToAll(Handle plugin, int numParams)
{
  int   x             = 1;
  int   soundIndex    = view_as<int>(GetNativeCell(x++));
  int   entity        = view_as<int>(GetNativeCell(x++));
  int   channel       = view_as<int>(GetNativeCell(x++));
  int   level         = view_as<int>(GetNativeCell(x++));
  int   flags         = view_as<int>(GetNativeCell(x++));
  float volume        = view_as<float>(GetNativeCell(x++));
  int   pitch         = view_as<int>(GetNativeCell(x++));
  int   speakerentity = view_as<int>(GetNativeCell(x++));
  float origin[3];      GetNativeArray(x++, origin, 3);
  float dir[3];         GetNativeArray(x++, dir, 3);
  bool  updatePos     = view_as<bool>(GetNativeCell(x++));
  float soundtime     = view_as<float>(GetNativeCell(x++));

  // invoke for all clients
  for (int i = 1; i <= MaxClients; i++)
  {
    if (!IsClientInGame(i) || IsFakeClient(i)) continue;
    SMix_Sound_EmitToClient(i, soundIndex, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
  }

  return 0;
}

public int Native_SMix_Sound_EmitToClient(Handle plugin, int numParams)
{
  int   x             = 1;
  int   client        = view_as<int>(GetNativeCell(x++));
  int   soundIndex    = view_as<int>(GetNativeCell(x++));
  int   entity        = view_as<int>(GetNativeCell(x++));
  int   channel       = view_as<int>(GetNativeCell(x++));
  int   level         = view_as<int>(GetNativeCell(x++));
  int   flags         = view_as<int>(GetNativeCell(x++));
  float volume        = view_as<float>(GetNativeCell(x++));
  int   pitch         = view_as<int>(GetNativeCell(x++));
  int   speakerentity = view_as<int>(GetNativeCell(x++));
  float origin[3];      GetNativeArray(x++, origin, 3);
  float dir[3];         GetNativeArray(x++, dir, 3);
  bool  updatePos     = view_as<bool>(GetNativeCell(x++));
  float soundtime     = view_as<float>(GetNativeCell(x++));

  // require valid user to play sound to
  if (!IsClientInGame(client) || IsFakeClient(client)) return 0;

  // require soundIndex to be valid
  SMixSound snd = new SMixSound(soundIndex);
  if(snd.index == -1) return 0;

  // which format shall we use?
  char playSound[PLATFORM_MAX_PATH];

  if (g_iForcedFormat[soundIndex] == 2 || (!g_iForcedFormat[soundIndex] && g_iUserState[client] == 1)) // wav
  {
    strcopy(playSound, sizeof(playSound), g_sWavSamples[soundIndex]);
  }
  else // mp3
  {
    Format(playSound, sizeof(playSound), "*%s", g_sMp3Samples[soundIndex]);
  }

  int clients[1];
  clients[0] = client;
  EmitSound(clients, 1, playSound, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);

  return 0;
}
