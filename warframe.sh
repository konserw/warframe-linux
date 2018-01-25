#!/bin/bash
# exit on first error
set -e

function print_synopsis {
	echo "$0 [options]"
	echo ""
	echo "options:"
	echo "    --download-dir      override default download_dir variable"
	echo "    --wine-prefix       override default wine_prefix_base variable"
	echo "    --video-ram         override default video_memory_size variable"
	echo "    --email             override default user_email variable"
	echo "    --winecfg           start winecfg with the current wine bottle"
	echo "    --regedit           start regedit with the current wine bottle"
	echo "    -w, --winetricks    install packages to wine bottle, don't launch game"
	echo "    -r, --registry      update wine registry, don't launch game"
	echo "    -c, --config        create basic warframe configuration file inside wine bottle"
	echo "    -i, --install       same as defining"
	echo "                        '--winetricks --registry and --config"
	echo "    --install-bin       install script to /usr/bin (uses sudo for root access)."
	echo "                        Replaces 'download_dir' and 'wine_prefix_base' with"
	echo "                        overrides."
	echo "    --menu-shortcut     create menu entry (uses sudo for root access)"
	echo "    --desktop-shortcut  create desktop shortcut (requires --menu-shortcut"
	echo "                        for installation of warframe icon)"
	echo "    --install-system    same as defining"
	echo "                        '--install-bin --menu-shortcut and --desktop-shortcut'"
	echo "    --uninstall-system  remove all the files installed by --install-system"
	echo "    -u, --update        use Warframe executable to update downloaded game files."
	echo "                        Use when launcher fails to update the files."
	echo "    --32bit             use 32bit wine bottle and 32bit Warframe"
	echo "    -v, --verbose       print each executed command"
	echo "    -h, --help          print this help message and quit"
}

#############################################################
# user defined constants
#############################################################
# wine bottles, script will append '_amd64' or '_i386'
wine_prefix_base="/home/$USER/Games/Warframe/wine_prefix" 

# specify the download folder, where all the game files are
download_dir="/home/$USER/Games/Warframe/Downloaded"

# Video RAM of your GPU
video_memory_size=2048
# your email, used in basic warframe config creation
user_email=""

#############################################################
# default values
#############################################################
start_game=true
use_x64=true

#############################################################
# parse command line arguments
#############################################################
# As long as there is at least one more argument, keep looping
while [[ $# -gt 0 ]]; do
	key="$1"
	case "$key" in
		--wine-prefix)
		if [ -z "$2" ]; then
			echo "option '$key' needs a value"
			print_synopsis
			exit 1
		fi
		wine_prefix_base="$2"
		shift # past argument
		;;
		--download-dir)
		if [ -z "$2" ]; then
			echo "option '$key' needs a value"
			print_synopsis
			exit 1
		fi
		download_dir="$2"
		shift # past argument
		;;
		--video-ram)
		if [ -z "$2" ]; then
			echo "option '$key' needs a value"
			print_synopsis
			exit 1
		fi
		video_memory_size="$2"
		shift # past argument
		;;
		--email)
		if [ -z "$2" ]; then
			echo "option '$key' needs a value"
			print_synopsis
			exit 1
		fi
		user_email="$2"
		shift # past argument
		;;
		--winecfg)
		start_winecfg=true
		;;
		--regedit)
		start_regedit=true
		;;
		-w|--winetricks)
		do_winetricks=true
		start_game=false
		;;
		-r|--registry)
		do_registry=true
		start_game=false
		;;
		-c|--config)
		do_config=true
		start_game=false
		;;
		-i|--install)
		do_winetricks=true
		do_registry=true
		do_config=true
		start_game=false
		;;
		-u|--update)
		do_update=true
		;;
		--install-bin)
		do_install_bin=true
		start_game=false
		;;
		--menu-shortcut)
		do_menu_shortcut=true
		start_game=false
		;;
		--desktop-shortcut)
		do_desktop_shortcut=true
		start_game=false
		;;
		--install-system)
		do_install_bin=true
		do_menu_shortcut=true
		do_desktop_shortcut=true
		start_game=false
		;;
		--uninstall-system)
		do_uninstall_system=true
		start_game=false
		;;
		--32bit)
		use_x64=false
		;;
		-v|--verbose)
		verbose=true
		;;
		-h|--help)
		print_synopsis
		exit 0
		;;
		*)
		echo "Unknown option '$key'"
		print_synopsis
		exit 1
		;;
	esac
	# Shift after checking all the cases to get the next option
	shift
