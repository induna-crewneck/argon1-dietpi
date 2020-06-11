<# Getting Argon 1 Fan Hat to run on DietPi

You probably need to be logged in as root to make everything work. Not sure though. Speaking of which, this is very inofficial and DIY. Use at your own caution, please.

### Download my stuff
I have edited the argon1 script that installs the necessary files and makes the fan adapt to temperature, so that it works on DietPi. For it to work though we also need another file. So in total you'll need argon1.sh and argonsetup in /etc/argon1. These commands should take care of everything for you.

1. Installing git. This is needed to clone repositories from github.
```
apt-get install git -y
```
2. Getting the Files from my GitHub Repository
```
git clone https://github.com/induna-crewneck/argon1-dietpi.git
```
3. Cleaning up some space by removing the unneeded files
```
rm -r /root/argon1-dietpi/.git
rm /root/argon1-dietpi/.internalinfo.md
rm /root/argon1-dietpi/README.md
```
4. Moving the Repo Files to where they need to be and making them accessible.
```
mv /root/argon1-dietpi/ /etc/argon1
chmod 777 /etc/argon1/argonsetup
```
5. Rebooting
```
reboot
```
6. After the reboot run the script
```
sh /etc/argon1/argon1.sh
```
