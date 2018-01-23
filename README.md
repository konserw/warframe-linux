## Installation Instructions

Please be sure to install wine system dependencies. This can usually be achieved by installing wine on your system through your package manager.  Additional help can be found here:
[How to get out of Wine Dependency Hell](https://www.gloriouseggroll.tv/how-to-get-out-of-wine-dependency-hell/)

Option A: Download Lutris. If you have lutris already, please make sure it is updated to version 0.4.13 or higher, as older versions had problems running batch scripts.  Next, run my Lutris install script for warframe:  
[Lutris 0.4.13](https://lutris.net/downloads/)  
[Warframe Install Script for Lutris](https://lutris.net/games/warframe/)  

Option B: Without Lutris:  
1. Install wine-staging 2.17 (or higher) for your linux distribution.  

2. Download a copy of my warframe wine wrapper repo and extract it somewhere: [warframe-linux-master](https://github.com/GloriousEggroll/warframe-linux/archive/master.zip)  

3. Open the extracted folder in a terminal and:  

```shell
  chmod a+x warframe.sh
```

For a full install use the following command
```shell
  ./warframe.sh --install --install-system
```

`--install` creates the wine prefix and all the needed configuration files. `--install-system` installes the script in the system path and adds menu entries.


if you wish to use a different location for the wine bottle or the `Downloaded` folder specify them together with the `--install-system` flag. The installed script will use the user overrides. No need to manually edit the script
```shell
  ./warframe.sh --install-system --download-dir ~/Warframe/Downloaded --wine-prefix-dir ~/Warframe/wine_prefix
```

4. Launch the game via any of the following methods:  

```
  Applications>Games>Warframe
  Warframe desktop shortcut
  type "warframe" in a terminal
```

5. There will be a black box that comes up - this will update your warframe game. Let it run. When it finishes, the Launcher will run. Press play!  

## Uninstallation/Removal Instructions
This applies to non-lutris only: 

```shell
  ./warframe.sh --uninstall-system
```
or use the installed script
```shell
  warframe --uninstall-system
```

## 32bit vs 64bit

On default the script prepares and uses a 64bit wine environment. To use a 32bit environment add the `--32bit` flag
```shell
  ./warframe.sh --install --install-system --32bit
  warframe --32bit
  warframe --uninstall-system --32bit
```

## Debugging and hacking the wine environment
To start `winecfg` to check or modify some options by hand use the flag `--winecfg`
```shell
  warframe --winecfg
```

To start `regedit` to check or modify some options by hand use the flag `--regedit`
```shell
  warframe --regedit
```

To tell the script to print each executed command use the flag `--verbose`.

## Technical notes:  
Known issues:
Local Reflections cause graphical glitches. Motion blurring is broken, Depth of Field causes stuttering and does not work correctly. Leave them off.  

These settings are disabled in the launcher to prevent crashing and for better performance:  

```
  64-bit mode
  Launcher GPU Acceleration
  Multithreading (this is handled by csmt instead. Game's MT causes artifacting)
```

These settings are disabled by default to reduce gameplay stuttering and/or graphical glitches:  

```
  Vsync: OFF
  Local Reflections: OFF
  Local Reflection Blur: OFF
  Motion Blurring: OFF
  Depth of Field: OFF
```

You can set all other graphics settings as you wish.
