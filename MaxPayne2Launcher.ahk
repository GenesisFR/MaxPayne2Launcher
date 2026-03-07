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
			return false
		else
			g_sGameDir := g_editGameDir.Text := A_WorkingDir "\"
	}

	return true
}

CreateGUI()
{
	global

	g_gui := Gui("-MinimizeBox -MaximizeBox", "Max Payne Launcher")
	g_gui.BackColor := "1F1F1F"
	g_gui.SetFont("CWhite s10")

	; Layout constants
	local l_nCurrentRow := 0
	local l_nSpacingX := 10
	local l_nSpacingY := 25
	local l_nTopY := 35
	; Leftmost controls
	local l_nLeftWidth := 120
	local l_nLeftX := 35
	; Middle controls
	local l_nMiddleX := l_nLeftX + l_nLeftWidth + l_nSpacingX
	local l_nMiddleWidth := 200
	; Rightmost controls
	local l_nRightX := l_nMiddleX + l_nMiddleWidth + l_nSpacingX
	local l_nRightWidth := 100

	g_tab := g_gui.AddTab3(, !FileExist(g_sWidescreenFixConfigFile) ? ["General"] : ["General", "Widescreen"])

	; Game
	g_gui.AddGroupBox("R2.5 x" l_nLeftX - 4 " y" l_nTopY " w" l_nLeftWidth + l_nMiddleWidth + l_nRightWidth + l_nSpacingX * 4, "Game")
	g_gui.AddText("Right x" l_nLeftX " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY " w" l_nLeftWidth, "Choose your game")
	g_radioMP1 := g_gui.AddRadio("Checked" (g_bMaxPayne2 ? "0" : "1") " x" l_nMiddleX " y" l_nTopY + l_nCurrentRow * l_nSpacingY, "Max Payne")
	g_radioMP2 := g_gui.AddRadio("Checked" g_bMaxPayne2 " x" l_nMiddleX + 100 " y" l_nTopY + l_nCurrentRow * l_nSpacingY, "Max Payne 2")
	g_gui.AddButton("Background1F1F1F Default x" l_nRightX " y" l_nTopY + l_nCurrentRow++ * l_nSpacingY - 7 " w" l_nRightWidth, "&Browse").OnEvent("Click",
	                GuiButtonBrowse_Click)

	g_gui.AddText("Right x" l_nLeftX " y" l_nTopY + l_nCurrentRow * l_nSpacingY + 5 " w" l_nLeftWidth, "Game directory")
	g_editGameDir := g_gui.AddEdit("CBlack R1 ReadOnly x" l_nMiddleX " y" l_nTopY + l_nCurrentRow++ * l_nSpacingY " w" l_nMiddleWidth + l_nRightWidth + l_nSpacingX - 2,
	                               g_sGameDir)

	; Resolution
	g_gui.AddGroupBox("R2.5 x" l_nLeftX - 4 " y" l_nTopY + l_nSpacingY * ++l_nCurrentRow - 2
	                  " w" l_nLeftWidth + l_nMiddleWidth + l_nRightWidth + l_nSpacingX * 4, "Resolution")
	g_gui.AddText("Right x" l_nLeftX " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY " w" l_nLeftWidth, "Width")
	g_gui.AddEdit("CBlack Number R1 x" l_nMiddleX " y" l_nTopY + l_nCurrentRow * l_nSpacingY - 5 " w" l_nMiddleWidth)
	g_udWidth := g_gui.AddUpDown("Range640-10000 0x80", g_nWidth)

	g_gui.AddText("Right x" l_nLeftX " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY " w" l_nLeftWidth, "Height")
	g_gui.AddEdit("CBlack Number R1 x" l_nMiddleX " y" l_nTopY + l_nCurrentRow++ * l_nSpacingY - 5 " w" l_nMiddleWidth)
	g_udHeight := g_gui.AddUpDown("Range480-10000 0x80", g_nHeight)

	; Launch parameters
	g_gui.AddGroupBox("R12.2 x" l_nLeftX - 4 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY " w" l_nLeftWidth + l_nMiddleWidth + l_nRightWidth + l_nSpacingX * 4,
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
	g_cbSkipstartup := g_gui.AddCheckbox("Checked" g_bSkipstartup             " x" l_nLeftX + 15 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY, "-skipstartup")
	g_cbWindow := g_gui.AddCheckbox("Checked" g_bWindow                       " x" l_nLeftX + 15 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY, "-window")

	; Extra
	l_nCurrentRow++
	g_gui.AddGroupBox("R2.45 x" l_nLeftX - 4 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY - 5 " w" l_nLeftWidth + l_nMiddleWidth + l_nRightWidth + l_nSpacingX * 4, "Extras")
	g_cbUnlockAllChapters := g_gui.AddCheckbox("x" l_nLeftX + 15 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY - 5, "Unlock all chapters")
	g_cbUnlockAllDiff := g_gui.AddCheckbox("x" l_nLeftX + 15 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY - 5, "Unlock all difficulties")

	l_nCurrentRow++
	g_tab.UseTab(0)
	
	; Customized game
	g_gui.AddGroupBox("R1.5 x" l_nLeftX - 4 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY - 10 " w" l_nLeftWidth + l_nMiddleWidth + l_nRightWidth + l_nSpacingX * 4,
	                  "Choose customized game")
	g_ddlCustomGame := g_gui.AddDropDownList("Choose1 x" l_nLeftX + 15 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY - 10 " w" l_nLeftWidth + l_nMiddleWidth + l_nRightWidth + 5)

	g_btnStart := g_gui.AddButton("Background1F1F1F Default x210 w" l_nRightWidth, "&Start game")

	; Widescreen fix settings
	if (FileExist(g_sWidescreenFixConfigFile))
	{
		l_nCurrentRow := 0
		l_nMiddleX += 40

		g_tab.UseTab(2)
		g_gui.AddGroupBox("R11.5 x" l_nLeftX - 4 " y" l_nTopY " w" l_nLeftWidth + l_nMiddleWidth + l_nRightWidth + l_nSpacingX * 4, "Widescreen fix")

		g_cbAllowAltTabbingWithoutPausing := g_gui.AddCheckbox("Checked" g_bAllowAltTabbingWithoutPausing " x" l_nLeftX + 15 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY,
		                                                       "Allow alt tabbing without pausing")
		g_cbCutsceneBorders := g_gui.AddCheckbox("Checked" g_bCutsceneBorders - 1 " x" l_nLeftX + 15 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY, "Cutscene borders")
		g_cbD3DHookBorders := g_gui.AddCheckbox("Checked" g_bD3DHookBorders " x" l_nLeftX + 15 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY, "D3D hook borders")
		g_gui.AddText("vSliderFOVFactorLeft", "FOV factor")
		g_editFOVFactor := g_gui.AddEdit("vSliderFOVFactorRight CBlack R1 ReadOnly w" 50, g_fFOVFactor)
		g_sliderFOVFactor := g_gui.AddSlider("AltSubmit Buddy1SliderFOVFactorLeft Buddy2SliderFOVFactorRight NoTicks Range1-20 x" l_nMiddleX
		                                     " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY - 2 " w" l_nMiddleWidth + 15, g_fFOVFactor * 10)
		g_cbGraphicNovelMode := g_gui.AddCheckbox("Checked" g_bGraphicNovelMode " x" l_nLeftX + 15 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY, "Graphic novel mode")
		g_gui.AddText("Right x" l_nLeftX + 10 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY + 5 " w" l_nLeftWidth + 40, "Graphic novel mode key")
		g_editGraphicNovelModeKey := g_gui.AddEdit("CBlack R1 x" l_nMiddleX + 10 " y" l_nTopY + l_nCurrentRow * l_nSpacingY " w" l_nMiddleWidth, g_sGraphicNovelModeKey)
		g_gui.AddText("Right x" l_nLeftX + 10 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY + 5 " w" l_nLeftWidth + 40, "Load save slot")
		g_ddlLoadSaveSlot := g_gui.AddDropDownList("Choose" Abs(g_nLoadSaveSlot) " x" l_nMiddleX + 10 " y" l_nTopY + l_nCurrentRow * l_nSpacingY
	                                               " w" l_nMiddleWidth, ["Disable", "Load last used", "Load most recent"])
		l_nTopY += 5
		g_cbUseGameFolderForSavegames := g_gui.AddCheckbox("Checked" g_bUseGameFolderForSavegames " x" l_nLeftX + 15 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY,
		                                                   "Use game folder for savegames")
		g_cbWidescreenHud := g_gui.AddCheckbox("Checked" g_bWidescreenHud " x" l_nLeftX + 15 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY, "Widescreen HUD")
		g_gui.AddText("vSliderWidescreenHudOffsetLeft", "Widescreen HUD offset")
		g_editWidescreenHudOffset := g_gui.AddEdit("vSliderWidescreenHudOffsetRight CBlack R1 ReadOnly w" 50, g_fWidescreenHudOffset)
		g_sliderWidescreenHudOffset := g_gui.AddSlider("AltSubmit Buddy1SliderWidescreenHudOffsetLeft Buddy2SliderWidescreenHudOffsetRight NoTicks Range10-200 x"
		                                               l_nMiddleX " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY " w" l_nMiddleWidth + 15, g_fWidescreenHudOffset)

		; Events
		g_sliderFOVFactor.OnEvent("Change", (*) => g_editFOVFactor.Text := Round(g_sliderFOVFactor.Value / 10.0, 1))
		g_sliderWidescreenHudOffset.OnEvent("Change", (*) => g_editWidescreenHudOffset.Text := Float(g_sliderWidescreenHudOffset.Value))

		; Xbox rain droplets settings
		if (FileExist(g_sXboxRainDropletsConfigFile))
		{
			l_nCurrentRow++
			g_gui.AddGroupBox("R8.5 x" l_nLeftX - 4 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY - 5 " w" l_nLeftWidth + l_nMiddleWidth + l_nRightWidth + l_nSpacingX * 4,
			                  "Xbox rain droplets")

			g_cbEnableGravity := g_gui.AddCheckbox("Checked" g_bEnableGravity " x" l_nLeftX + 15 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY, "Enable gravity")

			g_gui.AddText("vSliderMinSizeLeft", "Mininum size")
			g_editMinSize := g_gui.AddEdit("vSliderMinSizeRight CBlack R1 ReadOnly w" 50, g_nMinSize)
			g_sliderMinSize := g_gui.AddSlider("AltSubmit Buddy1SliderMinSizeLeft Buddy2SliderMinSizeRight NoTicks Range1-9 x" l_nMiddleX
			                                   " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY " w" l_nMiddleWidth + 15, g_nMinSize)

			g_gui.AddText("vSliderMaxDropsLeft", "Maximum drops")
			g_editMaxDrops := g_gui.AddEdit("vSliderMaxDropsRight CBlack R1 ReadOnly w" 50, g_nMaxDrops)
			g_sliderMaxDrops := g_gui.AddSlider("AltSubmit Buddy1SliderMaxDropsLeft Buddy2SliderMaxDropsRight NoTicks Range1000-10000 x" l_nMiddleX
			                                    " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY " w" l_nMiddleWidth + 15, g_nMaxDrops)

			g_gui.AddText("vSliderMaxMovingDropsLeft", "Maximum moving drops")
			g_editMaxMovingDrops := g_gui.AddEdit("vSliderMaxMovingDropsRight CBlack R1 ReadOnly w" 50, g_nMaxMovingDrops)
			g_sliderMaxMovingDrops := g_gui.AddSlider("AltSubmit Buddy1SliderMaxMovingDropsLeft Buddy2SliderMaxMovingDropsRight NoTicks Range1000-10000 x" l_nMiddleX
			                                          " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY " w" l_nMiddleWidth + 15, g_nMaxMovingDrops)

			g_gui.AddText("vSliderMaxSizeLeft", "Maximum size")
			g_editMaxSize := g_gui.AddEdit("vSliderMaxSizeRight CBlack R1 ReadOnly w" 50, g_nMaxSize)
			g_sliderMaxSize := g_gui.AddSlider("AltSubmit Buddy1SliderMaxSizeLeft Buddy2SliderMaxSizeRight NoTicks Range10-30 x" l_nMiddleX
			                                   " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY " w" l_nMiddleWidth + 15, g_nMaxSize)

			g_gui.AddText("vSliderMoveStepLeft", "Move step")
			g_editMoveStep := g_gui.AddEdit("vSliderMoveStepRight CBlack R1 ReadOnly w" 50, g_fMoveStep)
			g_sliderMoveStep := g_gui.AddSlider("AltSubmit Buddy1SliderMoveStepLeft Buddy2SliderMoveStepRight NoTicks Range1-20 x" l_nMiddleX
			                                    " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY " w" l_nMiddleWidth + 15, g_fMoveStep * 10)

			g_gui.AddText("vSliderSpeedAdjusterLeft", "Speed adjuster")
			g_editSpeedAdjuster := g_gui.AddEdit("vSliderSpeedAdjusterRight CBlack R1 ReadOnly w" 50, g_fSpeedAdjuster)
			g_sliderSpeedAdjuster := g_gui.AddSlider("AltSubmit Buddy1SliderSpeedAdjusterLeft Buddy2SliderSpeedAdjusterRight NoTicks Range1-20 x" l_nMiddleX
			                                         " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY " w" l_nMiddleWidth + 15, g_fSpeedAdjuster * 10)

			; Events
			g_sliderMinSize.OnEvent("Change", (*) => g_editMinSize.Text := g_sliderMinSize.Value)
			g_sliderMaxSize.OnEvent("Change", (*) => g_editMaxSize.Text := g_sliderMaxSize.Value)
			g_sliderMaxDrops.OnEvent("Change", (*) => g_editMaxDrops.Text := g_sliderMaxDrops.Value)
			g_sliderMaxMovingDrops.OnEvent("Change", (*) => g_editMaxMovingDrops.Text := g_sliderMaxMovingDrops.Value)
			g_sliderMoveStep.OnEvent("Change", (*) => g_editMoveStep.Text := Round(g_sliderMoveStep.Value / 10.0, 1))
			g_sliderSpeedAdjuster.OnEvent("Change", (*) => g_editSpeedAdjuster.Text := Round(g_sliderSpeedAdjuster.Value / 10.0, 1))
		}
	}

	; Events
	g_radioMP1.OnEvent(           "Click", GuiRadio_Click)
	g_radioMP2.OnEvent(           "Click", GuiRadio_Click)
	g_cbDeveloper.OnEvent(        "Click", GuiCB_Click)
	g_cbDeveloperKeys.OnEvent(    "Click", GuiCB_Click)
	g_cbNodialog.OnEvent(         "Click", GuiCB_Click)
	g_cbShowprogress.OnEvent(     "Click", GuiCB_Click)
	g_cbUnlockAllChapters.OnEvent("Click", GuiCB_Click)
	g_cbUnlockAllDiff.OnEvent(    "Click", GuiCB_Click)
	g_ddlCustomGame.OnEvent(     "Change", GuiDDL_Change)
	g_btnStart.OnEvent(           "Click", GuiButtonStart_Click)
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
		g_sGameDir := g_editGameDir.Text := l_sGameDir "\"

		; Change the game
		g_bMaxPayne2 := g_radioMP2.Value := l_sGameExe = "MaxPayne2.exe"
		UpdateGame()

		; Refresh the mod list
		UpdateMods()
	}
}

GuiButtonStart_Click(*)
{
	if (!g_bNoGUI)
	{
		; Turn MsgBoxes into modals
		g_gui.Opt("+OwnDialogs")
		g_gui.Hide()
	}

	SaveSettings()
	SaveWidescreenFixSettings()
	SaveXboxRainDropletsSettings()

	; If the launcher is already running, activate it
	if (WinExist(g_sWinTitle))
		WinActivate(g_sWinTitle)
	; Otherwise run it
	else
	{
		if (!CheckGameExe())
		{
			MsgBox("File not found:`n`n" g_sGameDir g_sGameExe, "Error", 16)
			return
		}

		Run(g_sGameDir g_sGameExe " " BuildLaunchArgs())

		; We give 15 seconds for the launcher to show up
		; If the game launcher always hangs, you should consider using https://community.pcgamingwiki.com/files/file/838-max-payne-series-startup-hang-patch
		if (!WinWaitActive(g_sWinTitle, , 15.0))
			ExitApp()
	}

	; Send the right keystrokes to the game launcher window
	ControlSend("{End}", "ComboBox1", g_sWinTitle) ; ComboBox1 = Display Adapter DDL
	ControlChooseString(g_sResolution, "ComboBox2", g_sWinTitle) ; ComboBox2 = Screen Mode DDL
	ControlChooseString(g_sModName, "ComboBox4", g_sWinTitle) ; ComboBox4 = Choose Customized Game DDL
	ControlSend("{Enter}", "Button1", g_sWinTitle) ; Button1 = Play button
}

GuiCB_Click(GuiCtrlObj, Info)
{
	global g_bUnlockAllChapters, g_bUnlockAllDiff

	; Turn MsgBox into a modal
	g_gui.Opt("+OwnDialogs")

	switch GuiCtrlObj
	{
		case g_cbDeveloper:
			if (!g_cbDeveloper.Value)
				g_cbDeveloperKeys.Value := g_cbShowprogress.Value := false
		case g_cbDeveloperKeys:
			if (g_cbDeveloperKeys.Value)
				g_cbDeveloper.Value := true
		case g_cbNodialog:
			if (g_cbNodialog.Value)
				MsgBox("Using -nodialog will prevent the game from loading mods!", "Warning", 48) 
		case g_cbShowprogress:
			if (g_cbShowprogress.Value)
				g_cbDeveloper.Value := true
		case g_cbUnlockAllChapters:
			g_bUnlockAllChapters := g_cbUnlockAllChapters.Value
		case g_cbUnlockAllDiff:
			g_bUnlockAllDiff := g_cbUnlockAllDiff.Value
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
		; Swap Max Payne and Max Payne 2 in the game directory path for convenience
		case g_radioMP1:
			g_bMaxPayne2 := 0
			g_editGameDir.Text := RegExReplace(g_editGameDir.Text, "i)(.*)Max Payne 2\\$", "$1Max Payne\", , 1)
		case g_radioMP2:
			g_bMaxPayne2 := 1
			g_editGameDir.Text := RegExReplace(g_editGameDir.Text, "i)(.*)Max Payne\\$", "$1Max Payne 2\", , 1)
	}

	; Change the game
	g_sGameDir := g_editGameDir.Text
	UpdateGame()

	; Refresh the mod list
	UpdateMods()
}

Init()
{
	ReadConfigFile()
	ReadWidescreenFixConfigFile()
	ReadXboxRainDropletsConfigFile()

	CreateGUI()
	UpdateGame()
	CheckGameExe()
	UpdateMods()

	if (g_bNoGUI)
		GuiButtonStart_Click()
	else
		g_gui.Show()
}

ReadConfigFile()
{
	global

	g_bMaxPayne2         := IniRead(g_sConfigFile, "General", "bMaxPayne2", true) == true
	g_sGameDir           := IniRead(g_sConfigFile, "General", "sGameDir", "C:\Program Files\Steam\steamapps\common\Max Payne 2\")
	g_nWidth             := IniRead(g_sConfigFile, "General", "nWidth", 2560)
	g_nHeight            := IniRead(g_sConfigFile, "General", "nHeight", 1440)
	g_sModName           := IniRead(g_sConfigFile, "General", "sModName", "")
	g_bUnlockAllChapters := IniRead(g_sConfigFile, "General", "bUnlockAllChapters", false) == true
	g_bUnlockAllDiff     := IniRead(g_sConfigFile, "General", "bUnlockAllDiff", false) == true
	g_bDeveloper         := IniRead(g_sConfigFile, "General", "bDeveloper", false) == true
	g_bDeveloperKeys     := IniRead(g_sConfigFile, "General", "bDeveloperKeys", false) == true
	g_bDisable3dpreloads := IniRead(g_sConfigFile, "General", "bDisable3dpreloads", false) == true
	g_bNodialog          := IniRead(g_sConfigFile, "General", "bNodialog", false) == true
	g_bNovidmemcheck     := IniRead(g_sConfigFile, "General", "bNovidmemcheck", false) == true
	g_bProfile           := IniRead(g_sConfigFile, "General", "bProfile", false) == true
	g_bScreenshot        := IniRead(g_sConfigFile, "General", "bScreenshot", false) == true
	g_bShowprogress      := IniRead(g_sConfigFile, "General", "bShowprogress", false) == true
	g_bSkipstartup       := IniRead(g_sConfigFile, "General", "bSkipstartup", false) == true
	g_bWindow            := IniRead(g_sConfigFile, "General", "bWindow", false) == true
	g_bNoGUI             := IniRead(g_sConfigFile, "General", "bNoGUI", false) == true

	g_sResolution := g_nWidth " x " g_nHeight " x 32"
}

ReadWidescreenFixConfigFile()
{
	global
	g_sWidescreenFixConfigFile := g_sGameDir "scripts\MaxPayne" (g_bMaxPayne2 ? "2" : "") ".WidescreenFix.ini"

	if (!g_bNoGUI && FileExist(g_sWidescreenFixConfigFile))
	{
		; The widescreen fix INI includes unorthodox // comments so we need to preserve and trim them
		g_arrWidescreenHud                 := StrSplit(IniRead(g_sWidescreenFixConfigFile, "MAIN", "WidescreenHud", true), "//", 2)
		g_arrWidescreenHudOffset           := StrSplit(IniRead(g_sWidescreenFixConfigFile, "MAIN", "WidescreenHudOffset", 100.0), "//", 2)
		g_arrFOVFactor                     := StrSplit(IniRead(g_sWidescreenFixConfigFile, "MAIN", "FOVFactor", 1.0), "//", 2)
		g_arrGraphicNovelMode              := StrSplit(IniRead(g_sWidescreenFixConfigFile, "MAIN", "GraphicNovelMode", true), "//", 2)
		g_arrGraphicNovelModeKey           := StrSplit(IniRead(g_sWidescreenFixConfigFile, "MAIN", "GraphicNovelModeKey", 0x71), "//", 2)
		g_arrCutsceneBorders               := StrSplit(IniRead(g_sWidescreenFixConfigFile, "MAIN", "CutsceneBorders", 2), "//", 2)
		g_arrD3DHookBorders                := StrSplit(IniRead(g_sWidescreenFixConfigFile, "MAIN", "D3DHookBorders", true), "//", 2)
		g_arrLoadSaveSlot                  := StrSplit(IniRead(g_sWidescreenFixConfigFile, "MISC", "LoadSaveSlot", -1), "//", 2)
		g_arrUseGameFolderForSavegames     := StrSplit(IniRead(g_sWidescreenFixConfigFile, "MISC", "UseGameFolderForSavegames", false), "//", 2)
		g_arrAllowAltTabbingWithoutPausing := StrSplit(IniRead(g_sWidescreenFixConfigFile, "MISC", "AllowAltTabbingWithoutPausing", true), "//", 2)

		; Main
		g_bWidescreenHud                   := Trim(g_arrWidescreenHud[1]) == true
		g_fWidescreenHudOffset             := Trim(g_arrWidescreenHudOffset[1])
		g_fFOVFactor                       := Trim(g_arrFOVFactor[1])
		g_bGraphicNovelMode                := Trim(g_arrGraphicNovelMode[1]) == true
		g_sGraphicNovelModeKey             := Trim(g_arrGraphicNovelModeKey[1])
		g_bCutsceneBorders                 := Trim(g_arrCutsceneBorders[1]) == 2
		g_bD3DHookBorders                  := Trim(g_arrD3DHookBorders[1]) == true

		; Misc
		g_nLoadSaveSlot                    := Trim(g_arrLoadSaveSlot[1])
		g_bUseGameFolderForSavegames       := Trim(g_arrUseGameFolderForSavegames[1]) == true
		g_bAllowAltTabbingWithoutPausing   := Trim(g_arrAllowAltTabbingWithoutPausing[1]) == true
	}
}

ReadXboxRainDropletsConfigFile()
{
	global
	g_sXboxRainDropletsConfigFile := g_sGameDir "scripts\MaxPayne2.XboxRainDroplets.ini"

	if (!g_bNoGUI && g_bMaxPayne2 && FileExist(g_sXboxRainDropletsConfigFile))
	{
		g_nMinSize        := IniRead(g_sXboxRainDropletsConfigFile, "MAIN", "MinSize", 4)
		g_nMaxSize        := IniRead(g_sXboxRainDropletsConfigFile, "MAIN", "MaxSize", 15)
		g_nMaxDrops       := IniRead(g_sXboxRainDropletsConfigFile, "MAIN", "MaxDrops", 3000)
		g_nMaxMovingDrops := IniRead(g_sXboxRainDropletsConfigFile, "MAIN", "MaxMovingDrops", 6000)
		g_bEnableGravity  := IniRead(g_sXboxRainDropletsConfigFile, "MAIN", "EnableGravity", true) == true
		g_fSpeedAdjuster  := IniRead(g_sXboxRainDropletsConfigFile, "MAIN", "SpeedAdjuster", 1.0)
		g_fMoveStep       := IniRead(g_sXboxRainDropletsConfigFile, "MAIN", "MoveStep", 0.1)
	}
}

SaveSettings()
{
	try
	{
		; Write to the registry
		RegWrite(g_nWidth,  "REG_DWORD", g_sGameRegKey "Video Settings", "Display Width")
		RegWrite(g_nHeight, "REG_DWORD", g_sGameRegKey "Video Settings", "Display Height")
		RegWrite(g_sModName,   "REG_SZ", g_sGameRegKey "Customized Game", "Customized Game")
		
		if (g_bUnlockAllChapters)
			RegWrite(g_bUnlockAllChapters, "REG_DWORD", g_sGameRegKey "Game Level", "LevelSelector")

		if (g_bUnlockAllDiff)
		{
			RegWrite(g_bUnlockAllDiff, "REG_DWORD", g_sGameRegKey "Game Level", "hell")
			RegWrite(g_bUnlockAllDiff, "REG_DWORD", g_sGameRegKey "Game Level", "nightmare")
			RegWrite(g_bUnlockAllDiff, "REG_DWORD", g_sGameRegKey "Game Level", "timedmode")
		}

		; Write to the config file
		if (!g_bNoGUI)
		{
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
	}
	catch as e
		MsgBox(Format("{1}: {2}.`n`nFile:`t{3}`nLine:`t{4}`nWhat:`t{5}`nStack:`n{6}", type(e), e.Message, e.File, e.Line, e.What, e.Stack), , 48)
}

SaveWidescreenFixSettings()
{
	global
	g_sWidescreenFixConfigFile := g_sGameDir "scripts\MaxPayne" (g_bMaxPayne2 ? "2" : "") ".WidescreenFix.ini"

	if (!g_bNoGUI && FileExist(g_sWidescreenFixConfigFile))
	{
		try
		{
			; We need to add the comments we stored earlier

			; Main
			IniWrite(" " g_cbWidescreenHud.Value (g_arrWidescreenHud.Length > 1 ? " //" g_arrWidescreenHud[2] : ""), g_sWidescreenFixConfigFile, "MAIN", "WidescreenHud")
			IniWrite(" " g_editWidescreenHudOffset.Text (g_arrWidescreenHudOffset.Length > 1 ? " //" g_arrWidescreenHudOffset[2] : ""), g_sWidescreenFixConfigFile,
			         "MAIN", "WidescreenHudOffset")
			IniWrite(" " g_editFOVFactor.Text (g_arrFOVFactor.Length > 1 ? " //" g_arrFOVFactor[2] : ""), g_sWidescreenFixConfigFile, "MAIN", "FOVFactor")
			IniWrite(" " g_cbGraphicNovelMode.Value (g_arrGraphicNovelMode.Length > 1 ? " //" g_arrGraphicNovelMode[2] : ""), g_sWidescreenFixConfigFile,
			         "MAIN", "GraphicNovelMode")
			IniWrite(" " g_editGraphicNovelModeKey.Text (g_arrGraphicNovelModeKey.Length > 1 ? " //" g_arrGraphicNovelModeKey[2] : ""), g_sWidescreenFixConfigFile,
			         "MAIN", "GraphicNovelModeKey")
			IniWrite(" " g_cbCutsceneBorders.Value + 1 (g_arrCutsceneBorders.Length > 1 ? " //" g_arrCutsceneBorders[2] : ""), g_sWidescreenFixConfigFile,
			         "MAIN", "CutsceneBorders")
			IniWrite(" " g_cbD3DHookBorders.Value (g_arrD3DHookBorders.Length > 1 ? " //" g_arrD3DHookBorders[2] : ""), g_sWidescreenFixConfigFile, "MAIN", "D3DHookBorders")

			; Misc
			IniWrite(" " (-g_ddlLoadSaveSlot.Value) (g_arrLoadSaveSlot.Length > 1 ? " //" g_arrLoadSaveSlot[2] : ""), g_sWidescreenFixConfigFile, "MISC", "LoadSaveSlot")
			IniWrite(" " g_cbUseGameFolderForSavegames.Value (g_arrUseGameFolderForSavegames.Length > 1 ? " //" g_arrUseGameFolderForSavegames[2] : ""),
			         g_sWidescreenFixConfigFile, "MISC", "UseGameFolderForSavegames")
			IniWrite(" " g_cbAllowAltTabbingWithoutPausing.Value (g_arrAllowAltTabbingWithoutPausing.Length > 1 ? " //" g_arrAllowAltTabbingWithoutPausing[2] : ""),
			         g_sWidescreenFixConfigFile, "MISC", "AllowAltTabbingWithoutPausing")
		}
		catch as e
			MsgBox(Format("{1}: {2}.`n`nFile:`t{3}`nLine:`t{4}`nWhat:`t{5}`nStack:`n{6}", type(e), e.Message, e.File, e.Line, e.What, e.Stack), , 48)
	}
}

SaveXboxRainDropletsSettings()
{
	global
	g_sXboxRainDropletsConfigFile := g_sGameDir "scripts\MaxPayne2.XboxRainDroplets.ini"

	if (!g_bNoGUI && g_bMaxPayne2 && FileExist(g_sXboxRainDropletsConfigFile))
	{
		try
		{
			; Write to the config file
			IniWrite(" " g_editMinSize.Text, g_sXboxRainDropletsConfigFile,        "MAIN", "MinSize")
			IniWrite(" " g_editMaxSize.Text, g_sXboxRainDropletsConfigFile,        "MAIN", "MaxSize")
			IniWrite(" " g_editMaxDrops.Text, g_sXboxRainDropletsConfigFile,       "MAIN", "MaxDrops")
			IniWrite(" " g_editMaxMovingDrops.Text, g_sXboxRainDropletsConfigFile, "MAIN", "MaxMovingDrops")
			IniWrite(" " g_cbEnableGravity.Value, g_sXboxRainDropletsConfigFile,   "MAIN", "EnableGravity")
			IniWrite(" " g_editSpeedAdjuster.Text, g_sXboxRainDropletsConfigFile,  "MAIN", "SpeedAdjuster")
			IniWrite(" " g_editMoveStep.Text, g_sXboxRainDropletsConfigFile,       "MAIN", "MoveStep")
		}
		catch as e
			MsgBox(Format("{1}: {2}.`n`nFile:`t{3}`nLine:`t{4}`nWhat:`t{5}`nStack:`n{6}", type(e), e.Message, e.File, e.Line, e.What, e.Stack), , 48)
	}
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

	; Retrieve the current mod name from the registry as a fallback if it was empty from a missing key/config file
	if (!g_sModName)
		try g_sModName := RegRead(g_sGameRegKey "Customized Game", "Customized Game", "")

	; Look for the mod file
	if (!g_sModName || (g_sModName != "<none selected>" && !FileExist(g_sGameDir g_sModName "." l_sModExt)))
		g_sModName := "<none selected>"

	; Retrieve all mod names from the game directory
	g_arrModFiles := ["<none selected>"]
	Loop Files, g_sGameDir "*." l_sModExt
	{
		SplitPath(A_LoopFileFullPath, , , , &l_sFileNameNoExt)
		g_arrModFiles.Push(l_sFileNameNoExt)
	}

	g_ddlCustomGame.Delete()
	g_ddlCustomGame.Add(g_arrModFiles)
	g_ddlCustomGame.Choose(1)
}
