#!/bin/bash
# (C) Markus tech & ez corps // Nekomekoraiyuu (Ignore this LINE LMAOAOA)
# Rewrite / revision 1 : I had accidentialy deleted my previous script
# Init
##### VARIABLES SECTION #######
CONFIG_DIR=~/.config/skylined
SKYLINED_PATH=~/skylined
TEMP_PATH=~/skylined_installer_temp
EXIT_STATUS="NULL"
ERR_STANDARD="* Failed; Perhaps try checking your\ninternet connection and try again?"
LOOPING="true"
###### canary check #####
if [ "$1" = "--canary" ];
  then
      canary_build="true"
  else 
      canary_build="false"
fi
#############
######## Distro \\ CHECK #########
# Check if its wsl/Linux (Ubuntu distro)
if [ "$(grep -h "^ID=" /etc/os-release 2>/dev/null | cut -d "=" -f 2)" = "ubuntu" ];
	then
		# Then specify the distro name
		DISTRO_TYPE="ubuntu"
# Else if check if its termux
elif [ "$(echo -e "$TERMUX_VERSION" | sed 's/\.//g')" -ge "01180" ];
			then
				DISTRO_TYPE="termux"
elif [ "$(echo -e "$TERMUX_VERSION" | sed 's/\.//g')" -lt "01180" ];
			then
				DISTRO_TYPE="termux_outdated"
elif [ -z "$TERMUX_VERSION" ];
	then
			if [ "$(pwd | cut -d "/" -f 4)" = "com.termux" ];
				then
						DISTRO_TYPE="termux_old"
			fi
# Else the distro is unknown
else
	DISTRO_TYPE="unknown"
fi
##########
####### FUNCTIONS SECTION #########
# Make a function to check and install packages
stuff_inst () {
	# Make a variable that stores value from arg
	specified_pkg=$1
	# Check if the pkg is installed
	if [[ -z "$(apt list --installed 2> /dev/null | grep -oh "^$specified_pkg/" | cut -d "/" -f 1)" ]];
		then 
		  echo -e "$specified_pkg is not installed [ x ]; Installing"
			# If not installed  Check if that package is in the repository
			if [ "$(apt search $specified_pkg 2> /dev/null | grep -oh "^$specified_pkg/" | cut -d "/" -f 1)" = "$specified_pkg" ];
				then
					sleep 0.2			
					apt-get -y -o Dpkg::Options::="--force-confnew" install "$specified_pkg" 2> /dev/null
				else
				# If the package is not available in the repository then prompt the user to change
					echo -e "The package $specified_pkg is not available in your current repository.. Do you want to switch?\b[Enter] to switch, [no] to cancel switching; exit"
					read -re ASK_CHOICE
					if [[ -z "$ASK_CHOICE" ]];
						then
							#  Aaaaaaa
							if [ "$DISTRO_TYPE" = "termux" ];
								then
									termux-switch-repo
							elif [ "$DISTRO_TYPE" = "ubuntu" ];
								then
									echo -e "* Switching via cli is not implemented in this script;\nYou can change repository using GUI from settings in ubuntu"
									exit 1
							fi
							apt-get update 2> /dev/null
							apt-get -y -o Dpkg::Options::="--force-confnew" install $specified_pkg 2> /dev/null
						else
						echo -e "* Canceled switching repositories; The Package $specific_pkg is not available in current repository; Aborting installation"
						exit 1
					fi
			fi
			
	fi
	# Double check if it was installed
if [[ -z "$(apt list --installed 2> /dev/null | grep -oh "^$specified_pkg/" | cut -d "/" -f 1)" ]];
	then
 		echo -e "$specified_pkg was not installed [ x ]; aborting"
 		exit 1
 	else
 		echo -e "$specified_pkg has been installed [ √ ]"
fi
}
# Make a function that does clean up on exit
clean_exit () {
  if [ "$EXIT_STATUS" != "OK" ];
    then
       rm -rf $TEMP_PATH 2>/dev/null 
       # check if skylined was finished installing before
       if [ "$(cat $CONFIG_DIR/skylined_script.conf 2>/dev/null | grep -h "has_skylined_installer_finished_install=" | cut -d "=" -f 2)" != "true" ];
        then
         rm -rf $SKYLINED_PATH 2>/dev/null
       fi
       ### Remove Temporary downloaded file on interrupt (If using old termux version)
       if [ "$DISTRO_TYPE" = "termux_old" ];
       	then
       		rm -rf ~/termux_git.apk
       fi
     else
     rm -rf $TEMP_PATH 2>/dev/null
  fi
}
################
###### [ Main ] #######
# execute cleanup on exit
trap clean_exit EXIT
# Show header (skylined indeed)
clear
echo -e "\e[1mSkylined installer $(if [ "$canary_build" = "true" ]; then echo -e "\e[33mCANARY\e[39m"; fi) - nekomekoraiyuu &\n markus tech\n____________________\e[22m"
sleep 1
####### DISTRO CHECK ###### (again)
# If The uses uses old termux version do not start the script.
if [ "$DISTRO_TYPE" = "termux_old" ];
	then
		echo -e "* Old termux version detected (Last playstore release?);\nYou have to use the latest version of termux to install the script.;\nDo you want to download the recommended termux version? [Y/N]"
		while [ "$LOOPING" = "true" ];
			do
				# Read input
				read -rsn1 ASK_INPUT
				case $ASK_INPUT in
				[yY])
					# Check if newer version of termux was downloaded before
					if [ -z $(ls ~ | grep -oh "termux_git.apk") ];
						then
							echo -e "* Downloading the recommended termux version: 0.118.0 from Github;\nPlease wait..."
							sleep 0.5
							curl -SLo ~/termux_git.apk https://github.com/termux/termux-app/releases/download/v0.118.0/termux-app_v0.118.0+github-debug_universal.apk || { echo -e "* Failed to download!\nPlease try checking your internet connection."; rm -rf ~/termux_git.apk; exit 1; }
							echo -e "* Download successful!\nPlease allow access files permission to save the downloaded apk file to downloads directory."
							sleep 0.8
						else
							echo -e "* Downloaded newer version of termux found in ~ directory!;\nTrying to move it into downloads directory.."
							sleep 0.7
					fi
					# Check if storage dir exists
					if [ -z $(ls ~ | grep -oh "storage") ];
						then
							termux-setup-storage <<< y
					fi
					cp ~/termux_git.apk ~/storage/downloads/ || { echo -e "* Failed to copy to downloads directory; perhaps you haven't given termux access files permission?\nIf so please give access files permission and re-run the script!"; exit 1; }
					echo -e "* File has been saved to '[Internal Storage]/downloads/termux_git.apk' directory!;\nPlease uninstall the current termux app and install it from the saved directory."
					exit 0
					;;
				[nN])
					echo -e "* Cancelled. To get the latest termux version please use these official links;\nGithub: https://github.com/termux/termux-app/releases\nFdroid: https://f-droid.org/en/packages/com.termux/"
					exit 1
					;;
				esac
			done
