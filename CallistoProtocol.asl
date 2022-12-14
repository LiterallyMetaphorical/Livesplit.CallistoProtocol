/*
Scanning Best Practices:

isLoading options
search for 257 in game, 65537 while loading, and then 257 in game again (in a different level)

last pointer offset is 0xC4
pointer should be around 06 region of memory


For mission

use the pinned message in #resource-dev to search for the associated loaded mission. I suggest using Habitat/Outbreak/Tower as they are named the same in game and memory (easier)

when address is found, search for a pointer with last offsets of 0x0. Final pointer should be in the 06 region.
*/

state("TheCallistoProtocol-Win64-Shipping", "Steam v1.31320")
{
    int loading       : 0x6181D08; 
    string150 mission : 0x05FE53C0, 0x188, 0x78, 0x20, 0x20, 0x30, 0x30, 0x0;
}

state("TheCallistoProtocol-Win64-Shipping", "Steam v1.0.0.0")
{
    int loading       : 0x0623E698, 0xC4; 
    string150 mission : 0x061668C8, 0x1C0, 0x30, 0x30, 0x0;
}

state("TheCallistoProtocol-Win64-Shipping", "Steam v1.1.0.0")
{
    int loading       : 0x0623E6D8, 0xC4; 
    string150 mission : 0x0612B628, 0x20, 0x30, 0x30, 0x0;
}

state("TheCallistoProtocol-Win64-Shipping", "Steam v1.2.0.0")
{
    int loading       : 0x06241798, 0xC4; 
    byte pauseStatus  : 0x06181BB0, 0x8C8;
    string150 mission : 0x06181BB0, 0xC58, 0x0, 0x30, 0x0;
}

init
{
switch (modules.First().ModuleMemorySize) 
    {
        case 372211712: 
            version = "Steam v1.31320";
            break;
        case 385458176 : 
            version = "Steam v1.0.0.0";
            break;
        case 382361600 : 
            version = "Steam v1.1.0.0";
            break;
        case 366514176 : 
            version = "Steam v1.2.0.0";
            break;

    default:
        print("Unknown version detected");
        return false;
    }
}

startup
  {
    // Timing offset and flag
    settings.Add("removeIntroTime", true, "Start timer at -30.00s. Enable this for No Intro runs");
    vars.startTimeOffsetFlag = false;
    vars.startTimeOffset = -30.00;

		if (timer.CurrentTimingMethod == TimingMethod.RealTime)
// Asks user to change to game time if LiveSplit is currently set to Real Time.
    {        
        var timingMessage = MessageBox.Show (
            "This game uses Time without Loads (Game Time) as the main timing method.\n"+
            "LiveSplit is currently set to show Real Time (RTA).\n"+
            "Would you like to set the timing method to Game Time?",
            "LiveSplit | The Callisto Protocol",
            MessageBoxButtons.YesNo,MessageBoxIcon.Question
        );

        if (timingMessage == DialogResult.Yes)
        {
            timer.CurrentTimingMethod = TimingMethod.GameTime;
        }
    }
}

onStart
{
    // This makes sure the timer always starts at 0.00
    timer.IsGameTimePaused = true;
}

gameTime
{
    if(settings["removeIntroTime"] && vars.startTimeOffsetFlag) 
    {
        vars.startTimeOffsetFlag = false;
        return TimeSpan.FromSeconds(vars.startTimeOffset);
    }
}

update
{
//DEBUG CODE 
//print(current.loading.ToString()); 
//print(current.mission.ToString());

        //Use cases for each version of the game listed in the State method
		switch (version) 
	{
		case "Steam v1.31320": case "Steam v1.0.0.0": case "Steam v1.1.0.0":
			break;
	}
}

start
{
    // Run starts when leaving the first loadscreen
    
    if (current.mission == null) 
    {return false;}

    if
    (
        //works on fresh boot of game when pointer has not been initialized yet
        (old.mission == null && (current.mission.Contains("Outbreak"))) || 
        (old.mission == null && (current.mission.Contains("Europa_ColdOpen_Persistent"))) ||

        //works after pointer is initialized by loading a map
        ((old.mission.Contains("MainMenu")) && (current.mission.Contains("Outbreak"))) || 
        ((old.mission.Contains("MainMenu")) && (current.mission.Contains("Europa_ColdOpen_Persistent")))
    )  
    {
        // custom timing
        if (settings["removeIntroTime"]) vars.startTimeOffsetFlag = true;
        return true;
    }

    return false;
}

split 
{ 	
    return
    (old.mission.Contains("Outbreak")) && (current.mission.Contains("Escape")) ||
    (old.mission.Contains("Escape")) && (current.mission.Contains("Habitat")) ||
    (old.mission.Contains("Habitat")) && (current.mission.Contains("Snowcat")) ||
    (old.mission.Contains("Snowcat")) && (current.mission.Contains("Hangar")) ||
    (old.mission.Contains("Hangar")) && (current.mission.Contains("Tunnels")) ||
    (old.mission.Contains("Tunnels")) && (current.mission.Contains("Minetown")) ||
    (old.mission.Contains("Minetown")) && (current.mission.Contains("Tower")) ||
    (old.mission.Contains("Tower")) && (current.mission.Contains("Europa")) ||
    (old.mission.Contains("Europa")) && (current.mission.Contains("Tower"));
}	

isLoading
{
    return current.loading == 65537 || current.pauseStatus == 1 || current.mission.Contains("MainMenu");
}
exit
{
	timer.IsGameTimePaused = true;
}
