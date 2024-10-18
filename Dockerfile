FROM eclipse-temurin:8-jdk
 
# sets the environment variable DEBIAN_FRONTEND to noninteractive
ENV DEBIAN_FRONTEND=noninteractive
 
# sets the working directory inside the Docker container to the root directory
WORKDIR /app
 
# This line sets the default shell for executing commands in subsequent RUN instructions to /bin/bash.
SHELL ["/bin/bash", "-c"]
 
#
# Then installs various dependencies required for Android development and testing using the apt package manager.
RUN apt update && apt install -y curl sudo wget unzip bzip2 libdrm-dev libxkbcommon-dev libgbm-dev libasound-dev libnss3 libxcursor1 libpulse-dev libxshmfence-dev xauth xvfb x11vnc fluxbox wmctrl libdbus-glib-1-2 
 
# Build arguments related to Android development
ARG ARCH="x86_64"
ARG TARGET="google_apis_playstore"
ARG API_LEVEL="32"
ARG BUILD_TOOLS="33.0.2"
ARG KATALON_VERSION="8.6.8"
ARG ANDROID_API_LEVEL="android-${API_LEVEL}"
ARG ANDROID_APIS="${TARGET};${ARCH}"
ARG EMULATOR_PACKAGE="system-images;${ANDROID_API_LEVEL};${ANDROID_APIS}"
ARG PLATFORM_VERSION="platforms;${ANDROID_API_LEVEL}"
ARG BUILD_TOOL="build-tools;${BUILD_TOOLS}"
ARG ANDROID_CMD="commandlinetools-linux-8092744_latest.zip"
ARG ANDROID_SDK_PACKAGES="${EMULATOR_PACKAGE} ${PLATFORM_VERSION} ${BUILD_TOOL} platform-tools"
ARG EMULATOR_NAME="nexus"
ARG EMULATOR_DEVICE="Nexus 6"
ARG APKFILE='Banreservas_x64_New.apk'
ARG APK_TYPE="/app/APK/${APKFILE}"

ENV ANDROID_SDK_ROOT=/opt/android
ENV KATALON_JAVA_HOME=/opt/java/openjdk/jre
ENV PATH="$PATH:$ANDROID_SDK_ROOT/cmdline-tools/tools:$ANDROID_SDK_ROOT/cmdline-tools/tools/bin:$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/tools/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/build-tools/${BUILD_TOOLS}"
ENV DOCKER="true"
ENV DISPLAY=:1
ENV EMULATOR_NAME=$EMULATOR_NAME
ENV KATALON_VERSION=$KATALON_VERSION
ENV DEVICE_NAME=$EMULATOR_DEVICE
ENV APK_TYPE=${APK_TYPE} 
 
# Install required Android CMD-line tools
RUN wget --retry-connrefused --waitretry=5 --timeout=30 --tries=5 https://dl.google.com/android/repository/${ANDROID_CMD} -P /tmp && \
    unzip -d $ANDROID_SDK_ROOT /tmp/$ANDROID_CMD && \
    mkdir -p $ANDROID_SDK_ROOT/cmdline-tools/tools && \
    cd $ANDROID_SDK_ROOT/cmdline-tools && \
    mv NOTICE.txt source.properties bin lib tools/ && \
    cd $ANDROID_SDK_ROOT/cmdline-tools/tools && ls

RUN yes Y | sdkmanager --licenses  
 
# Using to accept the Android SDK licenses non-interactively using yes command
RUN yes Y | sdkmanager --verbose --no_https ${ANDROID_SDK_PACKAGES}
 

RUN echo "no" | avdmanager --verbose create avd --force --name "${EMULATOR_NAME}" --device "${EMULATOR_DEVICE}" --package "${EMULATOR_PACKAGE}"
 
# Install latest nodejs, npm & appium
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash && \
    apt-get install -y nodejs && \
    npm install -g appium@1.22.3 && \
    apt-get update && apt-get install -y dos2unix && \
    exit 0 && \
    npm cache clean && \
    apt-get remove --purge -y npm && \  
    apt-get autoremove --purge -y && \
    apt-get install -y libxcb-xinerama0 libxcb-cursor0 libxcb-xkb1 libxkbcommon-x11-0 libxcb-icccm4 libx11-xcb-dev libglu1-mesa && \
    apt-get clean && \
    rm -Rf /tmp/* && rm -Rf /var/lib/apt/lists/*

   RUN export QT_QPA_PLATFORM_PLUGIN_PATH=/path/to/qt/plugins
   RUN apt-get install -y xvfb

 
# Alias
# ENV EMU=./start_emu.sh
ENV EMU_HEADED=./start_emu_headed.sh
ENV VNC=./start_vnc.sh
# ENV APPIUM=./start_appium.sh
 
# Ports
# ENV APPIUM_PORT=4723
 
# Set VNC password and create the necessary directories
ENV VNC_PASSWORD=password
RUN mkdir -p ~/.vnc && x11vnc -storepasswd $VNC_PASSWORD ~/.vnc/passwd
 
# Copying Scripts to root
COPY . /app



# RUN chmod +x /app/install_and_start.sh
RUN dos2unix ./start_vnc.sh && \
    # dos2unix ./start_appium.sh && \
    # dos2unix ./start_emu.sh && \
    dos2unix ./start_emu_headed.sh
 
RUN chmod a+x start_vnc.sh && \
    # chmod a+x start_appium.sh && \
    # chmod a+x start_emu.sh && \
    chmod a+x start_emu_headed.sh

# Expose the VNC port
EXPOSE 5900
# Copy the APK file from your local directory to /APK/ inside the container
COPY ./APK/Banreservas_x64_New.apk /APK/Banreservas_x64_New.apk


# framework entry point
# CMD ["/bin/bash","/app/start_emu_headed.sh && adb -s emulator-5554 install /app/APK/Banreservas_x64_New.apk"]
CMD ["/bin/bash","/app/start_emu_headed.sh"]


#commands:
    # docker build -t android-emulator . ---build image
    #docker run -it --privileged -d -p 5900:5900 --name androidContainer --privileged android-emulator  ---run container
    #docker ps
    #docker exec --privileged -it androidContainer bash -c "./start_vnc.sh"
    #ls
    #./start_emu_headless.sh
    
#commands for headed container:
    #docker run -it -d -p 5900:5900 --name androidContainer -e VNC_PASSWORD=password --privileged android-emulator
    #docker exec --privileged -it androidContainer bash -c "./start_vnc.sh"

#kill the conatiner:
    #    docker rm -f androidContainer

#manually start apk:
    #adb install /APK/Banreservas_x64_New.apk