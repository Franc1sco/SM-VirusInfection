#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define DATA "0.1 pre alpha"

public Plugin myinfo = 
{
	name = "SM CoronaVirus Infection",
	author = "Franc1sco franug",
	description = "",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
};

enum struct Virus{
	Handle tStartVirus;
	Handle tShareVirus;
	Handle tProgressVirus;
	bool bVirus;
}

Virus virus[MAXPLAYERS + 1];

public void OnPluginStart()
{
	RegAdminCmd("sm_givevirus", Command_GiveVirus, ADMFLAG_BAN);
	RegAdminCmd("sm_removevirus", Command_RemoveVirus, ADMFLAG_BAN);
	
	HookEventEx("player_spawn", Event_Restart);
	HookEventEx("player_death", Event_Restart);
}

public Action Command_GiveVirus(int client, int args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "Use: sm_givevirus <name>");
		return Plugin_Handled;
	}
	char strTarget[32]; 
	GetCmdArg(1, strTarget, sizeof(strTarget)); 

	// Progress the targets 
	char strTargetName[MAX_TARGET_LENGTH]; 
	int TargetList[MAXPLAYERS];
	int TargetCount; 
	bool TargetTranslate; 

	if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, 
					strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
	{ 
		ReplyToCommand(client, "client not found");
		return Plugin_Handled; 
	} 

	// Apply to all targets 
	int count;
	for (int i = 0; i < TargetCount; i++) 
	{ 
		int iClient = TargetList[i]; 
		if (IsClientInGame(iClient) && IsPlayerAlive(iClient)) 
		{
			count++;
			Infection(iClient);
			ReplyToCommand(client, "Player %N has been infected with coronavirus", iClient);
		} 
	}

	if(count == 0)
		ReplyToCommand(client, "No valid clients");
	
	return Plugin_Handled;
}

public Action Command_RemoveVirus(int client, int args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "Use: sm_removevirus <name>");
		return Plugin_Handled;
	}
	char strTarget[32]; 
	GetCmdArg(1, strTarget, sizeof(strTarget)); 

	// Progress the targets 
	char strTargetName[MAX_TARGET_LENGTH]; 
	int TargetList[MAXPLAYERS];
	int TargetCount; 
	bool TargetTranslate; 

	if ((TargetCount = ProcessTargetString(strTarget, client, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, 
					strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
	{ 
		ReplyToCommand(client, "client not found");
		return Plugin_Handled; 
	} 

	// Apply to all targets 
	int count;
	for (int i = 0; i < TargetCount; i++) 
	{ 
		int iClient = TargetList[i]; 
		if (IsClientInGame(iClient) && IsPlayerAlive(iClient) && virus[iClient].bVirus) 
		{
			count++;
			Infection(iClient);
			ReplyToCommand(client, "Player %N has been cured of coronavirus", iClient);
		} 
	}

	if(count == 0)
		ReplyToCommand(client, "No valid clients");
	
	return Plugin_Handled;
}

public void OnClientDisconnect(int client)
{
	resetClient(client);
}

public Action Event_Restart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	resetClient(client);
}

void Infection(int client)
{
	resetClient(client);
	
	virus[client].bVirus = true;
	
	virus[client].tStartVirus = CreateTimer(60.0, Timer_StartVirus, client);
	
	
	virus[client].tShareVirus = CreateTimer(1.0, Timer_ShareVirus, client);
}

public Action Timer_StartVirus(Handle timer, int client)
{
	virus[client].tStartVirus = null;
	
	if (!IsClientInGame(client) || !virus[client].bVirus)return;
	
	// todo do firsts effects with chat notification, damage, etc
	PrintToConsole(client, "Virus effects starting.."); // debug
	
	virus[client].tProgressVirus = CreateTimer(60.0, Timer_ProgressVirus, client);
}

public Action Timer_ProgressVirus(Handle timer, int client)
{
	if (!IsClientInGame(client) || !virus[client].bVirus)resetClient(client);
	
	// todo do progress effects, do damage and view effects
	PrintToConsole(client, "Virus effects progressing.."); // debug
	
	virus[client].tProgressVirus = CreateTimer(60.0, Timer_ProgressVirus, client);
}

public Action Timer_ShareVirus(Handle timer, int client)
{
	if (!IsClientInGame(client) || !virus[client].bVirus)resetClient(client);
	
	// todo do share virus, with nearby people
	PrintToConsole(client, "Sharing virus.."); // debug
	
	virus[client].tShareVirus = CreateTimer(1.0, Timer_ShareVirus, client);
}

void resetClient(int client)
{
	ClearTimer(virus[client].tStartVirus);
	ClearTimer(virus[client].tShareVirus);
	ClearTimer(virus[client].tProgressVirus);
	virus[client].bVirus = false;
}


stock void ClearTimer(Handle timer)
{
	if(timer != null)
		KillTimer(timer);
		
	timer = null;
}
