#Requires Autohotkey v2.0 ; Display an error and quit if this version requirement is not met.
#SingleInstance force     ; Allow only a single instance of the script to run.
#Warn                     ; Enable warnings to assist with detecting common errors.

; Do not edit this
g_sConfigFile := A_ScriptDir "\MaxPayne2Launcher.ini"

Init()

BuildLaunchArgs()
{
	l_mapArgs := Map(
		"-developer",         g_cbDeveloper.Value,
		"-developerkeys",     g_cbDeveloperKeys.Value,
		"-disable3dpreloads", g_cbDisable3dpreloads.Value,
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

ClampType(p_sValue, p_sDefault, p_sType, p_iMin := 0, p_iMax := 0)
{
	try
	{
		l_iValue := p_sValue + (p_sType == "int" ? 0 : 0.0)
	}
	catch TypeError ; not an integer/float
	{
		return p_sDefault
	}

	l_iValue := Min(l_iValue, p_iMax)
	l_iValue := Max(l_iValue, p_iMin)

	if (p_sType == "float")
		l_iValue := Round(l_iValue, 1)

	return l_iValue
}

FindGameExe()
{
	; Check in the user-defined directory
	if (FileExist(g_sGameDir g_sGameExe))
		return true

	; Check in the current directory
	if (FileExist(g_sGameExe))
	{
		global g_sGameDir := g_editGameDir.Text := A_WorkingDir "\"
		return true
	}

	; Check from the registry
	try l_sGameDir := RegRead("HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App " (g_bMaxPayne2 ? "12150" : "12140"), "InstallLocation", "")

	if (l_sGameDir && FileExist(l_sGameDir g_sGameExe))
	{
		global g_sGameDir := g_editGameDir.Text := l_sGameDir "\"
		return true
	}

	return false
}

; https://www.autohotkey.com/boards/viewtopic.php?t=77664
GetResolutionList(p_iDisp := 1)
{
	l_bufDevMode := Buffer(220, 0)
	l_sRes := ""

	; Safety check
	p_iDisp := IsInteger(p_iDisp) ? p_iDisp : 1
	if (p_iDisp < 1 || p_iDisp > MonitorGetCount())
		p_iDisp := 1

	; https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-enumdisplaysettingsw
	while DllCall("EnumDisplaySettingsW", "WStr", "\\.\DISPLAY" p_iDisp, "UInt", A_Index - 1, "Ptr", l_bufDevMode.Ptr)
	{
		l_iBpp := NumGet(l_bufDevMode, 168, "UInt")
		l_iFreq := NumGet(l_bufDevMode, 184, "UInt")

		; Only store 32-bit resolutions
		if (l_iBpp == 32)
		{
			l_iWidth := NumGet(l_bufDevMode, 172, "UInt")
			l_iHeight := NumGet(l_bufDevMode, 176, "UInt")
			l_sRes .= Format('{:} x {:}`n', l_iWidth, l_iHeight)
		}
	}

	; Sort and remove duplicates
	l_sRes := Sort(RTrim(l_sRes, '`n'), "CLogical U")
	return StrSplit(l_sRes, '`n')
}

GuiButtonBrowse_Click(*)
{
	; Turn FileSelect into a modal
	g_gui.Opt("+OwnDialogs")

	l_sSelectedFile := FileSelect("3", , "Select the target executable file", "Max Payne executable (MaxPayne.exe; MaxPayne2.exe)")
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
		if (!FindGameExe())
		{
			MsgBox("File not found:`n`n" g_sGameDir g_sGameExe, "Error", 16)
			return
		}

		DetectHiddenWindows(g_cbNodialog.Value)
		Run(g_sGameDir g_sGameExe " " BuildLaunchArgs(), , g_cbNodialog.Value ? "Hide" : "")

		; We give 15 seconds for the launcher to show up
		; If it always hangs, you should consider using https://community.pcgamingwiki.com/files/file/838-max-payne-series-startup-hang-patch
		if (!WinWaitActive(g_sWinTitleLauncher, , 15.0))
			return
	}

	; Send the right keystrokes to the game launcher window
	ControlSend("{End}", "ComboBox1", g_sWinTitleLauncher) ; ComboBox1 = Display Adapter DDL
	ControlChooseString(g_sResolution " x 32", "ComboBox2", g_sWinTitleLauncher) ; ComboBox2 = Screen Mode DDL
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
		case g_cbShowprogress:
			if (g_cbShowprogress.Value)
				g_cbDeveloper.Value := true
		case g_cbUnlockAllChapters:
			global g_bUnlockAllChapters := g_cbUnlockAllChapters.Value
		case g_cbUnlockAllDiff:
			global g_bUnlockAllDiff := g_cbUnlockAllDiff.Value
		case g_cbEnableXbox:
			try FileMove(g_cbEnableXbox.Value ? (g_sXboxAsiFile ".off") : g_sXboxAsiFile, g_cbEnableXbox.Value ? g_sXboxAsiFile : (g_sXboxAsiFile ".off"))
	}
}

