#!/bin/sh

# mhue: script for interacting with the philips hue light.
# 
# author  : Harald van der Laan
# modified for Asuswrt-Merlin: John Grana
# version : v0.7.1
# date    : 06/04/2021
#
# inplemented features:
# - powering a hue lightbulb or group
# - changing the saturation of the lightbulb or group
# - changing the brightness of the lightbulb or group
# - changing the hue of a lightbulb or group
# - changing the xy gamut of a lightbulb or group
# - changing the ct temperature of a lightbulb or group
# - demo (cycle) the colors of the hue system
#
# usage: 	hue.sh <light|group> <number> <action> <value> [<value>]
# power usage:	hue.sh light n state <on|off>
# saturation :	hue.sh light n sat <0-255>
# brightness :	hue.sh light n bri <0-255>
# hue        :	hue.sh light n hue <0-65535>
# xy	     :	hue.sh light n xy <0.0-1.0> <0.0-1.0>
# ct         :	hue.sh light n ct <153-500>
# cycle	     :  hue.sh light n cycle <0-65525> <0-65535>
#
# changelog:
# - v0.1		(initial release)			(HLA)
#
# - v0.2		Added hue cycle mode, this will cycle
#			through the color spectrum of the hue
#			lightbulb or group			(HLA)
#
# - v0.3		Added xy gamut change option. for more
#			info about gamut please go to the hue
#			api development page.			(HLA)
#
# - v0.3.1		Added extra check for curl package	(HLA)
#
# - v0.4		Added ct (color temperature)		(HLA)
#
# - v0.5		Fixed hueJsonData layout and redirect
#			curl output > /dev/nulll
#
# - v0.5.1		Changed brightness setting in cycle	(HLA)
#
# - v0.6.0		Added huePort for enter a no standard
#			port for the hue bridge			(HLA)
#
# - v0.7.0		Updated groups API route		(JJW)
#
# - v0.7.1		Added list of all lights and groups	(JJW)
#
# new fork - mhue
#
# - v0.1.0		Added support for Asuswrt-Merlin
#			changed some functions to be /bin/sh friendly
#			(no longer require bash shell)
#
#                       added install/uninstall 
#                       Asuswrt-merlin addon structure		(JJG)
#
# -v0.1.1		added support for scenes
#			added color manipulation support
#			added different "show" views 		(JJG)
#
# -v0.1.2		(Experimental) added function to
#			create hashed username			(JJG)
#
# -v0.1.3		added verbose mode for output
#			added more info after install		(JJG)
#

# global variables 

SCRIPTNAME="mhue"
SCRIPTDIR="/jffs/addons/$SCRIPTNAME"
SCRIPTVER="0.1.2"
SCRIPTCONF="$SCRIPTDIR/mhue.conf"
HUERESPONSE="/tmp/hueresponse"
HUEHASH="/tmp/mhue.hash"

Xval=0
Yval=0
debug=0

# functions
function usage() {
	echo ""
	echo "mhue Version $SCRIPTVER"
	echo ""
	echo "Usage:            mhue <command> | <light|group|scene> <number|name> <action> <value> [<value>]"
	echo "=========================================================================="
	echo "power usage                   :  mhue light|group n state <on|off> {color}"
	echo "saturation                    :  mhue light|group n sat <0-255>"
	echo "brightness                    :  mhue light|group n bri <0-255>"
	echo "hue                           :  mhue light|group n hue <0-65535>"
	echo "xy gamut                      :  mhue light|group n xy <0.0-1.0> <0.0-1.0>"
	echo "ct color temp                 :  mhue light|group n ct <153-500>"
	echo "color cycle                   :  mhue light|group n cycle <0-65535> <0-65535>"
	echo "scene                         :  mhue scene scenename group"
	echo ""	
	echo "show lights/groups/scenes     :  mhue show <lights|groups|scenes|all>"
	echo "colors - list colors          :  mhue colors"
	echo "convert - color to xy         :  mhue convert <color>"
	echo
	echo "help (this screen)            :  mhue help"
	echo "install                       :  mhue install"
	echo "uninstall                     :  mhue uninstall"
	echo "get hub username              :  mhue gethueun"
	echo "Show hub config               :  mhue hubconfig"
	echo "=========================================================================="
	exit 1
}

hueprint() {

	if [ "$hueVerbose" -eq "1" ]; then  
		echo $1
	fi
}

function checkapi() {
	if [ -f "$SCRIPTCONF" ]; then
		. "$SCRIPTCONF"
		hueBaseUrl="http://${hueBridge}:${huePort}/api/${hueApiHash}"
	else
		echo "[-] mhue: No $SCRIPTCONF found"
        	echo "[-] mhue: Please run mhue install and try again."
	exit 1
	fi
	if [[ $hueApiHash == "" ]]; then
		echo "[-] mhue: Failed to get IDs from API! Please edit your api hash variable in $SCRIPTCONF"
		exit 1
	fi
}

function showhuestuff() {

	if [ -z "$1" ]; then
		usage
		exit 1
	fi
	case "$1" in
		lights)
			showhuelights
			exit 0 ;;
		groups)
			showhuegroups
			exit 0 ;;
		scenes)
			showhuescenes
			exit 0 ;;
		all)
			showhuelights
			echo -n "Next...(press Enter)"
			read a
			showhuegroups
			echo -n "Next...(press Enter)"
			read a
			showhuescenes ;;
		*)
			usage 
			exit 1 ;;
	esac
}
			

