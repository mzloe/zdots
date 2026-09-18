#!/bin/bash

if pgrep -x waybar > /dev/null; then
    killall waybar
else
    exec waybar &
fi