# If use newer termux version then only print; Using termux
elif [ "$DISTRO_TYPE" = "termux" ];
	then
		echo -e "* Termux detected; Proceeding with the script."
		sleep 0.3
fi
### 
##### If wsl/Linux (Ubuntu) detected
if [ "$DISTRO_TYPE" = "ubuntu" ];
	then
		echo -e "* WSL/Linux (Ubuntu Distribution) detected; Proceeding with the script."
		# Check if running as root \\ sudo
		if [ "$EUID" -ne 0 ];
			then
				echo "* Please run the script as root! (use with sudo)"
				exit 1
		fi
elif [ "$DISTRO_TYPE" = "unknown" ];
	then
		echo -e "* WSL/Linux detected;\nbut looks like the script doesn't support your current distribution;\nPlease make a issue in the github repository to add support for your current distro.\nThank you--"
		exit 1
fi
#####
## Check if skylined was finished installing before
if [ "$(cat $CONFIG_DIR/skylined_script.conf 2>/dev/null | grep -h "has_skylined_installer_finished_install" | cut -d "=" -f 2)" = "true" ];
	then
		echo -e "* Looks like you had installed skylined before do you want to force reinstall it? (Which will remove existing skylined files and start from scratch.) Press [Y] to proceed $(echo '\\') Press [N] To Cancel."
		while [ "$LOOPING" = "true" ];
		do
		read -rsn 1 ASK_INPT
		if [[ "$ASK_INPT" = [yY] ]];
			then
				# If Yes then remove skylined, config directory
				rm -rf $SKYLINED_PATH 2>/dev/null
				rm -rf $CONFIG_DIR 2>/dev/null
				if [ "$DISTRO_TYPE" = "ubuntu" ];
					then
						rm -rf /bin/skylined 2>/dev/null
				elif [ "$DISTRO_TYPE" = "ubuntu" ];
					then
						rm -rf "$PATH/skylined" 2>/dev/null
				fi
				"* Successfully removed existing files, proceeding with the script!"
				break
		elif [[ "$ASK_INPT" = [nN] ]];
			then
				echo -e "* Cancelled." && exit 0
		fi
		done
fi
#####
####### Make a config directory if it simply doesnt exist
## If there is no config dir then make one
if [ -z $(ls ~/.config 2>/dev/null | grep -oh "skylined" ) ];
	then
		mkdir -p $CONFIG_DIR
