/*
Scanning Best Practices:

For isNotPlaying  : basically a bool - 0 in game and 1 on loading screen / main menu 
*/

state("TheCallistoProtocol-Win64-Shipping", "Steam v1.31320")
{
    int isNotPlaying  : 0x6181D08; 
    string150 mission : 0x05FE53C0, 0x188, 0x78, 0x20, 0x20, 0x30, 0x30, 0x0;
}

state("TheCallistoProtocol-Win64-Shipping", "Steam v1.0.0.0")
{
    int isNotPlaying  : 0x05FE37B0, 0x0, 0x290, 0xD70; 
    string150 mission : 0x061668C8, 0x1C0, 0x30, 0x30, 0x0;
}

init
{
    vars.setStartTime = false;
    vars.isNotPlaying = false;

    switch (modules.First().ModuleMemorySize) 
    {
        case 372211712: 
            version = "Steam v1.31320";
            break;
        case 385458176 : 
            version = "Steam v1.0.0.0";
            break;
    default:
        print("Unknown version detected");
        return false;
    }
}

startup
  {
      vars.TimeOffset = -30.00;

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
    vars.setStartTime = true;
    // This makes sure the timer always starts at 0.00
    timer.IsGameTimePaused = true;
}

gameTime 
{
    if(vars.setStartTime)
    {
      vars.setStartTime = false;
      return TimeSpan.FromSeconds(vars.TimeOffset);
    }
}  

update
{
//DEBUG CODE 
//print(current.isNotPlaying.ToString()); 
print(current.mission.ToString());

        //Use cases for each version of the game listed in the State method
		switch (version) 
	{
		case "Steam v1.31320": case "Steam v1.0.0.0":
			vars.isNotPlaying = current.isNotPlaying == 1;
			break;
	}
}

start
{
    return
    (old.mission.Contains("MainMenu")) && (current.mission.Contains("Outbreak"));
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
    return vars.isNotPlaying;
}

exit
{
	timer.IsGameTimePaused = true;
}