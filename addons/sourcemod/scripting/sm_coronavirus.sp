#include <sourcemod>
#include <sdktools>
#include <autoexecconfig>
#include <colorlib>
#undef REQUIRE_PLUGIN
#include <devzones>

#pragma semicolon 1
#pragma newdecls required

#define DATA "1.0"


#define ENGLISH // multi language pending to do


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
	Handle tQuarantine;
	Handle tBlind;
	bool bVirus;
	bool bNoticed;
}

Virus virus[MAXPLAYERS + 1];
UserMsg g_FadeUserMsgId;

ConVar cv_TIME_START, cv_TIME_EFFECTS, cv_TIME_SHARE, cv_TIME_BLIND, cv_SHARE_CHANCE, cv_SHARE_CHANCE_COUGH, cv_VIRUS_DAMAGE, cv_VIRUS_DISTANCE, cv_TIME_QUARANTINE;

public void OnPluginStart()
{
	CreateConVar("sm_coronavirus_version", DATA, "Coronavirus plugin version.");
	
	AutoExecConfig_SetFile("sm_coronavirus");
	cv_TIME_START = AutoExecConfig_CreateConVar("sm_coronavirus_time_start", "60.0", "Seconds for start to know that you have coronavirus.");
	cv_TIME_EFFECTS = AutoExecConfig_CreateConVar("sm_coronavirus_time_effects", "30.0", "Each X seconds for have the coronavirus effects.");
	cv_TIME_SHARE = AutoExecConfig_CreateConVar("sm_coronavirus_time_share", "5.0", "Each X seconds for share the coronavirus.");
	cv_TIME_BLIND = AutoExecConfig_CreateConVar("sm_coronavirus_time_blind", "5.0", "Seconds for have the blind effect.");
	cv_SHARE_CHANCE = AutoExecConfig_CreateConVar("sm_coronavirus_share_chance", "10", "Chance of share coronavirus.");
	cv_SHARE_CHANCE_COUGH = AutoExecConfig_CreateConVar("sm_coronavirus_share_chancecough", "60", "Chance of share coronavirus when you cough.");
	cv_VIRUS_DAMAGE = AutoExecConfig_CreateConVar("sm_coronavirus_virus_damage", "5", "Damage that produce coronavirus when you have the effects.");
	cv_VIRUS_DISTANCE = AutoExecConfig_CreateConVar("sm_coronavirus_virus_distance", "100.0", "Distance min for share coronavirus to someone.");
	cv_TIME_QUARANTINE = AutoExecConfig_CreateConVar("sm_coronavirus_quarantine_time", "60.0", "Seconds that you need to stay in a quarantine zone for be healed.");
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	RegAdminCmd("sm_givevirus", Command_GiveVirus, ADMFLAG_BAN);
	RegAdminCmd("sm_removevirus", Command_RemoveVirus, ADMFLAG_BAN);
	
	HookEventEx("player_spawn", Event_Restart);
	HookEventEx("player_death", Event_Restart);
	
	g_FadeUserMsgId = GetUserMessageId("Fade");
}

public void OnMapStart()
{
	AddFileToDownloadsTable("sound/sm_coronavirus/cough1.mp3");
	PrecacheSound("sm_coronavirus/cough1.mp3");
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
			#if defined ENGLISH
			CReplyToCommand(client, "{green}[SM-CoronaVirus]{lightgreen} Player %N has been infected with coronavirus", iClient);
			#else
			CReplyToCommand(client, "{green}[SM-CoronaVirus]{lightgreen} Jugador %N ha sido infectado con el coronavirus", iClient);
			#endif
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
			resetClient(iClient);
			#if defined ENGLISH
			CReplyToCommand(client, "{green}[SM-CoronaVirus]{lightgreen} Player %N has been cured of coronavirus", iClient);
			#else
			CReplyToCommand(client, "{green}[SM-CoronaVirus]{lightgreen} Jugador %N ha sido curado del coronavirus", iClient);
			#endif
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
	
	virus[client].tStartVirus = CreateTimer(cv_TIME_START.FloatValue, Timer_StartVirus, client);
	
	
	virus[client].tShareVirus = CreateTimer(cv_TIME_SHARE.FloatValue, Timer_ShareVirus, client);
}

