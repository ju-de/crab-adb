#!/bin/bash

adb="$ANDROID_HOME/platform-tools/adb"

DEVICEIDS=($($adb devices 2> /dev/null | sed '1,1d' | sed '$d' | cut -f 1 | sort)) 
DEVICEINFO=()
SELECTEDIDS=()
SELECTEDINFO=()
FILTERS=("-d" "-e" "-a" "-ad" "-ae")
COMMANDS=("help" "l" "s" "t" "i")

selection=true # Toggles device selection
flag=$2 # Command flag
selectedCommand="" # Method to be executed on devices
adbCommand=$(echo $@ | cut -d " " -f2-) # ADB command flag
textInput=$3
apkFile=$3
packageName=""

runAdb() {
	$adb -s ${SELECTEDIDS[i]} $adbCommand 2> /dev/null
	if [[ $(echo $?) == 1 ]]; then
		crabHelp
		exit 1
	fi
}

# Shows the user how to use the script
crabHelp() {
	echo "Crab Version 0.1 using $($adb help 2>&1)"
}

# Checks to see if ANDROID_HOME has been set
checkAndroidHome() {
	$adb version >/dev/null 2>&1
	error=$?
	if [[ -z $ANDROID_HOME ]]; then
		echo "ANDROID_HOME variable is not found in the PATH."
		exit 1
	elif [[ $error == 127 ]]; then
		echo "ANDROID_HOME is found at $ANDROID_HOME, but adb command is not found."
		echo "Ensure the correct installation of Android SDK."
		exit 1
	fi
}

