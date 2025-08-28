	state("TheCallistoProtocol-Win64-Shipping") {}

	startup
	{
		Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
		vars.Helper.GameName = "The Callisto Protocol";
		vars.Helper.AlertLoadless();

		#region setting creation
		//Autosplitter Settings Creation
		dynamic[,] _settings =
		{
		{ "Chapter Splits", true, "Chapter Splits", null },
			{ "Outbreak_Persistent",         true, "Outbreak",			"Chapter Splits" },
			{ "Escape_Persistent",           true, "Aftermath",			"Chapter Splits" },
			{ "Habitat_Persistent",          true, "Habitat",			"Chapter Splits" },
			{ "Snowcat_Persistent",          true, "Lost I",			"Chapter Splits" },
			{ "Hangar_Persistent",           true, "Lost II",			"Chapter Splits" },
			{ "Europa_Tunnels_Persistent",   false, "Lost III",			"Chapter Splits" },
			{ "Tunnels_Persistent",          true, "Below",				"Chapter Splits" },
			{ "Minetown_Persistent",         true, "Colony",			"Chapter Splits" },
			{ "Tower1",            			 true, "Tower I",           "Chapter Splits" },
			{ "Europa_Persistent",           true, "Tower II",          "Chapter Splits" },
			{ "Tower3",            			 true, "Tower III",			"Chapter Splits" },
			{ "DLC4_Persistent",             true, "Final Transmission","Chapter Splits" },
		{"GameInfo", 					true, "Print various Game Info to LiveSplit layout",	null},
			{"Mission",                 true, "Current Mission",                                "GameInfo"},
			{"timePause",               false, "Current Loading + Current Pause Status",        "GameInfo"},
			{"camTarget",               false, "Current Camera Target",         				"GameInfo"},
		{"Debug", 					    false, "Print various Game Info to LiveSplit layout",    null},
			{"playerLostControl",       true, "Current playerLostControl",                      "Debug"},
			{"TransitionType",       	true, "Current Transition Type",                      	"Debug"},
			{"playerCameraName",       	true, "Current Player Camera Name",                     "Debug"},
			{"playerCameraActive",      true, "Current Player Camera Active Status",            "Debug"},
			
		};
		vars.Helper.Settings.Create(_settings);
		#endregion

		#region TextComponent
		vars.lcCache = new Dictionary<string, LiveSplit.UI.Components.ILayoutComponent>();
		vars.SetText = (Action<string, object>)((text1, text2) =>
		{
			const string FileName = "LiveSplit.Text.dll";
			LiveSplit.UI.Components.ILayoutComponent lc;

			if (!vars.lcCache.TryGetValue(text1, out lc))
			{
				lc = timer.Layout.LayoutComponents.Reverse().Cast<dynamic>()
					.FirstOrDefault(llc => llc.Path.EndsWith(FileName) && llc.Component.Settings.Text1 == text1)
					?? LiveSplit.UI.Components.ComponentManager.LoadLayoutComponent(FileName, timer);

				vars.lcCache.Add(text1, lc);
			}

			if (!timer.Layout.LayoutComponents.Contains(lc)) timer.Layout.LayoutComponents.Add(lc);
			dynamic tc = lc.Component;
			tc.Settings.Text1 = text1;
			tc.Settings.Text2 = text2.ToString();
		});
		vars.RemoveText = (Action<string>)(text1 =>
		{
			LiveSplit.UI.Components.ILayoutComponent lc;
			if (vars.lcCache.TryGetValue(text1, out lc))
			{
				timer.Layout.LayoutComponents.Remove(lc);
				vars.lcCache.Remove(text1);
			}
		});
		vars.RemoveAllTexts = (Action)(() =>
		{
			foreach (var lc in vars.lcCache.Values) timer.Layout.LayoutComponents.Remove(lc);
			vars.lcCache.Clear();
		});
		#endregion

		vars.CompletedSplits 	 = new HashSet<string>();
		vars.LeftMainMenu    	 = false;
		vars.AutostartPrimed 	 = false;
	}

	init
	{
		IntPtr gWorld = vars.Helper.ScanRel(3, "48 8B 1D ???????? 48 85 DB 74 ?? 41 B0 01");
		IntPtr gEngine = vars.Helper.ScanRel(3, "48 89 05 ???????? 48 85 C9 74 ?? E8 ?? ?? ?? ?? 48 8D 4D");
		IntPtr fNames = vars.Helper.ScanRel(3, "48 8D 0d ???????? E8 ???????? C6 05 ?????????? 0F 10 03");
		IntPtr gSyncLoadCount = vars.Helper.ScanRel(5, "89 43 60 8B 05 ?? ?? ?? ??");
		IntPtr loadBase         = vars.Helper.ScanRel(3, "48 8B ?? ?? ?? ?? ?? 0F 29 ?? ?? ?? F2 ?? ?? ?? 66");
		IntPtr plcBase          = vars.Helper.ScanRel(3, "48 8B ?? ?? ?? ?? ?? 48 85 ?? 75 ?? E8 ?? ?? ?? ?? 48 85 ?? 74 ?? 48 8B ?? 48 83 ?? ?? E9 ?? ?? ?? ?? 33"); 
		//IntPtr pauseStatusBase  = vars.Helper.ScanRel(3, "48 63 ?? ?? ?? ?? ?? 8D ?? ?? 3B ?? ?? ?? ?? ?? 89 ?? ?? ?? ?? ?? 7E ?? 8B ?? 48 8D ?? ?? ?? ?? ?? E8 ?? ?? ?? ?? 48 8B ?? ?? ?? ?? ?? 48 8D ?? ?? 48 8D ?? ?? 48 85 ?? 74 ?? F2");
		
		if (gWorld == IntPtr.Zero || gEngine == IntPtr.Zero)
		{
			const string Msg = "Not all required addresses could be found by scanning.";
			throw new Exception(Msg);
		}

		vars.FNameToString = (Func<ulong, string>)(fName =>
		{
			var nameIdx = (fName & 0x000000000000FFFF) >> 0x00;
			var chunkIdx = (fName & 0x00000000FFFF0000) >> 0x10;
			var number = (fName & 0xFFFFFFFF00000000) >> 0x20;

			// IntPtr chunk = vars.Helper.Read<IntPtr>(fNames + 0x10 + (int)chunkIdx * 0x8);
			IntPtr chunk = vars.Helper.Read<IntPtr>(fNames + 0x10 + (int)chunkIdx * 0x8);
			IntPtr entry = chunk + (int)nameIdx * sizeof(short);

			int length = vars.Helper.Read<short>(entry) >> 6;
			string name = vars.Helper.ReadString(length, ReadStringType.UTF8, entry + sizeof(short));

			return number == 0 ? name : name + "_" + number;
		});

		#region Text Component
		vars.SetTextIfEnabled = (Action<string, object>)((text1, text2) =>
		{
			if (settings[text1]) vars.SetText(text1, text2); 
			else vars.RemoveText(text1);
		});
		#endregion

		vars.Helper["GSync"] = vars.Helper.Make<bool>(gSyncLoadCount); // GSync
		// GWorld.FNameIndex
		vars.Helper["GWorldName"] = vars.Helper.Make<ulong>(gWorld, 0x18);
		// GEngine -> TransitionType (In Pause Menu)
		vars.Helper["TransitionType"] = vars.Helper.Make<int>(gEngine, 0x8C8); 
		//vars.Helper["pauseStatus"]  = vars.Helper.Make<bool>(pauseStatusBase);
		vars.Helper["loading"]      = vars.Helper.Make<int>(loadBase, 0xC4);
		// GEngine -> GameInstance -> LocalPlayers[0](38) -> Dereference(0) -> PlayerController(30) -> bCanBeDamaged //THIS AINT IT BUT IM LOOKIN
		vars.Helper["playerLostControl"]  = vars.Helper.Make<int>(plcBase, 0x138);
		// GEngine -> GameInstance(D48) -> LocalPlayers[0](38) -> Dereference(0) -> PlayerController(30) -> PlayerCameraManager(2B8) -> ViewTarget.Target(320)
		vars.Helper["camTargetName"]  = vars.Helper.Make<ulong>(gEngine, 0xD48, 0x38, 0x0, 0x30, 0x2B8, 0xF90, 0x18);

		

		current.World = "";
		current.camTarget = "";
		current.playerLostControl = 0;
		current.playerCameraName = "Waiting for Player Camera...";
		current.playerCameraActive = false;
		current.loading = 0;
	}

	update
	{
		vars.Helper.Update();
		vars.Helper.MapPointers();

		var World = vars.FNameToString(current.GWorldName);
		if (!string.IsNullOrEmpty(World) && World != "None")
			current.World = World;
		if (old.World != current.World) vars.Log("World: " + old.World + " -> " + current.World);

		var camTarget = vars.FNameToString(current.camTargetName);
		if (!string.IsNullOrEmpty(camTarget) && camTarget != "None")
			current.camTarget = camTarget;
		if (old.camTarget != current.camTarget)
			vars.Log("camTarget: " + old.camTarget + " -> " + current.camTarget);

		if (old.loading == 257 && current.loading == 65537)
			{ current.playerCameraName = "Waiting for Player Camera..."; current.playerCameraActive = false; }
		if (old.loading == 65537 && current.loading == 257)
			{ current.playerCameraName = current.camTarget; }
		if (current.camTarget == current.playerCameraName)
			{ current.playerCameraActive = true; }

		vars.SetTextIfEnabled("Mission",current.World);
		vars.SetTextIfEnabled("camTarget",current.camTarget);
		vars.SetTextIfEnabled("timePause","Loading = " + current.loading + " & " + "Pause Status = " + current.TransitionType);
		vars.SetTextIfEnabled("playerLostControl",current.playerLostControl);
		vars.SetTextIfEnabled("TransitionType",current.TransitionType);
		vars.SetTextIfEnabled("playerCameraActive",current.playerCameraActive);
		vars.SetTextIfEnabled("playerCameraName",current.playerCameraName);
	}

	isLoading
	{
		return current.TransitionType == 1 || current.World == "MainMenu_Persistent" || current.loading == 65537;
	}

	//BP_PhxPlayerController_C - Pawn - (Vector) ReplicatedMovement.Location/Velocity

	start
	{
		if (
				current.playerCameraActive == true && old.playerLostControl == 1 && current.playerLostControl == 0
		   )
		   {return true;}
	}

	/*
	start
	{
		if (old.World == "MainMenu_Persistent" && current.World != "MainMenu_Persistent") { vars.LeftMainMenu = true; }
			
		if (old.playerLostControl == 1 && current.playerLostControl == 0){ vars.AutostartPrimed = true; } 

		if (vars.LeftMainMenu && vars.AutostartPrimed) 
		{
			vars.LeftMainMenu    = false;
			vars.AutostartPrimed = false;
			return true;
		}
	}
	*/

	split
	{
		var World = current.World;

		if (old.World != World)
		{
			if (   (World == "Outbreak_Persistent"       && settings["Outbreak_Persistent"])
				|| (World == "Escape_Persistent"         && settings["Escape_Persistent"])
				|| (World == "Habitat_Persistent"        && settings["Habitat_Persistent"])
				|| (World == "Snowcat_Persistent"        && settings["Snowcat_Persistent"])
				|| (World == "Hangar_Persistent"         && settings["Hangar_Persistent"])
				|| (World == "Europa_Tunnels_Persistent" && settings["Europa_Tunnels_Persistent"])
				|| (World == "Tunnels_Persistent"        && settings["Tunnels_Persistent"])
				|| (World == "Minetown_Persistent"       && settings["Minetown_Persistent"])
				|| (World == "Europa_Persistent"         && settings["Europa_Persistent"])			   // Tower 2
				|| (World == "DLC4_Persistent"           && settings["DLC4_Persistent"])
			   )
			{
				if (!vars.CompletedSplits.Contains(World))
				{
					vars.CompletedSplits.Add(World);
					return true;
				}
			}
		}

		if
		(	   old.World == "Minetown_Persistent" && current.World == "Tower_Persistent" && settings["Tower1"]  /* Colony - Tower 1 */
			|| old.World == "Europa_Persistent"   && current.World == "Tower_Persistent" && settings["Tower3"]	/* Tower 2 - Tower 3 */
		)
		{return true;}
	}

	exit
	{
		timer.IsGameTimePaused = true;
	}

	onReset
	{
		vars.CompletedSplits.Clear();
		vars.LeftMainMenu    = false;
		vars.AutostartPrimed = false;
		current.playerCameraActive = false;
		current.playerCameraName = "";
	}
