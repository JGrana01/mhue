# mhue
Hue Lighting Control for Asuswrt-Merlin based routers
## Installation
Using ssh/shell, execute the following line:

/usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/JGrana01/mhue/master/mhue.sh" -o "/jffs/scripts/mhue" && chmod 0755 /jffs/scripts/mhue && /jffs/scripts/mhue install

## Usage
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
