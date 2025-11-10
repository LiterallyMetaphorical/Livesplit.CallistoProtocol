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
		{ "Debug", false, "Debug", null },
			{ "Placeholder",                 true, "Placeholder",			     "Debug" },
			{ "World",                       true, "World",			             "Debug" },
			{ "MovementMode",                false, "MovementMode",			     "Debug" },
			{ "TransitionType",              false, "TransitionType",			 "Debug" },
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
		#endregion

		vars.CompletedSplits 	 = new HashSet<string>();
	}

	init
	{
		IntPtr gWorld = vars.Helper.ScanRel(3, "48 8B 1D ???????? 48 85 DB 74 ?? 41 B0 01");
		IntPtr gEngine = vars.Helper.ScanRel(3, "48 89 05 ???????? 48 85 C9 74 ?? E8 ?? ?? ?? ?? 48 8D 4D");
		IntPtr fNamePool = vars.Helper.ScanRel(3, "48 8D 0d ???????? E8 ???????? C6 05 ?????????? 0F 10 03");
		 
		// GWorld.FNameIndex(18)
		vars.Helper["GWorldName"] = vars.Helper.Make<ulong>(gWorld, 0x18);
		// GEngine -> TransitionType (In Pause Menu)
		vars.Helper["TransitionType"] = vars.Helper.Make<int>(gEngine, 0x8C8); 
		// GWorld - StreaminglevelsToConsider[ArrayNum](A0)
    	vars.Helper["SLCArrayNum"] = vars.Helper.Make<int>(gWorld, 0xA0);
		// GWorld - StreaminglevelsToConsider[ArrayNum](A4)
    	vars.Helper["SLCArrayMax"] = vars.Helper.Make<int>(gWorld, 0xA4);
		// GEngine -> GameInstance(D48) -> LocalPlayers[0](38) -> Dereference(0) - PlayerController(30) - Character(260) - CharacterMovement(288) - MovementMode(168)
		vars.Helper["MovementMode"] = vars.Helper.Make<byte>(gEngine, 0xD48, 0x38, 0x0, 0x30, 0x260, 0x288, 0x168);
		// GEngine -> GameInstance(D48) -> LocalPlayers[0](38) -> Dereference(0) - PlayerController(30) - CameraRig(688) - CameraActor(270) - Name(18)
		vars.Helper["CameraActorName"] = vars.Helper.Make<ulong>(gEngine, 0xD48, 0x38, 0x0, 0x30, 0x688, 0x270, 0x18);


		//vars.Helper["checkpointName"] = vars.Helper.Make<ulong>(PhxProgressManager, 0x440, 0x298);
		// ??? -> PhxProgressManager(???) -> CurrentCheckpoint (440) -> CheckpointId maybe? (298 - FName)
		// GameEngine - PhxGameInstance - UISystem - ProgressPromptDefaultClass or ToolTipWidgetClass
		// GameEngine - PhxGameInstance - PlayerCharacter(680) - InventoryComp(6D8) or StateMachineComp or HealthComp or bDead or bInvulnerable (try to force to always true!) or EnterCombatSound/ExitCombatSound

		vars.FNameToString = (Func<ulong, string>)(fName =>
		{
			var nameIdx = (fName & 0x000000000000FFFF) >> 0x00;
			var chunkIdx = (fName & 0x00000000FFFF0000) >> 0x10;
			var number = (fName & 0xFFFFFFFF00000000) >> 0x20;

			// IntPtr chunk = vars.Helper.Read<IntPtr>(fNamePool + 0x10 + (int)chunkIdx * 0x8);
			IntPtr chunk = vars.Helper.Read<IntPtr>(fNamePool + 0x10 + (int)chunkIdx * 0x8);
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

		current.World = "";
		current.Placeholder = "";
		current.TransitionType = 0;
		current.MovementMode = 0;
		current.SLCArrayNum = 999;
		current.SLCArrayMax = 999;
		current.checkpointID = "";
	}

	update
	{
		vars.Helper.Update();
		vars.Helper.MapPointers();

		var Placeholder = vars.FNameToString(current.CameraActorName);
		if (!string.IsNullOrEmpty(Placeholder) && Placeholder != "None")
			current.Placeholder = Placeholder;

		var World = vars.FNameToString(current.GWorldName);
		if (!string.IsNullOrEmpty(World) && World != "None")
			current.World = World;

		#region Debug Prints
		if (settings["Debug"])
			{
				if (old.Placeholder != current.Placeholder) 
				{
				vars.Log("Placeholder: " + old.Placeholder + " -> " + current.Placeholder); 
				vars.SetTextIfEnabled("Placeholder",current.Placeholder);
				}
				if (old.World != current.World) {vars.Log("World: " + old.World + " -> " + current.World); vars.SetTextIfEnabled("World",current.World);}
				if (old.TransitionType != current.TransitionType) {vars.Log("TransitionType: " + old.TransitionType + " -> " + current.TransitionType); vars.SetTextIfEnabled("TransitionType",current.TransitionType);}
				if (old.MovementMode != current.MovementMode) {vars.Log("MovementMode: " + old.MovementMode + " -> " + current.MovementMode); vars.SetTextIfEnabled("MovementMode",current.MovementMode);}
			}
		#endregion

		//vars.Log("World: " + current.World);
	}

	isLoading
	{
		return current.TransitionType == 1 || current.World == "LevelTransitions" || current.World == "MainMenu_Persistent" || current.MovementMode == 3 || current.SLCArrayNum != 0 || current.SLCArrayMax == 0;
	}

	start
	{
		return old.MovementMode == 6 && current.MovementMode == 1;
	}

	onStart
	{
		vars.CompletedSplits.Clear();
	}

	split
	{
		var World = current.World;

		if (old.World != World)
		{
			if 
			(
				(World == "Escape_Persistent"         && settings["Escape_Persistent"])
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
	}