function showhuelights() {

	checkapi
	echo ""
	echo "Lights:"
	curl -S --max-time ${hueTimeOut} --silent --request GET ${hueBaseUrl}/lights | jq -r 'keys[] as $k | "Light \($k)        :  \(.[$k] | .name)"'
	echo ""
}

function showhuegroups() {

	checkapi
	echo ""
	echo "Groups:"
	curl -S --max-time ${hueTimeOut} --silent --request GET ${hueBaseUrl}/groups | jq -r 'keys[] as $k | "Group \($k)        :  \(.[$k] | .name)"'
	echo ""
}

function showhuescenes() {
	
	checkapi
	checkscenes
	echo ""
	echo "Scenes:"
	if [ $(cat $SCRIPTDIR/scenes.group | wc -l ) -gt 1 ]; then
		echo "Scene              Group"
		echo "----------------------------------"
		column -t "$SCRIPTDIR/scenes.group"
	else
		echo "No scenes found"
	fi
	echo ""
}

function checkscenes() {

	if [ -f "$SCRIPTDIR/scenes.json" ]; then
		return
	fi
	curl -S --max-time ${hueTimeOut} --silent -o "$SCRIPTDIR/scenes.json" --request GET ${hueBaseUrl}/scenes
	if [ $(jq '.' $SCRIPTDIR/scenes.json | wc -l ) -gt 1 ]; then
		jq '.[] | .name + ":" + .group' "$SCRIPTDIR/scenes.json" | sed 's/ /_/g' | sed 's/:/ /' | sed 's/\"//g' > "$SCRIPTDIR/scenes.group"

		cat "$SCRIPTDIR/scenes.json" | jq -r 'keys[] as $k | "\($k)\t\(.[$k] | .name)"' | sed "s/ /_/g" > "$SCRIPTDIR/scenes"
	else
		echo "No scenes found"
	fi
}

function huePower() {
	local hueType=${1}
	local hueTypeNumber=${2}
	local hueState=${3}
	local hueColor=$4

	if ! echo "${hueTypeNumber}" | grep -q "^[0-9]"
	then
		echo "[-] mhue: ${hueType} number: ${hueTypeNumber} is not a number."
		exit 1
	fi

	case ${hueType} in
		light) hueUrl="${hueBaseUrl}/lights/${hueTypeNumber}/state" ;;
		group) hueUrl="${hueBaseUrl}/groups/${hueTypeNumber}/action" ;;
		*) echo "[-] mhue: The hue device mode is not light, group or scene."; exit 1 ;;
	esac
	
	case ${hueState} in
		on) hueJsonData='{"on":true}' ;;
		off) hueJsonData='{"on":false}' ;;
		*) echo "[-] mhue: The hue state can only be on or off."; exit 1 ;;
	esac

if [ "$debug" -eq 1 ]; then
	echo ${hueUrl}
	echo ${hueJsonData}
	echo ${hueColor}
	read a
fi


	curl --max-time ${hueTimeOut} --silent --request PUT --data ${hueJsonData} ${hueUrl} > $HUERESPONSE
	
	if [ ${?} -ne 0 ]; then
		echo "[-] mhue: Failed to send power command to ${hueType}/${hueTypeNumber}."
		echo "Hue response: $HUERESPONSE"
		exit 1
	fi

# check for a color argument

        if echo "${hueColor}" | grep -q "^[a-z]"
	then
		$(hue_color convert "$hueColor")
		hueXy "$hueType" "$hueTypeNumber" "$Xval" "$Yval"
		hueprint "[+] mhue: Power and color sent successfully to ${hueType}/${hueTypeNumber}."
	else
		hueprint "[+] mhue: Power command send successfully to ${hueType}/${hueTypeNumber}."
	fi

}

# $1 = group # $2 = scene

function hueSceneOn() {
	
	checkapi
	checkscenes

	hueBaseUrl="http://${hueBridge}:${huePort}/api/${hueApiHash}"

	local hueGroup=${2}
	local hueScene=${1}

        if echo "${hueGroup}" | grep -q "#[0-9]"
        then
           echo "[-] mhue: Group # is not a number ${hueGroup}"
           exit 1
        fi


	hueSceneId=$(grep "$hueScene" "$SCRIPTDIR/scenes" | awk '{print $1}')
	if [ -z "$hueSceneId" ]; then
		echo "[-] mhue: ${hueScene} : is not a scene."
		exit 1
	fi


	hueUrl="${hueBaseUrl}/groups/${hueGroup}/action"
	
	hueJsonData="{\"on\":true,\"scene\":\"$hueSceneId\"}"


	curl --max-time ${hueTimeOut} --request PUT --data ${hueJsonData} ${hueUrl}
	
	if [ ${?} -ne 0 ]; then
		echo "[-] mhue: Failed to send scene command to ${hueGroup}/${hueScene}."
		exit 1
	fi

	hueprint "[+] mhue: scene sent successfully to ${hueGroup}/${hueScene}."
}


function hueSaturation() {
	local hueType=${1}
	local hueTypeNumber=${2}
	local hueState=${3}
	
	if ! echo "${hueTypeNumber}" | grep -q "^[0-9]"
	then
                echo "[-] mhue: ${hueType} number: ${hueTypeNumber} is not a number."
                exit 1
        fi
	
	case ${hueType} in
                light) hueUrl="${hueBaseUrl}/lights/${hueTypeNumber}/state" ;;
                group) hueUrl="${hueBaseUrl}/groups/${hueTypeNumber}/action" ;;
                *) echo "[-] mhue: The Hue device mode is not light or group."; exit 1 ;;
        esac
	
