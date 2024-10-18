#!/bin/bash

BL='\033[0;34m'
G='\033[0;32m'
RED='\033[0;31m'
YE='\033[1;33m'
NC='\033[0m' # No Color

function start_appium () {
    if [ -z "$APPIUM_PORT" ] || [ "$APPIUM_PORT" == "null" ]; then
        printf "${G}==>  ${YE}No port provided, instance will run on default port 4723 ${G}<==${NC}\n"
        sleep 0.5
        appium >> /appium_logs/appium.log 2>&1 &
    else
        printf "${G}==>  ${BL}Instance will run on port ${YE}${APPIUM_PORT} ${G}<==${NC}\n"
        sleep 0.5
        appium -p $APPIUM_PORT >> /appium_logs/appium.log 2>&1 &
    fi

    # Ensure the emulator is fully booted before installing the APK
    printf "${G}==>  ${YE}Waiting for the Android emulator to fully boot... ${G}<==${NC}\n"
    adb wait-for-device
    adb shell getprop sys.boot_completed | grep -m 1 '1'
    
    # Ensure the APK exists before attempting installation
    # if [ -f "/APK/Banreservas_x64_New.apk" ]; then
    #     printf "${G}==>  ${BL}Installing APK: Banreservas_x64_New.apk ${G}<==${NC}\n"
    #     adb install /APK/Banreservas_x64_New.apk
    # else
    #     printf "${RED}==>  APK not found at /APK/Banreservas_x64_New.apk. Skipping installation. ${NC}\n"
    # fi
}

# Create a directory for Appium logs if it doesn't exist
mkdir -p /appium_logs

start_appium
