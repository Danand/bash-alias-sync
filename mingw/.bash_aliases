#!/bin/bash

alias clip='clip.exe'
alias paste='powershell.exe -command "Get-Clipboard"'
alias adb-stream='adb exec-out screenrecord --output-format=h264 - | ffplay -y 960 -framerate 60 -probesize 32 -sync video -'
