#!/bin/bash
# This script is modified to work on DietPi. Chances are it will not run on regular Raspbian.
# Credit: https://github.com/induna-crewneck

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

sudo apt-get install raspi-gpio python-rpi.gpio python3-rpi.gpio python-smbus python3-smbus i2c-tools -y

daemonname="argononed"
powerbuttonscript=/usr/bin/$daemonname.py
shutdownscript="/lib/systemd/system-shutdown/"$daemonname"-poweroff.py"
daemonconfigfile=/etc/$daemonname.conf
configscript=/usr/bin/argonone-config
removescript=/usr/bin/argonone-uninstall
argonsetup=/etc/argonsetup

daemonfanservice=/lib/systemd/system/$daemonname.service

if [ ! -f $daemonconfigfile ]; then
# Generate config file for fan speed -----------------------------------------------------------------------------------
	sudo touch $daemonconfigfile
	sudo chmod 666 $daemonconfigfile
	echo '#' >> $daemonconfigfile
	echo '# Argon One Fan Configuration' >> $daemonconfigfile
	echo '#' >> $daemonconfigfile
	echo '# List below the temperature (Celsius) and fan speed (in percent) pairs' >> $daemonconfigfile
	echo '# Use the following form:' >> $daemonconfigfile
	echo '# min.temperature=speed' >> $daemonconfigfile
	echo '#' >> $daemonconfigfile
	echo '# Example:' >> $daemonconfigfile
	echo '# 55=10' >> $daemonconfigfile
	echo '# 60=55' >> $daemonconfigfile
	echo '# 65=100' >> $daemonconfigfile
	echo '#' >> $daemonconfigfile
	echo '# Above example sets the fan speed to' >> $daemonconfigfile
	echo '#' >> $daemonconfigfile
	echo '# NOTE: Lines begining with # are ignored' >> $daemonconfigfile
	echo '#' >> $daemonconfigfile
	echo '# Type the following at the command line for changes to take effect:' >> $daemonconfigfile
	echo '# sudo systemctl restart '$daemonname'.service' >> $daemonconfigfile
	echo '#' >> $daemonconfigfile
	echo '# Start below:' >> $daemonconfigfile
	echo '50=5' >> $daemonconfigfile
	echo '55=10' >> $daemonconfigfile
	echo '60=55' >> $daemonconfigfile
	echo '65=100' >> $daemonconfigfile
fi
# Generate argonsetup (hacked together workaround for DietPi compatibility issues---------------------------------------
argon_create_file $argonsetup

