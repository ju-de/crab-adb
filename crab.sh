#!/bin/bash

# Vlad's Stuff:
# adb="$ANDROID_HOME/platform-tools/adb"
# devices=($($adb devices | sed '1,1d' | sed '$d' | cut -f 1 | sort))
# numDevices=${#devices[@]}

numDevices=$(($(adb devices | wc -l) - 2))
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
		for ((i = 2; i <= (($numDevices) +1); i++))
		do
			deviceID=$(adb devices | tail -n +$i | head -n1 | cut -f 1 | xargs -I X)
			deviceMake=$(adb -s $deviceID shell getprop ro.product.manufacturer | tr -d '\r') # outputs error if device is unauthorized
			deviceName=$(adb -s $deviceID shell getprop ro.product.model | tr -d '\r') # outputs error if device is unauthorized
			deviceOS=$(adb -s $deviceID shell getprop ro.build.version.release) # outputs error if device is unauthorized
			
			# Adds each device to the global array		
			DEVICELIST+=("${deviceMake}  -  ${deviceName}  -  ${deviceID}  -  ${deviceOS}")

		done
	fi			
}

menu() {
    for i in ${!DEVICELIST[@]}; do 
        printf "%3d%s) %s\n" $((i+1)) "${choices[i]:- }" "${DEVICELIST[i]}"
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
				    echo "${DEVICELIST[i]}"; 
				    msg=""; 
				    newId=$(echo ${DEVICELIST[i]} | awk 'BEGIN {FS=" - "} {print $3}');
				    SELECTEDIDS+=($newId);
				}
				# Save the ID(s) of the selected device(s) in a global array
			done
			echo "$msg"

			# echo "IDs of the selected device(s):"
			# for i in ${!SELECTEDIDS[@]}; do
			# 	echo "${SELECTEDIDS[i]}"
			# done
		}
	fi
}

# Takes a screenshot on connected devices (modified part of superadb)
crabScreenshot() {
	echo 'Taking Screenshot on all devices:'	
	echo ''

	# Figures out which devices are connected and what their serial number is
	for SERIAL in $(adb devices | grep -v List | cut -f 1); do
		# Gets the device info
		deviceMake=$(adb -s $SERIAL shell getprop | grep ro.product.manufacturer | cut -f2 -d ':' | tr -d '[]' | cut -c2- | tr -d '\r' | tr a-z A-Z)
		deviceName=$(adb -s $SERIAL shell getprop | grep ro.product.model | cut -f2 -d ':' | tr -d '[]' | cut -c1- | tr -d '\r' )
		# Gets the time stamp
		timestamp=$(date +"%I-%M-%S")

		# Credit to the following site for screenshot copying directly to the current directory
		# http://www.growingwiththeweb.com/2014/01/handy-adb-commands-for-android.html

		# May or may not need $ANDROID_HOME/platform-tools/ depending on the computer
		# $ANDROID_HOME/platform-tools/adb -s $SERIAL shell screencap -p | perl -pe 's/\x0D\x0A/\x0A/g' > $deviceMake-$timestamp-$screenshotname 
		adb -s $SERIAL shell screencap -p | perl -pe 's/\x0D\x0A/\x0A/g' > $deviceMake-$timestamp-$screenshotname 
		
		# Tells the user which device the screenshot was taken on
		echo 'Took screenshot on: ' $deviceMake ' ' $deviceName ' @ ' $timestamp

	done
}

# Grabs crash logs from connected devices (modified part of superadb)
crabLog() {
	echo 'Taking logs from all devices:'	
	echo ''

	for SERIAL in $(adb devices | grep -v List | cut -f 1); do
		deviceMake=$(adb -s $SERIAL shell getprop | grep ro.product.manufacturer | cut -f2 -d ':' | tr -d '[]' | cut -c2- | tr -d '\r' | tr a-z A-Z)
		deviceName=$(adb -s $SERIAL shell getprop | grep ro.product.model | cut -f2 -d ':' | tr -d '[]' | cut -c1- | tr -d '\r' )
		

		echo 'Logcat from' $deviceMake $deviceName '@' $timestamp
		echo ''
		# May or may not need $ANDROID_HOME/platform-tools/ depending on the computer
		# $ANDROID_HOME/platform-tools/adb -s $SERIAL logcat -d | grep AndroidR
		adb -s $SERIAL logcat -d | grep AndroidR
		echo ''

	done
}

# Inputs text on connected devices (modified part of superadb)
crabType() {

	if [[  -z "$textInput"  ]]; then
		{
			echo ''
			echo 'Text input stream is empty.'
			echo ''
			echo 'Enter text like this:'
			echo '     crab -t "Enter text here"'
			echo 'If quotes are not used, then only the first word will be typed.'
		}
	else
		{
			echo ''

			# May or may not need $ANDROID_HOME/platform-tools/ depending on the computer
			# for SERIAL in $($ANDROID_HOME/platform-tools/adb devices | grep -v List | cut -f 1); do
			for SERIAL in $(adb devices | grep -v List | cut -f 1); do
				deviceMake=$(adb -s $SERIAL shell getprop | grep ro.product.manufacturer | cut -f2 -d ':' | tr -d '[]' | cut -c2- | tr -d '\r' | tr a-z A-Z)
				deviceName=$(adb -s $SERIAL shell getprop | grep ro.product.model | cut -f2 -d ':' | tr -d '[]' | cut -c1- | tr -d '\r' )

				echo 'Entering text on' $deviceMake $deviceName'.'

				# Replaces all spaces with %s
				parsedText=${textInput// /%s}

				#words=(`echo $textInput | tr ' '`)

				#for i in words ; do
					# May or may not need $ANDROID_HOME/platform-tools/ depending on the computer
					# $ANDROID_HOME/platform-tools/adb -s $SERIAL shell input text $parsedText
					adb -s $SERIAL shell input text $parsedText
				#done
				echo ''

			done
		}
	fi
}


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
elif [[ $1 == "" || $1 == "-help" || $1 == "-h" ]]; then
	{
		crabHelp
	}
# If not a crab command, execute as adb script
else 
	{
		echo `adb $1`
		echo $?
		if [[ $(echo $?) == 1 ]]; then
			echo 'error'
			# crabHelp()
		fi

		# crabSelect
		# for ID in $SELECTEDIDS; do
		# 	# echo "adb -s" $ID $1
		# 	adb=`adb -s $ID $1` #only works with the first command/flag
		# 	echo $adb
		# done
	}
fi