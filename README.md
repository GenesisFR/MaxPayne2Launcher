# MaxPayne2Launcher
An AutoHotkey 2 script for Max Payne 1 and 2 that allows you to specify a resolution, launch mods, unlock all chapters/difficulties and use other options that are not available in the original launcher. It also supports the widescreen [fix](https://fusionfix.io/wfp#mp1) and Xbox rain droplets [plugin](https://github.com/ThirteenAG/XboxRainDroplets/releases/tag/maxpayne2) if they are detected.

It automates user interaction with the game launcher based on user-defined settings and comes with a config file to save settings on exit.

The `-nodialog` launch parameter (which skips the launcher but prevents the game from loading mods and creates other [problems](https://github.com/c6-dev/mp2fix)) will run the game launcher hidden instead, therefore bypassing the issues that normally come with it.

You can completely hide the GUI by setting `bNoGUI` to `1` in the config file. It'll be displayed if any error occurs.

The [Startup Hang Patch](https://community.pcgamingwiki.com/files/file/838-max-payne-series-startup-hang-patch/) is heavily recommended to reduce startup time.

<img width="1096" height="756" alt="image" src="https://github.com/user-attachments/assets/466a2f08-9506-40f9-8c70-1af32548351c" />