echo '#!/bin/bash' >> $argonsetup
echo 'CONFIG=/boot/config.txt' >> $argonsetup
echo 'INTERACTIVE=False' >> $argonsetup
echo 'USER=dietpi' >> $argonsetup
echo 'CMDLINE=/boot/cmdline.txt' >> $argonsetup
echo '' >> $argonsetup
echo 'do_i2c() {' >> $argonsetup
echo '  SETTING=on' >> $argonsetup
echo '  STATUS=enabled' >> $argonsetup
echo '  sed --in-place "s/dtparam=i2c_arm=off/dtparam=i2c_arm=on/" /boot/config.txt' >> $argonsetup
echo '  sed --in-place "s/#dtparam=i2c_arm=on/dtparam=i2c_arm=on/" /boot/config.txt' >> $argonsetup
echo '  sed /etc/modules -i -e "s/^#[[:space:]]*\(i2c[-_]dev\)/\1/"' >> $argonsetup
echo '  if ! grep -q "^i2c[-_]dev" /etc/modules; then' >> $argonsetup
echo '    printf "i2c-dev\n" >> /etc/modules' >> $argonsetup
echo '  fi' >> $argonsetup
echo '  dtparam i2c_arm=$SETTING' >> $argonsetup
echo '  modprobe i2c-dev' >> $argonsetup
echo '}' >> $argonsetup
echo '' >> $argonsetup
echo 'do_serial() {' >> $argonsetup
echo '  DEFAULTS=' >> $argonsetup
echo '  CURRENTS=1' >> $argonsetup
echo '  if grep -q "console=ttyAMA0" $CMDLINE ; then' >> $argonsetup
echo '    if [ -e /sys/firmware/devicetree/base/aliases/serial0 ]; then' >> $argonsetup
echo '      sed -i $CMDLINE -e "s/console=ttyAMA0/console=serial0/"' >> $argonsetup
echo '    fi' >> $argonsetup
echo '  elif ! grep -q "console=ttyAMA0" $CMDLINE && ! grep -q "console=serial0" $CMDLINE ; then' >> $argonsetup
echo '    if [ -e /proc/device-tree/aliases/serial0 ]; then' >> $argonsetup
echo '      sed -i $CMDLINE -e "s/root=/console=serial0,115200 root=/"' >> $argonsetup
echo '    else' >> $argonsetup
echo '      sed -i $CMDLINE -e "s/root=/console=ttyAMA0,115200 root=/"' >> $argonsetup
echo '    fi' >> $argonsetup
echo '  fi' >> $argonsetup
echo '  sed --in-place "s/enable_uart=0/enable_uart=1/" /boot/config.txt' >> $argonsetup
echo '  sed --in-place "s/#enable_uart=1/enable_uart=1/" /boot/config.txt' >> $argonsetup
echo '}' >> $argonsetup
echo '' >> $argonsetup
echo 'nonint() {' >> $argonsetup
echo '  "$@"' >> $argonsetup
echo '}' >> $argonsetup
echo '' >> $argonsetup
echo 'for i in $*' >> $argonsetup
echo 'do' >> $argonsetup
echo '  case $i in' >> $argonsetup
echo '  nonint)' >> $argonsetup
echo '    INTERACTIVE=False' >> $argonsetup
echo '    "$@"' >> $argonsetup
echo '    exit $?' >> $argonsetup
echo '    ;;' >> $argonsetup
echo '  *)' >> $argonsetup
echo '    ;;' >> $argonsetup
echo '  esac' >> $argonsetup
echo 'done' >> $argonsetup

sudo chmod 755 $argonsetup
$argonsetup nonint do_i2c 0
$argonsetup nonint do_serial 0
sudo rm $argonsetup

# Generate script that runs every shutdown event -----------------------------------------------------------------------
argon_create_file $shutdownscript

echo "#!/usr/bin/python" >> $shutdownscript
echo 'import sys' >> $shutdownscript
echo 'import smbus' >> $shutdownscript
echo 'import RPi.GPIO as GPIO' >> $shutdownscript
echo 'rev = GPIO.RPI_REVISION' >> $shutdownscript
echo 'if rev == 2 or rev == 3:' >> $shutdownscript
echo '	bus = smbus.SMBus(1)' >> $shutdownscript
echo 'else:' >> $shutdownscript
echo '	bus = smbus.SMBus(0)' >> $shutdownscript

echo 'if len(sys.argv)>1:' >> $shutdownscript
echo "	bus.write_byte(0x1a,0)"  >> $shutdownscript
echo '	if sys.argv[1] == "poweroff" or sys.argv[1] == "halt":'  >> $shutdownscript
echo "		try:"  >> $shutdownscript
echo "			bus.write_byte(0x1a,0xFF)"  >> $shutdownscript
echo "		except:"  >> $shutdownscript
echo "			rev=0"  >> $shutdownscript
sudo chmod 755 $shutdownscript

# Generate script to monitor shutdown button ---------------------------------------------------------------------------
argon_create_file $powerbuttonscript

echo "#!/usr/bin/python" >> $powerbuttonscript
echo 'import smbus' >> $powerbuttonscript
echo 'import RPi.GPIO as GPIO' >> $powerbuttonscript
echo 'import os' >> $powerbuttonscript
echo 'import time' >> $powerbuttonscript
echo 'from threading import Thread' >> $powerbuttonscript
echo 'rev = GPIO.RPI_REVISION' >> $powerbuttonscript
echo 'if rev == 2 or rev == 3:' >> $powerbuttonscript
echo '	bus = smbus.SMBus(1)' >> $powerbuttonscript
echo 'else:' >> $powerbuttonscript
echo '	bus = smbus.SMBus(0)' >> $powerbuttonscript

