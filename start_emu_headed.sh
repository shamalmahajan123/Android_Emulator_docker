#!/bin/bash

# Color definitions
BL='\033[0;34m'
G='\033[0;32m'
RED='\033[0;31m'
YE='\033[1;33m'
NC='\033[0m' # No Color

# Start Xvfb
Xvfb :1 -screen 0 1280x720x24 &
export DISPLAY=:1

# Get emulator name from environment variable
emulator_name=${EMULATOR_NAME}
apk_type=${APK_TYPE}
export PATH="$ANDROID_SDK_ROOT/platform-tools:$PATH"

function check_hardware_acceleration() {
    if [[ "$HW_ACCEL_OVERRIDE" != "" ]]; then
        hw_accel_flag="$HW_ACCEL_OVERRIDE"
    else
        if [[ "$OSTYPE" == "darwin"* ]]; then
            HW_ACCEL_SUPPORT=$(sysctl -a | grep -E -c '(vmx|svm)')
        else
            HW_ACCEL_SUPPORT=$(grep -E -c '(vmx|svm)' /proc/cpuinfo)
        fi

        if [[ $HW_ACCEL_SUPPORT == 0 ]]; then
            hw_accel_flag="-accel off"
        else
            hw_accel_flag="-accel on"
        fi
    fi

    echo "$hw_accel_flag"
}

hw_accel_flag=$(check_hardware_acceleration)

function launch_emulator() {
    adb devices | grep emulator | cut -f1 | xargs -r -I {} adb -s "{}" emu kill || echo "No running emulator to kill."
    options="-avd ${emulator_name} -no-snapshot -noaudio -no-boot-anim -memory 2048 ${hw_accel_flag} -camera-back none -gpu swiftshader_indirect"
    echo "Launching emulator with options: ${options}"

    nohup emulator $options &> /tmp/emulator.log &

    sleep 5

    if ! adb wait-for-device; then
        echo -e "${RED}Error: Emulator did not start${NC}"
        echo "Emulator log:"
        cat /tmp/emulator.log  # Print emulator logs for debugging
        exit 1
    fi
}

function check_emulator_status() {
    printf "${G}==> ${BL}Checking emulator booting up status 🧐${NC}\n"
    start_time=$(date +%s)
    spinner=("⠹" "⠺" "⠼" "⠶" "⠦" "⠧" "⠇" "⠏")
    i=0
    timeout=${EMULATOR_TIMEOUT:-300}

    while true; do
        result=$(adb shell getprop sys.boot_completed 2>&1)

        if [ "$result" == "1" ]; then
            printf "\e[K${G}==> \u2713 Emulator is ready : '$result'           ${NC}\n"
            adb devices -l
            adb shell input keyevent 82  # Unlock the device
            adb install ${apk_type}
            break
        elif [ "$result" == "" ]; then
            printf "${YE}==> Emulator is partially booted! 😕 ${spinner[$i]} ${NC}\r"
        else
            printf "${RED}==> $result, please wait ${spinner[$i]} ${NC}\r"
            i=$(( (i+1) % 8 ))
        fi

        current_time=$(date +%s)
        elapsed_time=$((current_time - start_time))
        if [ $elapsed_time -gt $timeout ]; then
            printf "${RED}==> Timeout after ${timeout} seconds elapsed 🕛.. ${NC}\n"
            break
        fi
        sleep 4
    done
}

function disable_animation() {
    adb shell "settings put global window_animation_scale 0.0"
    adb shell "settings put global transition_animation_scale 0.0"
    adb shell "settings put global animator_duration_scale 0.0"
}

function hidden_policy() {
    adb shell "settings put global hidden_api_policy_pre_p_apps 1; settings put global hidden_api_policy_p_apps 1; settings put global hidden_api_policy 1"
}

# Launch emulator
launch_emulator
sleep 30
# Check emulator status
check_emulator_status
sleep 1
disable_animation
sleep 1
hidden_policy
sleep 1

# List files and current directory for debugging
ls
pwd
