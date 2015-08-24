#!/bin/bash

adb="$ANDROID_HOME/platform-tools/adb"

DEVICEIDS=($($adb devices 2> /dev/null | sed '1,1d' | sed '$d' | cut -f 1 | sort)) 
DEVICEINFO=()
SELECTEDIDS=()
SELECTEDINFO=()

selection=true # Toggles device selection
flag="" # Command flag
adbCommand="" # ADB command flag
runAdb=false
textInput=""
FILTERS=("-d" "-e" "-a" "-ad" "-ae")
COMMANDS=("help" "l" "s" "t" "i")

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
		fi
	fi
}

# Takes a screenshot on connected devices (modified code from superadb)
crabScreenshot() {
	timestamp=$(date +"%I-%M-%S")
	# Credit to thttp://www.growingwiththeweb.com/2014/01/handy-adb-commands-for-android.html for screenshot copying directly to the current directory
	$adb -s ${SELECTEDIDS[i]} shell screencap -p | perl -pe 's/\x0D\x0A/\x0A/g' >> "${SELECTEDINFO[i]}"-$timestamp-"screenshot.png"
	echo 'Took screenshot on:' ${SELECTEDINFO[i]} ${SELECTEDIDS[i]} '@' $timestamp
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
	fi
}

# Main Procedure
#================

checkAndroidHome

if [[ $1 == ${FILTERS[0]} ]]; then # -d
	getRealDevices
	flag=$2
	textInput=$3
	adbCommand=$(echo $@ | cut -d " " -f2-)
elif [[ $1 == ${FILTERS[1]} ]]; then # -e
	getEmulators
	flag=$2
	textInput=$3
	adbCommand=$(echo $@ | cut -d " " -f2-)
elif [[ $1 == ${FILTERS[2]} ]]; then # -a
	getDeviceInfo
	SELECTEDIDS=("${DEVICEIDS[@]}")
	SELECTEDINFO=("${DEVICEINFO[@]}")
	selection=false
	flag=$2
	textInput=$3
	adbCommand=$(echo $@ | cut -d " " -f2-)
elif [[ $1 == ${FILTERS[3]} ]]; then # -ad
	getRealDevices
	SELECTEDIDS=("${DEVICEIDS[@]}")
	SELECTEDINFO=("${DEVICEINFO[@]}")
	selection=false
	flag=$2
	textInput=$3
	adbCommand=$(echo $@ | cut -d " " -f2-)
elif [[ $1 == ${FILTERS[4]} ]]; then # -ae
	getEmulators
	SELECTEDIDS=("${DEVICEIDS[@]}")
	SELECTEDINFO=("${DEVICEINFO[@]}")
	selection=false
	flag=$2
	textInput=$3
	adbCommand=$(echo $@ | cut -d " " -f2-)
else
	getDeviceInfo
	flag=$1
	textInput=$2
	adbCommand=$@
fi

# Commands that don't need device selection
if [[ $flag == ${COMMANDS[0]} ]]; then # help
	crabHelp
	exit 0
elif [[ $flag == ${COMMANDS[1]} ]]; then # l
	crabList
	exit 0
fi

# Commands that need device selection
crabSelect

for i in ${!SELECTEDIDS[@]}; do {
	if [[ $flag == ${COMMANDS[2]} ]]; then # s
		crabScreenshot
	elif [[ $flag == ${COMMANDS[3]} ]]; then # t
		crabType
	elif [[ $flag == ${COMMANDS[4]} ]]; then # i
		setAppFile "$2"
		crabInstall
	else
		runAdb=true
	fi
} &
done; wait

# If not a crab command, execute as adb command 
if [[ $runAdb == true ]]; then
	for i in ${!SELECTEDIDS[@]}; do
		$adb -s ${SELECTEDIDS[i]} $adbCommand 2> /dev/null

		if [[ $(echo $?) == 1 ]]; then
			crabHelp
			exit 1
		fi
	done
fi