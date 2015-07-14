
numDevices=$(($(adb devices | wc -l) - 2))
devices=$(adb devices)
# crabSelect() {
	deviceList=""

	if [[ "$numDevices" == "0" ]]; then
		{
			echo "No devices detected"
		}
 	#This needs to be modified, right now it just prints the ID
	elif [[ "$numDevices" == "1" ]]; then
		{
		echo $devices ":"
		}	
	else
		{
		#Modified part of superInstall
		echo "Select a device using its number:"
		for ((i = 2; i <= (($numDevices) +1); i++))
		do
			deviceID=$(adb devices | tail -n +$i | head -n1 | cut -f 1 | xargs -I X)
			deviceMake=$(adb -s $deviceID shell getprop ro.product.manufacturer | tr -d '\r')
			deviceName=$(adb -s $deviceID shell getprop ro.product.model | tr -d '\r')
			deviceOS=$(adb -s $deviceID shell getprop ro.build.version.release | tr -d '\r')
			
			#Adds each device to the string		
			deviceList="$deviceList \"${deviceMake}  -  ${deviceName}  -  ${deviceID}  -  ${deviceOS}\""
			
		done
		
		#Asks user to select device, and then prints out the device.
		eval set $deviceList
		select device in "$@"; 
		do
			#We need to return this value to the method that called it or save it to a global variable or something, but for now I just printed it
			echo $device
			echo $device | cut -f 5 -d " ";
			echo $device | awk 'BEGIN {FS=" - "} {print $3}'
			break
		done;
		}
	fi
# }


