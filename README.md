# mhue
Hue Lighting Control for Asuswrt-Merlin based routers
## Installation
Using ssh/shell, execute the following line:

/usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/JGrana01/mhue/master/mhue.sh" -o "/jffs/scripts/mhue" && chmod 0755 /jffs/scripts/mhue && /jffs/scripts/mhue install

## About
mhue is a utility that provides a number of commands to manipulate lights, groups and scenes on a Philips Hue Hub.
It runs under the Asuswrt-Merlin firmware on Asus WiFi routers. It requires Entware to be installed.

mhue can turn lights/groups off and on, change colors, brightness, hue etc. It also supports turning on "scenes" that are setup for light groups.

mhue attempts to support the Asuswrt-Merlin "AddOn" philosophy. It has an install and uninstall function and puts the executable script in /jffs/scripts (with a
symbolic link to /opt/bin) and install a "conf" file in /jffs/addons/mhue.

## Installation

When mhue installs, it checks/downloads apps it needs (jq, column), sets up the /jffs/addons/mhue directory with a config file (mhue.conf).
It attempts to get the Philips Hue Hub IP address and if successful, set's that in the .conf file.
If it can't determine the IP address of the hue hub, the user will need to find it and put the information in mhue.con

Before mhue can issue commands to the Hue Hub, it requires and authenticated username (aka hash). mhue install will ask the user if it wants to
attempt to get one from the hub.
This requires the user to first press the round "link" button on the top of the hub, then press Enter when prompted by install.
If successful, it populates the ApiHash (username) in mhue.conf. mhue is now ready for use.
If the user decides to do this later or it fails, they can attempt it again wirh mhue by executing:

$ mhue gethueun

If mhue can't get one, the user will need to create a Philips Hue developers account (easy and free) and generate the ApiHash (username) following the steps here:

https://www.sitebase.be/generate-phillips-hue-api-token/

An example of a fully populated mhue.conf file looks like this:

```
# mhue settings
hueBridge='192.168.1.40'
huePort='80'
hueVerbose='1'
# ApiHash is required.
# If this field is empty, create an account an get and api key from:
#    https://developers.meethue.com/login/
# then insert the key below
hueTimeOut='5'
hueApiHash="akskfke9rofndfkioifjdf;k"
```
## Usage
mhue supports numerous commands along with command arguments. Here is the present list:

```
Usage:            mhue <command> | <light|group|scene> <number|name> <action> <value> [<value>]
==========================================================================
power usage                   :  mhue light|group n state <on|off> {color}
saturation                    :  mhue light|group n sat <0-255>
brightness                    :  mhue light|group n bri <0-255>
hue                           :  mhue light|group n hue <0-65535>
xy gamut                      :  mhue light|group n xy <0.0-1.0> <0.0-1.0>
ct color temp                 :  mhue light|group n ct <153-500>
color cycle                   :  mhue light|group n cycle <0-65535> <0-65535>
scene                         :  mhue scene scenename group

show lights/groups/scenes     :  mhue show <lights|groups|scenes|all>
colors - list colors          :  mhue colors
convert - color to xy         :  mhue convert <color>

help (this screen)            :  mhue help
install                       :  mhue install
uninstall                     :  mhue uninstall
get hub username              :  mhue gethueun
Show hub config               :  mhue hubconfig
==========================================================================
```