public Action Timer_StartVirus(Handle timer, int client)
{
	delete virus[client].tStartVirus;
	
	if (!IsClientInGame(client) || !virus[client].bVirus)return;
	
	// todo do firsts effects with chat notification, damage, etc
	//PrintToConsoleAll("%N Virus effects starting..", client); // debug
	
	#if defined ENGLISH
	CPrintToChat(client, "{green}[SM-CoronaVirus]{lightgreen} Something start to be wrong...");
	#else
	CPrintToChat(client, "{green}[SM-CoronaVirus]{lightgreen} Algo empieza a ir mal...");
	#endif
	
	virus[client].bNoticed = true;

	int health = GetClientHealth(client) - cv_VIRUS_DAMAGE.IntValue;
	if(health <= 0)
	{
		ForcePlayerSuicide(client);
		return;
	}
		
	SetEntityHealth(client, health);
	
	float cal = (GetClientHealth(client) * 1.0) / (GetEntProp(client, Prop_Data, "m_iMaxHealth") * 1.0);
	cal = cal * 255.0;
	cal = cal - 255.0;
	if(cal != 0.0)
		cal *= -1.0;
	
	if(cal > 255.0)
		cal = 255.0;
	else if(cal < 0.0)
		cal = 0.0;
	
	PerformBlind(client, RoundToNearest(cal), cv_TIME_BLIND.FloatValue);
	
	virus[client].tProgressVirus = CreateTimer(cv_TIME_EFFECTS.FloatValue, Timer_ProgressVirus, client);
}

public Action Timer_ProgressVirus(Handle timer, int client)
{
	delete virus[client].tProgressVirus;
	
	if (!IsClientInGame(client) || !virus[client].bVirus)resetClient(client);
	
	// todo do progress effects, do damage and view effects
	//PrintToConsoleAll("%N Virus effects progress..", client); // debug
	
	#if defined ENGLISH
	CPrintToChat(client, "{green}[SM-CoronaVirus]{lightgreen} dry cough");
	#else
	CPrintToChat(client, "{green}[SM-CoronaVirus]{lightgreen} Tos seca");
	#endif
	
	EmitSoundToAll("sm_coronavirus/cough1.mp3", client);
	
	int health = GetClientHealth(client) - cv_VIRUS_DAMAGE.IntValue;
	if(health <= 0)
	{
		ForcePlayerSuicide(client);
		return;
	}
		
	SetEntityHealth(client, health);
	
	float cal = (GetClientHealth(client) * 1.0) / (GetEntProp(client, Prop_Data, "m_iMaxHealth") * 1.0);
	cal = cal * 255.0;
	cal = cal - 255.0;
	if(cal != 0.0)
		cal *= -1.0;
	
	if(cal > 255.0)
		cal = 255.0;
	else if(cal < 0.0)
		cal = 0.0;
	
	PerformBlind(client, RoundToNearest(cal), cv_TIME_BLIND.FloatValue);
	
	ShareVirus(client, true);
	
	virus[client].tProgressVirus = CreateTimer(cv_TIME_EFFECTS.FloatValue, Timer_ProgressVirus, client);
}

public Action Timer_ShareVirus(Handle timer, int client)
{
	delete virus[client].tShareVirus;
	
	if (!IsClientInGame(client) || !virus[client].bVirus)resetClient(client);
	
	// todo do share virus, with nearby people
	//PrintToConsoleAll("%N Virus effects share..", client); // debug
	
	ShareVirus(client, false);
	
	virus[client].tShareVirus = CreateTimer(cv_TIME_SHARE.FloatValue, Timer_ShareVirus, client);
}

void ShareVirus(int client, bool cough)
{
	float Origin[3], TargetOrigin[3], Distance;
	
	GetClientEyePosition(client, Origin);
	
	for (int X = 1; X <= MaxClients; X++)
	{
		if(IsClientInGame(X) && IsPlayerAlive(X) && !virus[X].bVirus) 
		{
			GetClientEyePosition(X, TargetOrigin);
			Distance = GetVectorDistance(TargetOrigin,Origin);
			if(Distance <= cv_VIRUS_DISTANCE.FloatValue)
			{ 
				if(!cough)
				{
					if(GetRandomInt(1, 100) <= cv_SHARE_CHANCE.FloatValue)
						Infection(X);
				}
				else
				{
					if(GetRandomInt(1, 100) <= cv_SHARE_CHANCE_COUGH.FloatValue)
						Infection(X);
				}
			}
		}
	}
}