echo 'GPIO.setwarnings(False)' >> $powerbuttonscript
echo 'GPIO.setmode(GPIO.BCM)' >> $powerbuttonscript
echo 'shutdown_pin=4' >> $powerbuttonscript
echo 'GPIO.setup(shutdown_pin, GPIO.IN,  pull_up_down=GPIO.PUD_DOWN)' >> $powerbuttonscript

echo 'def shutdown_check():' >> $powerbuttonscript
echo '	while True:' >> $powerbuttonscript
echo '		pulsetime = 1' >> $powerbuttonscript
echo '		GPIO.wait_for_edge(shutdown_pin, GPIO.RISING)' >> $powerbuttonscript
echo '		time.sleep(0.01)' >> $powerbuttonscript
echo '		while GPIO.input(shutdown_pin) == GPIO.HIGH:' >> $powerbuttonscript
echo '			time.sleep(0.01)' >> $powerbuttonscript
echo '			pulsetime += 1' >> $powerbuttonscript
echo '		if pulsetime >=2 and pulsetime <=3:' >> $powerbuttonscript
echo '			os.system("reboot")' >> $powerbuttonscript
echo '		elif pulsetime >=4 and pulsetime <=5:' >> $powerbuttonscript
echo '			os.system("shutdown now -h")' >> $powerbuttonscript

echo 'def get_fanspeed(tempval, configlist):' >> $powerbuttonscript
echo '	for curconfig in configlist:' >> $powerbuttonscript
echo '		curpair = curconfig.split("=")' >> $powerbuttonscript
echo '		tempcfg = float(curpair[0])' >> $powerbuttonscript
echo '		fancfg = int(float(curpair[1]))' >> $powerbuttonscript
echo '		if tempval >= tempcfg:' >> $powerbuttonscript
echo '			return fancfg' >> $powerbuttonscript
echo '	return 0' >> $powerbuttonscript

echo 'def load_config(fname):' >> $powerbuttonscript
echo '	newconfig = []' >> $powerbuttonscript
echo '	try:' >> $powerbuttonscript
echo '		with open(fname, "r") as fp:' >> $powerbuttonscript
echo '			for curline in fp:' >> $powerbuttonscript
echo '				if not curline:' >> $powerbuttonscript
echo '					continue' >> $powerbuttonscript
echo '				tmpline = curline.strip()' >> $powerbuttonscript
echo '				if not tmpline:' >> $powerbuttonscript
echo '					continue' >> $powerbuttonscript
echo '				if tmpline[0] == "#":' >> $powerbuttonscript
echo '					continue' >> $powerbuttonscript
echo '				tmppair = tmpline.split("=")' >> $powerbuttonscript
echo '				if len(tmppair) != 2:' >> $powerbuttonscript
echo '					continue' >> $powerbuttonscript
echo '				tempval = 0' >> $powerbuttonscript
echo '				fanval = 0' >> $powerbuttonscript
echo '				try:' >> $powerbuttonscript
echo '					tempval = float(tmppair[0])' >> $powerbuttonscript
echo '					if tempval < 0 or tempval > 100:' >> $powerbuttonscript
echo '						continue' >> $powerbuttonscript
echo '				except:' >> $powerbuttonscript
echo '					continue' >> $powerbuttonscript
echo '				try:' >> $powerbuttonscript
echo '					fanval = int(float(tmppair[1]))' >> $powerbuttonscript
echo '					if fanval < 0 or fanval > 100:' >> $powerbuttonscript
echo '						continue' >> $powerbuttonscript
echo '				except:' >> $powerbuttonscript
echo '					continue' >> $powerbuttonscript
echo '				newconfig.append( "{:5.1f}={}".format(tempval,fanval))' >> $powerbuttonscript
echo '		if len(newconfig) > 0:' >> $powerbuttonscript
echo '			newconfig.sort(reverse=True)' >> $powerbuttonscript
echo '	except:' >> $powerbuttonscript
echo '		return []' >> $powerbuttonscript
echo '	return newconfig' >> $powerbuttonscript