#	if [[ ${hueState} != *[[:digit:]]* ]]; then
	if ! echo "${hueState}" | grep -q "^[0-9]"
	then
		echo "[-] mhue: Saturation value: ${hueState} is not a number."
		exit 1
	fi 

	if [ ${hueState} -lt 0 -o ${hueState} -gt 255 ]; then
		echo "[-] mhue: Saturation value must be between 0 and 255."
		exit 1
	fi
	
	curl --max-time ${hueTimeOut} --silent --request PUT --data '{"sat":'${hueState}'}' ${hueUrl} &> /dev/null
	
	if [ ${?} -ne 0 ]; then
		echo "[-] mhue: Failed to send saturation command to ${hueType}/${hueTypeNumber}."
		exit 1
	fi
	
	hueprint "[+] mhue: Saturation command send successfully to ${hueType}/${hueTypeNumber}."
}

function hueBrightness() {
        local hueType=${1}
        local hueTypeNumber=${2}
        local hueState=${3}

#        if [[ ${hueTypeNumber} != *[[:digit:]]* ]]; then 
	if ! echo "${hueTypeNumber}" | grep -q "^[0-9]"
	then
                echo "[-] mhue: ${hueType} number: ${hueTypeNumber} is not a number."
                exit 1
        fi

        case ${hueType} in
                light) hueUrl="${hueBaseUrl}/lights/${hueTypeNumber}/state" ;;
                group) hueUrl="${hueBaseUrl}/groups/${hueTypeNumber}/action" ;;
                *) echo "[-] mhue: The Hue device mode is not light or group."; exit 1 ;;
        esac

#	if [[ ${hueState} != *[[:digit:]]* ]]; then
	if ! echo "${hueState}" | grep -q "^[0-9]"
	then
                echo "[-] mhue: Brightness value: ${hueState} is not a number."
                exit 1
        fi

        if [ ${hueState} -lt 0 -o ${hueState} -gt 255 ]; then
                echo "[-] mhue: Brightness value must be between 0 and 255."
                exit 1
        fi

        curl --max-time ${hueTimeOut} --silent --request PUT --data '{"bri":'${hueState}'}' ${hueUrl} &> /dev/null

        if [ ${?} -ne 0 ]; then
                echo "[-] mhue: Failed to send brightness command to ${hueType}/${hueTypeNumber}."
                exit 1
        fi

        hueprint "[+] mhue: Brightness command send successfully to ${hueType}/${hueTypeNumber}."
}

function hueHue() {
        local hueType=${1}
        local hueTypeNumber=${2}
        local hueState=${3}

#        if [[ ${hueTypeNumber} != *[[:digit:]]* ]]; then 
	if ! echo "${hueTypeNumber}" | grep -q "^[0-9]"
	then
                echo "[-] mhue: ${hueType} number: ${hueTypeNumber} is not a number."
                exit 1
        fi

        case ${hueType} in
                light) hueUrl="${hueBaseUrl}/lights/${hueTypeNumber}/state" ;;
                group) hueUrl="${hueBaseUrl}/groups/${hueTypeNumber}/action" ;;
                *) echo "[-] mhue: The Hue device mode is not light or group."; exit 1 ;;
        esac
	
#	if [[ ${hueState} != *[[:digit:]]* ]]; then
	if ! echo "${hueState}" | grep -q "^[0-9]"
	then
                echo "[-] mhue: Hue value: ${hueState} is not a number."
                exit 1
        fi

        if [ ${hueState} -lt 0 -o ${hueState} -gt 65535 ]; then
                echo "[-] mhue: Hue value must be between 0 and 65535."
                exit 1
        fi

        curl --max-time ${hueTimeOut} --silent --request PUT --data '{"hue":'${hueState}'}' ${hueUrl} &> /dev/null

        if [ ${?} -ne 0 ]; then
                echo "[-] mhue: Failed to send hue command to ${hueType}/${hueTypeNumber}."
                exit 1
        fi

        hueprint "[+] mhue: Hue command send successfully to ${hueType}/${hueTypeNumber}."
}

function hueXy() {
	local hueType=${1}
        local hueTypeNumber=${2}
        local hueState1=${3}
        local hueState2=${4}

#	if [[ ${hueTypeNumber} != *[[:digit:]]* ]]; then
	if ! echo "${hueTypeNumber}" | grep -q "^[0-9]"
	then
                echo "[-] mhue: ${hueType} number: ${hueTypeNumber} is not a number."
                exit 1
        fi

        case ${hueType} in
                light) hueUrl="${hueBaseUrl}/lights/${hueTypeNumber}/state" ;;
                group) hueUrl="${hueBaseUrl}/groups/${hueTypeNumber}/action" ;;
                *) echo "[-] mhue: The xy device mode is not light or group."; exit 1 ;;
        esac

#        if [[ ${hueState1} != *[[:digit:]]* ]]; then
	if ! echo "${hueState1}" | grep -q "^[0-9]"
	then
                echo "[-] mhue: Xy value1: ${hueState1} is not a number."
                exit 1
        fi

