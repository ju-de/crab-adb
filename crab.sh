#!/bin/bash

adb="$ANDROID_HOME/platform-tools/adb"

DEVICEIDS=($($adb devices | sed '1,1d' | sed '$d' | cut -f 1 | sort))
numDevices=${#DEVICEIDS[@]}
DEVICEINFO=()
SELECTEDIDS=()
SELECTEDINFO=()

selection=true # Toggles device selection
flag="" # Command flag
SELECTIONS=("-d" "-e" "-a" "-ad" "-ae")
COMMANDS=("-l" "-s" "logs" "-t" "help")

# for i in ${COMMANDS[@]}; do
# 	echo "$i"
# done

textInput=""

# Shows the user how to use the script
crabHelp() {
	echo "Crab Version 0.1 using $(adb help 2>&1)"
}

# Adds connected devices to a global array (modified part of superInstall)
getDeviceInfo() {
	if [ "$numDevices" == "0" ]; then 
		echo 'No devices detected!' 
		echo 'Troubleshooting tips if device is plugged in:'
		echo ' - USB Debugging should be enabled on the device.'
		echo ' - Execute in terminal "adb kill-server"'
		echo ' - Execute in terminal "adb start-server"'
		exit 1
	else
		echo 'Number of devices found:' $numDevices
		for ((i = 0; i < ($numDevices); i++))
		do
			DEVICEINFO+=("$(echo "$($adb -s ${DEVICEIDS[i]} shell "getprop ro.product.manufacturer && getprop ro.product.model && getprop ro.build.version.release" | tr -d '\r')" | tr '\n' ' ')")
		done
	fi			
}

# Gets all physical devices
getRealDevices() {
	DEVICEIDS=($($adb devices | sed '1,1d' | sed '$d' | cut -f 1 | sort | grep -v '^emu')) 
	numDevices=${#DEVICEIDS[@]}
}

# Gets all emulators
getEmulators() {
	DEVICEIDS=($($adb devices | sed '1,1d' | sed '$d' | cut -f 1 | sort | grep '^emu')) 
	numDevices=${#DEVICEIDS[@]}
}

# Helper function for outputting connected devices
menu() {
    for i in ${!DEVICEIDS[@]}; do 
        printf "%3d%s) %s" $((i+1)) "${choices[i]:- }" 
        echo ${DEVICEINFO[i]} ${DEVICEIDS[i]}
    done
    [[ "$msg" ]] && echo $msg; :
}

# Outputs connected devices
crabList() {
	getDeviceInfo
	menu
}

# Prompts user to select a device if multiple are connected
crabSelect() {
	if [[ $selection = true ]]; then {

		getDeviceInfo

		if [[ "$numDevices" == "1" ]]; then
				echo 'Selected the only detected device:' ${DEVICEINFO[0]} ${DEVICEIDS[0]}
				SELECTEDIDS=${DEVICEIDS[0]}
		else
			{
				# Asks user to select device, and then stores its ID as a global variable
				# Modified code from http://serverfault.com/questions/144939/multi-select-menu-in-bash-script
				echo "Multiple devices connected. Please select from the list:"
				echo "  0 ) All devices"
				prompt="Input an option to select (Input again to deselect; hit ENTER key when done): "
				while menu && read -rp "$prompt" num && [[ "$num" ]]; do
					echo "  0 ) All devices"
				    if [[ "$num" == "0" ]]; then 
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

						# Saves the ID(s) and info of the selected device(s) in global arrays
					    SELECTEDIDS+=(${DEVICEIDS[i]});
					    SELECTEDINFO+=("${DEVICEINFO[i]}");
					}
				done
				echo "$msg"

				# # Test to verify the correct device IDs are selected
				# echo "IDs of the selected device(s):"
				# for i in ${!SELECTEDIDS[@]}; do
				# 	echo "${SELECTEDIDS[i]}"
				# done
			}
		fi
		}
	fi
}

# Installs apk on selected devices
# crabInstall () {
# 	numSelectDevices=${#SELECTEDIDS[@]}
# 	for SERIAL in DEVICELIST;
# 	do
# 		adb -s SERIAL install "$1";
# }

# Takes a screenshot on connected devices (modified part of superadb)
crabScreenshot() {
	echo 'Taking screenshot on selected devices:'	
	echo ''

	for i in ${!SELECTEDIDS[@]}; do
		timestamp=$(date +"%I-%M-%S")
		# Credit to the following site for screenshot copying directly to the current directory
		# http://www.growingwiththeweb.com/2014/01/handy-adb-commands-for-android.html
		adb -s ${SELECTEDIDS[i]} shell screencap -p | perl -pe 's/\x0D\x0A/\x0A/g' >> "${SELECTEDINFO[i]}"-$timestamp-"screenshot.png"
		
		# Tells the user which device and when the screenshot was taken on
		echo 'Took screenshot on:' ${SELECTEDINFO[i]} ${SELECTEDIDS[i]} '@' $timestamp

	done
}

# Grabs crash logs from connected devices (modified part of superadb)
# crabLog() {
# 	echo 'Taking logs from all devices:'	
# 	echo ''

# 	for SERIAL in $(adb devices | grep -v List | cut -f 1); do
# 		deviceMake=$(adb -s $SERIAL shell getprop | grep ro.product.manufacturer | cut -f2 -d ':' | tr -d '[]' | cut -c2- | tr -d '\r' | tr a-z A-Z)
# 		deviceName=$(adb -s $SERIAL shell getprop | grep ro.product.model | cut -f2 -d ':' | tr -d '[]' | cut -c1- | tr -d '\r' )
		

# 		echo 'Logcat from' $deviceMake $deviceName '@' $timestamp
# 		echo ''
# 		adb -s $SERIAL logcat -d | grep AndroidR
# 		echo ''

# 	done
# }

# Inputs text on connected devices (modified part of superadb)
# crabType() {

# 	if [[  -z "$textInput"  ]]; then
# 		{
# 			echo ''
# 			echo 'Text input stream is empty.'
# 			echo ''
# 			echo 'Enter text like this:'
# 			echo '     crab -t "Enter text here"'
# 			echo 'If quotes are not used, then only the first word will be typed.'
# 		}
# 	else
# 		{
# 			echo ''

# 			for SERIAL in $(adb devices | grep -v List | cut -f 1); do
# 				deviceMake=$(adb -s $SERIAL shell getprop | grep ro.product.manufacturer | cut -f2 -d ':' | tr -d '[]' | cut -c2- | tr -d '\r' | tr a-z A-Z)
# 				deviceName=$(adb -s $SERIAL shell getprop | grep ro.product.model | cut -f2 -d ':' | tr -d '[]' | cut -c1- | tr -d '\r' )

# 				echo 'Entering text on' $deviceMake $deviceName'.'

# 				# Replaces all spaces with %s
# 				parsedText=${textInput// /%s}

# 				#words=(`echo $textInput | tr ' '`)

# 				#for i in words ; do
# 					adb -s $SERIAL shell input text $parsedText
# 				#done
# 				echo ''

# 			done
# 		}
# 	fi
# }

if [[ $1 == ${SELECTIONS[0]} ]]; then # -d
	{
		getRealDevices
		flag=$2
	}
elif [[ $1 == ${SELECTIONS[1]} ]]; then # -e
	{
		getEmulators
		flag=$2
	}
elif [[ $1 == ${SELECTIONS[2]} ]]; then # -a
	{
		SELECTEDIDS=DEVICEIDS
		selection=false
		flag=$2
	}
elif [[ $1 == ${SELECTIONS[3]} ]]; then # -ad
	{
		getRealDevices
		SELECTEDIDS=DEVICEIDS # Automatically selects all real devices
		selection=false
		flag=$2
	}
elif [[ $1 == ${SELECTIONS[4]} ]]; then # -ae
	{
		getEmulators
		SELECTEDIDS=DEVICEIDS # Automatically selects all emulators
		selection=false
		flag=$2
	} 
else
	{
		flag=$1
	}
fi

# Command selection
if [[ $flag == ${COMMANDS[0]} ]]; then	#-l
	{
		crabList
	}
elif [[ $flag == ${COMMANDS[1]} ]]; then #-s
	{
		crabSelect
		crabScreenshot
	}
elif [[ $flag == ${COMMANDS[2]} ]]; then #logs
	{
		crabSelect
		crabLog
	}
elif [[ $flag == ${COMMANDS[3]} ]]; then #-t
	{
		crabSelect
		textInput=$2
		crabType
	}
elif [[ $1 == ${COMMANDS[4]} ]]; then #help
	{
		crabHelp
	}
# If not a crab command, execute as adb script
else 
	{
		adb $flag 2> /dev/null
		if [[ $(echo $?) == 1 ]]; then
			crabHelp
		fi

		# crabSelect
		# for ID in $SELECTEDIDS; do
		# 	# echo "adb -s" $ID $1
		# 	adb=`adb -s $ID $1` #only works with the first command/flag
		# 	echo $adb
		# done
	}
fi