echo 'def temp_check():' >> $powerbuttonscript
echo '	fanconfig = ["65=100", "60=55", "55=10"]' >> $powerbuttonscript
echo '	tmpconfig = load_config("'$daemonconfigfile'")' >> $powerbuttonscript
echo '	if len(tmpconfig) > 0:' >> $powerbuttonscript
echo '		fanconfig = tmpconfig' >> $powerbuttonscript
echo '	address=0x1a' >> $powerbuttonscript
echo '	prevblock=0' >> $powerbuttonscript
echo '	while True:' >> $powerbuttonscript
echo '		temp = os.popen("vcgencmd measure_temp").readline()' >> $powerbuttonscript
echo '		temp = temp.replace("temp=","")' >> $powerbuttonscript
echo '		val = float(temp.replace("'"'"'C",""))' >> $powerbuttonscript
echo '		block = get_fanspeed(val, fanconfig)' >> $powerbuttonscript
echo '		if block < prevblock:' >> $powerbuttonscript
echo '			time.sleep(30)' >> $powerbuttonscript
echo '		prevblock = block' >> $powerbuttonscript
echo '		try:' >> $powerbuttonscript
echo '			bus.write_byte(address,block)' >> $powerbuttonscript
echo '		except IOError:' >> $powerbuttonscript
echo '			temp=""' >> $powerbuttonscript
echo '		time.sleep(30)' >> $powerbuttonscript

echo 'try:' >> $powerbuttonscript
echo '	t1 = Thread(target = shutdown_check)' >> $powerbuttonscript
echo '	t2 = Thread(target = temp_check)' >> $powerbuttonscript
echo '	t1.start()' >> $powerbuttonscript
echo '	t2.start()' >> $powerbuttonscript
echo 'except:' >> $powerbuttonscript
echo '	t1.stop()' >> $powerbuttonscript
echo '	t2.stop()' >> $powerbuttonscript
echo '	GPIO.cleanup()' >> $powerbuttonscript

sudo chmod 755 $powerbuttonscript

argon_create_file $daemonfanservice

# Fan Daemon -----------------------------------------------------------------------------------------------------------
echo "[Unit]" >> $daemonfanservice
echo "Description=Argon One Fan and Button Service" >> $daemonfanservice
echo "After=multi-user.target" >> $daemonfanservice
echo '[Service]' >> $daemonfanservice
echo 'Type=simple' >> $daemonfanservice
echo "Restart=always" >> $daemonfanservice
echo "RemainAfterExit=true" >> $daemonfanservice
echo "ExecStart=/usr/bin/python3 $powerbuttonscript" >> $daemonfanservice
echo '[Install]' >> $daemonfanservice
echo "WantedBy=multi-user.target" >> $daemonfanservice

sudo chmod 644 $daemonfanservice

argon_create_file $removescript

