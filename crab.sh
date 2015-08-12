#!/bin/bash

adb="$ANDROID_HOME/platform-tools/adb"

devices=($($adb devices | sed '1,1d' | sed '$d' | cut -f 1 | sort)) # Is it necessary to sort everything by deviceID?
numDevices=${#devices[@]}

DEVICELIST=()
SELECTEDIDS=()
textInput=""

# Shows the user how to use the script
crabHelp() {
	echo "Crab Version 0.1 using $(adb help 2>&1)"
}

# Adds connected devices to a global array (modified part of superInstall)
getDevices() {
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
			deviceInfo=$($adb -s ${devices[i]} shell "getprop ro.product.manufacturer && getprop ro.product.model && getprop ro.build.version.release" | tr -d '\r')
			
			# Adds each device to a global array		
			DEVICELIST+=("$deviceInfo ${devices[i]}")
		done
	fi			
}

# Helper function for outputting connected devices
menu() {
    for i in ${!DEVICELIST[@]}; do 
        printf "%3d%s) %s" $((i+1)) "${choices[i]:- }" 
        echo ${DEVICELIST[i]}
    done
}

# Outputs connected devices
crabList() {
	getDevices
	menu
}

# Prompts user to select a device if multiple are connected
crabSelect() {

	getDevices

	if [[ "$numDevices" == "1" ]]; then
			echo 'Selected the only detected device:' ${DEVICELIST[0]}
			SELECTEDIDS=${DEVICELIST[0]}
	else
		{
			# Asks user to select device, and then stores its ID as a global variable
			# Modified code from http://serverfault.com/questions/144939/multi-select-menu-in-bash-script
			echo "Multiple devices connected. Please select from the list:"
			prompt="Input an option to select (Input again to deselect; hit ENTER key when done): "
			while menu && read -rp "$prompt" num && [[ "$num" ]]; do
			    [[ "$num" != *[![:digit:]]* ]] &&
			    (( num > 0 && num <= ${#DEVICELIST[@]} )) ||
			    { msg="Invalid option: $num"; continue; }
			    ((num--)); msg="${DEVICELIST[num]} was ${choices[num]:+de}selected"
			    [[ "${choices[num]}" ]] && choices[num]="" || choices[num]="+"
			done

			echo "You selected:"; msg=" nothing"
			for i in ${!DEVICELIST[@]}; do 
			    [[ "${choices[i]}" ]] && { 
				    echo ${DEVICELIST[i]}; 
				    msg=""; 
				    newId=${devices[i]};

					# Saves the ID(s) of the selected device(s) in a global array
				    SELECTEDIDS+=($newId);
				}
			done
			echo "$msg"

			# echo "IDs of the selected device(s):"
			# for i in ${!SELECTEDIDS[@]}; do
			# 	echo "${SELECTEDIDS[i]}"
			# done
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
# crabScreenshot() {
# 	echo 'Taking Screenshot on all devices:'	
# 	echo ''

# 	# Figures out which devices are connected and what their serial number is
# 	for SERIAL in $(adb devices | grep -v List | cut -f 1); do
# 		# Gets the device info
# 		deviceMake=$(adb -s $SERIAL shell getprop | grep ro.product.manufacturer | cut -f2 -d ':' | tr -d '[]' | cut -c2- | tr -d '\r' | tr a-z A-Z)
# 		deviceName=$(adb -s $SERIAL shell getprop | grep ro.product.model | cut -f2 -d ':' | tr -d '[]' | cut -c1- | tr -d '\r' )
# 		# Gets the time stamp
# 		timestamp=$(date +"%I-%M-%S")

# 		# Credit to the following site for screenshot copying directly to the current directory
# 		# http://www.growingwiththeweb.com/2014/01/handy-adb-commands-for-android.html

# 		# May or may not need $ANDROID_HOME/platform-tools/ depending on the computer
# 		# $ANDROID_HOME/platform-tools/adb -s $SERIAL shell screencap -p | perl -pe 's/\x0D\x0A/\x0A/g' > $deviceMake-$timestamp-$screenshotname 
# 		adb -s $SERIAL shell screencap -p | perl -pe 's/\x0D\x0A/\x0A/g' > $deviceMake-$timestamp-$screenshotname 
		
# 		# Tells the user which device the screenshot was taken on
# 		echo 'Took screenshot on: ' $deviceMake ' ' $deviceName ' @ ' $timestamp

# 	done
# }

# Grabs crash logs from connected devices (modified part of superadb)
# crabLog() {
# 	echo 'Taking logs from all devices:'	
# 	echo ''

# 	for SERIAL in $(adb devices | grep -v List | cut -f 1); do
# 		deviceMake=$(adb -s $SERIAL shell getprop | grep ro.product.manufacturer | cut -f2 -d ':' | tr -d '[]' | cut -c2- | tr -d '\r' | tr a-z A-Z)
# 		deviceName=$(adb -s $SERIAL shell getprop | grep ro.product.model | cut -f2 -d ':' | tr -d '[]' | cut -c1- | tr -d '\r' )
		

# 		echo 'Logcat from' $deviceMake $deviceName '@' $timestamp
# 		echo ''
# 		# May or may not need $ANDROID_HOME/platform-tools/ depending on the computer
# 		# $ANDROID_HOME/platform-tools/adb -s $SERIAL logcat -d | grep AndroidR
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

# 			# May or may not need $ANDROID_HOME/platform-tools/ depending on the computer
# 			# for SERIAL in $($ANDROID_HOME/platform-tools/adb devices | grep -v List | cut -f 1); do
# 			for SERIAL in $(adb devices | grep -v List | cut -f 1); do
# 				deviceMake=$(adb -s $SERIAL shell getprop | grep ro.product.manufacturer | cut -f2 -d ':' | tr -d '[]' | cut -c2- | tr -d '\r' | tr a-z A-Z)
# 				deviceName=$(adb -s $SERIAL shell getprop | grep ro.product.model | cut -f2 -d ':' | tr -d '[]' | cut -c1- | tr -d '\r' )

# 				echo 'Entering text on' $deviceMake $deviceName'.'

# 				# Replaces all spaces with %s
# 				parsedText=${textInput// /%s}

# 				#words=(`echo $textInput | tr ' '`)

# 				#for i in words ; do
# 					# May or may not need $ANDROID_HOME/platform-tools/ depending on the computer
# 					# $ANDROID_HOME/platform-tools/adb -s $SERIAL shell input text $parsedText
# 					adb -s $SERIAL shell input text $parsedText
# 				#done
# 				echo ''

# 			done
# 		}
# 	fi
# }

# Selects all real devices
crabSelectDevice() {
	devices=($($adb devices | sed '1,1d' | sed '$d' | cut -f 1 | sort | grep -v '^emu'))
	numDevices=${#devices[@]}
	crabSelect
}

# Selects all emulators
crabSelectEmulator() {
	devices=($($adb devices | sed '1,1d' | sed '$d' | cut -f 1 | sort | grep '^emu'))
	numDevices=${#devices[@]}
	crabSelect
}

# Helper function for flags
# deviceOrEmulator() {
# 	if [[ $1 == "-d" ]]; then 
# 		{
# 			crabSelectDevice
# 		}

# 	elif [[ $1 == "-e" ]]; then 
# 		{
# 			crabSelectEmulator
# 		}

# 	# If you don't want to be promted and just want to select a device, then -s can be used
# 	# Some people use this so it should to be implemented.
# 	# elif [[ $1 == "-s"]]
# 	# 	{

# 	# 	}

# 	else 
# 		{
# 			crabSelect
# 		}
# 	fi
# }

# Command selection
if [[ $1 == "-l" ]]; then	# return connected devices
	{
		crabList
	}
elif [[ $1 == "-s" ]]; then
	{
		crabScreenshot
	}
elif [[ $1 == "logs" ]]; then
	{
		crabLog
	}
elif [[ $1 == "-t" ]]; then
	{
		textInput=$2
		crabType
	}
elif [[ $1 == "-select" ]]; then
	{
		crabSelect
	}

# Probably need to modify these and make them methods
elif [[ $1 == "-d" ]]; then  
 	{
 		crabSelectDevice
 	}

elif [[ $1 == "-e" ]]; then
	{
		crabSelectEmulator
	}

elif [[ $1 == "-help" || $1 == "help" || $1 == "-h" ]]; then
	{
		crabHelp
	}
# If not a crab command, execute as adb script
else 
	{
		adb $1 2> /dev/null
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