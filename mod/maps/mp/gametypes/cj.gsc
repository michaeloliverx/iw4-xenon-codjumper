#include maps\mp\gametypes\_hud_util;
#include maps\mp\_utility;

init()
{
	level thread onPlayerConnect();

	delete_unwanted_entities();

	setDvar("scr_war_timelimit", 0);

	setDvar("g_hardcore", 1);		 // Hardcore HUD
	setDvar("scr_game_forceuav", 0); // Disable compass
	setDvar("ui_drawCrosshair", 0);

	setDvar("player_sprintUnlimited", 1);
	setDvar("jump_slowdownEnable", 0);

	setDvar("bg_fallDamageMaxHeight", 9999);
	setDvar("bg_fallDamageMinHeight", 9998);

	setDvar("testClients_doAttack", 0);
	setDvar("testClients_doCrouch", 0);
	setDvar("testClients_doMove", 0);

	setDvar("g_TeamName_Allies", "Jumpers");
	setDvar("g_TeamName_Axis", "Bots");
}

onPlayerConnect()
{
	for (;;)
	{
		level waittill("connecting", player);

		// Don't setup bots
		if (isDefined(player.pers["isBot"]))
			continue;

		player init_client_dvars();
		player init_player_once();

		player thread onPlayerSpawned();
	}
}

onPlayerSpawned()
{
	self endon("disconnect");

	for (;;)
	{
		self waittill("spawned_player");

		self thread RemoveFields();
		self thread watch_player_buttons();
		self thread watch_player_commands();
		self thread replenish_ammo();
		self thread init_player_loadout();
	}
}

init_player_once()
{
	if (isdefined(self.init_player))
		return;

	self.cj = [];

	self notifyOnPlayerCommand("dpad_up", "+actionslot 1");
	self notifyOnPlayerCommand("dpad_up", "+actionslot 1");
	self notifyOnPlayerCommand("dpad_down", "+actionslot 2");
	self notifyOnPlayerCommand("dpad_right", "+actionslot 4");

	self.init_player = true;
}

init_client_dvars()
{
	self setClientDvar("loc_warnings", 0); // Disable unlocalized text warnings

	self setClientDvar("cg_drawSpectatorMessages", 0);
	self setClientDvar("player_spectateSpeedScale", 1.5);

	self setclientdvar("player_view_pitch_up", 89.9); // Allow looking straight up
	self setClientDvars("fx_enable", 0);			  // Disable FX (RPG smoke etc)

	self setClientDvar("aim_automelee_range", 0); // Remove melee lunge on enemy players
	// Remove aim assist on enemy players
	self setClientDvar("aim_slowdown_enabled", 0);
	self setClientDvar("aim_lockon_enabled", 0);

	// Remove overhead names and ranks on enemy players
	self setClientDvar("cg_overheadNamesSize", 0);
	self setClientDvar("cg_overheadRankSize", 0);
}

init_player_loadout()
{
	// loadout
	self clearPerks();
	self takeAllWeapons();

	self giveWeapon("deserteaglegold_mp");
	self giveWeapon("rpg_mp");
	self SetActionSlot(3, "weapon", "rpg_mp");
	self setPerk("specialty_fastreload");
	self setPerk("specialty_lightweight");
	wait 0.05;
	self switchToWeapon("deserteaglegold_mp");
}

/**
 * Check if a button is pressed.
 */
button_pressed(button)
{
	switch (ToLower(button))
	{
	case "ads":
		return self adsbuttonpressed();
	case "attack":
		return self attackbuttonpressed();
	case "frag":
		return self fragbuttonpressed();
	case "melee":
		return self meleebuttonpressed();
	case "smoke":
		return self secondaryoffhandbuttonpressed();
	case "use":
		return self usebuttonpressed();
	default:
		self iprintln("^1Unknown button " + button);
		return false;
	}
}

/**
 * Check if a button is pressed twice within 500ms.
 */
button_pressed_twice(button)
{
	if (self button_pressed(button))
	{
		// Wait for the button to be released after the first press
		while (self button_pressed(button))
		{
			wait 0.05;
		}

		// Now, wait for a second press within 500ms
		for (elapsed_time = 0; elapsed_time < 0.5; elapsed_time += 0.05)
		{
			if (self button_pressed(button))
			{
				// Ensure it was released before this second press
				return true;
			}

			wait 0.05;
		}
	}
	return false;
}

watch_player_buttons()
{
	self endon("disconnect");
	self endon("death");

	for (;;)
	{
		if (self button_pressed("frag"))
		{
			self thread toggle_ufo();
			wait 0.5;
		}
		if (self button_pressed_twice("melee"))
		{
			self thread save_position(0);
			wait 0.5;
		}
		if (self button_pressed("smoke"))
		{
			self thread load_position(0);
			wait 0.5;
		}
		wait 0.05;
	}
}

watch_player_commands()
{
	self endon("death");
	self endon("disconnect");

	for (;;)
	{
		button = self common_scripts\utility::waittill_any_return("dpad_up", "dpad_down", "dpad_right");

		switch (button)
		{
		case "dpad_up":
			self thread spawn_bot_at_origin();
			break;
		case "dpad_right":
			self toggle_meter_hud();
			break;
		case "frag":
			self toggle_ufo();
			break;
		case "smoke":
			self thread load_position(0);
			break;
		}
	}
}

/**
 * Constantly replace the players ammo.
 */