#        if [[ ${hueState2} != *[[:digit:]]* ]]; then
	if ! echo "${hueState2}" | grep -q "^[0-9]"
	then
                echo "[-] mhue: Xy value2: ${hueState2} is not a number."
                exit 1
        fi	
	

	curl --max-time ${hueTimeOut} --silent --request PUT --data '{"xy":['${hueState1}','${hueState2}']}' ${hueUrl} &> /dev/null
	
	if [ ${?} -ne 0 ]; then
		echo "[-] mhue: Failed to send xy command to ${hueType}/${hueTypeNumber}."
                exit 1
        fi

        hueprint "[+] mhue: Xy command sent successfully to ${hueType}/${hueTypeNumber}." 
}

function hueCt() {
	local hueType=${1}
        local hueTypeNumber=${2}
        local hueState=${3}

#        if [[ ${hueTypeNumber} != *[[:digit:]]* ]]; then
	if ! echo "${hueTypeNumber}" | grep -q "^[0-9]"
	then
                echo "[-] mhue: ${hueType} number: ${hueTypeNumber} is not a number."
                exit 1
        fi

        case ${hueType} in
                light) hueUrl="${hueBaseUrl}/lights/${hueTypeNumber}/state" ;;
                group) hueUrl="${hueBaseUrl}/groups/${hueTypeNumber}/action" ;;
                *) echo "[-] mhue: The Hue device mode is not light or group."; exit 1 ;;
        esac

#        if [[ ${hueState} != *[[:digit:]]* ]]; then
	if ! echo "${hueState}" | grep -q "^[0-9]"
	then
                echo "[-] mhue: Ct  value: ${hueState} is not a number."
                exit 1
        fi

        if [ ${hueState} -lt 153 -o ${hueState} -gt 500 ]; then
                echo "[-] mhue: Ct value must be between 0 and 255."
                exit 1
        fi

        curl --max-time ${hueTimeOut} --silent --request PUT --data '{"ct":'${hueState}'}' ${hueUrl} &> /dev/null

        if [ ${?} -ne 0 ]; then
                echo "[-] mhue: Failed to send ct command to ${hueType}/${hueTypeNumber}."
                exit 1
        fi

        hueprint "[+] mhue: Ct command send successfully to ${hueType}/${hueTypeNumber}."
}

function hueCycle() {
	local hueType=${1}
        local hueTypeNumber=${2}
        local hueState1=${3}
	local hueState2=${4}
	
#	if [[ ${hueTypeNumber} != *[[:digit:]]* ]]; then
	if ! echo "${hueTypeNumber}" | grep -q "^[0-9]"
	then
                echo "[-] mhue: ${hueType} number: ${hueTypeNumber} is not a number."
                exit 1
        fi

        case ${hueType} in
                light) hueUrl="${hueBaseUrl}/lights/${hueTypeNumber}/state" ;;
                group) hueUrl="${hueBaseUrl}/groups/${hueTypeNumber}/action" ;;
                *) echo "[-] mhue: The cycle device mode is not light or group."; exit 1 ;;
        esac

#        if [[ ${hueState1} != *[[:digit:]]* ]]; then
	if ! echo "${hueState1}" | grep -q "^[0-9]"
	then
                echo "[-] mhue: Cycle value1: ${hueState1} is not a number."
                exit 1
        fi
	
#	if [[ ${hueState2} != *[[:digit:]]* ]]; then
	if ! echo "${hueState2}" | grep -q "^[0-9]"
	then
                echo "[-] mhue: Cycle value2: ${hueState2} is not a number."
                exit 1
        fi
	
	if [ ${hueState1} -lt 0 -o ${hueState1} -gt 65535 ]; then
		echo "[-] mhue: Cycle value1 must be between 0 and 65535."
		exit 1
	fi
	
	if [ ${hueState2} -lt 0 -o ${hueState2} -gt 65535 ]; then
                echo "[-] mhue: Cycle value2 must be between 0 and 65535."
                exit 1
        fi
	
	if [ ${hueState1} -ge ${hueState2} ]; then
		echo "[-] mhue: Cycle value1 must be smaller then cycle value2."
		exit 1
	fi
	
	curl --max-time ${hueTimeOut} --silent --request PUT --data '{"on":true,"bri":254,"hue":54000,"sat":255}' ${hueUrl} &> /dev/null
	
	if [ ${?} -ne 0 ]; then
		echo "[-] mhue: Failed to send reset command to ${hueType}/${hueTypeNumber}."
	fi
	
#	for (( hueValue=${hueState1}; hueValue<=${hueState2}; hueValue+=1000 )); do
	lcount=${hueState1}
	while [ "$lcount" -lt "$hueState2" ]; do
		curl --max-time ${hueTimeOut} --silent --request PUT --data '{"hue":'${lcount}'}' ${hueUrl} &> /dev/null
		if [ ${?} -ne 0 ]; then
			echo "[-] mhue: Failed to send cycle command to ${hueType}/${hueTypeNumber}, Hue is: ${hueValue}."
		else
			hueprint "[ ] Hue: Cycle command successfully send to ${hueType}/${hueTypeNumber}, Hue is: ${hueValue}."
		fi

		sleep 1
		echo -n "hue $lcount ? "
		read a
		lcount="$((lcount + 1000))"
	done
}

# hue_color
# snippet from:
#     https://raw.githubusercontent.com/Josef-Friedrich/Hue-shell/master/base.sh


