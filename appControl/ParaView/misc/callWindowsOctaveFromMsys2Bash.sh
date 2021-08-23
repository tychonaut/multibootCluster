#!/bin/bash

octaveWindowsExe="C:\\Octave\\Octave-5.2.0\\mingw64\\bin\\octave-cli.exe"


#pth="D:\\devel\\scripts\\multiOSCluster\\appControl\\ParaView\\misc\\convertFrustum_FovEuler_To_FOUR_PlaneCorners_forMoreViz.m"
#pth="/d/devel/scripts/multiOSCluster/appControl/ParaView/misc/convertFrustum_FovEuler_To_FOUR_PlaneCorners_forMoreViz.m"


pth=$1

# https://stackoverflow.com/questions/20204820/check-if-shell-script-1-is-absolute-or-relative-path
if [[ "${pth:0:1}" == / || "${pth:0:2}" == ~[/a-z] ]]
then
    #echo "Absolute"
    pth="$1"
else
    #echo "Relative"
    pth="$(pwd)/$1"
fi

octaveScriptPath_Windows=$(echo "$pth" | sed -e 's/^\///' -e 's/\//\\/g' -e 's/^./\0:/')

powershell "${octaveWindowsExe} ${octaveScriptPath_Windows}"