fi
echo -e "---- SKYLINED-CONFIG ----\nhas_skylined_script_run_once=true\nhas_skylined_installer_finished_install=false\nhas_run_skylined_script_once=false\ncanary=false\nnameby_rom=titleid\nshow_console_logging=false" > $CONFIG_DIR/skylined_script.conf
echo -e "* Created config directory."
if [ "$1" = "--canary" ];
	then
		sed -i 's/canary=false/canary=true/' $CONFIG_DIR/skylined_script.conf
fi
#####
# Now do main stuff 
echo -e "* Updating available lists and installed packages [...]"
sleep 0.7
# Update termux packages since lets assume user has installed for the first time
apt-get update &> /dev/null || { echo -e "$ERR_STANDARD"; exit 1; }
apt-get -y -o Dpkg::Options::="--force-confnew" upgrade &> /dev/null || { echo -e "$ERR_STANDARD"; exit 1; }
# Then Start installing some required binaries
echo -e "* Installing required binaries; please wait [...]"
sleep 1
if [ "$DISTRO_TYPE" = "termux" ];
	then
		stuff_inst git
		stuff_inst vim
		stuff_inst micro
		stuff_inst clang
		stuff_inst make
		stuff_inst cmake
		stuff_inst binutils
		stuff_inst ncurses-utils
		stuff_inst tar
elif [ "$DISTRO_TYPE" = "ubuntu" ];
	then
		stuff_inst git
		stuff_inst xxd
		stuff_inst micro
		stuff_inst clang
		stuff_inst cmake
		stuff_inst make
		stuff_inst libncurses5-dbg
		stuff_inst binutils
fi
echo -e "* Done!"
sleep 0.3
echo -e "* Downloading skylined script.. $(if [ "$canary_build" = "true" ]; then echo -e "\e[33mCANARY-BRANCH\e[39m"; fi) [Please be patient]"
sleep 0.6
# clone skylined script from github
if [ "$canary_build" = "true" ];
  then
    git -C ~ clone -b canary https://github.com/nekomekoraiyuu/skylined --depth 1 &>/dev/null || { echo -e "$ERR_STANDARD"; exit 1; }
  else
    git -C ~ clone -b main https://github.com/nekomekoraiyuu/skylined --depth 1 &>/dev/null || { echo -e "$ERR_STANDARD"; exit 1; }
fi
###
echo -e "* Done!" && sleep 0.4
### todo
echo -e "* Now setting up skylined..."
# Setup a temporary directory
mkdir -p $TEMP_PATH
cd $TEMP_PATH
# clone hacpack and hactool 
echo -e "* Cloning hactool and hacpack..."
git clone https://github.com/SciresM/hactool ./hactool_source &>/dev/null || { echo -e "$ERR_STANDARD"; exit 1; }
git clone https://github.com/The-4n/hacPack ./hacpack_source &>/dev/null || { echo -e "$ERR_STANDARD"; exit 1; }
echo -e "* Done!" && sleep 0.4
# Setup hactool
echo -e "* Setting up hactool.."
sleep 0.4
cd ./hactool_source
git checkout c2c907430e674614223959f0377f5e71f9e44a4a &>/dev/null
mv config.mk.template config.mk
sed -i "372d" main.c
# start building
make || { echo -e "* Failed to build hactool! Please try again?"; exit 1; }
chmod +x hactool
mv hactool $SKYLINED_PATH/binaries/
echo -e "* Successfully set up hactool!"
cd ..
sleep 0.3
# Now setup hacpack
echo -e "* Setting up hacpack.."
cd ./hacpack_source
git checkout 7845e7be8d03a263c33430f9e8c2512f7c280c88 &>/dev/null
mv config.mk.template config.mk
# Start building hacpack
make || { echo -e "* Failed to build hacpack! Please try again?"; exit 1; }
chmod +x hacpack
mv hacpack $SKYLINED_PATH/binaries/
cd ~
# finished setting up now remove temp directory
rm -rf $TEMP_PATH
# setup skylined shortcut
if [ "$DISTRO_TYPE" = "termux" ];
  then
    echo -e "#!/bin/bash\nbash ~/skylined/skylined_main.sh" > "$PATH/skylined"
    chmod +x "$PATH/skylined"
elif [ "$DISTRO_TYPE" = "ubuntu" ];
  then
    echo -e "#!/bin/bash\nbash ~/skylined/skylined_main.sh" > "/bin/skylined"
    chmod +x "/bin/skylined"
fi
echo -e "* Everything is done!\nYou can now launch the script by typing\n\e[34mskylined\e[39m in the terminal!"
# Update config file and Exit since the script is finished
sed -i 's/has_skylined_installer_finished_install=false/has_skylined_installer_finished_install=true/' $CONFIG_DIR/skylined_script.conf
exit 0
# Done installing
