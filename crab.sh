#!/bin/bash

numDevices=$(($(adb devices | wc -l) - 2))
textInput=""
selectedDeviceId=""

# Shows the user how to use the script
crabHelp() {
	# Suppresses adb help output and error
	adb_help=`(adb help) 2>&1`

	# Replaces all instances of adb with crab
	adb_help="${adb_help//adb/crab}"

	echo "Crab Version 0.1 using $adb_help"
}


# Outputs connected devices (modified part of superInstall)
crabList() {
	if [ "$numDevices" == "0" ]; then 
		echo 'No devices detected! Please try again.'	
		exit 1
	else
		echo 'Number of devices found: ' $numDevices
		for ((i = 2; i <= (($numDevices) +1); i++))
		do
		(
			# device_list=`adb devices` # Parses through string of deviceIDs and authorization states
			# echo $device_list

			deviceID=$(adb devices | tail -n +$i | head -n1 | cut -f 1 | xargs -I X)
			deviceMake=$(adb -s $deviceID shell getprop ro.product.manufacturer | tr -d '\r') # outputs error if device is unauthorized
			deviceName=$(adb -s $deviceID shell getprop ro.product.model | tr -d '\r') # outputs error if device is unauthorized
			deviceOS=$(adb -s $deviceID shell getprop ro.build.version.release) # outputs error if device is unauthorized
			
			if [ "$numDevices" == "1" ]; then
				echo ${deviceMake} ' - ' ${deviceName} ' - ' ${deviceID} ' - ' ${deviceOS} >> deviceOutput
				# exit 1
			else
				echo $((i-1))". " ${deviceMake} ' - ' ${deviceName} ' - ' ${deviceID} ' - ' ${deviceOS} >> deviceOutput
				# exit 1
			fi

			# exit 1
		)&
		done
		wait
		cat deviceOutput | sort
		rm -rf deviceOutput
		exit 1
	fi			
}

# Prompts user to select a device if multiple are connected
crabSelect() {

	if [[ "$numDevices" == "0" ]]; then
		{
			echo "No devices detected"
		}
	elif [[ "$numDevices" == "1" ]]; then
		{
		selectedDeviceId=$(adb devices | cut -f 5 -d " ")
		}	
	else
		{
		# Modified part of superInstall
		echo "Select a device using its number:"
		for ((i = 2; i <= (($numDevices) +1); i++))
		do
			deviceID=$(adb devices | tail -n +$i | head -n1 | cut -f 1 | xargs -I X)
			deviceMake=$(adb -s $deviceID shell getprop ro.product.manufacturer | tr -d '\r')
			deviceName=$(adb -s $deviceID shell getprop ro.product.model | tr -d '\r')
			deviceOS=$(adb -s $deviceID shell getprop ro.build.version.release | tr -d '\r')
			
			# Adds each device to the string		
			deviceList="$deviceList \"${deviceMake}  -  ${deviceName}  -  ${deviceID}  -  ${deviceOS}\""
			
		done
		
		# Asks user to select device, and then prints out the device.
		eval set $deviceList
		select device in "$@"; 
		do
			# Save the ID of the selected device as a global variable
			selectedDeviceId=$(echo $device | awk 'BEGIN {FS=" - "} {print $3}')
			# echo The ID of the selected device is: $selectedDeviceId
			break
		done;
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
			echo '    Text input stream is empty.'
			echo ''
			echo '    Enter text like this:'
			echo '       crab -t "enter text here"' # Change command name?
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
elif [[ $1 == "" || $1 == "help" ]]; then
	{
		crabHelp
	}
# If not a crab command, execute as adb script
else
	{
		echo `adb $1`
	}
fi