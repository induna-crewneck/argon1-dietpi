# Getting Argon 1 Fan Hat to run on DietPi

You probably need to be logged in as root to make everything work. Not sure though. Speaking of which, this is very inofficial and DIY. Use at your own caution, please.

### Download my stuff
I have edited the argon1 script that installs the necessary files and makes the fan adapt to temperature, so that it works on DietPi. For it to work though we also need another file. So in total you'll need argon1.sh and argonsetup in /etc/argon1. These commands should take care of everything for you.

1. Installing required software.
```
apt-get install git raspi-gpio python-rpi.gpio python3-rpi.gpio python-smbus python3-smbus i2c-tools -y
```
2. Getting the Files from my GitHub Repository
```
git clone https://github.com/induna-crewneck/argon1-dietpi.git
```
3. Run the script
```
sh /root/argon1-dietpi/argon1.sh
```
4. reboot probably
```
reboot
```
5. clean up
```
rm -r /root/argon1-dietpi
```
6. Test
```
systemctl status argononed.service
```
