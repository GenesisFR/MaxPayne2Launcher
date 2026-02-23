#Requires AutoHotkey v2
#SingleInstance Force

; Do not edit these
g_sConfigFile := A_ScriptDir "\MaxPayne2Launcher.ini"
g_sGameExe := "MaxPayne2.exe"
g_sGameRegKey := "HKEY_CURRENT_USER\Software\Remedy Entertainment\Max Payne 2\"
g_sWinTitle := "ahk_exe MaxPayne2.exe ahk_class #32770"

ReadConfigFile()
CheckGameExe()
GetResolutionFromRegistry()
CheckMods()

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

	; Resolution
	g_gui.AddText("Right x10 y10 w50", "Width")
	g_gui.AddEdit("Number r1 x70 y5 w150")
	g_udWidth := g_gui.AddUpDown("Range640-10000 0x80", g_nWidth)
	g_gui.AddText("Right x10 y35 w50", "Height")
	g_gui.AddEdit("Number r1 x70 y30 w150")
	g_udHeight := g_gui.AddUpDown("Range480-10000 0x80", g_nHeight)


	; Only display the mod DDL if mods were found
	if (g_arrModFiles.Length > 1)
	{
		g_gui.AddText("Right x10 y60 w50", "Mod")
		g_ddlModName := g_gui.AddDropDownList("Choose1 x70 y55", g_arrModFiles)
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

	g_gui.AddLink(, 'Launch parameters (see this <a href="https://www.pcgamingwiki.com/wiki/Max_Payne_2:_The_Fall_of_Max_Payne#Command_line_arguments">link</a> for details)')
	g_cbDeveloper := g_gui.AddCheckbox("x10", "-developer")
	g_cbDeveloperKeys := g_gui.AddCheckbox("x10", "-developerkeys")
	g_cbDisable3dpreloads := g_gui.AddCheckbox("x10", "-disable3dpreloads")
	g_cbNodialog := g_gui.AddCheckbox("x10", "-nodialog")
	g_cbNodialog.OnEvent("Click", (*) => g_ddlModName.Enabled := !g_cbNodialog.Value)
	g_cbNovidmemcheck := g_gui.AddCheckbox("x10", "-novidmemcheck")
	g_cbProfile := g_gui.AddCheckbox("x10", "-profile")
	g_cbScreenshot := g_gui.AddCheckbox("x10", "-screenshot")
	g_cbShowprogress:= g_gui.AddCheckbox("x10", "-showprogress")
	g_cbShowprogress.OnEvent("Click", (*) => g_cbDeveloper.Value := true)
	g_cbSkipstartup := g_gui.AddCheckbox("x10", "-skipstartup")
	g_cbWindow := g_gui.AddCheckbox("x10", "-window")

	g_gui.AddButton("Default x85", "&Start game").OnEvent("Click", GuiStartButton_Click)
}

CheckMods()
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

	; Retrieve all mod names from the game directory
	g_arrModFiles := ["<none selected>"]
	Loop Files, g_sGameDir "\*.mp2m"
	{
		SplitPath(A_LoopFileFullPath, , , , &l_sFileNameNoExt)
		g_arrModFiles.Push(l_sFileNameNoExt)
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
			g_nWidth := RegRead(g_sGameRegKey "Video Settings", "Display Width", "")
			g_nHeight := RegRead(g_sGameRegKey "Video Settings", "Display Height", "")
		}

		; Still not found, force 1440p
		if (!g_sResolution)
		{
			g_nWidth := 2560
			g_nHeight := 1440
		}

		g_sResolution := g_nWidth " x " g_nHeight " x 32"
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
	global

	WriteSettingsToRegistryAndConfig()

	if (!g_bNoGUI)
		g_gui.Hide()

	if (WinExist(g_sWinTitle))
		WinActivate(g_sWinTitle)
	else
	{
		local l_sLaunchArgs := ""
		
		if (g_bNoGUI)
		{
			l_sLaunchArgs .= g_bDeveloper ? "-developer" : ""
			l_sLaunchArgs .= " " (g_bDeveloperKeys ? "-developerkeys" : "")
			l_sLaunchArgs .= " " (g_bDisable3dpreloads ? "-disable3dpreloads" : "")
			l_sLaunchArgs .= " " (g_bNodialog ? "-nodialog" : "")
			l_sLaunchArgs .= " " (g_bNovidmemcheck ? "-novidmemcheck" : "")
			l_sLaunchArgs .= " " (g_bProfile ? "-profile" : "")
			l_sLaunchArgs .= " " (g_bScreenshot ? "-screenshot" : "")
			l_sLaunchArgs .= " " (g_bShowprogress ? "-showprogress" : "")
			l_sLaunchArgs .= " " (g_bSkipstartup ? "-skipstartup" : "")
			l_sLaunchArgs .= " " (g_bWindow ? "-window" : "")
		}
		else
		{
			l_sLaunchArgs .= g_cbDeveloper.Value ? g_cbDeveloper.Text : ""
			l_sLaunchArgs .= " " (g_cbDeveloperKeys.Value ? g_cbDeveloperKeys.Text : "")
			l_sLaunchArgs .= " " (g_cbDisable3dpreloads.Value ? g_cbDisable3dpreloads.Text : "")
			l_sLaunchArgs .= " " (g_cbNodialog.Value ? g_cbNodialog.Text : "")
			l_sLaunchArgs .= " " (g_cbNovidmemcheck.Value ? g_cbNovidmemcheck.Text : "")
			l_sLaunchArgs .= " " (g_cbProfile.Value ? g_cbProfile.Text : "")
			l_sLaunchArgs .= " " (g_cbScreenshot.Value ? g_cbScreenshot.Text : "")
			l_sLaunchArgs .= " " (g_cbShowprogress.Value ? g_cbShowprogress.Text : "")
			l_sLaunchArgs .= " " (g_cbSkipstartup.Value ? g_cbSkipstartup.Text : "")
			l_sLaunchArgs .= " " (g_cbWindow.Value ? g_cbWindow.Text : "")
		}

		Run(g_sGameExe " " l_sLaunchArgs)
	}

	; We give 15 seconds for the launcher to show up
	; If the game launcher always hangs, you should consider using https://community.pcgamingwiki.com/files/file/838-max-payne-series-startup-hang-patch
	if (!WinWaitActive(g_sWinTitle, , 15.0))
		ExitApp()

	; Send the right keystrokes to the game launcher window
	ControlSend("{Down}", "ComboBox1", g_sWinTitle) ; ComboBox1 = Display Adapter DDL
	ControlChooseString(g_sResolution, "ComboBox2", g_sWinTitle) ; ComboBox2 = Screen Mode DDL
	ControlChooseString(g_sModName, "ComboBox4", g_sWinTitle) ; ComboBox4 = Choose Customized Game DDL
	ControlSend("{Enter}", "Button1", g_sWinTitle) ; Button1 = Play button
}

