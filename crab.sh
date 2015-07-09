#!/bin/bash

numDevices=$(($(adb devices | wc -l) - 2))

crabHelp() {
	# suppress adb help output and error
	adb_help=$((adb help) 2>&1)
	
	# replace all instances of adb with crab
	adb_help="${adb_help//adb/crab}"

	echo "Crab Version 0.1 using $adb_help"
}

# output connected devices (ft. superinstall)
crabList() {
	if [ "$numDevices" = "0" ]; then 
		echo 'No devices detected! Please try again.'
		echo "say no devices detected"	

		echo ' '	
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
			
			echo ${deviceMake} ' - ' ${deviceName} ' - ' ${deviceID} ' - ' ${deviceOS} >> deviceOutput

			exit 1
		)&
		done
		wait
		cat deviceOutput | sort
		rm -rf deviceOutput
		exit 1
	fi			
}				

# return connected devices
if [[ $1 == "-l" ]]; then
	{
		crabList
	}
elif [[ $1 == "" ]]; then
	{
		crabHelp
	}
# if not crab command, execute adb script
else
{
	echo `adb $1`
}
fi