done

# show all executed commands
if [ "$verbose" = true ] ; then
	set -x
fi

#############################################################
# define variables
#############################################################
export PULSE_LATENCY_MSEC=60
# without this I get about 30 to 40 fps instead of 15 to 30
#export __GL_THREADED_OPTIMIZATIONS=1

export MSI="${download_dir}/Public/Warframe.msi"
warframe_exe_base="${download_dir}/Public"

# distinction between 32bit and 64bit
if [ "$use_x64" = true ] ; then
	export WINEPREFIX="${wine_prefix_base}_amd64"
	export WINEARCH=win64
	export WARFRAME="${warframe_exe_base}/Warframe.x64.exe"
	WINE=wine64
else
	export WINEPREFIX="${wine_prefix_base}_i386"
	export WINEARCH=win32
	export WARFRAME="${warframe_exe_base}/Warframe.exe"
	WINE=wine
fi

# folder where warframe saves its configuration and launcher
warframe_config_dir="${WINEPREFIX}/drive_c/users/${USER}/Local Settings/Application Data/Warframe"
config_file="${warframe_config_dir}/EE.cfg"

#############################################################
# start specified program and then exit, good for debugging
#############################################################
if [ "$start_winecfg" = true ] ; then
	echo "calling winecfg and exit this script afterwards"
	winecfg
	exit 0
fi
if [ "$start_regedit" = true ] ; then
	echo "calling regedit and exit this script afterwards"
	regedit
	exit 0
fi

#############################################################
# essential wine-prefix preparation
#############################################################
if [ "$do_winetricks" = true ] ; then
	echo "using winetricks to install needed packages"
	# - winetricks for Warframe
	# with wine 2.21-staging only those two packages are needed
	# 20180105 - add win7: with winXP only dx9 is supported, with win7 dx10 is available
	winetricks -q vcrun2015 xact win7
	# from the lutris installer the following packages were installed
	#winetricks -q vcrun2015 xact xinput win7 hosts
fi

#############################################################
# update wine registry
#############################################################
if [ "$do_registry" = true ] ; then
	reg_file="/tmp/wf.reg"
	# transform absolute linux path to absolute Windows path for registy
	download_dir_windows="z:$(echo "${download_dir}" | sed 's/\//\\\\/g')"
	echo "update windows registry, creating temporary file at '$reg_file'"
	if [ "$use_x64" = true ] ; then
		Enable64Bit="dword:00000001"
	else
		Enable64Bit="dword:00000000"
	fi
	# create registry file
	cat <<EOF > "$reg_file"
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\\Software\\Digital Extremes\\Warframe\\Launcher]
"APR2007_xinput_x64.cab"="743B333C2DB3D4CF190FB39C29F3C346"
"APR2007_xinput_x86.cab"="C234DF417C9B12E2D31C7FD1E17E4786"
"DownloadDir"="${download_dir_windows}"
"DSETUP.dll"="9E0711BED229B60A853BCC5D10DEAAFC"
"dsetup32.dll"="0F58CCD58A29827B5D406874360E4C08"
"DXSETUP.exe"="DDCE338BB173B32024679D61FB4F2BA6"
"dxupdate.cab"="8ADF5A3C4BD187052BFA92B34220F4E7"
"Enable64Bit"=${Enable64Bit}
"EnableAggressiveDownload"=dword:00000001
"EnableBulkDownload"=dword:00000000
"EnableDirectX10"=dword:00000001
"EnableDirectX11"=dword:00000000
"EnableFullScreen"=dword:00000000
"EnableMTRendering"=dword:00000000
"Jun2010_XAudio_x64.cab"="EDEB828A8E54A9F3851007D80BC8DD6E"
"Jun2010_XAudio_x86.cab"="9D2DA3B1055120AF7C2995896F5D51ED"
"Language"="en"
"LauncherExe"="C:\\\\users\\\\${USER}\\\\Local Settings\\\\Application Data\\\\Warframe\\\\Downloaded\\\\Public\\\\Tools\\\\Launcher.exe"
"LauncherGPU"=dword:00000000
"LauncherStats"=dword:00000000
"Oct2005_xinput_x64.cab"="C39E4358CEA9538AB1D4B842DA669BC6"
"Oct2005_xinput_x86.cab"="B296431A5DFFF596FEF2F04B4F36362A"
"ReadCba"="9CBC69E1D9AE2874F4D1AF57A19AE923"
"ReadEula"="ECFEC2AEE8054A9E7665DBD03D1DE6A1"
"ServerCluster"=dword:00000000
"UpdateVersion"=dword:00000016
"VerifyVersionPublic"=dword:00000002

