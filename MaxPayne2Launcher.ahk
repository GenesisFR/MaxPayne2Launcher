#Requires AutoHotkey v2
#SingleInstance Force

g_sWinTitle := "ahk_exe MaxPayne2.exe ahk_class #32770"
g_sGameDir := "F:\SteamLibrary\steamapps\common\Max Payne 2\"
g_sGameExe := "MaxPayne2.exe"
g_sGameBaseRegKey := "HKEY_CURRENT_USER\Software\Remedy Entertainment\Max Payne 2\"
g_nResolution := "2560 x 1440 x 32" ; width x height x 32
g_sModName := "Hostages" ; without the .mp2m extension
g_bUnlockAllDiff := false
g_bUnlockAllChapters := false
g_bNoGUI := false ; skip GUI creation and run the game with the values above

; Check for game exe in the current directory
if (!FileExist("MaxPayne2.exe"))
{
	; Not found, check in the user-defined directory
	A_WorkingDir := g_sGameDir
	if (!FileExist("MaxPayne2.exe"))
	{
		MsgBox("File not found:`n`n" g_sGameDir g_sGameExe, "Error", 16)
		ExitApp()
	}
}

; Retrieve current resolution from the registry
if (!g_bNoGUI)
{
	try
	{
		g_nResolution := RegRead(g_sGameBaseRegKey "Video Settings", "Display Width", "") " x "
		g_nResolution .= RegRead(g_sGameBaseRegKey "Video Settings", "Display Height", "") " x 32"
	}

	; Not found, force 1440p
	if (!g_nResolution)
		g_nResolution := "2560 x 1440 x 32"
}

; Retrieve current mod name from the registry
if (!g_bNoGUI)
	try g_sModName := RegRead(g_sGameBaseRegKey "Customized Game", "Customized Game", "")

; Check for mod file
if (!g_sModName)
	g_sModName := "<none selected>"
else if (g_sModName && g_sModName != "<none selected>" && !FileExist(g_sModName ".mp2m"))
{
	OutputDebug("Mod not found: " g_sGameDir g_sModName ".mp2m`n")
	g_sModName := "<none selected>"
}

if (g_bNoGUI)
	GuiStartButton_Click()
else
{
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
		g_cbUnlockAllChapters.Value .= RegRead(g_sGameBaseRegKey "Game Level", "LevelSelector", 0)
		g_cbUnlockAllDiff.Value := RegRead(g_sGameBaseRegKey "Game Level", "hell", 0) &&
		                           RegRead(g_sGameBaseRegKey "Game Level", "nightmare", 0) &&
		                           RegRead(g_sGameBaseRegKey "Game Level", "timedmode", 0)
	}
	g_gui.AddButton("Default x85", "&Start game").OnEvent("Click", GuiStartButton_Click)
	g_gui.Show()
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
	try
	{
		RegWrite(g_bUnlockAllChapters, "REG_DWORD", g_sGameBaseRegKey "Game Level", "LevelSelector")
		RegWrite(g_bUnlockAllDiff, "REG_DWORD", g_sGameBaseRegKey "Game Level", "hell")
		RegWrite(g_bUnlockAllDiff, "REG_DWORD", g_sGameBaseRegKey "Game Level", "nightmare")
		RegWrite(g_bUnlockAllDiff, "REG_DWORD", g_sGameBaseRegKey "Game Level", "timedmode")
	}
	catch as e
		MsgBox(Format("{1}: {2}.`n`nFile:`t{3}`nLine:`t{4}`nWhat:`t{5}`nStack:`n{6}", type(e), e.Message, e.File, e.Line, e.What, e.Stack), , 48)

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