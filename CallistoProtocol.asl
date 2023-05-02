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

state("TheCallistoProtocol-Win64-Shipping", "Steam v1.3.0.0")
{
    int loading       : 0x062649F8, 0xC4; 
    int pauseStatus   : 0x6265A08;
    string150 mission : 0x061A4A30, 0xC58, 0x0, 0x30, 0x0;
}

state("TheCallistoProtocol-Win64-Shipping", "Steam v1.8.0.0")
{
    int loading       : 0x062ADF28, 0xC4; 
    int pauseStatus   : 0x62B1F38;
    string150 mission : 0x06056DE0, 0x188, 0x78, 0x20, 0x20, 0x30, 0x30, 0x0;
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
        case 366084096 : 
            version = "Steam v1.3.0.0";
            break;
        case 374734848 : 
            version = "Steam v1.8.0.0";
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
//print(current.pauseStatus.ToString()); 
//print(current.mission.ToString());
//print(modules.First().ModuleMemorySize.ToString());
}

start
{
    // Run starts when leaving the first loadscreen
    
    if (current.mission == null) 
    {return false;}

    if
    (
        //works on fresh boot of game when pointer has not been initialized yet
        (old.mission == null && current.mission == "/Game/Maps/Game/Outbreak/Outbreak_Persistent") || 
        (old.mission == null && current.mission == "/Game/Maps/Game/Europa/Europa_ColdOpen_Persistent") ||

        //works after pointer is initialized by loading a map
        (old.mission == "/Game/Maps/Game/MainMenu/MainMenu_Persistent" && current.mission == "/Game/Maps/Game/Outbreak/Outbreak_Persistent") || 
        (old.mission == "/Game/Maps/Game/MainMenu/MainMenu_Persistent" && current.mission == "/Game/Maps/Game/Europa/Europa_ColdOpen_Persistent")
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
    old.mission == "/Game/Maps/Game/Outbreak/Outbreak_Persistent" && current.mission == "/Game/Maps/Game/Escape/Escape_Persistent" || /* Outbreak - Aftermath */
    old.mission == "/Game/Maps/Game/Escape/Escape_Persistent" && current.mission == "/Game/Maps/Game/Habitat/Habitat_Persistent" || /* Aftermath - Habitat */
    old.mission == "/Game/Maps/Game/Habitat/Habitat_Persistent" && current.mission == "/Game/Maps/Game/Snowcat/Snowcat_Persistent" || /* Habitat - Lost 1 */
    old.mission == "/Game/Maps/Game/Snowcat/Snowcat_Persistent" && current.mission == "/Game/Maps/Game/Hangar/Hangar_Persistent" || /* Lost 1 - Lost 2 */
    old.mission == "/Game/Maps/Game/Europa/Europa_Tunnels_Persistent" && current.mission == "/Game/Maps/Game/Tunnels/Tunnels_Persistent" || /* Technically Lost 3 - Below. Speedrunners dont make a split for Lost 3 tho cause its short */
    old.mission == "/Game/Maps/Game/Tunnels/Tunnels_Persistent" && current.mission == "/Game/Maps/Game/Minetown/Minetown_Persistent" || /* Below - Colony */
    old.mission == "/Game/Maps/Game/Minetown/Minetown_Persistent" && current.mission == "/Game/Maps/Game/Tower/Tower_Persistent" || /* Colony - Tower 1 */
    old.mission == "/Game/Maps/Game/Tower/Tower_Persistent" && current.mission == "/Game/Maps/Game/Europa/Europa_Persistent" || /* Tower 1 - Tower 2 */
    old.mission == "/Game/Maps/Game/Europa/Europa_Persistent" && current.mission == "/Game/Maps/Game/Tower/Tower_Persistent"; /* Tower 2 - Tower 3 */
}	

isLoading
{
    return current.loading == 65537 || current.pauseStatus == 1 || current.mission == "/Game/Maps/Game/MainMenu/MainMenu_Persistent";
}
exit
{
	timer.IsGameTimePaused = true;
}
