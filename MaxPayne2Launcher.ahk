#Requires AutoHotkey v2
#SingleInstance Force

; TODO
; add more options (see https://steamcommunity.com/sharedfiles/filedetails/?id=2022465230)
; split resolution into width and height to limit user errors

; Do not edit these
g_sConfigFile := A_ScriptDir "\MaxPayne2Launcher.ini"
g_sGameExe := "MaxPayne2.exe"
g_sGameRegKey := "HKEY_CURRENT_USER\Software\Remedy Entertainment\Max Payne 2\"
g_sWinTitle := "ahk_exe MaxPayne2.exe ahk_class #32770"

ReadConfigFile()
CheckGameExe()
GetResolutionFromRegistry()
CheckMod()

if (g_bNoGUI)
	GuiStartButton_Click()
else
{
	CreateGUI()
	g_gui.Show()
}

CheckGameExe()
{
	; Check for game exe in the user-defined directory
	if (!FileExist(g_sGameDir g_sGameExe))
	{
		; Not found, check in the current directory
		if (!FileExist("MaxPayne2.exe"))
		{
			MsgBox("File not found:`n`n" g_sGameDir g_sGameExe, "Error", 16)
			ExitApp()
		}
	}

	A_WorkingDir := g_sGameDir
}

CreateGUI()
{
	global

	g_gui := Gui("-MinimizeBox -MaximizeBox", "Max Payne 2 Launcher")
	g_gui.SetFont("s10")
	g_gui.AddText(, "Resolution")
	g_editResolution := g_gui.AddEdit("r1 x90 y5 w150", g_nResolution)

	; Retrieve all mod names from the game directory
	g_arrModFiles := ["<none selected>"]
	Loop Files, g_sGameDir "\*.mp2m"
	{
		SplitPath(A_LoopFileFullPath, , , , &l_sFileNameNoExt)
		g_arrModFiles.Push(l_sFileNameNoExt)
	}

	; Only display the mod DDL if mods were found
	if (g_arrModFiles.Length > 1)
	{
		g_gui.AddText("x50", "Mod")
		g_ddlModName := g_gui.AddDropDownList("Choose1 x90 y33", g_arrModFiles)
		g_ddlModName.OnEvent("Change", GuiDDLMod_Change)

		if (g_sModName)
			g_ddlModName.Text := g_sModName

		g_sModName := g_ddlModName.Text
	}

	g_cbUnlockAllChapters := g_gui.AddCheckbox("x10", "Unlock all chapters")
	g_cbUnlockAllChapters.OnEvent("Click", GuiCB_Click)
	g_cbUnlockAllDiff := g_gui.AddCheckbox("x10", "Unlock all difficulties")
	g_cbUnlockAllDiff.OnEvent("Click", GuiCB_Click)

	try
	{
		g_cbUnlockAllChapters.Value .= RegRead(g_sGameRegKey "Game Level", "LevelSelector", 0)
		g_cbUnlockAllDiff.Value := RegRead(g_sGameRegKey "Game Level", "hell", 0) &&
		                           RegRead(g_sGameRegKey "Game Level", "nightmare", 0) &&
		                           RegRead(g_sGameRegKey "Game Level", "timedmode", 0)
	}

	g_gui.AddButton("Default x85", "&Start game").OnEvent("Click", GuiStartButton_Click)
}

CheckMod()
{
	global

	; Retrieve current mod name from the registry
	if (!g_bNoGUI && !FileExist(g_sConfigFile))
		try g_sModName := RegRead(g_sGameRegKey "Customized Game", "Customized Game", "")

	; Check for mod file
	if (!g_sModName)
		g_sModName := "<none selected>"
	else if (g_sModName && g_sModName != "<none selected>" && !FileExist(g_sModName ".mp2m"))
	{
		MsgBox("Mod not found:`n`n" g_sGameDir g_sModName ".mp2m", "Warning", 48)
		g_sModName := "<none selected>"
	}
}

GetResolutionFromRegistry()
{
	global

	; Retrieve current resolution from the registry if the config file is missing
	if (!g_bNoGUI && !FileExist(g_sConfigFile))
	{
		try
		{
			g_nResolution := RegRead(g_sGameRegKey "Video Settings", "Display Width", "") " x "
			g_nResolution .= RegRead(g_sGameRegKey "Video Settings", "Display Height", "") " x 32"
		}

		; Still not found, force 1440p
		if (!g_nResolution)
			g_nResolution := "2560 x 1440 x 32"
	}
}

GuiCB_Click(GuiCtrlObj, Info)
{
	global

	switch GuiCtrlObj
	{
		case g_cbUnlockAllChapters:
			g_bUnlockAllChapters := g_cbUnlockAllChapters.Value
		case g_cbUnlockAllDiff:
			g_bUnlockAllDiff := g_cbUnlockAllDiff.Value
	}
}

GuiDDLMod_Change(*)
{
	global g_sModName := g_ddlModName.Text
}

GuiStartButton_Click(*)
{
	WriteSettingsToRegistryAndConfig()

	if (!g_bNoGUI)
		g_gui.Hide()

	if (WinExist(g_sWinTitle))
		WinActivate(g_sWinTitle)
	else
		Run(g_sGameExe)

	; We give 15 seconds for the launcher to show up
	; If the game launcher always hangs, you should consider using https://community.pcgamingwiki.com/files/file/838-max-payne-series-startup-hang-patch
	if (!WinWaitActive(g_sWinTitle, , 15.0))
		ExitApp()

	; Send the right keystrokes to the game launcher window
	ControlSend("{Down}", "ComboBox1", g_sWinTitle) ; ComboBox1 = Display Adapter DDL
	ControlChooseString(g_nResolution, "ComboBox2", g_sWinTitle) ; ComboBox2 = Screen Mode DDL
	ControlChooseString(g_sModName, "ComboBox4", g_sWinTitle) ; ComboBox4 = Choose Customized Game DDL
	ControlSend("{Enter}", "Button1", g_sWinTitle) ; Button1 = Play button
}

ReadConfigFile()
{
	global

	try
	{
		g_sGameDir := IniRead(g_sConfigFile, "General", "sGameDir", "C:\Program Files\Steam\steamapps\common\Max Payne 2\")
		local l_nWidth := IniRead(g_sConfigFile, "General", "nWidth", 2560)
		local l_nHeight := IniRead(g_sConfigFile, "General", "nHeight", 1440)
		g_nResolution := l_nWidth " x " l_nHeight " x 32"
		g_sModName := IniRead(g_sConfigFile, "General", "sModName", "")
		g_bUnlockAllDiff := IniRead(g_sConfigFile, "General", "bUnlockAllDiff", 1)
		g_bUnlockAllChapters := IniRead(g_sConfigFile, "bUnlockAllChapters", "sGameDir", 1)
		g_bNoGUI := IniRead(g_sConfigFile, "General", "bNoGUI", 0)
	}
}

WriteSettingsToRegistryAndConfig()
{
	try
	{
		RegWrite(g_bUnlockAllChapters, "REG_DWORD", g_sGameRegKey "Game Level", "LevelSelector")
		RegWrite(g_bUnlockAllDiff, "REG_DWORD", g_sGameRegKey "Game Level", "hell")
		RegWrite(g_bUnlockAllDiff, "REG_DWORD", g_sGameRegKey "Game Level", "nightmare")
		RegWrite(g_bUnlockAllDiff, "REG_DWORD", g_sGameRegKey "Game Level", "timedmode")

		if (!g_bNoGUI)
		{
			local l_arrResolutionParts := StrSplit(g_nResolution, " x ")

			if (!g_bNoGUI && l_arrResolutionParts.Length > 1)
			{
				IniWrite(l_arrResolutionParts[1], g_sConfigFile, "General", "nWidth")
				IniWrite(l_arrResolutionParts[2], g_sConfigFile, "General", "nHeight")
			}

			IniWrite("`"" g_sModName "`"", g_sConfigFile, "General", "sModName")
			IniWrite(g_cbUnlockAllDiff.Value, g_sConfigFile, "General", "bUnlockAllDiff")
			IniWrite(g_cbUnlockAllChapters.Value, g_sConfigFile, "General", "bUnlockAllChapters")
		}
	}
	catch as e
		MsgBox(Format("{1}: {2}.`n`nFile:`t{3}`nLine:`t{4}`nWhat:`t{5}`nStack:`n{6}", type(e), e.Message, e.File, e.Line, e.What, e.Stack), , 48)
}
