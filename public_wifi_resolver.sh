#!/bin/bash

# This is free and unencumbered software released into the public domain.
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
# For more information, please refer to <https://unlicense.org>

# AP settings
AP_NAME="Liberty_Net"
AP_PSK="piraspberry8888"
AP_IFACE_FROM="lo"

# Hello message
echo "--------------------"
echo "Public WiFi Resolver"
echo "--------------------"

# Get list of interfaces
mapfile -t ifaces <<< "$(find /sys/class/net -mindepth 1 -printf '%f\n')"
ifaces_n=${#ifaces[@]}

# Ask for default interface
echo ""
echo "Select the default interface"
echo "on which to open the AP."
echo "In most cases it is wlan0"
echo ""
for i in $(seq 1 $ifaces_n)
do
	echo "${i}: ${ifaces[$i - 1]}"
done
read -p "> " default_iface_index
default_iface=${ifaces[$default_iface_index - 1]}
echo "Default interface: $default_iface"
echo ""

# Ask for command
echo ""
echo "List of commands:"
echo "1: disable $default_iface, change mac"
echo "   and start nmtui"
echo "2: enable $default_iface and create AP"
echo ""
read -p "> " command
echo "Selected command: $command"
echo ""

if [ "$command" == "1" ];
# Command 1 - disable default iface, change mac and start nmtui
then
	# Disable default iface
	echo "Disabling $default_iface..."
	sudo ifconfig $default_iface down
	
	echo ""
	echo "Select interface to change MAC or enter 0 to skip"
	for i in $(seq 1 $ifaces_n)
	do
		echo "${i}: ${ifaces[$i - 1]}"
	done
	read -p "> " mac_iface_index
	echo ""
	
	# Change MAC to random
	if (( mac_iface_index > 0 && mac_iface_index < ifaces_n + 1 )); then
		mac_iface=${ifaces[$mac_iface_index - 1]}
		echo "Changing MAC on $mac_iface..."
		sudo ifconfig $mac_iface down
		sudo macchanger -r $mac_iface
		sudo ifconfig $mac_iface up
	else
		echo "Skipping mac changing"
	fi
	
	# NMtui
	echo "Starting nmtui..."
	nmtui
	
	# Enable iface
	echo "Enabling $default_iface..."
	sudo ifconfig $default_iface up
	
	echo "Done"
	
elif [ "$command" == "2" ]
then
	# Enable iface
	echo "Enabling $default_iface..."
	sudo ifconfig $default_iface up
	
	# Start AP
	echo "Starting AP on $default_iface from $AP_IFACE_FROM"
	echo "AP Name: $AP_NAME"
	echo "AP Pass: $AP_PSK"
	sudo create_ap $default_iface $AP_IFACE_FROM "$AP_NAME" "$AP_PSK"
	
	echo "Finished"
else
	echo "Invalid command. Exiting..."
fi
exit 0
