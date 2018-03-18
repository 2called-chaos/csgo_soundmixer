// STD includes
#include <sourcemod>
#include <sdktools>

// require new syntax and semicolons
#pragma newdecls required
#pragma semicolon 1

// include self
#include <csgo_soundmixer>

// variables
Handle FwdOnPlayerChange = INVALID_HANDLE;

// storage
int g_iUserState[MAXPLAYERS+1] = {-1,...};
float g_fSoundVolumes[SMIX_MAXSOUNDS] = {1.0,...};
char g_sSoundNames[SMIX_MAXSOUNDS][PLATFORM_MAX_PATH];
char g_sMp3Samples[SMIX_MAXSOUNDS][PLATFORM_MAX_PATH];
char g_sWavSamples[SMIX_MAXSOUNDS][PLATFORM_MAX_PATH];
int g_bPrecacheSound[SMIX_MAXSOUNDS] = {true,...};
int g_iForcedFormat[SMIX_MAXSOUNDS] = {0,...};
Handle g_hSoundTrie = INVALID_HANDLE;

// states
int g_iSoundIndex = 0;
bool g_bGlobalPreloadDone = false;
int g_iGlobalForceFormat = -1;

// plugin info
#define PLUGIN_VERSION SMIX_VERSION
public Plugin myinfo =
{
  name = "CS:GO Soundmixer",
  author = "2called-chaos",
  description = "Play sounds depending on client's snd_stream setting",
  version = PLUGIN_VERSION,
  url = "https://github.com/2called-chaos/csgo_soundmixer"
};

#include "csgo_soundmixer/natives.sp"
#include "csgo_soundmixer/cvar_tracker.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
  SMix_CreateNatives();
  RegPluginLibrary("csgo_soundmixer");
  return APLRes_Success;
}

public void OnPluginStart()
{
  g_hSoundTrie = CreateTrie();
  FwdOnPlayerChange = CreateGlobalForward("SMix_OnPlayerChange", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
  CreateCvarTrackerTimer(10.0);
}

public void OnConfigsExecuted()
{
  PrecacheAllSounds();
}

public void OnClientPutInServer(int client)
{
  g_iUserState[client] = -1;
  if(!IsFakeClient(client))
  {
    CheckClientCvar(client);
  }
}

public void OnClientDisconnect(int client)
{
  g_iUserState[client] = -1;
}

void PrecacheAllSounds()
{
  for (int i = 0; i < g_iSoundIndex; i++)
  {
    if (i >= SMIX_MAXSOUNDS) break;
    AddDownloadFile(i);
    DoPrecacheSound(i);
  }
  g_bGlobalPreloadDone = true;
}

void AddDownloadFile(int soundIndex)
{
  if (!g_bPrecacheSound[soundIndex]) return;
  char downloadLocation[PLATFORM_MAX_PATH];

  // download mp3
  if (!g_iForcedFormat[soundIndex] || g_iForcedFormat[soundIndex] == 1)
  {
    Format(downloadLocation, sizeof(downloadLocation), "sound/%s", g_sMp3Samples[soundIndex]);
    AddFileToDownloadsTable(downloadLocation);
  }

  // download wav
  if (!g_iForcedFormat[soundIndex] || g_iForcedFormat[soundIndex] == 2)
  {
    Format(downloadLocation, sizeof(downloadLocation), "sound/%s", g_sWavSamples[soundIndex]);
    AddFileToDownloadsTable(downloadLocation);
  }
}

bool DoPrecacheSound(int soundIndex)
{
  if (!g_bPrecacheSound[soundIndex]) return;

  // fake precache mp3
  if (!g_iForcedFormat[soundIndex] || g_iForcedFormat[soundIndex] == 1)
  {
    char pathStar[PLATFORM_MAX_PATH];
    Format(pathStar, sizeof(pathStar), "*%s", g_sMp3Samples[soundIndex]);
    AddToStringTable(FindStringTable("soundprecache"), pathStar);
  }

  // precache wav
  if (!g_iForcedFormat[soundIndex] || g_iForcedFormat[soundIndex] == 2)
  {
    PrecacheSound(g_sWavSamples[soundIndex]);
  }
}
