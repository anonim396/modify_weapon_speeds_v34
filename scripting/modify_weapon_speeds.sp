#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <sdktools_gamerules>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "Modify weapon speeds",
	author = "",
	description = "",
	version = "1.0.0",
	url = ""
};

DHookSetup g_ResetMaxSpeed = null;
Handle g_GetMaxSpeed = null;

public void OnPluginStart()
{
	GameData gameconf = new GameData("maxspeed.gamedata");
	if(gameconf == null)
		SetFailState("Failed to find maxspeed.gamedata.txt");
	
	g_ResetMaxSpeed = DHookCreateFromConf(gameconf, "CCSPlayer::ResetMaxSpeed");
	if(g_ResetMaxSpeed == null)
		SetFailState("Failed to create detour \"CCSPlayer::ResetMaxSpeed\"");

	StartPrepSDKCall(SDKCall_Entity);
	if(!PrepSDKCall_SetFromConf(gameconf, SDKConf_Virtual, "CWeaponCSBase::GetMaxSpeed"))
		SetFailState("Failed to get offset \"CWeaponCSBase::GetMaxSpeed\"");
	PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_ByValue);
	g_GetMaxSpeed = EndPrepSDKCall();
	if(g_GetMaxSpeed == null)
		SetFailState("Error creating SDK Call \"CWeaponCSBase::GetMaxSpeed\"");

	gameconf.Close();

	if(!DHookEnableDetour(g_ResetMaxSpeed, false, Detour_ResetMaxSpeed))
		SetFailState("Error enabling detour \"CCSPlayer::ResetMaxSpeed\"");
}

stock float GetWeaponMaxSpeed(int weapon)
{
	return SDKCall(g_GetMaxSpeed, weapon);
}

public MRESReturn Detour_ResetMaxSpeed(int client)
{
	float speed;
	if(IsClientObserver(client))
	{
		speed = 900.0;
	}
	if(GameRules_GetProp("m_bFreezePeriod", 1))
	{
		speed = 1.0;
	}
	else
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(weapon != -1)
		{
			//speed = GetWeaponMaxSpeed(weapon); //def
			speed = 260.0;
		}
		else
		{
			speed = 260.0; //def 240
		}
	}

	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", speed);
	return MRES_Supercede;
}