# Executes command on selected devices
executeCommand() {
	if [[ ${#SELECTEDIDS[@]} > 1 ]]; then
		for i in ${!SELECTEDIDS[@]}; do { # Execute command in the background
			$selectedCommand
		} &	
		done; wait
	else
		$selectedCommand # Execute command normally
	fi
}

# Adds connected devices to a global array (modified code from superInstall)
getDeviceInfo() {
	if [[ ${#DEVICEIDS[@]} == 0 ]]; then 
		echo 'No devices detected!' 
		echo 'Troubleshooting tips if device is plugged in:'
		echo ' - USB Debugging should be enabled on the device.'
		echo ' - Execute in terminal "adb kill-server"'
		echo ' - Execute in terminal "adb start-server"'
		exit 1
	else
		echo 'Number of devices found:' ${#DEVICEIDS[@]}
		for i in ${!DEVICEIDS[@]}; do
			DEVICEINFO+=("$(echo "$($adb -s ${DEVICEIDS[i]} shell "getprop ro.product.manufacturer && getprop ro.product.model && getprop ro.build.version.release" | tr -d '\r')" | tr '\n' ' ')")
		done
	fi			
}

# Gets all physical devices
getRealDevices() {
	DEVICEIDS=($($adb devices | sed '1,1d' | sed '$d' | cut -f 1 | sort | grep -v '^emu')) 
	getDeviceInfo
}

# Gets all emulators
getEmulators() {
	DEVICEIDS=($($adb devices | sed '1,1d' | sed '$d' | cut -f 1 | sort | grep '^emu')) 
	getDeviceInfo
}

# Outputs connected devices
crabList() {
    for i in ${!DEVICEIDS[@]}; do
        printf "%3d%s) %s" $((i+1)) "${choices[i]:- }" 
        echo ${DEVICEINFO[i]} ${DEVICEIDS[i]}
    done
    [[ "$msg" ]] && echo $msg; :
}

# Prompts user to select a device if multiple are connected
crabSelect() {
	if [[ $selection == true ]]; then
		if [[ ${#DEVICEIDS[@]} == 1 ]]; then
				echo 'Selected the only detected device:' ${DEVICEINFO[0]} ${DEVICEIDS[0]}
				SELECTEDIDS=${DEVICEIDS[0]}
				SELECTEDINFO=${DEVICEINFO[0]}
		else
			# Modified code from http://serverfault.com/questions/144939/multi-select-menu-in-bash-script
			echo "Multiple devices connected. Please select from the list:"
			echo "  0 ) All devices"
			prompt="Input an option to select (Input again to deselect; hit ENTER key when done): "
			while crabList && read -rp "$prompt" num && [[ "$num" ]]; do
				echo "  0 ) All devices"
			    if [[ $num == 0 ]]; then 
			    	while [[ $num < ${#DEVICEIDS[@]} ]]; do
			    		choices[num]="+"
			    		num=$((num+1))
			    	done
			    	msg="All devices were selected"
			    else
				    [[ "$num" != *[![:digit:]]* ]] &&
				    (( num >= 0 && num <= ${#DEVICEIDS[@]} )) ||
				    { msg="Invalid option: $num"; continue; }
				    ((num--)); msg="${DEVICEINFO[num]} ${DEVICEIDS[num]} was ${choices[num]:+de}selected"
				    [[ "${choices[num]}" ]] && choices[num]="" || choices[num]="+"
			    fi
			done

			echo "You selected:"; msg=" nothing"
			for i in ${!DEVICEIDS[@]}; do 
			    [[ "${choices[i]}" ]] && { 
				    echo ${DEVICEINFO[i]} ${DEVICEIDS[i]}; 
				    msg=""; 
				    SELECTEDIDS+=(${DEVICEIDS[i]});
				    SELECTEDINFO+=("${DEVICEINFO[i]}");
				}
			done
			echo "$msg"
			if [[ ${#SELECTEDIDS[@]} < 1 ]]; then
				exit 1
			fi
		fi
	fi
}

# Takes a screenshot on selected devices (modified code from superadb)
crabScreenshot() {
	timestamp=$(date +"%I-%M-%S")
	echo 'Taking screenshot on' ${SELECTEDINFO[i]}
	# Credit to thttp://www.growingwiththeweb.com/2014/01/handy-adb-commands-for-android.html for screenshot copying directly to the current directory
	$adb -s ${SELECTEDIDS[i]} shell screencap -p | perl -pe 's/\x0D\x0A/\x0A/g' >> "${SELECTEDINFO[i]}"-$timestamp-"screenshot.png"
	echo 'Successfully took screenshot on' ${SELECTEDINFO[i]} '@' $timestamp
}

# Inputs text on connected devices (modified code from superadb)
crabType() {
	if [[  -z "$textInput"  ]]; then
			echo 'Text input stream is empty.'
			echo ''
			echo 'Enter text like this:'
			echo '     crab -t "Enter text here"'
			echo 'If quotes are not used, then only the first word will be typed.'
			exit 1
	else
		echo 'Entering text on' ${SELECTEDINFO[i]}
		parsedText=${textInput// /%s} # Replaces all spaces with %s
		$adb -s ${SELECTEDIDS[i]} shell input text $parsedText
		echo 'Successfully entered text on' ${SELECTEDINFO[i]}
	fi
}

# Installs the specified .apk file to selected devices (modified code from superInstall)
crabInstall() {
 	if ! test -e "$1" ; then 
		echo "Please specify an existing .apk file."
		exit 1
	elif [[ ${1: -3} == "apk" ]] ; then
		packageName=`aapt dump badging $1 | grep package: | cut -d "'" -f 2`
		echo "Installing $packageName to" ${SELECTEDINFO[i]}		
		$adb -s ${SELECTEDIDS[i]} install -r $1 >> /dev/null # -r for overinstall
		# $adb -s ${SELECTEDIDS[i]} shell am start -a android.intent.action.MAIN -n $packageName/$(aapt dump badging $1 | grep launchable | cut -d "'" -f 2) >> /dev/null
		echo "Successfully installed $packageName to" ${SELECTEDINFO[i]}
	else
		echo "The application file is not an .apk file; Please specify a valid application file."
		exit 1
	fi
}

# Main Procedure
#================

checkAndroidHome

if [[ $1 == ${FILTERS[0]} ]]; then # -d
	getRealDevices
elif [[ $1 == ${FILTERS[1]} ]]; then # -e
	getEmulators
elif [[ $1 == ${FILTERS[2]} ]]; then # -a
	getDeviceInfo
	SELECTEDIDS=("${DEVICEIDS[@]}")
	SELECTEDINFO=("${DEVICEINFO[@]}")
	selection=false
elif [[ $1 == ${FILTERS[3]} ]]; then # -ad
	getRealDevices
	SELECTEDIDS=("${DEVICEIDS[@]}")
	SELECTEDINFO=("${DEVICEINFO[@]}")
	selection=false
elif [[ $1 == ${FILTERS[4]} ]]; then # -ae
	getEmulators
	SELECTEDIDS=("${DEVICEIDS[@]}")
	SELECTEDINFO=("${DEVICEINFO[@]}")
	selection=false
else
	getDeviceInfo
	flag=$1
	textInput=$2
	apkFile=$2
	adbCommand=$@
fi

# Command selection
if [[ $flag == ${COMMANDS[0]} ]]; then # help
	crabHelp
	exit 0
elif [[ $flag == ${COMMANDS[1]} ]]; then # l
	crabList
	exit 0
elif [[ $flag == ${COMMANDS[2]} ]]; then # s
	selectedCommand="crabScreenshot"
elif [[ $flag == ${COMMANDS[3]} ]]; then # t
	selectedCommand="crabType"
elif [[ $flag == ${COMMANDS[4]} ]]; then # i
	selectedCommand="crabInstall $apkFile"
else
	selectedCommand="runAdb" # If not a crab command, execute as adb command 
fi

crabSelect
executeCommand