# Convert color strings to hue values.
#	$1: COLOR_NAME
# to show x y values:
#       $1: show    $2 COLOR_NAME
# internal $1: convert   $2 COLOR_NAME
#     populate Xval and Yval
#
# Always uses Gamut B - most common
#

function hue_color() {

SHOWXY=0

if [ "$1" = "show" ]; then
	SHOWXY=1
	lookcolor="$2"
elif [ "$1" = "convert" ]; then
	SHOWXY=2
   	lookcolor="$2"
else
	lookcolor="$1"
fi

# Gamut B (most typical)
	case "$lookcolor" in
		alice-blue) COLOR='-x 0.3092 -y 0.321' ;;
		antique-white) COLOR='-x 0.3548 -y 0.3489' ;;
		aqua) COLOR='-x 0.2858 -y 0.2747' ;;
		aquamarine) COLOR='-x 0.3237 -y 0.3497' ;;
		azure) COLOR='-x 0.3123 -y 0.3271' ;;
		beige) COLOR='-x 0.3402 -y 0.356' ;;
		bisque) COLOR='-x 0.3806 -y 0.3576' ;;
		black) COLOR='-x 0.168 -y 0.041' ;;
		blanched-almond) COLOR='-x 0.3695 -y 0.3584' ;;
		blue) COLOR='-x 0.168 -y 0.041' ;;
		blue-violet) COLOR='-x 0.251 -y 0.1056' ;;
		brown) COLOR='-x 0.6399 -y 0.3041' ;;
		burlywood) COLOR='-x 0.4236 -y 0.3811' ;;
		cadet-blue) COLOR='-x 0.2961 -y 0.295' ;;
		chartreuse) COLOR='-x 0.408 -y 0.517' ;;
		chocolate) COLOR='-x 0.6009 -y 0.3684' ;;
		coral) COLOR='-x 0.5763 -y 0.3486' ;;
		cornflower) COLOR='-x 0.2343 -y 0.1725' ;;
		cornsilk) COLOR='-x 0.3511 -y 0.3574' ;;
		crimson) COLOR='-x 0.6417 -y 0.304' ;;
		cyan) COLOR='-x 0.2858 -y 0.2747' ;;
		dark-blue) COLOR='-x 0.168 -y 0.041' ;;
		dark-cyan) COLOR='-x 0.2858 -y 0.2747' ;;
		dark-goldenrod) COLOR='-x 0.5204 -y 0.4346' ;;
		dark-gray) COLOR='-x 0.3227 -y 0.329' ;;
		dark-green) COLOR='-x 0.408 -y 0.517' ;;
		dark-khaki) COLOR='-x 0.4004 -y 0.4331' ;;
		dark-magenta) COLOR='-x 0.3824 -y 0.1601' ;;
		dark-olive-green) COLOR='-x 0.3908 -y 0.4829' ;;
		dark-orange) COLOR='-x 0.5916 -y 0.3824' ;;
		dark-orchid) COLOR='-x 0.2986 -y 0.1341' ;;
		dark-red) COLOR='-x 0.674 -y 0.322' ;;
		dark-salmon) COLOR='-x 0.4837 -y 0.3479' ;;
		dark-sea-green) COLOR='-x 0.3429 -y 0.3879' ;;
		dark-slate-blue) COLOR='-x 0.2218 -y 0.1477' ;;
		dark-slate-gray) COLOR='-x 0.2982 -y 0.2993' ;;
		dark-turquoise) COLOR='-x 0.2835 -y 0.2701' ;;
		dark-violet) COLOR='-x 0.2836 -y 0.1079' ;;
		deep-pink) COLOR='-x 0.5386 -y 0.2468' ;;
		deep-sky-blue) COLOR='-x 0.2428 -y 0.1893' ;;
		dim-gray) COLOR='-x 0.3227 -y 0.329' ;;
		dodger-blue) COLOR='-x 0.2115 -y 0.1273' ;;
		firebrick) COLOR='-x 0.6566 -y 0.3123' ;;
		floral-white) COLOR='-x 0.3361 -y 0.3388' ;;
		forest-green) COLOR='-x 0.408 -y 0.517' ;;
		fuchsia) COLOR='-x 0.3824 -y 0.1601' ;;
		gainsboro) COLOR='-x 0.3227 -y 0.329' ;;
		ghost-white) COLOR='-x 0.3174 -y 0.3207' ;;
		gold) COLOR='-x 0.4859 -y 0.4599' ;;
		goldenrod) COLOR='-x 0.5113 -y 0.4413' ;;
		gray) COLOR='-x 0.3227 -y 0.329' ;;
		web-gray) COLOR='-x 0.3227 -y 0.329' ;;
		green) COLOR='-x 0.408 -y 0.517' ;;
		web-green) COLOR='-x 0.408 -y 0.517' ;;
		green-yellow) COLOR='-x 0.408 -y 0.517' ;;
		honeydew) COLOR='-x 0.3213 -y 0.345' ;;
		hot-pink) COLOR='-x 0.4682 -y 0.2452' ;;
		indian-red) COLOR='-x 0.5488 -y 0.3112' ;;
		indigo) COLOR='-x 0.2437 -y 0.0895' ;;
		ivory) COLOR='-x 0.3334 -y 0.3455' ;;
		khaki) COLOR='-x 0.4019 -y 0.4261' ;;
		lavender) COLOR='-x 0.3085 -y 0.3071' ;;
		lavender-blush) COLOR='-x 0.3369 -y 0.3225' ;;
		lawn-green) COLOR='-x 0.408 -y 0.517' ;;
		lemon-chiffon) COLOR='-x 0.3608 -y 0.3756' ;;
		light-blue) COLOR='-x 0.2975 -y 0.2979' ;;
		light-coral) COLOR='-x 0.5075 -y 0.3145' ;;
		light-cyan) COLOR='-x 0.3096 -y 0.3218' ;;
		light-goldenrod) COLOR='-x 0.3504 -y 0.3717' ;;
		light-gray) COLOR='-x 0.3227 -y 0.329' ;;
		light-green) COLOR='-x 0.3682 -y 0.438' ;;
		light-pink) COLOR='-x 0.4112 -y 0.3091' ;;
		light-salmon) COLOR='-x 0.5016 -y 0.3531' ;;
		light-sea-green) COLOR='-x 0.2946 -y 0.292' ;;
		light-sky-blue) COLOR='-x 0.2714 -y 0.246' ;;
		light-slate-gray) COLOR='-x 0.2924 -y 0.2877' ;;
		light-steel-blue) COLOR='-x 0.293 -y 0.2889' ;;
		light-yellow) COLOR='-x 0.3436 -y 0.3612' ;;
		lime) COLOR='-x 0.408 -y 0.517' ;;
		lime-green) COLOR='-x 0.408 -y 0.517' ;;
		linen) COLOR='-x 0.3411 -y 0.3387' ;;
		magenta) COLOR='-x 0.3824 -y 0.1601' ;;
		maroon) COLOR='-x 0.5383 -y 0.2566' ;;
		web-maroon) COLOR='-x 0.674 -y 0.322' ;;
		medium-aquamarine) COLOR='-x 0.3224 -y 0.3473' ;;
		medium-blue) COLOR='-x 0.168 -y 0.041' ;;
		medium-orchid) COLOR='-x 0.3365 -y 0.1735' ;;
		medium-purple) COLOR='-x 0.263 -y 0.1773' ;;
		medium-sea-green) COLOR='-x 0.3588 -y 0.4194' ;;
		medium-slate-blue) COLOR='-x 0.2189 -y 0.1419' ;;
		medium-spring-green) COLOR='-x 0.3622 -y 0.4262' ;;
		medium-turquoise) COLOR='-x 0.2937 -y 0.2903' ;;
		medium-violet-red) COLOR='-x 0.5002 -y 0.2255' ;;
		midnight-blue) COLOR='-x 0.1825 -y 0.0697' ;;
		mint-cream) COLOR='-x 0.3165 -y 0.3355' ;;
		misty-rose) COLOR='-x 0.3581 -y 0.3284' ;;
		moccasin) COLOR='-x 0.3927 -y 0.3732' ;;
		navajo-white) COLOR='-x 0.4027 -y 0.3757' ;;
		navy-blue) COLOR='-x 0.168 -y 0.041' ;;
		old-lace) COLOR='-x 0.3421 -y 0.344' ;;
		olive) COLOR='-x 0.4317 -y 0.4996' ;;
		olive-drab) COLOR='-x 0.408 -y 0.517' ;;
		orange) COLOR='-x 0.5562 -y 0.4084' ;;
		orange-red) COLOR='-x 0.6733 -y 0.3224' ;;
		orchid) COLOR='-x 0.3688 -y 0.2095' ;;
		pale-goldenrod) COLOR='-x 0.3751 -y 0.3983' ;;
		pale-green) COLOR='-x 0.3657 -y 0.4331' ;;
		pale-turquoise) COLOR='-x 0.3034 -y 0.3095' ;;
		pale-violet-red) COLOR='-x 0.4658 -y 0.2773' ;;
		papaya-whip) COLOR='-x 0.3591 -y 0.3536' ;;
		peach-puff) COLOR='-x 0.3953 -y 0.3564' ;;
		peru) COLOR='-x 0.5305 -y 0.3911' ;;
		pink) COLOR='-x 0.3944 -y 0.3093' ;;
		plum) COLOR='-x 0.3495 -y 0.2545' ;;
		powder-blue) COLOR='-x 0.302 -y 0.3068' ;;
		purple) COLOR='-x 0.2725 -y 0.1096' ;;
		web-purple) COLOR='-x 0.3824 -y 0.1601' ;;
		rebecca-purple) COLOR='-x 0.2703 -y 0.1398' ;;
		red) COLOR='-x 0.674 -y 0.322' ;;
		rosy-brown) COLOR='-x 0.4026 -y 0.3227' ;;
		royal-blue) COLOR='-x 0.2047 -y 0.1138' ;;
		saddle-brown) COLOR='-x 0.5993 -y 0.369' ;;
		salmon) COLOR='-x 0.5346 -y 0.3247' ;;
		sandy-brown) COLOR='-x 0.5104 -y 0.3826' ;;
		sea-green) COLOR='-x 0.3602 -y 0.4223' ;;
		seashell) COLOR='-x 0.3397 -y 0.3353' ;;
		sienna) COLOR='-x 0.5714 -y 0.3559' ;;
		silver) COLOR='-x 0.3227 -y 0.329' ;;
		sky-blue) COLOR='-x 0.2807 -y 0.2645' ;;
		slate-blue) COLOR='-x 0.2218 -y 0.1444' ;;
		slate-gray) COLOR='-x 0.2944 -y 0.2918' ;;
		snow) COLOR='-x 0.3292 -y 0.3285' ;;
		spring-green) COLOR='-x 0.3882 -y 0.4777' ;;
		steel-blue) COLOR='-x 0.248 -y 0.1997' ;;
		tan) COLOR='-x 0.4035 -y 0.3772' ;;
		teal) COLOR='-x 0.2858 -y 0.2747' ;;
		thistle) COLOR='-x 0.3342 -y 0.2971' ;;
		tomato) COLOR='-x 0.6112 -y 0.3261' ;;
		turquoise) COLOR='-x 0.2997 -y 0.3022' ;;
		violet) COLOR='-x 0.3644 -y 0.2133' ;;
		wheat) COLOR='-x 0.3852 -y 0.3737' ;;
		white) COLOR='-x 0.3227 -y 0.329' ;;
		white-smoke) COLOR='-x 0.3227 -y 0.329' ;;
		yellow) COLOR='-x 0.4317 -y 0.4996' ;;
		yellow-green) COLOR='-x 0.408 -y 0.517' ;;
		*) COLOR='No Color Found' ;;
	esac

	if [ "$SHOWXY" = "1" ]; then
		echo "$COLOR"
	elif [ "$SHOWXY" = "2" ]; then
			Xval=$(echo "$COLOR" | awk '{print $2}')
			Yval=$(echo "$COLOR" | awk '{print $4}')
	else
		echo "$COLOR" | sed 's/-x //' | sed 's/-y //'
	fi
}

