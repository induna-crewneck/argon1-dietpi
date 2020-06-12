# Getting Argon 1 Fan Hat to run on DietPi

You probably need to be logged in as root to make everything work. Not sure though. Speaking of which, this is very inofficial and DIY. Use at your own caution, please.

I have modified the argon1 script that installs the necessary files and makes the fan adapt to temperature, so that it works on DietPi. It might be pretty hacky so if you know your way around this kind of code do yourself a favor and don't look at it. 

Installation is pretty straight forward. 

## The easy way
#### Up and running in 3 easy steps!
1. (Optional) If you don't have 'git' installed:
```
apt-get install git -y
```
2. Getting the Files from my GitHub Repository
```
git clone https://github.com/induna-crewneck/argon1-dietpi.git
```
3. Run the script
```
sudo sh /root/argon1-dietpi/argon1diet.sh
```
4. (Optional) Test
```
systemctl status argononed.service
```

## The hands-on way
#### If you want to get a little down and dirty
1. Download [argon1diet.sh](/argon1diet.sh)

2. Use FTP or whatever else means of getting files on your Pi to push the script (location doesn't matter AFAIK)

3. Use SSH or whatever else means of executing commands on your Pi

4. Run this command:
   ```
   sudo sh /root/argon1-dietpi/argon1diet.sh
   ```
5. (Optional) Run this command to see if it's working
   ```
   systemctl status argononed.service
   ```
6. Use the tools used in step 3 to remove the script. Unless you want to keep it as a memento of our little fan-installing-adventure. In this case you can place it in your souvenir folder. Mine is in /etc/remembrance/. Now you can look at it from time to time, reminiscing about the time before the argon 1 fan hat ran properly on your DietPi. And in those moments you would think of me and thank me for what I've done here today. You might even be tempted to run the script again, just to see if you can get the thrill back of running it the first time. But then you'd realize that moment is long gone and you can't go back to it. Unless? What's that you're thinking? You could reset your DietPi! Wipe everything! Start fresh! And then you could run the script again, as if it was the first time. And you would be back in that fleeting moment of bliss when the faint noise of the rotating fanblades atop your Raspberry Pi spin accelerated according to it's cpu temperature.

   Alternatively run
   ```
   rm path/to/argon1diet.sh
   ```

## The incredibly tedious, fully manual way
#### If you just want to feel something again and this is your last resort before starting to eat thumb tacks
1. Manually create the configuration file which asigns fan speeds to CPU temperature values
   ```
   nano /etc/argononed.conf
   ```
   In this file you enter whatever values you want. The mask is temp=fanspeed. The temperature is in °C, but you can manually convert that into freedom units should you need it. The default values are:
   ```
   55=10
   60=55
   65=100
   ```
   - Set permissions for this file
     ```
     chmod 666 /etc/argononed.conf
     ```
2. Manually create the script that runs every shutdown event because in some cases it's ok to let a script do the work for you
   ```
   nano /lib/systemd/system-shutdown/argononed-poweroff.py
   ```
   In this file you can either copy the code below or manually enter it:
```
#!/usr/bin/python
import sys
import smbus
import RPi.GPIO as GPIO
rev = GPIO.RPI_REVISION
if rev == 2 or rev == 3:
	bus = smbus.SMBus(1)
else:
	bus = smbus.SMBus(0)

if len(sys.argv)>1:
	bus.write_byte(0x1a,0)
	if sys.argv[1] == "poweroff" or sys.argv[1] == "halt":
		try:
			bus.write_byte(0x1a,0xFF)
		except:
			rev=0
```
   - Set permissions for this file
     ```
     chmod 755 /lib/systemd/system-shutdown/argononed-poweroff.py
     ```
3. Manually create the script that monitors the shutdown button on the fan hat
   ```
   nano /usr/bin/argononed.py
   ```
   In this file you can copy the code below but in this instance I really suggest you manually type it to fill that void in your heart:
```
#!/usr/bin/python
import smbus
import RPi.GPIO as GPIO
import os
import time
from threading import Thread
rev = GPIO.RPI_REVISION
if rev == 2 or rev == 3:
	bus = smbus.SMBus(1)
else:
	bus = smbus.SMBus(0)

GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)
shutdown_pin=4
GPIO.setup(shutdown_pin, GPIO.IN,  pull_up_down=GPIO.PUD_DOWN)

def shutdown_check():
	while True:
		pulsetime = 1
		GPIO.wait_for_edge(shutdown_pin, GPIO.RISING)
		time.sleep(0.01)
		while GPIO.input(shutdown_pin) == GPIO.HIGH:
			time.sleep(0.01)
			pulsetime += 1
		if pulsetime >=2 and pulsetime <=3:
			os.system("reboot")
		elif pulsetime >=4 and pulsetime <=5:
			os.system("shutdown now -h")

def get_fanspeed(tempval, configlist):
	for curconfig in configlist:
		curpair = curconfig.split("=")
		tempcfg = float(curpair[0])
		fancfg = int(float(curpair[1]))
		if tempval >= tempcfg:
			return fancfg
	return 0

def load_config(fname):
	newconfig = []
	try:
		with open(fname, "r") as fp:
			for curline in fp:
				if not curline:
					continue
				tmpline = curline.strip()
				if not tmpline:
					continue
				if tmpline[0] == "#":
					continue
				tmppair = tmpline.split("=")
				if len(tmppair) != 2:
					continue
				tempval = 0
				fanval = 0
				try:
					tempval = float(tmppair[0])
					if tempval < 0 or tempval > 100:
						continue
				except:
					continue
				try:
					fanval = int(float(tmppair[1]))
					if fanval < 0 or fanval > 100:
						continue
				except:
					continue
				newconfig.append( "{:5.1f}={}".format(tempval,fanval))
		if len(newconfig) > 0:
			newconfig.sort(reverse=True)
	except:
		return []
	return newconfig

def temp_check():
	fanconfig = ["65=100", "60=55", "55=10"]
	tmpconfig = load_config("'$daemonconfigfile'")
	if len(tmpconfig) > 0:
		fanconfig = tmpconfig
	address=0x1a
	prevblock=0
	while True:
		temp = os.popen("vcgencmd measure_temp").readline()
		temp = temp.replace("temp=","")
		val = float(temp.replace("'"'"'C",""))
		block = get_fanspeed(val, fanconfig)
		if block < prevblock:
			time.sleep(30)
		prevblock = block
		try:
			bus.write_byte(address,block)
		except IOError:
			temp=""
		time.sleep(30)

try:
	t1 = Thread(target = shutdown_check)
	t2 = Thread(target = temp_check)
	t1.start()
	t2.start()
except:
	t1.stop()
	t2.stop()
	GPIO.cleanup()
```
   - Set permissions for this file
     ```
     chmod 755 /usr/bin/argononed.py
     ```
4. Manually create the service that controls the fan
   ```
   nano /lib/systemd/system/argononed.service
   ```
   In this file you can either copy the code below or manually enter it:
```
[Unit]
Description=Argon One Fan and Button Service
After=multi-user.target
[Service]
Type=simple
Restart=always
RemainAfterExit=true
ExecStart=/usr/bin/python3 $powerbuttonscript
[Install]
WantedBy=multi-user.target
```
   - Set permissions for this file
     ```
     chmod 644 /lib/systemd/system/argononed.service
     ```
5. Enable and start the service
   ```
   systemctl daemon-reload
   systemctl enable argononed.service
   systemctl start argononed.service
   ```
6. You are done. You did it. You did such a great job. Give yourself a pat on the back. Or better yet:
  ```
  echo "I am proud of you"
  ```