ReadConfigFile()
{
	global

	try
	{
		g_sGameDir := IniRead(g_sConfigFile, "General", "sGameDir", "C:\Program Files\Steam\steamapps\common\Max Payne 2\")
		g_nWidth := IniRead(g_sConfigFile, "General", "nWidth", 2560)
		g_nHeight := IniRead(g_sConfigFile, "General", "nHeight", 1440)
		g_sResolution := g_nWidth " x " g_nHeight " x 32"
		g_sModName := IniRead(g_sConfigFile, "General", "sModName", "")
		g_bUnlockAllDiff := IniRead(g_sConfigFile, "General", "bUnlockAllDiff", 0)
		g_bUnlockAllChapters := IniRead(g_sConfigFile, "bUnlockAllChapters", "sGameDir", 0)
		g_bDeveloper := IniRead(g_sConfigFile, "General", "bDeveloper", 0)
		g_bDeveloperKeys := IniRead(g_sConfigFile, "General", "bDeveloperKeys", 0)
		g_bDisable3dpreloads := IniRead(g_sConfigFile, "General", "bDisable3dpreloads", 0)
		g_bNodialog := IniRead(g_sConfigFile, "General", "bNodialog", 0)
		g_bNovidmemcheck := IniRead(g_sConfigFile, "General", "bNovidmemcheck", 0)
		g_bProfile := IniRead(g_sConfigFile, "General", "bProfile", 0)
		g_bScreenshot := IniRead(g_sConfigFile, "General", "bScreenshot", 0)
		g_bShowprogress := IniRead(g_sConfigFile, "General", "bShowprogress", 0)
		g_bSkipstartup := IniRead(g_sConfigFile, "General", "bSkipstartup", 0)
		g_bWindow := IniRead(g_sConfigFile, "General", "bWindow", 0)
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
			IniWrite(g_udWidth.Value, g_sConfigFile, "General", "nWidth")
			IniWrite(g_udHeight.Value, g_sConfigFile, "General", "nHeight")
			IniWrite("`"" g_sModName "`"", g_sConfigFile, "General", "sModName")
			IniWrite(g_cbUnlockAllDiff.Value, g_sConfigFile, "General", "bUnlockAllDiff")
			IniWrite(g_cbUnlockAllChapters.Value, g_sConfigFile, "General", "bUnlockAllChapters")
			IniWrite(g_cbDeveloper.Value, g_sConfigFile, "General", "bDeveloper")
			IniWrite(g_cbDeveloperKeys.Value, g_sConfigFile, "General", "bDeveloperKeys")
			IniWrite(g_cbDisable3dpreloads.Value, g_sConfigFile, "General", "bDisable3dpreloads")
			IniWrite(g_cbNodialog.Value, g_sConfigFile, "General", "bNodialog")
			IniWrite(g_cbNovidmemcheck.Value, g_sConfigFile, "General", "bNovidmemcheck")
			IniWrite(g_cbProfile.Value, g_sConfigFile, "General", "bProfile")
			IniWrite(g_cbScreenshot.Value, g_sConfigFile, "General", "bScreenshot")
			IniWrite(g_cbShowprogress.Value, g_sConfigFile, "General", "bShowprogress")
			IniWrite(g_cbSkipstartup.Value, g_sConfigFile, "General", "bSkipstartup")
			IniWrite(g_cbWindow.Value, g_sConfigFile, "General", "bWindow")
		}
	}
	catch as e
		MsgBox(Format("{1}: {2}.`n`nFile:`t{3}`nLine:`t{4}`nWhat:`t{5}`nStack:`n{6}", type(e), e.Message, e.File, e.Line, e.What, e.Stack), , 48)
}
