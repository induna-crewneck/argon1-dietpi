#!/bin/bash
echo "-----------------------------------"
echo "Argon One Uninstall Tool for DietPi"
echo "-----------------------------------"
timeout /t 1
echo "Sorry I'm not asking you to confirm. Couldn't get that to work."
echo " ¯\_(ツ)_/¯"
timeout /t 2
echo "But because I'm nice I'll give you 3 seconds to abort.
timeout /3
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
sudo rm /usr/share/pixmaps/ar1uninstall.png
sudo rm /usr/share/pixmaps/ar1config.png
sudo rm /root/Desktop/argonone-config.desktop
sudo rm /root/Desktop/argonone-uninstall.desktop
sudo rm -r /root/argon1-dietpi
sudo rm -r /etc/argon1
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