# Uninstall Script - DietPi Version ------------------------------------------------------------------------------------
echo '#!/bin/bash' >> $removescript
echo 'echo "-----------------------------------"' >> $removescript
echo 'echo "Argon One Uninstall Tool for DietPi"' >> $removescript
echo 'echo "-----------------------------------"' >> $removescript
echo 'echo -n "Press Y to continue:"' >> $removescript
echo 'read -n 1 confirm' >> $removescript
echo 'echo' >> $removescript
echo 'if [ "$confirm" = "y" ]' >> $removescript
echo 'then' >> $removescript
echo '	confirm="Y"' >> $removescript
echo 'fi' >> $removescript
echo '' >> $removescript
echo 'if [ "$confirm" != "Y" ]' >> $removescript
echo 'then' >> $removescript
echo '	echo "Alrighty then."' >> $removescript
echo '  echo " ¯\_(ツ)_/¯"' >> $removescript
echo '	exit' >> $removescript
echo 'fi' >> $removescript
echo '	sudo systemctl stop '$daemonname'.service' >> $removescript
echo '	sudo systemctl disable '$daemonname'.service' >> $removescript
echo '	sudo /usr/bin/python3 '$shutdownscript' uninstall' >> $removescript
echo '	sudo rm "/root/Desktop/argonone-config.desktop"' >> $removescript
echo '	sudo rm "/root/Desktop/argonone-uninstall.desktop"' >> $removescript
echo '  sudo rm /usr/bin/argononed.py' >> $removescript
echo '  sudo rm /lib/systemd/system-shutdown/argononed-poweroff.py' >> $removescript
echo '  sudo rm /etc/argononed.conf' >> $removescript
echo '  sudo rm /usr/bin/argonone-config' >> $removescript
echo '  sudo rm /usr/bin/argonone-uninstall' >> $removescript
echo '  sudo rm /usr/bin/argononed.py' >> $removescript
echo '  sudo rm /lib/systemd/system-shutdown/argononed-poweroff.py' >> $removescript
echo '  sudo rm /usr/bin/argonone-uninstall' >> $removescript
echo '  sudo rm /usr/share/pixmaps/ar1uninstall.png' >> $removescript
echo '  sudo rm /usr/share/pixmaps/ar1config.png' >> $removescript
echo '  sudo rm /root/Desktop/argonone-config.desktop' >> $removescript
echo '  sudo rm /root/Desktop/argonone-uninstall.desktop' >> $removescript
echo '  sudo rm -r /root/argon1-dietpi' >> $removescript
echo '	sudo rm $powerbuttonscript' >> $removescript
echo '	sudo rm $shutdownscript' >> $removescript
echo '	sudo rm $removescript' >> $removescript
echo '	sudo rm /usr/bin/argononed.py' >> $removescript
echo '	sudo rm /lib/systemd/system-shutdown/argononed-poweroff.py' >> $removescript
echo '	sudo rm /usr/bin/argonone-uninstall' >> $removescript
echo '  echo "Removed all the Argon One stuff."' >> $removescript
echo '  echo "Rebooting is highly recommended"' >> $removescript
echo '  sleep 1' >> $removescript
echo '  echo "but I am not your mom"' >> $removescript
echo '  sleep 1' >> $removescript
echo '  echo "so do whatever you want"' >> $removescript
echo '  sleep 3' >> $removescript
echo '  echo "No, you know what?"' >> $removescript
echo '  sleep 1' >> $removescript
echo '  echo "You want me to do all the work, so I feel like I am entitled to have a say in this, too."' >> $removescript
echo '  sleep 3' >> $removescript
echo '  echo "So I will just reboot."' >> $removescript
echo '  sleep 1' >> $removescript
echo '  echo "Deal with it."' >> $removescript
echo '  sleep 1' >> $removescript
echo '  reboot' >> $removescript
echo 'fi' >> $removescript

sudo chmod 755 $removescript

argon_create_file $configscript

# Config Script
echo '#!/bin/bash' >> $configscript
echo 'daemonconfigfile=/etc/'$daemonname'.conf' >> $configscript
echo 'echo "--------------------------------------"' >> $configscript
echo 'echo "Argon One Fan Speed Configuration Tool"' >> $configscript
echo 'echo "--------------------------------------"' >> $configscript
echo 'echo "WARNING: This will remove existing configuration."' >> $configscript
echo 'echo -n "Press Y to continue:"' >> $configscript
echo 'read -n 1 confirm' >> $configscript
echo 'echo' >> $configscript
echo 'if [ "$confirm" = "y" ]' >> $configscript
echo 'then' >> $configscript
echo '	confirm="Y"' >> $configscript
echo 'fi' >> $configscript
echo '' >> $configscript
echo 'if [ "$confirm" != "Y" ]' >> $configscript
echo 'then' >> $configscript
echo '	echo "Cancelled"' >> $configscript
echo '	exit' >> $configscript
echo 'fi' >> $configscript
echo 'echo "Thank you."' >> $configscript

