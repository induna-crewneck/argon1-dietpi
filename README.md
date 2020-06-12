# Getting Argon 1 Fan Hat to run on DietPi

You probably need to be logged in as root to make everything work. Not sure though. Speaking of which, this is very inofficial and DIY. Use at your own caution, please.

I have modified the argon1 script that installs the necessary files and makes the fan adapt to temperature, so that it works on DietPi. It might be pretty hacky so if you know your way around this kind of code do yourself a favor and don't look at it. 

Installation is pretty straight forward. 

### Easy way

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

### Manual way
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