void resetClient(int client)
{
	if(virus[client].tBlind != null)
		PerformBlind(client, 0, 0.0);
		
	delete virus[client].tStartVirus;
	delete virus[client].tShareVirus;
	delete virus[client].tProgressVirus;
	delete virus[client].tBlind;
	delete virus[client].tQuarantine;
	virus[client].bVirus = false;
	virus[client].bNoticed = false;
}

void PerformBlind(int target, int amount, float time)
{
	int targets[2];
	targets[0] = target;
	
	int duration = 1536;
	int holdtime = 1536;
	int flags;
	if (amount == 0)
	{
		flags = (0x0001 | 0x0010);
	}
	else
	{
		flags = (0x0002 | 0x0008);
	}
	
	int color[4] = { 0, 0, 0, 0 };
	color[3] = amount;
	
	Handle message = StartMessageEx(g_FadeUserMsgId, targets, 1);
	if (GetUserMessageType() == UM_Protobuf)
	{
		Protobuf pb = UserMessageToProtobuf(message);
		pb.SetInt("duration", duration);
		pb.SetInt("hold_time", holdtime);
		pb.SetInt("flags", flags);
		pb.SetColor("clr", color);
	}
	else
	{
		BfWrite bf = UserMessageToBfWrite(message);
		bf.WriteShort(duration);
		bf.WriteShort(holdtime);
		bf.WriteShort(flags);		
		bf.WriteByte(color[0]);
		bf.WriteByte(color[1]);
		bf.WriteByte(color[2]);
		bf.WriteByte(color[3]);
	}
	
	EndMessage();
	
	if(time > 0.0)
	{
		delete virus[target].tBlind;
		virus[target].tBlind = CreateTimer(time, Timer_NoBlind, target);
	}
}

public Action Timer_NoBlind(Handle timer, int client)
{
	delete virus[client].tBlind;
	
	PerformBlind(client, 0, 0.0);
}

public void Zone_OnClientEntry(int client, const char[] zone)
{
	if(client < 1 || client > MaxClients || !IsClientInGame(client) ||!IsPlayerAlive(client)) 
		return;
		
	if(StrContains(zone, "safezone", false) != 0) return;
	
	#if defined ENGLISH
	CPrintToChat(client, "{green}[SM-CoronaVirus]{lightgreen} You joined a quarantine zone. Stay here during %i seconds if you think that you have coronavirus.", RoundToNearest(cv_TIME_QUARANTINE.FloatValue));
	#else
	CPrintToChat(client, "{green}[SM-CoronaVirus]{lightgreen} Has entrado a una zona de cuarentena. Permanece aquí %i segundos si crees que tienes el coronavirus.", RoundToNearest(cv_TIME_QUARANTINE.FloatValue));
	#endif
	
	
	if (!virus[client].bVirus)return;
	
	delete virus[client].tQuarantine;
	virus[client].tQuarantine = CreateTimer(cv_TIME_QUARANTINE.FloatValue, Timer_Quarantine, client);
	
}

public void Zone_OnClientLeave(int client, const char[] zone)
{
	if(client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client)) 
		return;
		
	if(StrContains(zone, "safezone", false) != 0) return;
	
	
	#if defined ENGLISH
	CPrintToChat(client, "{green}[SM-CoronaVirus]{lightgreen} You left a quarantine zone.");
	#else
	CPrintToChat(client, "{green}[SM-CoronaVirus]{lightgreen} Has salido de una zona de cuarentena.");
	#endif
	
	if (!virus[client].bVirus)return;
	
	
	delete virus[client].tQuarantine;

}

public Action Timer_Quarantine(Handle timer, int client)
{
	delete virus[client].tQuarantine;
	
	#if defined ENGLISH
	CPrintToChat(client, "{green}[SM-CoronaVirus]{lightgreen} You have been quarantined long enough so you are healed!");
	#else
	CPrintToChat(client, "{green}[SM-CoronaVirus]{lightgreen} Has permanecido en cuarentena el tiempo suficiente así que estas curado!");
	#endif
	
	resetClient(client);
}