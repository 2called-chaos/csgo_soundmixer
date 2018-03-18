// STD includes
#include <sourcemod>
#include <sdktools>

// require new syntax and semicolons
#pragma newdecls required
#pragma semicolon 1

// include self
#include <csgo_soundmixer>

// plugin info
#define PLUGIN_VERSION "0.0.1"
public Plugin myinfo =
{
  name = "CS:GO Soundmixer Test",
  author = "2called-chaos",
  description = "Testing soundmixer from another plugin",
  version = PLUGIN_VERSION,
  url = "https://github.com/2called-chaos/csgo_soundmixer"
};

SMixSound g_sndWhatever;

public void OnPluginStart()
{
  SMix_CreateSound("tied", "fcs_soundtest3/gg_tiedlead.mp3", 0.7);
  SMix_CreateSound("taken", "fcs_soundtest3/gg_takenlead.mp3", 0.7);
  SMix_CreateSound("lost", "fcs_soundtest3/gg_lostlead.mp3", 0.7);
  g_sndWhatever = SMix_CreateSound("whatever", "fcs_soundtest3/whatever.mp3", 0.7);
  RegAdminCmd("act_lead", Command_Lead, ADMFLAG_CONVARS, "Play sounds over different channels");
  RegAdminCmd("act_whatever", Command_Whatever, ADMFLAG_CONVARS, "Play sounds over different channels");
}

public void SMix_OnPlayerChange(int client, int was, int now)
{
  LogError("Client %i changed snd_stream to %i was %i", client, now, was);
}

public Action Command_Lead(int client, int args)
{
  char name[96];
  GetCmdArg(1, name, sizeof(name));
  SMix_EmitSoundToClient(client, name);
  return Plugin_Handled;
}

public Action Command_Whatever(int client, int args)
{
  g_sndWhatever.EmitToClient(client);
  return Plugin_Handled;
}
