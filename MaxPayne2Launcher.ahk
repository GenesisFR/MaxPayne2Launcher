#Requires Autohotkey v2.0 ; Display an error and quit if this version requirement is not met.
#SingleInstance force     ; Allow only a single instance of the script to run.
#Warn                     ; Enable warnings to assist with detecting common errors.

; Do not edit this
g_sConfigFile := A_ScriptDir "\MaxPayne2Launcher.ini"

Init()

BuildLaunchArgs()
{
	; Create launch arguments
	if (g_bNoGUI)
	{
		local l_mapArgs := Map(
			"-developer",         g_bDeveloper,
			"-developerkeys",     g_bDeveloperKeys,
			"-disable3dpreloads", g_bDisable3dpreloads,
			"-nodialog",          g_bNodialog,
			"-novidmemcheck",     g_bNovidmemcheck,
			"-profile",           g_bProfile,
			"-screenshot",        g_bScreenshot,
			"-showprogress",      g_bShowprogress,
			"-skipstartup",       g_bSkipstartup,
			"-window",            g_bWindow
		)
	}
	else
	{
		local l_mapArgs := Map(
			"-developer",         g_cbDeveloper.Value,
			"-developerkeys",     g_cbDeveloperKeys.Value,
			"-disable3dpreloads", g_cbDisable3dpreloads.Value,
			"-nodialog",          g_cbNodialog.Value,
			"-novidmemcheck",     g_cbNovidmemcheck.Value,
			"-profile",           g_cbProfile.Value,
			"-screenshot",        g_cbScreenshot.Value,
			"-showprogress",      g_cbShowprogress.Value,
			"-skipstartup",       g_cbSkipstartup.Value,
			"-window",            g_cbWindow.Value
		)
	}

	local l_sLaunchArgs := ""
	for l_sKey, l_sValue in l_mapArgs
	{
		if (l_sValue)
			l_sLaunchArgs .= l_sLaunchArgs ? " " l_sKey : l_sKey
	}

	return l_sLaunchArgs
}

CheckGameExe()
{
	global g_sGameDir

	; Check for game exe in the user-defined directory
	if (!FileExist(g_sGameDir g_sGameExe))
	{
		; Not found, check in the current directory
		if (!FileExist(g_sGameExe))
		{
			MsgBox("File not found:`n`n" g_sGameDir g_sGameExe, "Error", 16)
			return false
		}
		else
			g_sGameDir := A_WorkingDir
	}

	return true
}