# gethue_user - get a Hue hub username
#       reqires user to press the link button on top of the hue
#       very experimental - might not work in all cases.
#    


gethue_user() {
	if [ -f "$SCRIPTCONF" ]; then
		. "$SCRIPTCONF"
	else
		echo "[-] mhue: No $SCRIPTCONF found"
        	echo "[-] mhue: Please run mhue install and try again."
	exit 1
	fi

	hueBaseUrl="http://${hueBridge}:${huePort}"
	hueUrl="${hueBaseUrl}/api" 
	hueJsonData='{"devicetype":"mhue#admin"}'

	cat <<EOF

Attempting to get a hashed username from your Hue hub. This
will require you to press the round link button on top of the hub.
If you can't do this right now, you will need to create a hue
developers account and create a username there.
Once you press the link button, you will have no more than 25-30 seconds
to contniue

EOF
	echo -n "Do you want to proceed? Press Y to proceed any other key to exit? "
	read a
	if [ "$a" == "Y" ] || [ "$a" == "y" ]; then
		echo
		echo
		echo -n "Press the link button - then press enter..."
		echo
		read a
		curl --max-time ${hueTimeOut} --request POST --data ${hueJsonData} ${hueUrl} > $HUEHASH
		if [ $(grep -c 'error' $HUEHASH) -gt 0 ]; then
			if [ $(grep -c 'button' $HUEHASH) -gt 0 ]; then
				echo
				echo "Hue hub reported that the Link button wasnt pressed"
				sleep 1
				showhowun
				rm -f $HUEHASH
				exit 1
			else
				echo "Hue responded with an unexpected error:"
				cat $HUEHASH
				showhowun
				rm -f $HUEHASH
				exit 1
			fi
		else

			huekey=$(cat $HUEHASH | awk 'BEGIN { FS = "\"" } ; {print $6};')
			echo "Success hue username key is $huekey"
			sed -i '/hueApiHash/d' $SCRIPTCONF
			echo "hueApiHash=\"$huekey\"" >> $SCRIPTCONF
			echo
			echo "Updated $SCRIPTCONF:"
			echo
			sleep 2
			cat $SCRIPTCONF
			echo
			echo "Install done."

		fi
	else
		showhowun
	fi
rm -f $HUEHASH
}

