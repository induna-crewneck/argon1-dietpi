# Getting Argon1 Fan Hat to work on DietPi

The Argon 1 Fan Hat is a GPIO HAT, that controls the fan speed according to the RPis temperature. In theory, at least. The script provided doesn't work on DietPi due to lines 43 and 44:
```
sudo raspi-config nonint do_i2c 0
sudo raspi-config nonint do_serial 0
```

I'm trying to find a workaround to get it to work on the DietPi.

The original script can be downloaded and executed with 
```
curl https://download.argon40.com/argon1.sh | bash
```
In the end you should be able to run this command to test it and it should not yield any errors:
```
systemctl restart argononed.service
```

## Analyzing the code
**sudo** just tells the code to run the command as root.

**raspi-config** is replaced by dietpi-config in DietPi and for the most part it works the same. 

**nonint** is the noninteractive mode that the raspi-config supports but not the dietpi-config. This is where the compatibility issues start.

**do_i2c 0** enables i2c in the config.txt which for DietPi is located in /boot/. From the raspi-config code we see what exactly the command does:
```
do_i2c() {
  DEFAULT=--defaultno
  if [ $(get_i2c) -eq 0 ]; then
    DEFAULT=
  fi
  if [ "$INTERACTIVE" = True ]; then
    whiptail --yesno "Would you like the ARM I2C interface to be enabled?" $DEFAULT 20 60 2
    RET=$?
  else
    RET=$1
  fi
  if [ $RET -eq 0 ]; then
    SETTING=on
    STATUS=enabled
  elif [ $RET -eq 1 ]; then
    SETTING=off
    STATUS=disabled
  else
    return $RET
  fi
```

**do_serial 0** similarly enables serial UART. Here's the raspi-config code:
```
do_serial() {
  DEFAULTS=--defaultno
  DEFAULTH=--defaultno
  CURRENTS=0
  CURRENTH=0
  if [ $(get_serial) -eq 0 ]; then
      DEFAULTS=
      CURRENTS=1
  fi
  if [ $(get_serial_hw) -eq 0 ]; then
      DEFAULTH=
      CURRENTH=1
  fi
  if [ "$INTERACTIVE" = True ]; then
    whiptail --yesno "Would you like a login shell to be accessible over serial?" $DEFAULTS 20 60 2
    RET=$?
  else
    RET=$1
  fi
  if [ $RET -eq $CURRENTS ]; then
    ASK_TO_REBOOT=1
  fi
  if [ $RET -eq 0 ]; then
    if grep -q "console=ttyAMA0" $CMDLINE ; then
      if [ -e /proc/device-tree/aliases/serial0 ]; then
        sed -i $CMDLINE -e "s/console=ttyAMA0/console=serial0/"
      fi
    elif ! grep -q "console=ttyAMA0" $CMDLINE && ! grep -q "console=serial0" $CMDLINE ; then
      if [ -e /proc/device-tree/aliases/serial0 ]; then
        sed -i $CMDLINE -e "s/root=/console=serial0,115200 root=/"
      else
        sed -i $CMDLINE -e "s/root=/console=ttyAMA0,115200 root=/"
      fi
    fi
    set_config_var enable_uart 1 $CONFIG
    SSTATUS=enabled
    HSTATUS=enabled
  elif [ $RET -eq 1 ] || [ $RET -eq 2 ]; then
    sed -i $CMDLINE -e "s/console=ttyAMA0,[0-9]\+ //"
    sed -i $CMDLINE -e "s/console=serial0,[0-9]\+ //"
    SSTATUS=disabled
    if [ "$INTERACTIVE" = True ]; then
      whiptail --yesno "Would you like the serial port hardware to be enabled?" $DEFAULTH 20 60 2
      RET=$?
    else
      RET=$((2-$RET))
    fi
    if [ $RET -eq $CURRENTH ]; then
     ASK_TO_REBOOT=1
    fi
    if [ $RET -eq 0 ]; then
      set_config_var enable_uart 1 $CONFIG
      HSTATUS=enabled
    elif [ $RET -eq 1 ]; then
      set_config_var enable_uart 0 $CONFIG
      HSTATUS=disabled
    else
      return $RET
    fi
  else
    return $RET
  fi
  if [ "$INTERACTIVE" = True ]; then
      whiptail --msgbox "The serial login shell is $SSTATUS\nThe serial interface is $HSTATUS" 20 60 1
  fi
}
```

## Workaround
I tried placing the original raspi-config next to the dietpi-config and running the command but it seems not to work. Also adding the above code to the dietpi-config code doesn't work and sends us into the config GUI.

So it seems the changes need to be made manually:

### Enabling i2c

The files that need to be edited seem to be '/etc/modules' and the above mentioned '/boot/config.txt'. So first, to edit the modules file
```
nano /etc/modules
```
For me it was empty, but in any case the following line needs to be added to the list:
```
i2c-dev
```
In the '/boot/config.txt' an entry needs to be changed. So edit it with
```
nano /boot/config.txt
```
and look for this:
![i2c in config.txt](https://i.imgur.com/FqAylKA.png)
The lines could be commented (# in the front) in which case the # needs to be removed. Also the first line should say "off" by default, so change it. In the end it should look like in the image.


### Enabling serial