CreateGUI()
{
	global

	g_gui := Gui("-MinimizeBox -MaximizeBox", "Max Payne Launcher")
	g_gui.BackColor := "353434"
	g_gui.SetFont("CWhite s10")

	; Layout constants
	local l_nCurrentRow := 0
	local l_nSpacingX := 10
	local l_nSpacingY := 25
	local l_nTopY := 10
	; Leftmost controls
	local l_nLeftWidth := 120
	local l_nLeftX := 15
	; Middle controls
	local l_nMiddleX := l_nLeftX + l_nLeftWidth + l_nSpacingX
	local l_nMiddleWidth := 200
	; Rightmost controls
	local l_nRightX := l_nMiddleX + l_nMiddleWidth + l_nSpacingX
	local l_nRightWidth := 100

	; Game
	g_gui.AddGroupBox("R2.5 x" l_nLeftX - 3 " w" l_nLeftWidth + l_nMiddleWidth + l_nRightWidth + l_nSpacingX * 4, "Game")
	g_gui.AddText("Right x" l_nLeftX " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY " w" l_nLeftWidth, "Choose your game")
	g_radioMP1 := g_gui.AddRadio("Checked" (g_bMaxPayne2 ? "0" : "1") " x" l_nMiddleX " y" l_nTopY + l_nCurrentRow * l_nSpacingY, "Max Payne 1")
	g_radioMP1.OnEvent("Click", GuiRadio_Click)
	g_radioMP2 := g_gui.AddRadio("Checked" g_bMaxPayne2 " x" l_nMiddleX + 100 " y" l_nTopY + l_nCurrentRow * l_nSpacingY, "Max Payne 2")
	g_radioMP2.OnEvent("Click", GuiRadio_Click)

	g_gui.AddText("Right x" l_nLeftX " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY " w" l_nLeftWidth, "Game directory")
	g_editGameDir := g_gui.AddEdit("CBlack R1 ReadOnly x" l_nMiddleX " y" l_nTopY + l_nCurrentRow * l_nSpacingY - 5 " w" l_nMiddleWidth, g_sGameDir)
	g_gui.AddButton("Background353434 Default x" l_nRightX " y" l_nTopY + l_nCurrentRow++ * l_nSpacingY - 7 " w" l_nRightWidth, "&Browse").OnEvent("Click",
	                GuiButtonBrowse_Click)

	; Resolution
	g_gui.AddGroupBox("R2.5 x" l_nLeftX - 3 " y" l_nTopY + l_nSpacingY * ++l_nCurrentRow - 2 " w" l_nLeftWidth + l_nMiddleWidth + l_nRightWidth + l_nSpacingX * 4, "Resolution")
	g_gui.AddText("Right x" l_nLeftX " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY " w" l_nLeftWidth, "Width")
	g_gui.AddEdit("CBlack Number R1 x" l_nMiddleX " y" l_nTopY + l_nCurrentRow * l_nSpacingY - 5 " w" l_nMiddleWidth)
	g_udWidth := g_gui.AddUpDown("Range640-10000 0x80", g_nWidth)

	g_gui.AddText("Right x" l_nLeftX " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY " w" l_nLeftWidth, "Height")
	g_gui.AddEdit("CBlack Number R1 x" l_nMiddleX " y" l_nTopY + l_nCurrentRow++ * l_nSpacingY - 5 " w" l_nMiddleWidth)
	g_udHeight := g_gui.AddUpDown("Range480-10000 0x80", g_nHeight)

	; Launch parameters
	g_gui.AddGroupBox("R12.2 x" l_nLeftX - 3 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY " w" l_nLeftWidth + l_nMiddleWidth + l_nRightWidth + l_nSpacingX * 4,
	                  "Launch parameters")
	g_linkPCGW := g_gui.AddLink("x" l_nLeftX + 15 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY,
	                            'See this <a href="https://www.pcgamingwiki.com/wiki/Max_Payne_2:_The_Fall_of_Max_Payne#Command_line_arguments">link</a> for more details.')
	g_cbDeveloper := g_gui.AddCheckbox("Checked" g_bDeveloper                 " x" l_nLeftX + 15 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY, "-developer")
	g_cbDeveloperKeys := g_gui.AddCheckbox("Checked" g_bDeveloperKeys         " x" l_nLeftX + 15 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY, "-developerkeys")
	g_cbDisable3dpreloads := g_gui.AddCheckbox("Checked" g_bDisable3dpreloads " x" l_nLeftX + 15 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY, "-disable3dpreloads")
	g_cbNodialog := g_gui.AddCheckbox("Checked" g_bNodialog                   " x" l_nLeftX + 15 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY, "-nodialog")
	g_cbNovidmemcheck := g_gui.AddCheckbox("Checked" g_bNovidmemcheck         " x" l_nLeftX + 15 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY, "-novidmemcheck")
	g_cbProfile := g_gui.AddCheckbox("Checked" g_bProfile                     " x" l_nLeftX + 15 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY, "-profile")
	g_cbScreenshot := g_gui.AddCheckbox("Checked" g_bScreenshot               " x" l_nLeftX + 15 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY, "-screenshot")
	g_cbShowprogress:= g_gui.AddCheckbox("Checked" g_bShowprogress            " x" l_nLeftX + 15 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY, "-showprogress")
	g_cbShowprogress.OnEvent("Click", GuiCB_Click)
	g_cbSkipstartup := g_gui.AddCheckbox("Checked" g_bSkipstartup             " x" l_nLeftX + 15 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY, "-skipstartup")
	g_cbWindow := g_gui.AddCheckbox("Checked" g_bWindow                       " x" l_nLeftX + 15 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY, "-window")

	; Extra
	l_nCurrentRow++
	g_gui.AddGroupBox("R2.45 x" l_nLeftX - 3 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY - 5 " w" l_nLeftWidth + l_nMiddleWidth + l_nRightWidth + l_nSpacingX * 4, "Extras")
	g_cbUnlockAllChapters := g_gui.AddCheckbox("x" l_nLeftX + 15 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY - 5, "Unlock all chapters")
	g_cbUnlockAllChapters.OnEvent("Click", GuiCB_Click)
	g_cbUnlockAllDiff := g_gui.AddCheckbox("x" l_nLeftX + 15 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY - 5, "Unlock all difficulties")
	g_cbUnlockAllDiff.OnEvent("Click", GuiCB_Click)

	l_nCurrentRow++

	g_gui.AddGroupBox("R1.5 x" l_nLeftX - 3 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY - 10 " w" l_nLeftWidth + l_nMiddleWidth + l_nRightWidth + l_nSpacingX * 4, "Choose customized game")
	g_ddlCustomGame := g_gui.AddDropDownList("Choose1 x" l_nLeftX + 15 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY - 10 " w" l_nLeftWidth + l_nMiddleWidth + l_nRightWidth + 5, g_arrModFiles)
	g_ddlCustomGame.OnEvent("Change", GuiDDL_Change)
	g_cbNodialog.OnEvent("Click", (*) => g_ddlCustomGame.Enabled := !g_cbNodialog.Value)

	if (g_sModName)
		g_ddlCustomGame.Text := g_sModName

	g_btnStart := g_gui.AddButton("Background353434 Default x195 w" l_nRightWidth, "&Start game")
	g_btnStart.OnEvent("Click", GuiButtonStart_Click)
}

GuiButtonBrowse_Click(*)
{
	global g_bMaxPayne2, g_sGameDir

	; Turn FileSelect into a modal
	g_gui.Opt("+OwnDialogs")

	l_sSelectedFile := FileSelect("3", , "Select the target executable file", "Game executable (MaxPayne.exe; MaxPayne2.exe)")
	SplitPath(l_sSelectedFile, &l_sGameExe, &l_sGameDir)

	if (l_sGameExe ~= "i)\A(maxpayne.exe|maxpayne2.exe)\z")
	{
		g_editGameDir.Value := g_sGameDir := l_sGameDir "\"

		; Change the game
		g_bMaxPayne2 := g_radioMP2.Value := l_sGameExe = "MaxPayne2.exe"
		UpdateGame()

		; Refresh the mod list
		UpdateMods()
		g_ddlCustomGame.Delete()
		g_ddlCustomGame.Add(g_arrModFiles)
		g_ddlCustomGame.Choose(1)
	}
}

GuiButtonStart_Click(*)
{
	if (!g_bNoGUI)
	{
		; Turn MsgBoxes into modals
		g_gui.Opt("+OwnDialogs")
		SaveSettings()
		g_gui.Hide()
	}

	; If the launcher is already running, activate it
	if (WinExist(g_sWinTitle))
		WinActivate(g_sWinTitle)
	; Otherwise run it
	else
	{
		if (!CheckGameExe())
			return

		Run(g_sGameDir g_sGameExe " " BuildLaunchArgs())

		; We give 15 seconds for the launcher to show up
		; If the game launcher always hangs, you should consider using https://community.pcgamingwiki.com/files/file/838-max-payne-series-startup-hang-patch
		if (!WinWaitActive(g_sWinTitle, , 15.0))
			ExitApp()
	}

	; Send the right keystrokes to the game launcher window
	ControlSend("{Down}", "ComboBox1", g_sWinTitle) ; ComboBox1 = Display Adapter DDL
	ControlChooseString(g_sResolution, "ComboBox2", g_sWinTitle) ; ComboBox2 = Screen Mode DDL
	ControlChooseString(g_sModName, "ComboBox4", g_sWinTitle) ; ComboBox4 = Choose Customized Game DDL
	ControlSend("{Enter}", "Button1", g_sWinTitle) ; Button1 = Play button
}

GuiCB_Click(GuiCtrlObj, Info)
{
	global g_bUnlockAllChapters, g_bUnlockAllDiff

	switch GuiCtrlObj
	{
		case g_cbUnlockAllChapters:
			g_bUnlockAllChapters := g_cbUnlockAllChapters.Value
		case g_cbUnlockAllDiff:
			g_bUnlockAllDiff := g_cbUnlockAllDiff.Value
		case g_cbShowprogress:
			if (g_cbShowprogress.Value)
				g_cbDeveloper.Value := true
	}
}

GuiDDL_Change(GuiCtrlObj, Info)
{
	global
	g_sModName := g_ddlCustomGame.Text
}

GuiRadio_Click(GuiCtrlObj, Info)
{
	global

	switch GuiCtrlObj
	{
		; Swap Max Payne and Max Payne 2 in the game directory for convenience
		case g_radioMP1:
			g_bMaxPayne2 := 0
			g_editGameDir.Text := RegExReplace(g_editGameDir.Text, "i)(.*)Max Payne 2\\$", "$1Max Payne\", , 1)
		case g_radioMP2:
			g_bMaxPayne2 := 1
			g_editGameDir.Text := RegExReplace(g_editGameDir.Text, "i)(.*)Max Payne\\$", "$1Max Payne 2\", , 1)
	}

	g_sGameDir := g_editGameDir.Text
	UpdateGame()
	UpdateMods()

	; Refresh the mod list
	g_ddlCustomGame.Delete()
	g_ddlCustomGame.Add(g_arrModFiles)
	g_ddlCustomGame.Choose(1)
}

Init()
{
	ReadConfigFile()
	UpdateMods()
	CreateGUI()
	UpdateGame()

	if (g_bNoGUI)
		GuiButtonStart_Click()
	else
		g_gui.Show()
}

ReadConfigFile()
{
	global

	g_bMaxPayne2 := IniRead(g_sConfigFile,         "General", "bMaxPayne2", true) == true
	g_sGameDir := IniRead(g_sConfigFile,           "General", "sGameDir", "C:\Program Files\Steam\steamapps\common\Max Payne 2\")
	g_nWidth := IniRead(g_sConfigFile,             "General", "nWidth", 2560)
	g_nHeight := IniRead(g_sConfigFile,            "General", "nHeight", 1440)
	g_sModName := IniRead(g_sConfigFile,           "General", "sModName", "")
	g_bUnlockAllChapters := IniRead(g_sConfigFile, "General", "bUnlockAllChapters", false) == true
	g_bUnlockAllDiff := IniRead(g_sConfigFile,     "General", "bUnlockAllDiff", false) == true
	g_bDeveloper := IniRead(g_sConfigFile,         "General", "bDeveloper", false) == true
	g_bDeveloperKeys := IniRead(g_sConfigFile,     "General", "bDeveloperKeys", false) == true
	g_bDisable3dpreloads := IniRead(g_sConfigFile, "General", "bDisable3dpreloads", false) == true
	g_bNodialog := IniRead(g_sConfigFile,          "General", "bNodialog", false) == true
	g_bNovidmemcheck := IniRead(g_sConfigFile,     "General", "bNovidmemcheck", false) == true
	g_bProfile := IniRead(g_sConfigFile,           "General", "bProfile", false) == true
	g_bScreenshot := IniRead(g_sConfigFile,        "General", "bScreenshot", false) == true
	g_bShowprogress := IniRead(g_sConfigFile,      "General", "bShowprogress", false) == true
	g_bSkipstartup := IniRead(g_sConfigFile,       "General", "bSkipstartup", false) == true
	g_bWindow := IniRead(g_sConfigFile,            "General", "bWindow", false) == true
	g_bNoGUI := IniRead(g_sConfigFile,             "General", "bNoGUI", false) == true

	g_sResolution := g_nWidth " x " g_nHeight " x 32"
}

SaveSettings()
{
	try
	{
		if (g_bUnlockAllChapters)
			RegWrite(g_bUnlockAllChapters, "REG_DWORD", g_sGameRegKey "Game Level", "LevelSelector")

		if (g_bUnlockAllDiff)
		{
			RegWrite(g_bUnlockAllDiff, "REG_DWORD", g_sGameRegKey "Game Level", "hell")
			RegWrite(g_bUnlockAllDiff, "REG_DWORD", g_sGameRegKey "Game Level", "nightmare")
			RegWrite(g_bUnlockAllDiff, "REG_DWORD", g_sGameRegKey "Game Level", "timedmode")
		}

		IniWrite(g_radioMP2.Value, g_sConfigFile,            "General", "bMaxPayne2")
		IniWrite(g_sGameDir, g_sConfigFile,                  "General", "sGameDir")
		IniWrite(g_udWidth.Value, g_sConfigFile,             "General", "nWidth")
		IniWrite(g_udHeight.Value, g_sConfigFile,            "General", "nHeight")
		IniWrite(g_sModName, g_sConfigFile,                  "General", "sModName")
		IniWrite(g_cbUnlockAllChapters.Value, g_sConfigFile, "General", "bUnlockAllChapters")
		IniWrite(g_cbUnlockAllDiff.Value, g_sConfigFile,     "General", "bUnlockAllDiff")
		IniWrite(g_cbDeveloper.Value, g_sConfigFile,         "General", "bDeveloper")
		IniWrite(g_cbDeveloperKeys.Value, g_sConfigFile,     "General", "bDeveloperKeys")
		IniWrite(g_cbDisable3dpreloads.Value, g_sConfigFile, "General", "bDisable3dpreloads")
		IniWrite(g_cbNodialog.Value, g_sConfigFile,          "General", "bNodialog")
		IniWrite(g_cbNovidmemcheck.Value, g_sConfigFile,     "General", "bNovidmemcheck")
		IniWrite(g_cbProfile.Value, g_sConfigFile,           "General", "bProfile")
		IniWrite(g_cbScreenshot.Value, g_sConfigFile,        "General", "bScreenshot")
		IniWrite(g_cbShowprogress.Value, g_sConfigFile,      "General", "bShowprogress")
		IniWrite(g_cbSkipstartup.Value, g_sConfigFile,       "General", "bSkipstartup")
		IniWrite(g_cbWindow.Value, g_sConfigFile,            "General", "bWindow")
	}
	catch as e
		MsgBox(Format("{1}: {2}.`n`nFile:`t{3}`nLine:`t{4}`nWhat:`t{5}`nStack:`n{6}", type(e), e.Message, e.File, e.Line, e.What, e.Stack), , 48)
}

UpdateGame()
{
	global

	g_sGameExe := "MaxPayne" (g_bMaxPayne2 ? "2" : "") ".exe"
	g_sGameRegKey := "HKEY_CURRENT_USER\Software\Remedy Entertainment\Max Payne" (g_bMaxPayne2 ? " 2\" : "\")
	g_sWinTitle := "ahk_exe " g_sGameExe " ahk_class #32770"
	g_sLink := g_bMaxPayne2 ? "https://www.pcgamingwiki.com/wiki/Max_Payne_2:_The_Fall_of_Max_Payne#Command_line_arguments"
	                        : "https://www.pcgamingwiki.com/wiki/Max_Payne#Command_line_arguments"
	g_linkPCGW.Text := 'See this <a href="' g_sLink '">link</a> for more details.'
	g_radioMP2.Value := g_bMaxPayne2
	g_radioMP1.Value := !g_radioMP2.Value

	try
	{
		g_cbUnlockAllChapters.Value := RegRead(g_sGameRegKey "Game Level", "LevelSelector", 0)
		g_cbUnlockAllDiff.Value := RegRead(g_sGameRegKey "Game Level", "hell", 0) &&
								RegRead(g_sGameRegKey "Game Level", "nightmare", 0) &&
								RegRead(g_sGameRegKey "Game Level", "timedmode", 0)
	}
}

UpdateMods()
{
	global

	local l_sModExt := g_bMaxPayne2 ? "mp2m" : "mpm"

	; Check for mod file
	if (!g_sModName || (g_sModName != "<none selected>" && !FileExist(g_sGameDir g_sModName "." l_sModExt)))
		g_sModName := "<none selected>"

	; Retrieve all mod names from the game directory
	g_arrModFiles := ["<none selected>"]
	Loop Files, g_sGameDir "*." l_sModExt
	{
		SplitPath(A_LoopFileFullPath, , , , &l_sFileNameNoExt)
		g_arrModFiles.Push(l_sFileNameNoExt)
	}
}