gethueconfig() {
	if [ -f "$SCRIPTCONF" ]; then
		. "$SCRIPTCONF"
	else
		echo "[-] mhue: No $SCRIPTCONF found"
        	echo "[-] mhue: Please run mhue install and try again."
	exit 1
	fi

	hueBaseUrl="http://${hueBridge}:${huePort}"
	hueUrl="${hueBaseUrl}/api/${hueApiHash}/config" 
	curl --max-time ${hueTimeOut} --request GET ${hueUrl} > $SCRIPTDIR/hueconfig
	jq -C '.' $SCRIPTDIR/hueconfig | more
}


showhowun() {
		cat <<EOF

You can try again by running mhue with this argument:
  mhue gethueun

If that fails again... You will need to create one manually at:

        https://developers.meethue.com/develop/get-started-2/

Setting up a developers account is required and free (and easy).

Once you get the username, copy it and insert it into the $SCRIPTCONF file:
hueApiHash=xxxxxxxxxxxxxxxxx

EOF
}


install_hue() {
	echo "Creating script directory ${SCRIPTDIR}"
        mkdir -p "$SCRIPTDIR"
        if [ ! -x /opt/bin/opkg ]; then
                printf "\\nmhue requires Entware to be installed\\n"
                printf "\\nInstall Entware using amtm and run mhue install\\n"
                exit 1
        else
                echo "Checking for and installing required apps"
		entwareup=0
                for app in jq column; do
                        if [ ! -x /opt/bin/$app ]; then
				if [ "$entwareup" = "0" ]; then
                			opkg update
					entwareup=1
				fi
                                echo "Installing $app to /opt/bin"
                                opkg install $app
                        fi
                done
        fi
        if [ -d "/opt/bin" ] && [ ! -L "/opt/bin/mhue" ]; then
                ln -s "/jffs/scripts/mhue" /opt/bin/mhue
               	chmod 0755 "/opt/bin/mhue"
        fi
	echo "Creating conf file"
        echo "# mhue settings  " > "$SCRIPTCONF"
	hubip=$(arp -n | grep "00:17:88" | grep -oP '(?<=[(])[^)]*')
	if [ ! -z $hubip ]; then
		echo "hueBridge='${hubip}'" >> "$SCRIPTCONF"
	else
		echo "Couldnt fine hue bridge on the network."
		echo "You will need to find it and add it to ${SCRIPTDIR}/mhue.conf"
		echo "hueBridge=''" >> "$SCRIPTCONF"
	fi
	echo "huePort='80'" >> "$SCRIPTCONF"
	echo "hueVerbose='0'" >> "$SCRIPTCONF"
        echo "# ApiHash is required. " >> "$SCRIPTCONF"
        echo "# If this field is empty, create an account an get and api key from: " >> "$SCRIPTCONF"
        echo "#    https://developers.meethue.com/login/ " >> "$SCRIPTCONF"
        echo "# then insert the key below " >> "$SCRIPTCONF"
	echo "hueApiHash=''" >> "$SCRIPTCONF"
        echo "hueTimeOut='5'" >> "$SCRIPTCONF"

# attempt to see about a username/key

	if [ ! -z $hubip ]; then
		gethue_user
	else
		echo "No valid hub found - no username/key generated"
		echo "Find the hubs local IP address and update $SCRIPTCONF"
		exit 1
	fi

}

