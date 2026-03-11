#Requires Autohotkey v2.0 ; Display an error and quit if this version requirement is not met.
#SingleInstance force     ; Allow only a single instance of the script to run.
#Warn                     ; Enable warnings to assist with detecting common errors.

;TODO
; clamp variables within allowed ranges when reading config files

; Do not edit this
g_sConfigFile := A_ScriptDir "\MaxPayne2Launcher.ini"

Init()

BuildLaunchArgs()
{
	l_mapArgs := Map(
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

	l_sLaunchArgs := ""
	for l_sKey, l_sValue in l_mapArgs
	{
		if (l_sValue)
			l_sLaunchArgs .= l_sLaunchArgs ? " " l_sKey : l_sKey
	}

	return l_sLaunchArgs
}

CheckGameExe()
{
	; Check for game exe in the user-defined directory
	if (!FileExist(g_sGameDir g_sGameExe))
	{
		; Not found, check in the current directory
		if (!FileExist(g_sGameExe))
			return false
		else
			global g_sGameDir := g_editGameDir.Text := A_WorkingDir "\"
	}

	return true
}

CreateGui()
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

	g_tabs := g_gui.AddTab3(, ["General"])
	g_arrTabs := ["General"]

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

	; Customized game
	g_gui.AddGroupBox("R1.5 x" l_nLeftX - 4 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY - 10 " w" l_nLeftWidth + l_nMiddleWidth + l_nRightWidth + l_nSpacingX * 4,
	                  "Choose customized game")
	g_ddlCustomGame := g_gui.AddDropDownList("Choose1 x" l_nLeftX + 15 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY - 10 " w" l_nLeftWidth + l_nMiddleWidth + l_nRightWidth + 5)

	g_tabs.UseTab(0)
	g_btnStart := g_gui.AddButton("Background1F1F1F Default x210 w" l_nRightWidth, "&Start game")

	; Events
	g_tabs.OnEvent("Change", GuiTab_Change)
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

CreateGuiWidescreen()
{
	global

	; Layout constants
	local l_nCurrentRow := 0
	local l_nSpacingX := 10
	local l_nSpacingY := 25
	local l_nTopY := 35
	; Leftmost controls
	local l_nLeftWidth := 120
	local l_nLeftX := 35
	; Middle controls
	local l_nMiddleX := l_nLeftX + l_nLeftWidth + l_nSpacingX + 40
	local l_nMiddleWidth := 200
	; Rightmost controls
	local l_nRightX := l_nMiddleX + l_nMiddleWidth + l_nSpacingX
	local l_nRightWidth := 100

	; Widescreen fix settings
	g_tabs.Add(["Widescreen"])
	g_arrTabs.Push("Widescreen")
	g_tabs.UseTab(2)

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

	; Xbox rain droplets settings
	l_nCurrentRow++
	g_gbXbox := g_gui.AddGroupBox("R8.5 x" l_nLeftX - 4 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY - 5
	                              " w" l_nLeftWidth + l_nMiddleWidth + l_nRightWidth + l_nSpacingX * 4, "Xbox rain droplets")

	g_cbEnableGravity := g_gui.AddCheckbox("Checked" g_bEnableGravity " x" l_nLeftX + 15 " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY, "Enable gravity")

	g_textMinSize := g_gui.AddText("vSliderMinSizeLeft", "Mininum size")
	g_editMinSize := g_gui.AddEdit("vSliderMinSizeRight CBlack R1 ReadOnly w" 50, g_nMinSize)
	g_sliderMinSize := g_gui.AddSlider("AltSubmit Buddy1SliderMinSizeLeft Buddy2SliderMinSizeRight NoTicks Range1-9 x" l_nMiddleX
	                                   " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY " w" l_nMiddleWidth + 15, g_nMinSize)

	g_textMaxDrops := g_gui.AddText("vSliderMaxDropsLeft", "Maximum drops")
	g_editMaxDrops := g_gui.AddEdit("vSliderMaxDropsRight CBlack R1 ReadOnly w" 50, g_nMaxDrops)
	g_sliderMaxDrops := g_gui.AddSlider("AltSubmit Buddy1SliderMaxDropsLeft Buddy2SliderMaxDropsRight NoTicks Range1000-10000 x" l_nMiddleX
	                                    " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY " w" l_nMiddleWidth + 15, g_nMaxDrops)

	g_textMaxMovingDrops := g_gui.AddText("vSliderMaxMovingDropsLeft", "Maximum moving drops")
	g_editMaxMovingDrops := g_gui.AddEdit("vSliderMaxMovingDropsRight CBlack R1 ReadOnly w" 50, g_nMaxMovingDrops)
	g_sliderMaxMovingDrops := g_gui.AddSlider("AltSubmit Buddy1SliderMaxMovingDropsLeft Buddy2SliderMaxMovingDropsRight NoTicks Range1000-10000 x" l_nMiddleX
	                                          " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY " w" l_nMiddleWidth + 15, g_nMaxMovingDrops)

	g_textMaxSize := g_gui.AddText("vSliderMaxSizeLeft", "Maximum size")
	g_editMaxSize := g_gui.AddEdit("vSliderMaxSizeRight CBlack R1 ReadOnly w" 50, g_nMaxSize)
	g_sliderMaxSize := g_gui.AddSlider("AltSubmit Buddy1SliderMaxSizeLeft Buddy2SliderMaxSizeRight NoTicks Range10-30 x" l_nMiddleX
	                                   " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY " w" l_nMiddleWidth + 15, g_nMaxSize)

	g_textMoveStep := g_gui.AddText("vSliderMoveStepLeft", "Move step")
	g_editMoveStep := g_gui.AddEdit("vSliderMoveStepRight CBlack R1 ReadOnly w" 50, g_fMoveStep)
	g_sliderMoveStep := g_gui.AddSlider("AltSubmit Buddy1SliderMoveStepLeft Buddy2SliderMoveStepRight NoTicks Range1-20 x" l_nMiddleX
	                                    " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY " w" l_nMiddleWidth + 15, g_fMoveStep * 10)

	g_textSpeedAdjuster := g_gui.AddText("vSliderSpeedAdjusterLeft", "Speed adjuster")
	g_editSpeedAdjuster := g_gui.AddEdit("vSliderSpeedAdjusterRight CBlack R1 ReadOnly w" 50, g_fSpeedAdjuster)
	g_sliderSpeedAdjuster := g_gui.AddSlider("AltSubmit Buddy1SliderSpeedAdjusterLeft Buddy2SliderSpeedAdjusterRight NoTicks Range1-20 x" l_nMiddleX
	                                         " y" l_nTopY + ++l_nCurrentRow * l_nSpacingY " w" l_nMiddleWidth + 15, g_fSpeedAdjuster * 10)

	; Events
	g_sliderFOVFactor.OnEvent("Change", (*) => g_editFOVFactor.Text := Round(g_sliderFOVFactor.Value / 10.0, 1))
	g_sliderWidescreenHudOffset.OnEvent("Change", (*) => g_editWidescreenHudOffset.Text := Float(g_sliderWidescreenHudOffset.Value))
	g_sliderMinSize.OnEvent("Change", (*) => g_editMinSize.Text := g_sliderMinSize.Value)
	g_sliderMaxSize.OnEvent("Change", (*) => g_editMaxSize.Text := g_sliderMaxSize.Value)
	g_sliderMaxDrops.OnEvent("Change", (*) => g_editMaxDrops.Text := g_sliderMaxDrops.Value)
	g_sliderMaxMovingDrops.OnEvent("Change", (*) => g_editMaxMovingDrops.Text := g_sliderMaxMovingDrops.Value)
	g_sliderMoveStep.OnEvent("Change", (*) => g_editMoveStep.Text := Round(g_sliderMoveStep.Value / 10.0, 1))
	g_sliderSpeedAdjuster.OnEvent("Change", (*) => g_editSpeedAdjuster.Text := Round(g_sliderSpeedAdjuster.Value / 10.0, 1))
}

GuiButtonBrowse_Click(*)
{
	; Turn FileSelect into a modal
	g_gui.Opt("+OwnDialogs")

	l_sSelectedFile := FileSelect("3", , "Select the target executable file", "Game executable (MaxPayne.exe; MaxPayne2.exe)")
	SplitPath(l_sSelectedFile, &l_sGameExe, &l_sGameDir)

	if (l_sGameExe ~= "i)\A(maxpayne.exe|maxpayne2.exe)\z")
	{
		global g_sGameDir := g_editGameDir.Text := l_sGameDir "\"

		; Change the game
		global g_bMaxPayne2 := g_radioMP2.Value := l_sGameExe = "MaxPayne2.exe"
		UpdateGame()

		; Refresh the mod list
		UpdateMods()

		ReadWidescreenFixConfigFile()
		ReadXboxRainDropletsConfigFile()
		GuiUpdateWidescreen()
	}
}

GuiButtonStart_Click(*)
{
	g_gui.Hide()

	SaveSettings()
	SaveWidescreenFixSettings()
	SaveXboxRainDropletsSettings()

	; If the launcher/game is already running, activate it
	if (WinExist(g_sWinTitleLauncher))
		WinActivate(g_sWinTitleLauncher)
	else if (WinExist(g_sWinTitleGame))
	{
		WinActivate(g_sWinTitleGame)
		return
	}
	; Otherwise start the launcher with arguments
	else
	{
		if (!CheckGameExe())
		{
			MsgBox("File not found:`n`n" g_sGameDir g_sGameExe, "Error", 16)
			return
		}

		Run(g_sGameDir g_sGameExe " " BuildLaunchArgs())

		; We give 15 seconds for the launcher to show up
		; If it always hangs, you should consider using https://community.pcgamingwiki.com/files/file/838-max-payne-series-startup-hang-patch
		if (!WinWaitActive(g_sWinTitleLauncher, , 15.0))
			return
	}

	; Send the right keystrokes to the game launcher window
	ControlSend("{End}", "ComboBox1", g_sWinTitleLauncher) ; ComboBox1 = Display Adapter DDL
	ControlChooseString(g_sResolution, "ComboBox2", g_sWinTitleLauncher) ; ComboBox2 = Screen Mode DDL
	ControlChooseString(g_sModName, "ComboBox4", g_sWinTitleLauncher) ; ComboBox4 = Choose Customized Game DDL
	ControlSend("{Enter}", "Button1", g_sWinTitleLauncher) ; Button1 = Play button
}

GuiCB_Click(GuiCtrlObj, Info)
{
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
			global g_bUnlockAllChapters := g_cbUnlockAllChapters.Value
		case g_cbUnlockAllDiff:
			global g_bUnlockAllDiff := g_cbUnlockAllDiff.Value
	}
}

GuiDDL_Change(*)
{
	global g_sModName := g_ddlCustomGame.Text
}

GuiRadio_Click(GuiCtrlObj, Info)
{
	switch GuiCtrlObj
	{
		; Swap Max Payne and Max Payne 2 in the game directory path for convenience
		case g_radioMP1:
			global g_bMaxPayne2 := 0
			g_editGameDir.Text := RegExReplace(g_editGameDir.Text, "i)(.*)Max Payne 2\\$", "$1Max Payne\", , 1)
		case g_radioMP2:
			global g_bMaxPayne2 := 1
			g_editGameDir.Text := RegExReplace(g_editGameDir.Text, "i)(.*)Max Payne\\$", "$1Max Payne 2\", , 1)
	}

	; Change the game
	global g_sGameDir := g_editGameDir.Text
	UpdateGame()

	; Refresh the mod list
	UpdateMods()

	ReadWidescreenFixConfigFile()
	ReadXboxRainDropletsConfigFile()
	GuiUpdateWidescreen()
}

GuiTab_Change(*)
{
	; Toggle Xbox rain droplets controls visibility
	if (g_tabs.Text == "Widescreen")
	{
		l_bXboxCfgFileExists := FileExist(g_sXboxCfgFile)
		l_arrControlsXbox := [
			g_gbXbox, g_cbEnableGravity,
			g_editMaxDrops, g_editMaxMovingDrops, g_editMaxSize, g_editMinSize, g_editMoveStep, g_editSpeedAdjuster,
			g_sliderMinSize, g_sliderMaxDrops, g_sliderMaxMovingDrops, g_sliderMaxSize, g_sliderMoveStep, g_sliderSpeedAdjuster,
			g_textMaxDrops, g_textMaxMovingDrops, g_textMaxSize, g_textMinSize, g_textMoveStep, g_textSpeedAdjuster
		]

		for l_ctrl in l_arrControlsXbox
			l_ctrl.Visible := l_bXboxCfgFileExists
	}
}

GuiUpdateWidescreen()
{
	global g_sWidescreenCfgFile := g_sGameDir "scripts\MaxPayne" (g_bMaxPayne2 ? "2" : "") ".WidescreenFix.ini"
	global g_sXboxCfgFile := g_sGameDir "scripts\MaxPayne" (g_bMaxPayne2 ? "2" : "") ".XboxRainDroplets.ini"

	if (FileExist(g_sWidescreenCfgFile))
	{
		; Add the widescreen tab if it's missing
		if (g_arrTabs.Length < 2)
		{
			g_tabs.Add(["Widescreen"])
			g_arrTabs.Push("Widescreen")
		}

		; Widescreen
		g_cbAllowAltTabbingWithoutPausing.Value := g_bAllowAltTabbingWithoutPausing
		g_cbCutsceneBorders.Value := g_bCutsceneBorders
		g_cbD3DHookBorders.Value := g_bD3DHookBorders
		g_editFOVFactor.Text := g_fFOVFactor
		g_sliderFOVFactor.Value := g_fFOVFactor * 10
		g_cbGraphicNovelMode.Value := g_bGraphicNovelMode
		g_editGraphicNovelModeKey.Value := g_sGraphicNovelModeKey
		g_ddlLoadSaveSlot.Value := Abs(g_nLoadSaveSlot)
		g_cbUseGameFolderForSavegames.Value := g_bUseGameFolderForSavegames
		g_cbWidescreenHud.Value := g_bWidescreenHud
		g_sliderWidescreenHudOffset.Value := g_editWidescreenHudOffset.Value := g_fWidescreenHudOffset

		; Xbox
		g_cbEnableGravity.Value := g_bEnableGravity
		g_sliderMinSize.Value := g_editMinSize.Text := g_nMinSize
		g_sliderMaxDrops.Value := g_editMaxDrops.Text := g_nMaxDrops
		g_sliderMaxMovingDrops.Value := g_editMaxMovingDrops.Text := g_nMaxMovingDrops
		g_sliderMaxSize.Value := g_editMaxSize.Text := g_nMaxSize
		g_editMoveStep.Text := g_fMoveStep
		g_sliderMoveStep.Value := g_fMoveStep * 10
		g_editSpeedAdjuster.Text := g_fSpeedAdjuster
		g_sliderSpeedAdjuster.Value := g_fSpeedAdjuster * 10
	}
	; Delete the widescreen tab if it's no longer necessary
	else if (g_arrTabs.Length > 1)
	{
		g_tabs.Delete(2)
		g_tabs.Redraw()
		g_arrTabs.Pop()
	}
}

Init()
{
	ReadConfigFile()
	CreateGui()
	UpdateGame()
	CheckGameExe()
	UpdateMods()

	if (g_bNoGUI)
		GuiButtonStart_Click()
	else
	{
		ReadWidescreenFixConfigFile()
		ReadXboxRainDropletsConfigFile()
		CreateGuiWidescreen()
		GuiUpdateWidescreen()
		g_gui.Show()
	}
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

	g_sWidescreenCfgFile := g_sGameDir "scripts\MaxPayne" (g_bMaxPayne2 ? "2" : "") ".WidescreenFix.ini"

	; The widescreen fix INI includes non-standard // comments so we need to preserve and trim them
	g_arrWidescreenHud                 := StrSplit(IniRead(g_sWidescreenCfgFile, "MAIN", "WidescreenHud", true), "//", 2)
	g_arrWidescreenHudOffset           := StrSplit(IniRead(g_sWidescreenCfgFile, "MAIN", "WidescreenHudOffset", 100.0), "//", 2)
	g_arrFOVFactor                     := StrSplit(IniRead(g_sWidescreenCfgFile, "MAIN", "FOVFactor", 1.0), "//", 2)
	g_arrGraphicNovelMode              := StrSplit(IniRead(g_sWidescreenCfgFile, "MAIN", "GraphicNovelMode", true), "//", 2)
	g_arrGraphicNovelModeKey           := StrSplit(IniRead(g_sWidescreenCfgFile, "MAIN", "GraphicNovelModeKey", 0x71), "//", 2)
	g_arrCutsceneBorders               := StrSplit(IniRead(g_sWidescreenCfgFile, "MAIN", "CutsceneBorders", 2), "//", 2)
	g_arrD3DHookBorders                := StrSplit(IniRead(g_sWidescreenCfgFile, "MAIN", "D3DHookBorders", true), "//", 2)
	g_arrLoadSaveSlot                  := StrSplit(IniRead(g_sWidescreenCfgFile, "MISC", "LoadSaveSlot", -1), "//", 2)
	g_arrUseGameFolderForSavegames     := StrSplit(IniRead(g_sWidescreenCfgFile, "MISC", "UseGameFolderForSavegames", false), "//", 2)
	g_arrAllowAltTabbingWithoutPausing := StrSplit(IniRead(g_sWidescreenCfgFile, "MISC", "AllowAltTabbingWithoutPausing", true), "//", 2)

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

ReadXboxRainDropletsConfigFile()
{
	global

	g_sXboxCfgFile := g_sGameDir "scripts\MaxPayne" (g_bMaxPayne2 ? "2" : "") ".XboxRainDroplets.ini"

	g_nMinSize        := IniRead(g_sXboxCfgFile, "MAIN", "MinSize", 4)
	g_nMaxSize        := IniRead(g_sXboxCfgFile, "MAIN", "MaxSize", 15)
	g_nMaxDrops       := IniRead(g_sXboxCfgFile, "MAIN", "MaxDrops", 3000)
	g_nMaxMovingDrops := IniRead(g_sXboxCfgFile, "MAIN", "MaxMovingDrops", 6000)
	g_bEnableGravity  := IniRead(g_sXboxCfgFile, "MAIN", "EnableGravity", true) == true
	g_fSpeedAdjuster  := IniRead(g_sXboxCfgFile, "MAIN", "SpeedAdjuster", 1.0)
	g_fMoveStep       := IniRead(g_sXboxCfgFile, "MAIN", "MoveStep", 0.1)
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
	if (!g_bNoGUI && g_arrTabs.Length > 1 && FileExist(g_sWidescreenCfgFile))
	{
		try
		{
			; We need to add the comments we stored earlier

			; Main
			IniWrite(" " g_cbWidescreenHud.Value (g_arrWidescreenHud.Length > 1 ? " //" g_arrWidescreenHud[2] : ""), g_sWidescreenCfgFile, "MAIN", "WidescreenHud")
			IniWrite(" " g_editWidescreenHudOffset.Text (g_arrWidescreenHudOffset.Length > 1 ? " //" g_arrWidescreenHudOffset[2] : ""), g_sWidescreenCfgFile,
			         "MAIN", "WidescreenHudOffset")
			IniWrite(" " g_editFOVFactor.Text (g_arrFOVFactor.Length > 1 ? " //" g_arrFOVFactor[2] : ""), g_sWidescreenCfgFile, "MAIN", "FOVFactor")
			IniWrite(" " g_cbGraphicNovelMode.Value (g_arrGraphicNovelMode.Length > 1 ? " //" g_arrGraphicNovelMode[2] : ""), g_sWidescreenCfgFile,
			         "MAIN", "GraphicNovelMode")
			IniWrite(" " g_editGraphicNovelModeKey.Text (g_arrGraphicNovelModeKey.Length > 1 ? " //" g_arrGraphicNovelModeKey[2] : ""), g_sWidescreenCfgFile,
			         "MAIN", "GraphicNovelModeKey")
			IniWrite(" " g_cbCutsceneBorders.Value + 1 (g_arrCutsceneBorders.Length > 1 ? " //" g_arrCutsceneBorders[2] : ""), g_sWidescreenCfgFile,
			         "MAIN", "CutsceneBorders")
			IniWrite(" " g_cbD3DHookBorders.Value (g_arrD3DHookBorders.Length > 1 ? " //" g_arrD3DHookBorders[2] : ""), g_sWidescreenCfgFile, "MAIN", "D3DHookBorders")

			; Misc
			IniWrite(" " (-g_ddlLoadSaveSlot.Value) (g_arrLoadSaveSlot.Length > 1 ? " //" g_arrLoadSaveSlot[2] : ""), g_sWidescreenCfgFile, "MISC", "LoadSaveSlot")
			IniWrite(" " g_cbUseGameFolderForSavegames.Value (g_arrUseGameFolderForSavegames.Length > 1 ? " //" g_arrUseGameFolderForSavegames[2] : ""),
			         g_sWidescreenCfgFile, "MISC", "UseGameFolderForSavegames")
			IniWrite(" " g_cbAllowAltTabbingWithoutPausing.Value (g_arrAllowAltTabbingWithoutPausing.Length > 1 ? " //" g_arrAllowAltTabbingWithoutPausing[2] : ""),
			         g_sWidescreenCfgFile, "MISC", "AllowAltTabbingWithoutPausing")
		}
		catch as e
			MsgBox(Format("{1}: {2}.`n`nFile:`t{3}`nLine:`t{4}`nWhat:`t{5}`nStack:`n{6}", type(e), e.Message, e.File, e.Line, e.What, e.Stack), , 48)
	}
}

SaveXboxRainDropletsSettings()
{
	if (!g_bNoGUI && g_arrTabs.Length > 1 && FileExist(g_sXboxCfgFile))
	{
		try
		{
			IniWrite(" " g_editMinSize.Text, g_sXboxCfgFile,        "MAIN", "MinSize")
			IniWrite(" " g_editMaxSize.Text, g_sXboxCfgFile,        "MAIN", "MaxSize")
			IniWrite(" " g_editMaxDrops.Text, g_sXboxCfgFile,       "MAIN", "MaxDrops")
			IniWrite(" " g_editMaxMovingDrops.Text, g_sXboxCfgFile, "MAIN", "MaxMovingDrops")
			IniWrite(" " g_cbEnableGravity.Value, g_sXboxCfgFile,   "MAIN", "EnableGravity")
			IniWrite(" " g_editSpeedAdjuster.Text, g_sXboxCfgFile,  "MAIN", "SpeedAdjuster")
			IniWrite(" " g_editMoveStep.Text, g_sXboxCfgFile,       "MAIN", "MoveStep")
		}
		catch as e
			MsgBox(Format("{1}: {2}.`n`nFile:`t{3}`nLine:`t{4}`nWhat:`t{5}`nStack:`n{6}", type(e), e.Message, e.File, e.Line, e.What, e.Stack), , 48)
	}
}

UpdateGame()
{
	global

	local l_sLink := "https://www.pcgamingwiki.com/wiki/Max_Payne" (g_bMaxPayne2 ? "_2:_The_Fall_of_Max_Payne" : "") "#Command_line_arguments"

	g_sGameExe := "MaxPayne" (g_bMaxPayne2 ? "2" : "") ".exe"
	g_sGameRegKey := "HKEY_CURRENT_USER\Software\Remedy Entertainment\Max Payne" (g_bMaxPayne2 ? " 2\" : "\")
	g_sWinTitleGame := "ahk_exe " g_sGameExe " ahk_class MaxPayne" (g_bMaxPayne2 ? "2" : "")
	g_sWinTitleLauncher := "ahk_exe " g_sGameExe " ahk_class #32770"
	g_linkPCGW.Text := 'See this <a href="' l_sLink '">link</a> for more details.'
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
	global g_arrModFiles, g_sModName

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
	g_ddlCustomGame.Choose(g_sModName)
}