echo 'get_number () {' >> $configscript
echo '	read curnumber' >> $configscript
echo '	re="^[0-9]+$"' >> $configscript
echo '	if [ -z "$curnumber" ]' >> $configscript
echo '	then' >> $configscript
echo '		echo "-2"' >> $configscript
echo '		return' >> $configscript
echo '	elif [[ $curnumber =~ ^[+-]?[0-9]+$ ]]' >> $configscript
echo '	then' >> $configscript
echo '		if [ $curnumber -lt 0 ]' >> $configscript
echo '		then' >> $configscript
echo '			echo "-1"' >> $configscript
echo '			return' >> $configscript
echo '		elif [ $curnumber -gt 100 ]' >> $configscript
echo '		then' >> $configscript
echo '			echo "-1"' >> $configscript
echo '			return' >> $configscript
echo '		fi	' >> $configscript
echo '		echo $curnumber' >> $configscript
echo '		return' >> $configscript
echo '	fi' >> $configscript
echo '	echo "-1"' >> $configscript
echo '	return' >> $configscript
echo '}' >> $configscript
echo '' >> $configscript

echo 'loopflag=1' >> $configscript
echo 'while [ $loopflag -eq 1 ]' >> $configscript
echo 'do' >> $configscript
echo '	echo' >> $configscript
echo '	echo "Select fan mode:"' >> $configscript
echo '	echo "  1. Always on"' >> $configscript
echo '	echo "  2. Adjust to temperatures (55C, 60C, and 65C)"' >> $configscript
echo '	echo "  3. Customize behavior"' >> $configscript
echo '	echo "  4. Cancel"' >> $configscript
echo '	echo "NOTE: You can also edit $daemonconfigfile directly"' >> $configscript
echo '	echo -n "Enter Number (1-4):"' >> $configscript
echo '	newmode=$( get_number )' >> $configscript
echo '	if [[ $newmode -ge 1 && $newmode -le 4 ]]' >> $configscript
echo '	then' >> $configscript
echo '		loopflag=0' >> $configscript
echo '	fi' >> $configscript
echo 'done' >> $configscript

echo 'echo' >> $configscript
echo 'if [ $newmode -eq 4 ]' >> $configscript
echo 'then' >> $configscript
echo '	echo "Cancelled"' >> $configscript
echo '	exit' >> $configscript
echo 'elif [ $newmode -eq 1 ]' >> $configscript
echo 'then' >> $configscript
echo '	echo "#" > $daemonconfigfile' >> $configscript
echo '	echo "# Argon One Fan Speed Configuration" >> $daemonconfigfile' >> $configscript
echo '	echo "#" >> $daemonconfigfile' >> $configscript
echo '	echo "# Min Temp=Fan Speed" >> $daemonconfigfile' >> $configscript
echo '	echo 1"="100 >> $daemonconfigfile' >> $configscript
echo '	sudo systemctl restart '$daemonname'.service' >> $configscript
echo '	echo "Fan always on."' >> $configscript
echo '	exit' >> $configscript
echo 'elif [ $newmode -eq 2 ]' >> $configscript
echo 'then' >> $configscript
echo '	echo "Please provide fan speeds for the following temperatures:"' >> $configscript
echo '	echo "#" > $daemonconfigfile' >> $configscript
echo '	echo "# Argon One Fan Speed Configuration" >> $daemonconfigfile' >> $configscript
echo '	echo "#" >> $daemonconfigfile' >> $configscript
echo '	echo "# Min Temp=Fan Speed" >> $daemonconfigfile' >> $configscript
echo '	curtemp=55' >> $configscript
echo '	while [ $curtemp -lt 70 ]' >> $configscript
echo '	do' >> $configscript
echo '		errorfanflag=1' >> $configscript
echo '		while [ $errorfanflag -eq 1 ]' >> $configscript
echo '		do' >> $configscript
echo '			echo -n ""$curtemp"C (0-100 only):"' >> $configscript
echo '			curfan=$( get_number )' >> $configscript
echo '			if [ $curfan -ge 0 ]' >> $configscript
echo '			then' >> $configscript
echo '				errorfanflag=0' >> $configscript
echo '			fi' >> $configscript
echo '		done' >> $configscript
echo '		echo $curtemp"="$curfan >> $daemonconfigfile' >> $configscript
echo '		curtemp=$((curtemp+5))' >> $configscript
echo '	done' >> $configscript