remove_hue() {
	printf "\\n Uninstall mhue and it's data/directories? [Y=Yes] ";read -r continue
	case "$continue" in
		Y|y) printf "\\n Uninstalling...\\n"
		   rm -rf "$SCRIPTDIR"
                   rm -f /jffs/scripts/mhue
                   if [ -L /opt/bin/mhue ]; then
			rm -f /opt/bin/mhue
		   fi
		   printf "\\nmhue uninstalled\\n"
		;;
		*) printf "\\nmhue NOT uninstalled\\n"
		;;
	esac
}



# main script

if [ ${#} -eq 0 ]; then
	usage
	exit 0
fi


if [ ${#} -le 3 ]; then
	case "$1" in
		install)
			install_hue
			exit 0
		;;
		uninstall)
			remove_hue
			exit 0
		;;
		show)
			showhuestuff $2
			exit 0
		;;
		colors)
			grep "COLOR=" /jffs/scripts/mhue | awk 'BEGIN { FS = ")" } ; { print $1 }' | sed 's/\t\t//' | more 
		;;
		convert)
			hue_color $2
			exit 0
		;;
		scene)
			hueSceneOn $2 $3
		;;
		gethueun)
			gethue_user
			exit 0
		;;
		verbose)
			checkapi
			if [ "$hueVerbose" -eq "0" ]; then
				sed -i "s/hueVerbose='0'/hueVerbose='1'/" $SCRIPTCONF
			else
				sed -i "s/hueVerbose='1'/hueVerbose='0'/" $SCRIPTCONF
			fi
			exit 0
		;;
		hubconfig)
			checkapi
			gethueconfig
			exit 0
		;;
		help)
			usage
			exit 0
		;;
		*)
			echo "[1] mhue: Unknown command $1"
			exit 1
		;;
	esac
fi


if [ -z $(which jq) ]; then
	echo "[-] mhue: jq is not installed. This script needs curl to communicate with the hue api."
        echo "[-] mhue: Please run mhue install and try again."
        exit 1
fi

if [ -f "$SCRIPTCONF" ]; then
	. "$SCRIPTCONF"
	hueBaseUrl="http://${hueBridge}:${huePort}/api/${hueApiHash}"
else
	echo "[-] mhue: No $SCRIPTCONF found"
        echo "[-] mhue: Please run mhue install and try again."
	exit 1
fi

if [ ${#} -lt 4 ]; then
		usage
fi
hueDevice=${1}
hueDeviceNumber=${2}
hueDeviceAction=${3}
hueDeviceActionValue1=${4}
hueDeviceActionValue2=${5}

case ${hueDeviceAction} in
	state) huePower ${hueDevice} ${hueDeviceNumber} ${hueDeviceActionValue1} ${hueDeviceActionValue2} ;;
	sat) hueSaturation ${hueDevice} ${hueDeviceNumber} ${hueDeviceActionValue1} ;;
	bri) hueBrightness ${hueDevice} ${hueDeviceNumber} ${hueDeviceActionValue1} ;;
	hue) hueHue ${hueDevice} ${hueDeviceNumber} ${hueDeviceActionValue1} ;;
	xy) hueXy ${hueDevice} ${hueDeviceNumber} ${hueDeviceActionValue1} ${hueDeviceActionValue2} ;;
	ct) hueCt ${hueDevice} ${hueDeviceNumber} ${hueDeviceActionValue1} ;;
	cycle) hueCycle ${hueDevice} ${hueDeviceNumber} ${hueDeviceActionValue1} ${hueDeviceActionValue2} ;;
	*) usage ;;
esac

exit 0