GuiCreateGeneral()
{
	global

	g_gui := Gui("-MinimizeBox -MaximizeBox", "Max Payne Launcher")
	g_gui.BackColor := "1F1F1F"
	g_gui.SetFont("CWhite s10")

	; Layout constants
	local l_iCurrentRow := 0
	local l_iSpacingX := 10
	local l_iSpacingY := 25
	local l_iTopY := 35
	; Leftmost controls
	local l_iLeftWidth := 150
	local l_iLeftX := 35
	; Middle controls
	local l_iMiddleWidth := 200
	local l_iMiddleX := l_iLeftX + l_iLeftWidth + l_iSpacingX
	; Rightmost controls
	local l_iRightWidth := 100
	local l_iRightX := l_iMiddleX + l_iMiddleWidth + l_iSpacingX

	g_tabs := g_gui.AddTab3(, ["General"])
	g_arrTabs := ["General"]

	; Game
	g_gui.AddGroupBox("h" l_iSpacingY * 3.5 " x" l_iLeftX - 7 " y" l_iTopY " w" l_iLeftWidth + l_iMiddleWidth + l_iRightWidth + l_iSpacingX * 4, "Game")
	g_gui.AddText("Right x" l_iLeftX " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY " w" l_iLeftWidth, "Choose your game")
	g_radioMP1 := g_gui.AddRadio("x" l_iMiddleX " y" l_iTopY + l_iCurrentRow * l_iSpacingY, "Max Payne")
	g_radioMP2 := g_gui.AddRadio("Checked" g_bMaxPayne2 " x" l_iMiddleX + 100 " y" l_iTopY + l_iCurrentRow * l_iSpacingY, "Max Payne 2")
	g_gui.AddButton("Background1F1F1F Default x" l_iRightX " y" l_iTopY + l_iCurrentRow++ * l_iSpacingY - 7 " w" l_iRightWidth, "&Browse").OnEvent("Click",
	                GuiButtonBrowse_Click)

	g_gui.AddText("Right x" l_iLeftX " y" l_iTopY + l_iCurrentRow * l_iSpacingY + 5 " w" l_iLeftWidth, "Game directory")
	g_editGameDir := g_gui.AddEdit("CBlack R1 ReadOnly x" l_iMiddleX " y" l_iTopY + l_iCurrentRow++ * l_iSpacingY " w" l_iMiddleWidth + l_iRightWidth + l_iSpacingX - 2,
	                               g_sGameDir)

	; Resolution
	l_iTopY += l_iSpacingY - 3
	g_gui.AddGroupBox("h" l_iSpacingY * 2.6 " x" l_iLeftX - 7 " y" l_iTopY + l_iSpacingY * l_iCurrentRow++ " w" l_iLeftWidth + l_iMiddleWidth + l_iRightWidth + l_iSpacingX * 4, "Resolution")
	local l_arrResolutions := GetResolutionList()
	g_ddlResolution := g_gui.AddDropDownList(" x" l_iLeftX + 10 " y" l_iTopY + l_iCurrentRow++ * l_iSpacingY " w" l_iLeftWidth + l_iMiddleWidth + l_iRightWidth + 7, l_arrResolutions)
	try g_ddlResolution.Text := g_sResolution
	catch
	{
		; Resolution not found, default to the highest available
		g_ddlResolution.Choose(l_arrResolutions.Length)
		g_sResolution := g_ddlResolution.Text
	}

	; Launch parameters
	l_iTopY += l_iSpacingY
	g_gui.AddGroupBox("h" l_iSpacingY * 12.1 " x" l_iLeftX - 7 " y" l_iTopY + l_iCurrentRow * l_iSpacingY " w" l_iLeftWidth + l_iMiddleWidth + l_iRightWidth + l_iSpacingX * 4,
	                  "Launch parameters")
	g_linkPCGW := g_gui.AddLink("x" l_iLeftX + 15 " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY, "See this link for more details.")
	g_cbDeveloper := g_gui.AddCheckbox("Checked" g_bDeveloper                 " x" l_iLeftX + 15 " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY, "-developer")
	g_cbDeveloperKeys := g_gui.AddCheckbox("Checked" g_bDeveloperKeys         " x" l_iLeftX + 15 " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY, "-developerkeys")
	g_cbDisable3dpreloads := g_gui.AddCheckbox("Checked" g_bDisable3dpreloads " x" l_iLeftX + 15 " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY, "-disable3dpreloads")
	g_cbNodialog := g_gui.AddCheckbox("Checked" g_bNodialog                   " x" l_iLeftX + 15 " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY, "-nodialog")
	g_cbNovidmemcheck := g_gui.AddCheckbox("Checked" g_bNovidmemcheck         " x" l_iLeftX + 15 " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY, "-novidmemcheck")
	g_cbProfile := g_gui.AddCheckbox("Checked" g_bProfile                     " x" l_iLeftX + 15 " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY, "-profile")
	g_cbScreenshot := g_gui.AddCheckbox("Checked" g_bScreenshot               " x" l_iLeftX + 15 " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY, "-screenshot")
	g_cbShowprogress:= g_gui.AddCheckbox("Checked" g_bShowprogress            " x" l_iLeftX + 15 " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY, "-showprogress")
	g_cbSkipstartup := g_gui.AddCheckbox("Checked" g_bSkipstartup             " x" l_iLeftX + 15 " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY, "-skipstartup")
	g_cbWindow := g_gui.AddCheckbox("Checked" g_bWindow                       " x" l_iLeftX + 15 " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY, "-window")

	; Extra
	l_iTopY += l_iSpacingY + 12
	g_gui.AddGroupBox("h" l_iSpacingY * 3.1 " x" l_iLeftX - 7 " y" l_iTopY + l_iCurrentRow * l_iSpacingY " w" l_iLeftWidth + l_iMiddleWidth + l_iRightWidth + l_iSpacingX * 4, "Extras")
	g_cbUnlockAllChapters := g_gui.AddCheckbox("x" l_iLeftX + 15 " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY, "Unlock all chapters")
	g_cbUnlockAllDiff := g_gui.AddCheckbox("x" l_iLeftX + 15 " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY, "Unlock all difficulties")

	; Customized game
	l_iTopY += l_iSpacingY + 12
	g_gui.AddGroupBox("h" l_iSpacingY * 2.6 " x" l_iLeftX - 7 " y" l_iTopY + l_iCurrentRow * l_iSpacingY " w" l_iLeftWidth + l_iMiddleWidth + l_iRightWidth + l_iSpacingX * 4,
	                  "Customized game")
	g_ddlCustomGame := g_gui.AddDropDownList("Choose1 x" l_iLeftX + 10 " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY " w" l_iLeftWidth + l_iMiddleWidth + l_iRightWidth + 7)

	g_tabs.UseTab(0)
	g_gui.AddButton("Background1F1F1F Default x223 w" l_iRightWidth, "&Start game").OnEvent("Click", GuiButtonStart_Click)

	; Events
	g_cbDeveloper.OnEvent(        "Click", GuiCB_Click)
	g_cbDeveloperKeys.OnEvent(    "Click", GuiCB_Click)
	g_cbShowprogress.OnEvent(     "Click", GuiCB_Click)
	g_cbUnlockAllChapters.OnEvent("Click", GuiCB_Click)
	g_cbUnlockAllDiff.OnEvent(    "Click", GuiCB_Click)
	g_ddlCustomGame.OnEvent(     "Change", GuiDDL_Change)
	g_ddlResolution.OnEvent(     "Change", GuiDDL_Change)
	g_radioMP1.OnEvent(           "Click", GuiRadio_Click)
	g_radioMP2.OnEvent(           "Click", GuiRadio_Click)
	g_tabs.OnEvent(              "Change", GuiTab_Change)
}

GuiCreateWidescreen()
{
	global

	local l_arrExtraKeys := ["None", "Backspace", "Enter", "Escape", "Space", "Tab", "LButton", "RButton", "MButton", "XButton1", "XButton2"]

	; Layout constants
	local l_iCurrentRow := 0
	local l_iSpacingX := 10
	local l_iSpacingY := 25
	local l_iTopY := 35
	; Leftmost controls
	local l_iLeftWidth := 150
	local l_iLeftX := 35
	; Middle controls
	local l_iMiddleX := l_iLeftX + l_iLeftWidth + l_iSpacingX
	local l_iMiddleWidth := 200
	; Rightmost controls
	local l_iRightX := l_iMiddleX + l_iMiddleWidth + l_iSpacingX
	local l_iRightWidth := 85

	; Widescreen fix settings
	g_tabs.Add(["Widescreen"])
	g_arrTabs.Push("Widescreen")
	g_tabs.UseTab(2)

	g_gui.AddGroupBox("h" l_iSpacingY * 11.7 " x" l_iLeftX - 7 " y" l_iTopY " w" l_iLeftWidth + l_iMiddleWidth + l_iRightWidth + l_iSpacingX * 4 + 15, "Widescreen fix")

	g_cbAllowAltTabbingWithoutPausing := g_gui.AddCheckbox("Checked" g_bAllowAltTabbingWithoutPausing " x" l_iLeftX + 15 " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY,
	                                                       "Allow alt tabbing without pausing")
	g_cbCutsceneBorders := g_gui.AddCheckbox("Checked" g_bCutsceneBorders - 1 " x" l_iLeftX + 15 " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY, "Cutscene borders")
	g_cbD3DHookBorders := g_gui.AddCheckbox("Checked" g_bD3DHookBorders " x" l_iLeftX + 15 " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY, "D3D hook borders")
	g_gui.AddText("vSliderFOVFactorLeft", "FOV factor")
	g_editFOVFactor := g_gui.AddEdit("vSliderFOVFactorRight CBlack R1 ReadOnly w" l_iRightWidth, g_fFOVFactor)
	g_sliderFOVFactor := g_gui.AddSlider("AltSubmit Buddy1SliderFOVFactorLeft Buddy2SliderFOVFactorRight NoTicks Page2 Range1-20 x" l_iMiddleX
	                                     " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY - 2 " w" l_iMiddleWidth + 15, g_fFOVFactor * 10)
	g_cbGraphicNovelMode := g_gui.AddCheckbox("Checked" g_bGraphicNovelMode " x" l_iLeftX + 15 " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY, "Graphic novel mode")
	g_gui.AddLink("Right x" l_iLeftX + 10 " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY + 5 " w" l_iLeftWidth,
	              'Graphic novel mode <a href="https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes">key</a>')
	g_hkGraphicNovelModeKey := g_gui.AddHotkey("CBlack R1 x" l_iMiddleX + 10 " y" l_iTopY + l_iCurrentRow * l_iSpacingY " w" l_iMiddleWidth, g_sGraphicNovelModeKey)

	g_ddlGraphicNovelModeKey := g_gui.AddDropDownList("x" l_iRightX + 7 " y" l_iTopY + l_iSpacingY * l_iCurrentRow " w" l_iRightWidth, l_arrExtraKeys)
	g_ddlGraphicNovelModeKey.Text := IsExtraOption(g_sGraphicNovelModeKey) ? g_sGraphicNovelModeKey : "None"

	g_gui.AddText("Right x" l_iLeftX + 10 " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY + 5 " w" l_iLeftWidth, "Load save slot")
	g_ddlLoadSaveSlot := g_gui.AddDropDownList("Choose" Abs(g_iLoadSaveSlot) " x" l_iMiddleX + 10 " y" l_iTopY + l_iCurrentRow * l_iSpacingY
	                                           " w" l_iMiddleWidth, ["Disable", "Load last used", "Load most recent"])
	l_iTopY += 5
	g_cbUseGameFolderForSavegames := g_gui.AddCheckbox("Checked" g_bUseGameFolderForSavegames " x" l_iLeftX + 15 " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY,
	                                                   "Use game folder for savegames")
	g_cbWidescreenHud := g_gui.AddCheckbox("Checked" g_bWidescreenHud " x" l_iLeftX + 15 " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY, "Widescreen HUD")
	g_gui.AddText("vSliderWidescreenHudOffsetLeft", "Widescreen HUD offset")
	g_editWidescreenHudOffset := g_gui.AddEdit("vSliderWidescreenHudOffsetRight CBlack R1 ReadOnly w" l_iRightWidth, g_fWidescreenHudOffset)
	g_sliderWidescreenHudOffset := g_gui.AddSlider("AltSubmit Buddy1SliderWidescreenHudOffsetLeft Buddy2SliderWidescreenHudOffsetRight NoTicks Page10 Range10-200 x"
	                                               l_iMiddleX " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY " w" l_iMiddleWidth + 15, g_fWidescreenHudOffset)

	; Xbox rain droplets settings
	l_iTopY += l_iSpacingY + 27
	g_gbXbox := g_gui.AddGroupBox("h" l_iSpacingY * 9.7 " x" l_iLeftX - 7 " y" l_iTopY + l_iCurrentRow * l_iSpacingY - 5
	                              " w" l_iLeftWidth + l_iMiddleWidth + l_iRightWidth + l_iSpacingX * 4 + 15, "Xbox rain droplets")

	g_cbEnableXbox := g_gui.AddCheckbox("x" l_iLeftX + 15 " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY, "Enable Xbox rain droplets")
	g_cbEnableGravity := g_gui.AddCheckbox("Checked" g_bEnableGravity " x" l_iLeftX + 15 " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY, "Enable gravity")

	g_textMinSize := g_gui.AddText("vSliderMinSizeLeft", "Mininum size")
	g_editMinSize := g_gui.AddEdit("vSliderMinSizeRight CBlack R1 ReadOnly w" l_iRightWidth, g_iMinSize)
	g_sliderMinSize := g_gui.AddSlider("AltSubmit Buddy1SliderMinSizeLeft Buddy2SliderMinSizeRight NoTicks Range1-9 x" l_iMiddleX
	                                   " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY " w" l_iMiddleWidth + 15, g_iMinSize)

	g_textMaxDrops := g_gui.AddText("vSliderMaxDropsLeft", "Maximum drops")
	g_editMaxDrops := g_gui.AddEdit("vSliderMaxDropsRight CBlack R1 ReadOnly w" l_iRightWidth, g_iMaxDrops)
	g_sliderMaxDrops := g_gui.AddSlider("AltSubmit Buddy1SliderMaxDropsLeft Buddy2SliderMaxDropsRight NoTicks Page200 Range1000-10000 x" l_iMiddleX
	                                    " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY " w" l_iMiddleWidth + 15, g_iMaxDrops)

	g_textMaxMovingDrops := g_gui.AddText("vSliderMaxMovingDropsLeft", "Maximum moving drops")
	g_editMaxMovingDrops := g_gui.AddEdit("vSliderMaxMovingDropsRight CBlack R1 ReadOnly w" l_iRightWidth, g_iMaxMovingDrops)
	g_sliderMaxMovingDrops := g_gui.AddSlider("AltSubmit Buddy1SliderMaxMovingDropsLeft Buddy2SliderMaxMovingDropsRight NoTicks Page200 Range1000-10000 x" l_iMiddleX
	                                          " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY " w" l_iMiddleWidth + 15, g_iMaxMovingDrops)

	g_textMaxSize := g_gui.AddText("vSliderMaxSizeLeft", "Maximum size")
	g_editMaxSize := g_gui.AddEdit("vSliderMaxSizeRight CBlack R1 ReadOnly w" l_iRightWidth, g_iMaxSize)
	g_sliderMaxSize := g_gui.AddSlider("AltSubmit Buddy1SliderMaxSizeLeft Buddy2SliderMaxSizeRight NoTicks Page2 Range10-30 x" l_iMiddleX
	                                   " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY " w" l_iMiddleWidth + 15, g_iMaxSize)

	g_textMoveStep := g_gui.AddText("vSliderMoveStepLeft", "Move step")
	g_editMoveStep := g_gui.AddEdit("vSliderMoveStepRight CBlack R1 ReadOnly w" l_iRightWidth, g_fMoveStep)
	g_sliderMoveStep := g_gui.AddSlider("AltSubmit Buddy1SliderMoveStepLeft Buddy2SliderMoveStepRight NoTicks Page2 Range1-20 x" l_iMiddleX
	                                    " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY " w" l_iMiddleWidth + 15, g_fMoveStep * 10)

	g_textSpeedAdjuster := g_gui.AddText("vSliderSpeedAdjusterLeft", "Speed adjuster")
	g_editSpeedAdjuster := g_gui.AddEdit("vSliderSpeedAdjusterRight CBlack R1 ReadOnly w" l_iRightWidth, g_fSpeedAdjuster)
	g_sliderSpeedAdjuster := g_gui.AddSlider("AltSubmit Buddy1SliderSpeedAdjusterLeft Buddy2SliderSpeedAdjusterRight NoTicks Page2 Range1-20 x" l_iMiddleX
	                                         " y" l_iTopY + ++l_iCurrentRow * l_iSpacingY " w" l_iMiddleWidth + 15, g_fSpeedAdjuster * 10)

	; Events
	g_cbEnableXbox.OnEvent(              "Click", GuiCB_Click)
	g_ddlGraphicNovelModeKey.OnEvent(   "Change", GuiDDL_Change)
	g_hkGraphicNovelModeKey.OnEvent(    "Change", GuiHK_Change)
	g_sliderFOVFactor.OnEvent(          "Change", GuiSlider_Change)
	g_sliderMaxDrops.OnEvent(           "Change", GuiSlider_Change)
	g_sliderMaxMovingDrops.OnEvent(     "Change", GuiSlider_Change)
	g_sliderMaxSize.OnEvent(            "Change", GuiSlider_Change)
	g_sliderMinSize.OnEvent(            "Change", GuiSlider_Change)
	g_sliderMoveStep.OnEvent(           "Change", GuiSlider_Change)
	g_sliderSpeedAdjuster.OnEvent(      "Change", GuiSlider_Change)
	g_sliderWidescreenHudOffset.OnEvent("Change", GuiSlider_Change)
}

GuiDDL_Change(GuiCtrlObj, Info)
{
	switch GuiCtrlObj
	{
		case g_ddlResolution:
			global g_sResolution := g_ddlResolution.Text
		case g_ddlCustomGame:
			global g_sModName := g_ddlCustomGame.Text
		case g_ddlGraphicNovelModeKey:
			g_hkGraphicNovelModeKey.Value := g_ddlGraphicNovelModeKey.Value == 1 ? "" : g_ddlGraphicNovelModeKey.Text 
	}
}

GuiHK_Change(GuiCtrlObj, Info)
{
	; Turn MsgBox into a modal
	g_gui.Opt("+OwnDialogs")

	l_sHotkey := GuiCtrlObj.Value
	l_sHotkeyLength := StrLen(l_sHotkey)
	l_bShift := InStr(GuiCtrlObj.Value, "+")
	l_bControl := InStr(GuiCtrlObj.Value, "^")
	l_bAlt := InStr(GuiCtrlObj.Value, "!")

	if (l_bShift && !l_bControl && !l_bAlt && l_sHotkeyLength == 1)
		GuiCtrlObj.Value := "LShift"
	else if (!l_bShift && l_bControl && !l_bAlt && l_sHotkeyLength == 1)
		GuiCtrlObj.Value := "LControl"
	else if (!l_bShift && !l_bControl && l_bAlt && l_sHotkeyLength == 1)
		GuiCtrlObj.Value := "LAlt"
	else if (l_bShift || l_bControl || l_bAlt && l_sHotkeyLength > 1)
	{
		GuiCtrlObj.Value := ""
		MsgBox("You can't use modified keys!", , 48)
	}

	g_ddlGraphicNovelModeKey.Choose(1)
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

GuiSlider_Change(GuiCtrlObj, Info)
{
	switch GuiCtrlObj
	{
		case g_sliderFOVFactor:
			g_editFOVFactor.Text := Round(g_sliderFOVFactor.Value / 10.0, 1)
		case g_sliderWidescreenHudOffset:
			g_editWidescreenHudOffset.Text := Float(g_sliderWidescreenHudOffset.Value)
		case g_sliderMinSize:
			g_editMinSize.Text := g_sliderMinSize.Value
		case g_sliderMaxSize:
			g_editMaxSize.Text := g_sliderMaxSize.Value
		case g_sliderMaxDrops:
			g_editMaxDrops.Text := g_sliderMaxDrops.Value
		case g_sliderMaxMovingDrops:
			g_editMaxMovingDrops.Text := g_sliderMaxMovingDrops.Value
		case g_sliderMoveStep:
			g_editMoveStep.Text := Round(g_sliderMoveStep.Value / 10.0, 1)
		case g_sliderSpeedAdjuster:
			g_editSpeedAdjuster.Text := Round(g_sliderSpeedAdjuster.Value / 10.0, 1)
	}
}

GuiTab_Change(*)
{
	; Toggle Xbox rain droplets controls visibility
	if (g_tabs.Text == "Widescreen")
	{
		l_bXboxAsiFileExists := FileExist(g_sXboxAsiFile) || FileExist(g_sXboxAsiFile ".off")
		l_arrControlsXbox := [
			g_gbXbox, g_cbEnableXbox, g_cbEnableGravity,
			g_editMaxDrops, g_editMaxMovingDrops, g_editMaxSize, g_editMinSize, g_editMoveStep, g_editSpeedAdjuster,
			g_sliderMinSize, g_sliderMaxDrops, g_sliderMaxMovingDrops, g_sliderMaxSize, g_sliderMoveStep, g_sliderSpeedAdjuster,
			g_textMaxDrops, g_textMaxMovingDrops, g_textMaxSize, g_textMinSize, g_textMoveStep, g_textSpeedAdjuster
		]

		for l_ctrl in l_arrControlsXbox
			l_ctrl.Visible := l_bXboxAsiFileExists
	}
}

GuiUpdateWidescreen()
{
	global g_sWidescreenCfgFile := g_sGameDir "scripts\MaxPayne" (g_bMaxPayne2 ? "2" : "") ".WidescreenFix.ini"
	global g_sXboxAsiFile := g_sGameDir "scripts\MaxPayne" (g_bMaxPayne2 ? "2" : "") ".XboxRainDroplets.asi"
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
		g_hkGraphicNovelModeKey.Value := g_sGraphicNovelModeKey
		g_ddlLoadSaveSlot.Value := Abs(g_iLoadSaveSlot)
		g_cbUseGameFolderForSavegames.Value := g_bUseGameFolderForSavegames
		g_cbWidescreenHud.Value := g_bWidescreenHud
		g_sliderWidescreenHudOffset.Value := g_editWidescreenHudOffset.Value := g_fWidescreenHudOffset

		; Xbox
		g_cbEnableXbox.Value := FileExist(g_sXboxAsiFile) != ""
		g_cbEnableGravity.Value := g_bEnableGravity
		g_sliderMinSize.Value := g_editMinSize.Text := g_iMinSize
		g_sliderMaxDrops.Value := g_editMaxDrops.Text := g_iMaxDrops
		g_sliderMaxMovingDrops.Value := g_editMaxMovingDrops.Text := g_iMaxMovingDrops
		g_sliderMaxSize.Value := g_editMaxSize.Text := g_iMaxSize
		g_editMoveStep.Text := g_fMoveStep
		g_sliderMoveStep.Value := g_fMoveStep * 10
		g_editSpeedAdjuster.Text := g_fSpeedAdjuster
		g_sliderSpeedAdjuster.Value := g_fSpeedAdjuster * 10
	}
	; Delete the widescreen tab if it's no longer necessary
	else if (g_arrTabs.Length > 1)
	{
		g_tabs.Delete(2)
		; There are artifacts if we don't redraw the tabs after deleting one
		g_tabs.Redraw()
		g_arrTabs.Pop()
	}
}

Init()
{
	ReadConfigFile()
	GuiCreateGeneral()
	UpdateGame()
	if (!FindGameExe())
		MsgBox("File not found:`n`n" g_sGameDir g_sGameExe, "Error", 16)
	UpdateMods()

	if (g_bNoGUI)
		GuiButtonStart_Click()
	else
	{
		ReadWidescreenFixConfigFile()
		ReadXboxRainDropletsConfigFile()
		GuiCreateWidescreen()
		GuiUpdateWidescreen()
		g_gui.Show()
	}
}

IsExtraOption(p_sKey)
{
	; https://www.autohotkey.com/docs/v2/lib/If.htm#ExIfInContains
	return StrLower(p_sKey) ~= "i)\A(lbutton|mbutton|rbutton|xbutton1|xbutton2|space|tab|enter|escape|backspace)\z"
}

ReadConfigFile()
{
	global

	g_bMaxPayne2         := IniRead(g_sConfigFile, "General", "bMaxPayne2", true) == true
	g_sGameDir           := IniRead(g_sConfigFile, "General", "sGameDir", "C:\Program Files\Steam\steamapps\common\Max Payne 2\")
	g_iWidth             := IniRead(g_sConfigFile, "General", "iWidth", 2560)
	g_iHeight            := IniRead(g_sConfigFile, "General", "iHeight", 1440)
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

	; Clamping remaining variables
	g_iWidth := ClampType(g_iWidth, 2560, "int", 640, 10000)
	g_iHeight := ClampType(g_iHeight, 1440, "int", 480, 10000)
	g_sResolution := g_iWidth " x " g_iHeight
}

ReadWidescreenFixConfigFile()
{
	global

	g_sWidescreenCfgFile := g_sGameDir "scripts\MaxPayne" (g_bMaxPayne2 ? "2" : "") ".WidescreenFix.ini"

	; The widescreen fix INI includes non-standard // comments so we need to preserve and trim them
	g_arrWidescreenHud                 := StrSplit(IniRead(g_sWidescreenCfgFile, "MAIN", "WidescreenHud", true), "//", , 2)
	g_arrWidescreenHudOffset           := StrSplit(IniRead(g_sWidescreenCfgFile, "MAIN", "WidescreenHudOffset", 100.0), "//", , 2)
	g_arrFOVFactor                     := StrSplit(IniRead(g_sWidescreenCfgFile, "MAIN", "FOVFactor", 1.0), "//", , 2)
	g_arrGraphicNovelMode              := StrSplit(IniRead(g_sWidescreenCfgFile, "MAIN", "GraphicNovelMode", true), "//", , 2)
	g_arrGraphicNovelModeKey           := StrSplit(IniRead(g_sWidescreenCfgFile, "MAIN", "GraphicNovelModeKey", "0x71"), "//", , 2)
	g_arrCutsceneBorders               := StrSplit(IniRead(g_sWidescreenCfgFile, "MAIN", "CutsceneBorders", 2), "//", , 2)
	g_arrD3DHookBorders                := StrSplit(IniRead(g_sWidescreenCfgFile, "MAIN", "D3DHookBorders", true), "//", , 2)
	g_arrLoadSaveSlot                  := StrSplit(IniRead(g_sWidescreenCfgFile, "MISC", "LoadSaveSlot", -1), "//", , 2)
	g_arrUseGameFolderForSavegames     := StrSplit(IniRead(g_sWidescreenCfgFile, "MISC", "UseGameFolderForSavegames", false), "//", , 2)
	g_arrAllowAltTabbingWithoutPausing := StrSplit(IniRead(g_sWidescreenCfgFile, "MISC", "AllowAltTabbingWithoutPausing", true), "//", , 2)

	; Main
	g_bWidescreenHud                   := Trim(g_arrWidescreenHud[1]) == true
	g_fWidescreenHudOffset             := Trim(g_arrWidescreenHudOffset[1])
	g_fFOVFactor                       := Trim(g_arrFOVFactor[1])
	g_bGraphicNovelMode                := Trim(g_arrGraphicNovelMode[1]) == true
	g_sGraphicNovelModeKey             := Trim(g_arrGraphicNovelModeKey[1])
	g_bCutsceneBorders                 := Trim(g_arrCutsceneBorders[1]) == 2
	g_bD3DHookBorders                  := Trim(g_arrD3DHookBorders[1]) == true

	; Misc
	g_iLoadSaveSlot                    := Trim(g_arrLoadSaveSlot[1])
	g_bUseGameFolderForSavegames       := Trim(g_arrUseGameFolderForSavegames[1]) == true
	g_bAllowAltTabbingWithoutPausing   := Trim(g_arrAllowAltTabbingWithoutPausing[1]) == true

	; Clamping remaining variables
	g_fWidescreenHudOffset := ClampType(g_fWidescreenHudOffset, 100.0, "float", 10.0, 200.0)
	g_fFOVFactor := ClampType(g_fFOVFactor, 1.0, "float", 0.1, 2.0)
	g_iLoadSaveSlot := ClampType(g_iLoadSaveSlot, -1, "int", -3, -1)

	; Convert the GraphicNovelMode key to human readable format
	local l_sGraphicNovelModeKey := GetKeyName(StrReplace(g_sGraphicNovelModeKey, "0x", "vk"))
	g_sGraphicNovelModeKey := l_sGraphicNovelModeKey ? l_sGraphicNovelModeKey : "0x71"
}

ReadXboxRainDropletsConfigFile()
{
	global

	g_sXboxAsiFile := g_sGameDir "scripts\MaxPayne" (g_bMaxPayne2 ? "2" : "") ".XboxRainDroplets.asi"
	g_sXboxCfgFile := g_sGameDir "scripts\MaxPayne" (g_bMaxPayne2 ? "2" : "") ".XboxRainDroplets.ini"

	g_iMinSize        := IniRead(g_sXboxCfgFile, "MAIN", "MinSize", 4)
	g_iMaxSize        := IniRead(g_sXboxCfgFile, "MAIN", "MaxSize", 15)
	g_iMaxDrops       := IniRead(g_sXboxCfgFile, "MAIN", "MaxDrops", 3000)
	g_iMaxMovingDrops := IniRead(g_sXboxCfgFile, "MAIN", "MaxMovingDrops", 6000)
	g_bEnableGravity  := IniRead(g_sXboxCfgFile, "MAIN", "EnableGravity", true) == true
	g_fSpeedAdjuster  := IniRead(g_sXboxCfgFile, "MAIN", "SpeedAdjuster", 1.0)
	g_fMoveStep       := IniRead(g_sXboxCfgFile, "MAIN", "MoveStep", 0.1)

	; Clamping remaining variables
	g_iMinSize := ClampType(g_iMinSize, 4, "int", 1, 9)
	g_iMaxSize := ClampType(g_iMaxSize, 15, "int", 10, 30)
	g_iMaxDrops := ClampType(g_iMaxDrops, 3000, "int", 1000, 10000)
	g_iMaxMovingDrops := ClampType(g_iMaxMovingDrops, 6000, "int", 1000, 10000)
	g_fSpeedAdjuster := ClampType(g_fSpeedAdjuster, 1.0, "float", 0.1, 2.0)
	g_fMoveStep := ClampType(g_fMoveStep, 0.1, "float", 0.1, 2.0)
}

SaveSettings()
{
	try
	{
		l_arrResolution := StrSplit(g_sResolution, " x ")
		global g_iWidth := l_arrResolution[1]
		global g_iHeight := l_arrResolution[2]

		; Write to the registry
		RegWrite(g_iWidth,  "REG_DWORD", g_sGameRegKey "Video Settings", "Display Width")
		RegWrite(g_iHeight, "REG_DWORD", g_sGameRegKey "Video Settings", "Display Height")
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
			IniWrite(g_iWidth, g_sConfigFile,                    "General", "iWidth")
			IniWrite(g_iHeight, g_sConfigFile,                   "General", "iHeight")
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
			; Convert the GraphicNovelMode key back to hexadecimal format
			l_hkGraphicNovelModeKey := g_hkGraphicNovelModeKey.Value ? g_hkGraphicNovelModeKey.Value : "F2"
			l_hkGraphicNovelModeKey := Format("0x{:X}", GetKeyVK(l_hkGraphicNovelModeKey))

			; We need to add the comments we stored earlier

			; Main
			IniWrite(" " g_cbWidescreenHud.Value (g_arrWidescreenHud.Length > 1 ? " //" g_arrWidescreenHud[2] : ""), g_sWidescreenCfgFile, "MAIN", "WidescreenHud")
			IniWrite(" " g_editWidescreenHudOffset.Text (g_arrWidescreenHudOffset.Length > 1 ? " //" g_arrWidescreenHudOffset[2] : ""), g_sWidescreenCfgFile,
			         "MAIN", "WidescreenHudOffset")
			IniWrite(" " g_editFOVFactor.Text (g_arrFOVFactor.Length > 1 ? " //" g_arrFOVFactor[2] : ""), g_sWidescreenCfgFile, "MAIN", "FOVFactor")
			IniWrite(" " g_cbGraphicNovelMode.Value (g_arrGraphicNovelMode.Length > 1 ? " //" g_arrGraphicNovelMode[2] : ""), g_sWidescreenCfgFile,
			         "MAIN", "GraphicNovelMode")
			IniWrite(" " l_hkGraphicNovelModeKey (g_arrGraphicNovelModeKey.Length > 1 ? " //" g_arrGraphicNovelModeKey[2] : ""), g_sWidescreenCfgFile,
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
	g_sGameRegKey := "HKCU\Software\Remedy Entertainment\Max Payne" (g_bMaxPayne2 ? " 2\" : "\")
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

	; Recreate the entries in the mod drop-down list
	g_ddlCustomGame.Delete()
	g_ddlCustomGame.Add(g_arrModFiles)
	g_ddlCustomGame.Choose(g_sModName)
}