[HKEY_CURRENT_USER\\Software\\Wine\\DllRedirects]
 "wined3d"="wined3d-csmt.dll"

[HKEY_CURRENT_USER\\Software\\Wine\\Direct3D]
"OffscreenRenderingMode"="fbo"
"RenderTargetLockMode"="readtex"
"StrictDrawOrdering"="disabled"
"VideoMemorySize"="${video_memory_size}"

[HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides]
"rasapi32"="native"
"d3dcompiler_43"="native,builtin"
"d3dcompiler_47"="native,builtin"
EOF
	# update registry to set warframe download folder and other wine options
	$WINE regedit /S "${reg_file}"
fi

#############################################################
# create warframe config file
#############################################################
if [ "$do_config" = true ] ; then
	echo "create basic configuration file '$config_file'"
	# create folder if they don't exist
	mkdir -p "$warframe_config_dir"
	# write basic configurations
	cat <<EOF > "$config_file"
+nowarning
+version=5

[KeyBindings,/EE/Types/Input/KeyBindings]

[LotusDedicatedServerAccountSettings,/Lotus/Types/Game/DedicatedServerAccountSettings]
email=

[LotusWindows_KeyBindings,/Lotus/Types/Input/KeyBindings]

[Windows_Config,/EE/Types/Base/Config]
Stats.Visible=1
Graphics.AnisotropicFiltering=AF_NONE
Graphics.AntiAliasing=AA_FXAA
Graphics.AutoDetectGraphicsSettings=0
Graphics.BlurLocalReflections=0
Graphics.Borderless=1
Graphics.Brightness=1.4540318
Graphics.Contrast=0.99721003
Graphics.DynamicLighting=0
Graphics.DynamicResolution=DYNRES_USER
Graphics.EnableColorCorrection=0
Graphics.EnableDOF=0
Graphics.EnableHDR=0
Graphics.EnableMotionBlur=0
Graphics.EnableScreenShake=0
Graphics.EnableVolumetricLighting=0
Graphics.GeometryDetail=GD_LOW
Graphics.LocalReflections=0
Graphics.LowShaderQuality=1
Graphics.MaxFrameRate=200
Graphics.ParticleSysQuality=PQ_LOW
Graphics.ShadowQuality=SQ_LOW
Graphics.VSyncMode=VSM_NEVER_SYNC
Flash.FlashDrawScale=0.75108659
Flash.FlashDrawScaleMode=MSM_CUSTOM
Client.Email=${user_email}
EOF
fi

