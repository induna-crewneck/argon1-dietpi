#!/bin/bash
echo "-----------------------------------"
echo "Argon One Uninstall Tool for DietPi"
echo "-----------------------------------"
echo -n "Press Y to continue:"
read -n 1 confirm
echo
if [ "$confirm" = "y" ]
then
	confirm="Y"
fi

if [ "$confirm" != "Y" ]
then
	echo "Alrighty then."
	exit
fi
	sudo systemctl stop argononed.service
	sudo systemctl disable argononed.service
	sudo /usr/bin/python3 /lib/systemd/system-shutdown/argononed-poweroff.py uninstall
	sudo rm /usr/bin/argononed.py
	sudo rm /lib/systemd/system-shutdown/argononed-poweroff.py
	sudo rm /etc/argononed.conf
	sudo rm /usr/bin/argonone-config
	sudo rm /usr/bin/argonone-uninstall
	sudo rm /home/dietpi/Desktop/argonone-config.desktop"
	sudo rm /home/dietpi/Desktop/argonone-uninstall.desktop"
	sudo rm /usr/bin/argononed.py
	sudo rm /lib/systemd/system-shutdown/argononed-poweroff.py
	sudo rm /usr/bin/argonone-uninstall
	echo "Removed all the Argon One shit."
	echo "Rebooting is highly recommended"
	timeout /t 1
	echo "but I'm not your mom"
	timeout /t 1
	echo "so do whatever you want"
	timeout /t 3
	echo "No, you know what?"
	timeout /t 1
	echo "You want me to do all the work, so I feel like I am entitled to have a say in this, too."
	timeout /t 3
	echo "So I'll just reboot."
	timeout /t 1
	echo "Deal with it."
	timeout /t 1
	reboot
fi
