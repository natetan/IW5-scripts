/*
	Modified Nuke Effects - IW5 / Plutonium

	Based on Resxt's script for disabling all MOAB/nuke effects:
	https://github.com/Resxt/Plutonium-IW5-Scripts/blob/main/disable_nuke_effects/disable_nuke_effects_all.gsc

	This version overrides the original behavior to remove the EMP effect
	while disabling the other unwanted effects. Removing the EMP would
	effectively nerf the MOAB, and the goal here is not to change its power
	level.
*/

#include maps\mp\killstreaks\_nuke;

main()
{
	replacefunc(maps\mp\killstreaks\_nuke::nukeVision, ::disableNukeVision); 
	replacefunc(maps\mp\killstreaks\_nuke::nukeSlowMo, ::disableNukeSlowMo);
	replacefunc(maps\mp\killstreaks\_nuke::nukeEffects, ::disableNukeEffects);

  // Intentionally do not replace nuke_EMPJam; the MOAB should retain its EMP.
}

disableNukeVision()
{

}

disableNukeSlowMo()
{

}

disableNukeEffects()
{
	level endon( "nuke_cancelled" );
	setdvar( "ui_bomb_timer", 0 );
}