#############################################################
# install-system section
#############################################################
if [ "$do_install_bin" = true ] ; then
	system_bin_file="/usr/bin/warframe"
	tmp_bin_file="/tmp/warframe"
	cp "$0" "$tmp_bin_file"
	# replace default values with the overridden ones
	sed -i '/^wine_prefix_base=/s#.*#'"wine_prefix_base=\"${wine_prefix_base}\"#" "${tmp_bin_file}"
	sed -i '/^download_dir=/s#.*#'"download_dir=\"${download_dir}\"#" "${tmp_bin_file}"
	sed -i '/^video_memory_size=/s#.*#'"video_memory_size=\"${video_memory_size}\"#" "${tmp_bin_file}"
	sed -i '/^user_email=/s#.*#'"user_email=\"${user_email}\"#" "${tmp_bin_file}"
	echo "installing this script as '${system_bin_file}'"
	# install script in search path
	sudo cp "$tmp_bin_file" "$system_bin_file"
fi

# variables for desktop file creation
menu_tmp_file="/tmp/warframe.desktop"
applications_dir="/usr/share/applications"
desktop_icon="/usr/share/pixmaps/warframe.png"
if [ "$use_x64" = true ] ; then
	desktop_name="Warframe 64bit"
	desktop_exec="/usr/bin/warframe \"\$@\""
	menu_file="${applications_dir}/warframe64.desktop"
	desktop_file="/home/$USER/Desktop/warframe64.desktop"
else
	desktop_name="Warframe 32bit"
	desktop_exec="/usr/bin/warframe --32bit \"\$@\""
	menu_file="${applications_dir}/warframe32.desktop"
	desktop_file="/home/$USER/Desktop/warframe32.desktop"
fi
function create_desktop_file {
	cat <<EOF > "$menu_tmp_file"
[Desktop Entry]
Encoding=UTF-8
Name=${desktop_name}
GenericName=Warframe
Warframe
Exec=${desktop_exec}
Icon=${desktop_icon}
StartupNotify=true
Terminal=false
Type=Application
Categories=Application;Game
EOF
}

if [ "$do_menu_shortcut" = true ] ; then
	echo "copy warframe icon to '${desktop_icon}'"
	sudo cp warframe.png ${desktop_icon}

	echo "creating menu shortcut for warframe at '${menu_file}'"
	# create temporary desktop entry file
	create_desktop_file
	# copy desktop entry file to its right position
	sudo cp "$menu_tmp_file" "$menu_file"
fi

if [ "$do_desktop_shortcut" = true ] ; then
	echo "creating desktop shortcut at '${desktop_file}'"
	# create temporary desktop entry file
	create_desktop_file
	# copy desktop entry file to the desktop
	cp "$menu_tmp_file" "$desktop_file"
fi

#############################################################
# uninstall files installed by --install-system
#############################################################
if [ "$do_uninstall_system" = true ] ; then
	echo "removing icon file '${desktop_icon}'"
	sudo rm -f "$desktop_icon"
	echo "removing menu file '${menu_file}'"
	sudo rm -f "$menu_file"
	echo "removing desktop file '${desktop_file}'"
	rm -f "$desktop_file"
	echo "removing script '${system_bin_file}'"
	sudo rm -f "$menu_file"
fi

#############################################################
# update game files
#############################################################
# use warframe exe to update game files
# use if launcher fails to do so
if [ "$do_update" = true ] ; then
	echo "updating Warframe files"
	# download most recent msi file from the official website
	wget "http://content.warframe.com/dl/Warframe.msi" -O "$MSI"
	# use warframe executable to update the game files
	$WINE "${WARFRAME}" -silent -log:/Preprocessing.log -dx10:1 -dx11:0 -threadedworker:1 -cluster:public -language:en -applet:/EE/Types/Framework/ContentUpdate
fi

#############################################################
# actually start the game
#############################################################
if [ "$start_game" = true ] ; then
	if [ "$verbose" = true ] ; then
		export WINEDEBUG=""
	else
		export WINEDEBUG=-all
	fi
	#WINEDEBUG=-all wine64 "${LAUNCHER}"
	# start MSI file instead of launcher, because launcher.exe can't replace itself under wine and loops forever
	$WINE msiexec /i "${MSI}"
fi

