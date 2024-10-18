#!/bin/bash
 
export DISPLAY=:1
Xvfb :1 -screen 0 1280x720x24 &
x11vnc -display :1 -nopw -forever -shared &



main_function() {
    xvfb
    window_manager_fluxbox
    vnc_server
    printf "Welcome to android-emulator VNC""\n"
}
 
xvfb(){
    export DISPLAY=${XVFB_DISPLAY:-:1}
    local screen=${XVFB_SCREEN:-0}
    local resolution=${XVFB_RESOLUTION:-1280x1024x24}
    local timeout=${XVFB_TIMEOUT:-20}
   
    Xvfb ${DISPLAY} -screen ${screen} ${resolution} &
    local xvfb_pid=$!
   
    local loop_count=0
    until xdpyinfo -display ${DISPLAY} > /dev/null 2>&1; do
        ((loop_count++))
        sleep 1
        if [ $loop_count -gt $timeout ]; then
            echo "Xvfb failed to start within timeout period."
            if ps -p $xvfb_pid > /dev/null; then
                kill $xvfb_pid
                wait $xvfb_pid
            fi
            exit 1
        fi
    done
    echo "Xvfb started successfully."
}
 
window_manager_fluxbox() {
    TIMEOUT=10
 
    fluxbox &
 
    FLUXBOX_PID=$!
 
    sleep_count=0
    while ! wmctrl -m > /dev/null 2>&1; do
        sleep 1
        sleep_count=$((sleep_count + 1))
        if [ $sleep_count -ge $TIMEOUT ]; then
            echo "Fluxbox failed to start within timeout period."
            if ps -p $FLUXBOX_PID > /dev/null; then
                kill $FLUXBOX_PID
                wait $FLUXBOX_PID
            fi
            exit 1
        fi
    done
    echo "Fluxbox started successfully."
}
 
vnc_server(){
 local passwordArgument=''
 
    if [ -n "${VNC_PASSWORD}" ]; then
        local passwordFilePath="${HOME}/x11vnc.pass"
        if ! x11vnc -storepasswd "${VNC_PASSWORD}" "${passwordFilePath}"; then
            echo "${G_LOG_E} Failed to store x11vnc password."
            exit 1
        fi
        passwordArgument="-rfbauth ${passwordFilePath}"
        echo "${G_LOG_I} The VNC server will ask for a password."
    else
        echo "${G_LOG_W} The VNC server will NOT ask for a password."
        passwordArgument='-nopw'
    fi
 
    x11vnc -ncache_cr -display "${DISPLAY}" -forever ${passwordArgument} &
    wait $!
}
 
control_c() {
    echo ""
    exit
}
 
trap control_c SIGINT SIGTERM SIGHUP
 
main_function
 
exit