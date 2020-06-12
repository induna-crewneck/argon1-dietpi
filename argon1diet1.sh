#!/bin/bash
# This file is edited. Make sure argonsetup is located in /etc/argon1/

argon_create_file() {
	if [ -f $1 ]; then
        sudo rm $1
    fi
	sudo touch $1
	sudo chmod 666 $1
}
argon_check_pkg() {
    RESULT=$(dpkg-query -W -f='${Status}\n' "$1" 2> /dev/null | grep "installed")

    if [ "" == "$RESULT" ]; then
        echo "NG"
    else
        echo "OK"
    fi
}

daemonname="argononed"
powerbuttonscript=/usr/bin/$daemonname.py
shutdownscript="/lib/systemd/system-shutdown/"$daemonname"-poweroff.py"
daemonconfigfile=/etc/$daemonname.conf
configscript=/usr/bin/argonone-config
removescript=/usr/bin/argonone-uninstall

daemonfanservice=/lib/systemd/system/$daemonname.service

echo "First part of installation complete. Proceed according to guide."