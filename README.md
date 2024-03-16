# EdgeTX Telemetry Lua Script
EdgeTX telemetry lua script to display battery voltage, timer and signal strength. Designed to look like a zoomed section of the main screen so the timer and battery voltage are easy to see at a glance. 

![image](../assets/screenshot_boxer_24-03-15_17-02-34.png)

For 128x64 b&w screens like the Boxer, T-Lite or similar radios. Tested to work on 212x64 screens but not really designed for that.

## Features

* Text configuration
* Battery voltage (displayed within set range)
* Signal strength (system rssi or telemetry value)
* Flight timer (set to use timer 1)
* System time

## Installing

1. Download the `vmon.lua` script above.
2. Open `vmon.lua` and edit to match your setup.
3. Place this script into your `/SCRIPTS/TELEMETRY` folder on the radio.

## Usage

Enable the script on a telemetry screen.
