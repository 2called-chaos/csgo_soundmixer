void CreateCvarTrackerTimer(float delay)
{
  CreateTimer(delay, Timer_UpdateCvarCache, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

void CheckClientCvar(int client)
{
  QueryClientConVar(client, "snd_stream", view_as<ConVarQueryFinished>(NotifyCvarCallback));
}

public Action Timer_UpdateCvarCache(Handle event)
{
  for (int i = 1; i <= MaxClients; i++)
  {
    if (!IsClientInGame(i) || IsFakeClient(i)) continue;
    CheckClientCvar(i);
  }
  return Plugin_Continue;
}

public void NotifyCvarCallback(QueryCookie cookie, int client, ConVarQueryResult result, char [] cvarName, char [] cvarValue)
{
  int was = g_iUserState[client];
  g_iUserState[client] = StringToInt(cvarValue);
  if(was != g_iUserState[client])
  {
    Action ret;
    Call_StartForward(FwdOnPlayerChange);
    Call_PushCell(client);
    Call_PushCell(was);
    Call_PushCell(g_iUserState[client]);
    Call_Finish(ret);
  }
}

