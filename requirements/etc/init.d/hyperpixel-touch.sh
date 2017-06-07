#!/bin/sh
### BEGIN INIT INFO
# Provides:          hyperpixel-touch
# Required-Start:    $local_fs
# Required-Stop:     $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: hyperpixel-touch
# Description:       Touch screen driver for Hyper Pixel
### END INIT INFO

sudo bash -c "echo 1  > /sys/class/backlight/backlight/bl_power"
sudo python /usr/bin/hyperpixel-touch >> /var/log/hptouch.log