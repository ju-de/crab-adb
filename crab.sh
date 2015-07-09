#!/bin/bash

numDevices=$(($(adb devices | wc -l) - 2))
textinput=""

crabHelp() {
	# suppress adb help output and error
	adb_help=$((adb help) 2>&1)

	# replace all instances of adb with crab
	adb_help="${adb_help//adb/crab}"

	echo "Crab Version 0.1 using $adb_help"
}


# output connected devices (ft. superinstall)
crabList() {
	if [ "$numDevices" == "0" ]; then 
		echo 'No devices detected! Please try again.'	
		exit 1
	else
		echo 'Number of devices found: ' $numDevices
		for ((i = 2; i <= (($numDevices) +1); i++))
		do
		(
			# device_list=`adb devices` #parse through string of deviceIDs and authorization states
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

# prompts user to select a device if multiple are connected
crabSelect() {

	#display devices
	if [ "$numDevices" == "1" ]; then
		echo "Only one device found:"
	else
		echo "Select a device using its number:"
	fi

	crabList

	#take input

	# DEVICES="Hello Quit"
	# select device in $DEVICES; do
	# 	if [ "$device" = "Quit" ]; then
	# 		echo done
	# 		exit
	# 	elif [ "device" = "Hello" ]; then
	# 		echo Hello World
	# 	else
	# 		clear
	# 		echo "Device does not exist."
	# 	fi
	# done

}

# take a screenshot on connected devices (ft. superadb)
crabScreenshot() {
	echo 'Taking Screenshot on all devices:'	
	echo ''

	# Figures out which devices are connected and what their serial number is
	for SERIAL in $(adb devices | grep -v List | cut -f 1); do
		# get the device info
		deviceMake=$(adb -s $SERIAL shell getprop | grep ro.product.manufacturer | cut -f2 -d ':' | tr -d '[]' | cut -c2- | tr -d '\r' | tr a-z A-Z)
		deviceName=$(adb -s $SERIAL shell getprop | grep ro.product.model | cut -f2 -d ':' | tr -d '[]' | cut -c1- | tr -d '\r' )
		# get the time stamp
		timestamp=$(date +"%I-%M-%S")

		#Credit to the following site for screenshot copying directly to the current directory
		#http://www.growingwiththeweb.com/2014/01/handy-adb-commands-for-android.html
		$ANDROID_HOME/platform-tools/adb -s $SERIAL shell screencap -p | perl -pe 's/\x0D\x0A/\x0A/g' > $deviceMake-$timestamp-$screenshotname 
		# tell the user which device the screenshot was taken on
		echo 'Took screenshot on: ' $deviceMake ' ' $deviceName ' @ ' $timestamp

	done
}

# grab crash logs from connected devices (ft. superadb)
crabLog() {
	echo 'Taking logs from all devices:'	
	echo ''

	for SERIAL in $(adb devices | grep -v List | cut -f 1); do
		deviceMake=$(adb -s $SERIAL shell getprop | grep ro.product.manufacturer | cut -f2 -d ':' | tr -d '[]' | cut -c2- | tr -d '\r' | tr a-z A-Z)
		deviceName=$(adb -s $SERIAL shell getprop | grep ro.product.model | cut -f2 -d ':' | tr -d '[]' | cut -c1- | tr -d '\r' )
		

		echo 'Logcat from' $deviceMake $deviceName '@' $timestamp
		echo ''
		$ANDROID_HOME/platform-tools/adb -s $SERIAL logcat -d | grep AndroidR
		echo ''

	done
}

# inputs text on connected devices (ft. superadb)
crabType() {

				if [[  -z "$textinput"  ]]; then
					{
						echo ''
						echo '    Text input stream is empty.'
						echo ''
						echo '    Enter text like this:'
						echo '       superAdb -t "enter text here"'
				}
				else
					{

						echo ''

						for SERIAL in $($ANDROID_HOME/platform-tools/adb devices | grep -v List | cut -f 1); do
						deviceMake=$(adb -s $SERIAL shell getprop | grep ro.product.manufacturer | cut -f2 -d ':' | tr -d '[]' | cut -c2- | tr -d '\r' | tr a-z A-Z)
						deviceName=$(adb -s $SERIAL shell getprop | grep ro.product.model | cut -f2 -d ':' | tr -d '[]' | cut -c1- | tr -d '\r' )
			
						echo 'Entering text on' $deviceMake $deviceName'.'

						# replaces all spaces with %s
						parsedText=${textinput// /%s}

						#words=(`echo $textinput | tr ' '`)

						#for i in words ; do
							$ANDROID_HOME/platform-tools/adb -s $SERIAL shell input text $parsedText
						#done
						echo ''
					done
				}
				fi
}


#command select
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
		textinput=$2
		crabType
	}
elif [[ $1 == "" ]]; then
	{
		crabHelp
	}
# if not crab command, execute as adb script
else
	{
		echo `adb $1`
	}
fi