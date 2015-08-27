# crab
Adds new commands to Android Debug Bridge and extends its functionality across multiple devices and emulators

Requires [Android Debug Bridge](http://developer.android.com/tools/help/adb.html)

Requires aapt (only for uninstall)
___

**Selection Filters**

-d &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; - physical devices

-e &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; - emulators

-a &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; - selects all

-ad &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;- automatically selects all physical devices

-ae &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;- automatically selects all emulators

**Commands Available**

adb help &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; - shows usage of the script

adb l &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; - lists connected devices

adb s &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; - takes a screenshot on selected devices

adb t "text input" &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; - types on selected devices

adb i \<file> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; - pushes this package file to selected devices and installs it (overinstall)

adb u \<file> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; - removes this app package from selected devices

adb c \<file> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; - force closes app and clears data


adb \<adb command>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;- executes command using original adb

**Install**

1. Ensure that you have adb installed (and aapt if you want uninstall)

2. Set ANDROID_HOME correctly in the PATH

3. Download crab.sh

4. cd into the folder with crab.sh

5. Set up an alias for the script to redirect adb by typing the following:
>alias adb=./crab.sh

Note: The alias can be removed anytime by typing the following:
>unalias adb

**Usage**

Type commands like this:
>crab \<selection filter> \<command>

**Bugs/Future Enhancements**

- commands with | (pipes) do not work with selection filters
- "Number of devices found: X" is outputted when running help command with a filter
- Install/uninstall does not work if apk name has a space?
- batch installation
- clear data
- screen recording
