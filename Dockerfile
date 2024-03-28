#Based on buster, the last debian version to use python 2.7
FROM debian:buster

##Tooling For building wirepas
RUN apt-get update
RUN apt search pip
RUN apt-get install -y python \
    python-pip \
    srecord \
    wget

RUN python -m pip install --upgrade pip
RUN python -m pip install pycryptodome

## gcc 4.8 arm embedded cross compiler
## per instructions at https://launchpad.net/gcc-arm-embedded/4.8/4.8-2014-q3-update
ARG GCC_DIR="gcc-arm-none-eabi-4_8-2014q3"
ARG GCC_TARBALL="${GCC_DIR}-20140805-linux.tar.bz2"
ARG GCC_URL="https://launchpad.net/gcc-arm-embedded/4.8/4.8-2014-q3-update/+download/${GCC_TARBALL}"

RUN apt-get install -y lib32z1-dev lib32ncurses-dev
RUN wget ${GCC_URL}
RUN tar -C /opt/ -xvf $GCC_TARBALL
RUN rm $GCC_TARBALL
ENV PATH "$PATH:/opt/$GCC_DIR/bin"

ARG SRC_BASE="/root/src"
RUN mkdir -p $SRC_BASE
RUN apt-get install -y git

#Install the segger compiler
#https://www.segger.com/downloads/embedded-studio/Setup_EmbeddedStudio_ARM_v732_linux_arm64.tar.gz
#https://www.segger.com/downloads/embedded-studio/Setup_EmbeddedStudio_ARM_v418_linux_x64.tar.gz
ARG SEGGER_DL_URL="https://www.segger.com/downloads/embedded-studio"
ARG SEGGER_VER_MAJOR="4"
ARG SEGGER_VER_MINOR="18"
ARG SEGGER_PKGFILE="Setup_EmbeddedStudio_ARM_v${SEGGER_VER_MAJOR}${SEGGER_VER_MINOR}_linux_x64.tar.gz"
ARG SEGGER_UNPACKED_INSTALLER="arm_segger_embedded_studio_${SEGGER_VER_MAJOR}${SEGGER_VER_MINOR}_linux_x64/install_segger_embedded_studio"
ARG SEGGER_SDK_NAME="segger_embedded_studio_for_arm_${SEGGER_VER_MAJOR}.${SEGGER_VER_MINOR}"
ENV SEGGER_SDK "/usr/share/$SEGGER_SDK_NAME"
RUN wget "$SEGGER_DL_URL/$SEGGER_PKGFILE"
RUN tar -xvf "$SEGGER_PKGFILE"

# for reasons that are inexplicable to me, even in commandline mode segger 4.18 needs gui libs
RUN apt-get install -y libx11-6 libfreetype6 libxrender1 libfontconfig1 libxext6
RUN yes yes | "$SEGGER_UNPACKED_INSTALLER" --copy-files-to "$SEGGER_SDK"
RUN rm "$SEGGER_PKGFILE"
RUN rm -rf $(dirname $SEGGER_UNPACKED_INSTALLER)

#Install the nordic SDK
ARG NORDIC_DL_URL="https://nsscprodmedia.blob.core.windows.net/prod/software-and-other-downloads"
ARG NRF_SDK_VER="nrf5sdk160098a08e2"
ARG NRF5_PKGFILE="${NRF_SDK_VER}.zip"
RUN wget "$NORDIC_DL_URL/sdks/nrf5/binaries/$NRF5_PKGFILE"
RUN apt-get install -y unzip
ENV NRF5_SDK "$SRC_BASE/$NRF_SDK_VER"
RUN mkdir -p "$NRF5_SDK"
RUN unzip -d "$NRF5_SDK" "$NRF5_PKGFILE"
RUN rm "$NRF5_PKGFILE"

#Install nrf commandline tools
ARG NRF_TOOLS_PKGFILE="nrf-command-line-tools_10.15.2_amd64.deb"
ARG NRF_TOOLS_URL="$NORDIC_DL_URL/desktop-software/nrf-command-line-tools/sw/versions-10-x-x/10-23-0/$NRF_TOOLS_PKGFILE"
ARG NRF_TOOLS_URL="$NORDIC_DL_URL/desktop-software/nrf-command-line-tools/sw/versions-10-x-x/10-15-2/$NRF_TOOLS_PKGFILE"
ARG NRFUTIL="nrfutil-linux"
ARG NRFUTIL_URL="https://github.com/NordicSemiconductor/pc-nrfutil/releases/download/v6.1.7/$NRFUTIL"
ARG NRF_UTIL_INSTALL_DIR="/opt/nrfutil"
RUN wget $NRF_TOOLS_URL
RUN apt-get install -y ./$NRF_TOOLS_PKGFILE
RUN rm -rf $NRF_TOOLS_PKGFILE
RUN mkdir -p $NRF_UTIL_INSTALL_DIR
RUN wget -P $NRF_UTIL_INSTALL_DIR $NRFUTIL_URL
RUN chmod a+x $NRF_UTIL_INSTALL_DIR/$NRFUTIL
RUN ln -s $NRF_UTIL_INSTALL_DIR/$NRFUTIL /usr/bin/nrfutil

#Install python packages needed by NOKE_NRFUTIL
RUN pip install -q click pc_ble_driver_py protobuf pyserial ecdsa