echo '	sudo systemctl restart '$daemonname'.service' >> $configscript
echo '	echo "Configuration updated."' >> $configscript
echo '	exit' >> $configscript
echo 'fi' >> $configscript

echo 'echo "Please provide fan speeds and temperature pairs"' >> $configscript
echo 'echo' >> $configscript

echo 'loopflag=1' >> $configscript
echo 'paircounter=0' >> $configscript
echo 'while [ $loopflag -eq 1 ]' >> $configscript
echo 'do' >> $configscript
echo '	errortempflag=1' >> $configscript
echo '	errorfanflag=1' >> $configscript
echo '	while [ $errortempflag -eq 1 ]' >> $configscript
echo '	do' >> $configscript
echo '		echo -n "Provide minimum temperature (in Celsius) then [ENTER]:"' >> $configscript
echo '		curtemp=$( get_number )' >> $configscript
echo '		if [ $curtemp -ge 0 ]' >> $configscript
echo '		then' >> $configscript
echo '			errortempflag=0' >> $configscript
echo '		elif [ $curtemp -eq -2 ]' >> $configscript
echo '		then' >> $configscript
echo '			errortempflag=0' >> $configscript
echo '			errorfanflag=0' >> $configscript
echo '			loopflag=0' >> $configscript
echo '		fi' >> $configscript
echo '	done' >> $configscript
echo '	while [ $errorfanflag -eq 1 ]' >> $configscript
echo '	do' >> $configscript
echo '		echo -n "Provide fan speed for "$curtemp"C (0-100) then [ENTER]:"' >> $configscript
echo '		curfan=$( get_number )' >> $configscript
echo '		if [ $curfan -ge 0 ]' >> $configscript
echo '		then' >> $configscript
echo '			errorfanflag=0' >> $configscript
echo '		elif [ $curfan -eq -2 ]' >> $configscript
echo '		then' >> $configscript
echo '			errortempflag=0' >> $configscript
echo '			errorfanflag=0' >> $configscript
echo '			loopflag=0' >> $configscript
echo '		fi' >> $configscript
echo '	done' >> $configscript
echo '	if [ $loopflag -eq 1 ]' >> $configscript
echo '	then' >> $configscript
echo '		if [ $paircounter -eq 0 ]' >> $configscript
echo '		then' >> $configscript
echo '			echo "#" > $daemonconfigfile' >> $configscript
echo '			echo "# Argon One Fan Speed Configuration" >> $daemonconfigfile' >> $configscript
echo '			echo "#" >> $daemonconfigfile' >> $configscript
echo '			echo "# Min Temp=Fan Speed" >> $daemonconfigfile' >> $configscript
echo '		fi' >> $configscript
echo '		echo $curtemp"="$curfan >> $daemonconfigfile' >> $configscript
echo '		' >> $configscript
echo '		paircounter=$((paircounter+1))' >> $configscript
echo '		' >> $configscript
echo '		echo "* Fan speed will be set to "$curfan" once temperature reaches "$curtemp" C"' >> $configscript
echo '		echo' >> $configscript
echo '	fi' >> $configscript
echo 'done' >> $configscript
echo '' >> $configscript
echo 'echo' >> $configscript
echo 'if [ $paircounter -gt 0 ]' >> $configscript
echo 'then' >> $configscript
echo '	echo "Thank you!  We saved "$paircounter" pairs."' >> $configscript
echo '	sudo systemctl restart '$daemonname'.service' >> $configscript
echo '	echo "Changes should take effect now."' >> $configscript
echo 'else' >> $configscript
echo '	echo "Cancelled, no data saved."' >> $configscript
echo 'fi' >> $configscript

sudo chmod 755 $configscript

sudo rm -r /root/argon1-dietpi

sudo systemctl daemon-reload
sudo systemctl enable $daemonname.service

sudo systemctl start $daemonname.service

echo "***************************"
echo "Argon One Setup Completed."
echo "***************************"
echo 
echo "Use 'argonone-config' to configure fan"
echo "Use 'argonone-uninstall' to uninstall"
sleep 2
echo "8=====D"
sleep 1
echo "It's a rocket ship."
echo
