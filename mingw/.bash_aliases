#!/bin/bash

alias adb-stream='adb exec-out screenrecord --output-format=h264 - | ffplay -y 960 -framerate 60 -probesize 32 -sync video -'