replenish_ammo()
{
	self endon("disconnect");
	self endon("death");

	for (;;)
	{
		currentWeapon = self getCurrentWeapon(); // undefined if the player is mantling or on a ladder
		if (isdefined(currentWeapon))
			self giveMaxAmmo(currentWeapon);
		wait 1;
	}
}

spawn_bot_at_origin()
{
	origin = self.origin;
	playerAngles = self getPlayerAngles();

	if (!isdefined(self.cj["bot"]))
	{
		bot = addtestclient();
		if (!isdefined(bot))
		{
			self iprintln("Could not add bot");
			wait 1;
			return;
		}

		bot thread TestClient("axis");
		wait 0.10;

		bot giveWeapon("deserteagle_mp");
		wait 0.05;
		bot switchToWeapon("deserteagle_mp");
		bot freezecontrols(true);
		wait 0.05;
		self.cj["bot"] = bot;
	}

	wait 0.5;
	for (i = 3; i > 0; i--)
	{
		self iPrintLn("Bot updates in ^2" + i);
		wait 1;
	}
	self.cj["bot"] setOrigin(origin);
	// Only set the yaw angle
	self.cj["bot"] setPlayerAngles((0, playerAngles[1], 0));
}

TestClient(team)
{
	self endon("disconnect");

	while (!isdefined(self.pers["team"]))
		wait .05;

	self notify("menuresponse", game["menu_team"], team);
	wait 0.5;

	while (1)
	{
		self notify("menuresponse", "changeclass", "class1");
		self waittill("spawned_player");
		wait(0.10);
	}
}

toggle_meter_hud()
{
	if (!isdefined(self.cj["meter_hud"]))
		self.cj["meter_hud"] = [];

	// not defined means OFF
	if (!isdefined(self.cj["meter_hud"]["speed"]))
	{
		self.cj["meter_hud"] = [];
		self thread start_hud_speed();
		self thread start_hud_z_origin();
	}
	else
	{
		self notify("end_hud_speed");
		self notify("end_hud_z_origin");

		self.cj["meter_hud"]["speed"] destroy();
		self.cj["meter_hud"]["z_origin"] destroy();
	}
}

start_hud_speed()
{
	self endon("disconnect");
	self endon("end_hud_speed");

	fontScale = 1.4;
	x = 62;
	y = 22;
	alpha = 0.5;

	self.cj["meter_hud"]["speed"] = createFontString("small", fontScale);
	self.cj["meter_hud"]["speed"] setPoint("BOTTOMRIGHT", "BOTTOMRIGHT", x, y);
	self.cj["meter_hud"]["speed"].alpha = alpha;
	self.cj["meter_hud"]["speed"].label = &"speed:&&1";

	for (;;)
	{
		velocity3D = self getVelocity();
		horizontalSpeed2D = int(sqrt(velocity3D[0] * velocity3D[0] + velocity3D[1] * velocity3D[1]));
		self.cj["meter_hud"]["speed"] setValue(horizontalSpeed2D);

		wait 0.05;
	}
}

start_hud_z_origin()
{
	self endon("disconnect");
	self endon("end_hud_z_origin");

	fontScale = 1.4;
	x = 62;
	y = 36;

	self.cj["meter_hud"]["z_origin"] = createFontString("small", fontScale);
	self.cj["meter_hud"]["z_origin"] setPoint("BOTTOMRIGHT", "BOTTOMRIGHT", x, y);
	self.cj["meter_hud"]["z_origin"].alpha = 0.5;
	self.cj["meter_hud"]["z_origin"].label = &"z:&&1";

	for (;;)
	{
		self.cj["meter_hud"]["z_origin"] setValue(self.origin[2]);

		wait 0.05;
	}
}

toggle_ufo()
{
	if (self.sessionstate == "playing")
	{
		self allowSpectateTeam("freelook", true);
		self.sessionstate = "spectator";
	}
	else
	{
		self allowSpectateTeam("freelook", false);
		self.sessionstate = "playing";
	}
}

save_position(i)
{
	if (!self isonground())
		return;

	save = spawnstruct();
	save.origin = self.origin;
	save.angles = self getplayerangles();

	self.cj["saves"][i] = save;
}

load_position(i)
{
	self freezecontrols(true);
	wait 0.05;

	save = self.cj["saves"][i];

	self setplayerangles(save.angles);
	self setorigin(save.origin);

	wait 0.05;
	self freezecontrols(false);
}

delete_unwanted_entities()
{
	ents = getentarray();

	for (i = 0; i < ents.size; i++)
	{
		dodelete = false;

		if (isdefined(ents[i].targetname))
		{
			if (ents[i].targetname == "sab_bomb" || ents[i].targetname == "sd_bomb")
				dodelete = true;
		}

		if (dodelete)
			ents[i] delete ();
	}
}

RemoveFields()
{
    if(!isdefined(level.FieldsRemoved))
    {
        level.FieldsRemoved = false;
    }
    if(level.FieldsRemoved == true)
    {
        return;
    }
    level.FieldsRemoved = true;
    minefields = getentarray("minefield", "targetname");
    radiationFields = getentarray("radiation", "targetname");
    for (i = 0; i < minefields.size; i++) 
    {
        if (minefields[i])
        {
	        self iPrintln("^3Removed " + minefields.size + " Minefields Fields");
	        minefields[i] delete();
	        wait .1;

        }
    }

    for (i = 0; i < radiationFields.size; i++) 
    {
        if (radiationFields[i])
        {
	        self iPrintln("^3Removed " + radiationFields.size + " Radiation Fields");
	        radiationFields[i] delete();
	        wait .1;

        }
    }
}
