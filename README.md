# crab
Adds new commands to Android Debug Bridge and extends its functionality across multiple devices and emulators

Requires [Android Debug Bridge](http://developer.android.com/tools/help/adb.html)

Requires aapt (only for uninstall)
___

**Selection Filters**

-d      - physical devices

-e      - emulators

-a      - selects all

-ad     - automatically selects all physical devices

-ae     - automatically selects all emulators

**Commands Available**

crab help             - shows usage of the script      

crab l                - lists connected devices

crab s                - takes a screenshot on selected devices

crab t \<text input>   - types on selected devices

crab i \<file>         - pushes this package file to selected devices and installs it (overinstall)

crab u \<file>         - removes this app package from selected devices

crab \<adb command>    - executes command using original adb

**Install**

1. Ensure that you have adb installed (and aapt if you want uninstall)

2. Set ANDROID_HOME correctly in the PATH

3. Download crab.sh

4. cd into the folder with crab.sh

5. Set up an alias for the script to redirect adb by typing the following:
>alias adb=./crab.sh

The alias can be removed anytime by typing the following:
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
