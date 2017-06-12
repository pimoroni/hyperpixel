#!/bin/bash

: <<'DISCLAIMER'

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

This script is licensed under the terms of the MIT license.
Unless otherwise noted, code reproduced herein
was written for this script.

- The Pimoroni Crew -

DISCLAIMER

# script control variables

productname="Hyperpixel" # the name of the product to install
scriptname="setup.sh" # the name of this script
spacereq=20 # minimum size required on root partition in MB
debugmode="no" # whether the script should use debug routines
debuguser="none" # optional test git user to use in debug mode
debugpoint="none" # optional git repo branch or tag to checkout
forcesudo="no" # whether the script requires to be ran with root privileges
promptreboot="yes" # whether the script should always prompt user to reboot
mininstall="no" # whether the script enforces minimum install routine
customcmd="yes" # whether to execute commands specified before exit
armhfonly="yes" # whether the script is allowed to run on other arch
armv6="yes" # whether armv6 processors are supported
armv7="yes" # whether armv7 processors are supported
armv8="yes" # whether armv8 processors are supported
raspbianonly="no" # whether the script is allowed to run on other OSes
pkgdeplist=( "python-pip" "python-dev" ) # list of dependencies

FORCE=""

ASK_TO_REBOOT=false
CURRENT_SETTING=false
MIN_INSTALL=false
FAILED_PKG=false
REMOVE_PKG=false
UPDATE_DB=false

AUTOSTART=~/.config/lxsession/LXDE-pi/autostart
BOOTCMD=/boot/cmdline.txt
CONFIG=/boot/config.txt
APTSRC=/etc/apt/sources.list
INITABCONF=/etc/inittab
BLACKLIST=/etc/modprobe.d/raspi-blacklist.conf
LOADMOD=/etc/modules

# function define

confirm() {
    if [ "$FORCE" == '-y' ]; then
        true
    else
        read -r -p "$1 [y/N] " response < /dev/tty
        if [[ $response =~ ^(yes|y|Y)$ ]]; then
            true
        else
            false
        fi
    fi
}

prompt() {
        read -r -p "$1 [y/N] " response < /dev/tty
        if [[ $response =~ ^(yes|y|Y)$ ]]; then
            true
        else
            false
        fi
}

success() {
    echo -e "$(tput setaf 2)$1$(tput sgr0)"
}

inform() {
    echo -e "$(tput setaf 6)$1$(tput sgr0)"
}

warning() {
    echo -e "$(tput setaf 1)$1$(tput sgr0)"
}

newline() {
    echo ""
}

progress() {
    count=0
    until [ $count -eq 7 ]; do
        echo -n "..." && sleep 1
        ((count++))
    done;
    if ps -C $1 > /dev/null; then
        echo -en "\r\e[K" && progress $1
    fi
}

sudocheck() {
    if [ $(id -u) -ne 0 ]; then
        echo -e "Install must be run as root. Try 'sudo ./$scriptname'\n"
        exit 1
    fi
}

sysclean() {
    sudo apt-get clean && sudo apt-get autoclean
    sudo apt-get -y autoremove &> /dev/null
}

sysupdate() {
    if ! $UPDATE_DB; then
        echo "Updating apt indexes..." && progress apt-get &
        sudo apt-get update 1> /dev/null || { warning "Apt failed to update indexes!" && exit 1; }
        sleep 3 && UPDATE_DB=true
    fi
}

sysupgrade() {
    sudo apt-get upgrade
    sudo apt-get clean && sudo apt-get autoclean
    sudo apt-get -y autoremove &> /dev/null
}

sysreboot() {
    warning "Some changes made to your system require"
    warning "your computer to reboot to take effect."
    echo
    if prompt "Would you like to reboot now?"; then
        sync && sudo reboot
    fi
}

apt_pkg_req() {
    APT_CHK=$(dpkg-query -W -f='${Status}\n' "$1" 2> /dev/null | grep "install ok installed")

    if [ "" == "$APT_CHK" ]; then
        echo "$1 is required"
        true
    else
        echo "$1 is already installed"
        false
    fi
}

apt_pkg_install() {
    echo "Installing $1..."
    sudo apt-get --yes install "$1" 1> /dev/null || { inform "Apt failed to install $1!\nFalling back on pypi..." && return 1; }
}

config_set() {
    if [ -n $defaultconf ]; then
        sudo sed -i "s|$1=.*$|$1=$2|" $defaultconf
    else
        sudo sed -i "s|$1=.*$|$1=$2|" $3
    fi
}

: <<'MAINSTART'

Perform all global variables declarations as well as function definition
above this section for clarity, thanks!

MAINSTART

# checks and init

if [ $forcesudo == "yes" ]; then
    sudocheck
fi

# main routine

echo -e "Installing dependencies..."

if apt_pkg_req "python-evdev" &> /dev/null; then
    sudo dpkg -i ./dependencies/python-evdev_0.6.4-1_armhf.deb
fi

if apt_pkg_req "python-evdev" &> /dev/null; then
    for pkgdep in ${pkgdeplist[@]}; do
        if apt_pkg_req "$pkgdep"; then
            sysupdate && apt_pkg_install "$pkgdep"
        fi
    done
    sudo pip install evdev
fi

echo -e "\nInstalling Requirements..."

dtbolist=( "hyperpixel.dtbo" "hyperpixel-gpio-backlight.dtbo" )

for dtbofile in ${dtbolist[@]}; do
    sudo cp ./requirements/boot/overlays/$dtbofile /boot/overlays/ &> /dev/null
done

binlist=( "hyperpixel-init" "hyperpixel-touch" )

for binfile in ${binlist[@]}; do
    sudo cp ./requirements/usr/bin/$binfile /usr/bin/ &> /dev/null
    sudo chmod +x /usr/bin/$binfile
done

echo -e "\nInstalling init script..."

sudo cp ./requirements/boot/hyperpixel-initramfs.cpio.gz /boot/ &> /dev/null

initlist=( "hyperpixel-touch.sh" )

for initfile in ${initlist[@]}; do
    sudo cp ./requirements/etc/init.d/$initfile /etc/init.d/ &> /dev/null
    sudo chmod +x /etc/init.d/$initfile
    sudo update-rc.d $initfile defaults 100
done

if [ $(grep -c "hyperpixel" $CONFIG) == 0 ]; then
    echo -e "\nWriting settings to $CONFIG..."
    sudo bash -c "cat <<EOT >> $CONFIG

# Initialize Hyper Pixel at boot using an initramfs
initramfs hyperpixel-initramfs.cpio.gz followkernel

# HyperPixel LCD Settings
dtoverlay=hyperpixel
overscan_left=0
overscan_right=0
overscan_top=0
overscan_bottom=0
framebuffer_width=800
framebuffer_height=480
enable_dpi_lcd=1
display_default_lcd=1
dpi_group=2
dpi_mode=87
dpi_output_format=0x6f016
display_rotate=2
hdmi_timings=800 0 50 20 50 480 1 3 2 3 0 0 0 60 0 32000000 6

# Use a basic GPIO backlight driver with on/off support
dtoverlay=hyperpixel-gpio-backlight

# Disable i2c and spi, they clash with Hyper Pixel's pins
dtparam=i2c_arm=off
dtparam=spi=off

# Enable soft i2c for touchscreen
dtoverlay=i2c-gpio,i2c_gpio_sda=10,i2c_gpio_scl=11,i2c_gpio_delay_us=4
EOT"

fi

success "\nAll done!\n"

if [ "$FORCE" != '-y' ]; then
    sysreboot
fi; echo

exit 0
