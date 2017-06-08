# HyperPixel

## Automatic Setup (recommended)

Bear with us. A one-line installer is coming soon, but for now you'll need to clone this repository, then run:

```
./setup.sh
```

reboot. That's all! Enjoy!

## Important note

HyperPixel uses DPI mode 6, which means you can't use (hardware) I2C or SPI at the same time (the `setup.sh` script will disable those interfaces for you, but make sure not to reenable them by accident).

In addition, DAC type of products communicatng with the Pi over I2S are also incompatible, as they use the same pins. It is possible to use the on-board audio chip alongside HyperPixel however, provided you force route the audio signal over HDMI, or are happy losing refined control over the backlight (PWM).

## Manual Setup

### LCD Display

First you'll need to grab the files from `requirements/boot` and place them in the relevant locations in `/boot` on your Pi.

You can do this either on your Pi, or by inserting your SD card into a host computer.

If you want to hotplug Hyper Pixel, place `requirements/usr/bin/hyperpixel` into `/usr/bin/` and run it with `hyperpixel` to initialize the LCD.

Then, add the following to the bottom of your /boot/config.txt

```
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
```

### Touch Screen

We need to ensure the `evdev` module is installed for Python. The easiest is to grab our pre-compiled deb file:

```
sudo dpkg -i ./dependencies/python-evdev_0.6.4-1_armhf.deb
```

alternatively, you can install it from source like so:

```
sudo apt-get install python-dev
sudo pip install evdev
```

Make sure you add `uinput` to `/etc/modules`.

Also copy the following:

```
sudo cp ./requirements/usr/bin/hyperpixel-init /usr/bin/
sudo cp ./requirements/usr/bin/hyperpixel-touch /usr/bin/
sudo cp ./requirements/etc/init.d/hyperpixel-touch.sh /etc/init.d/
```

and make sure they are executable:

```
sudo chmod +x /usr/bin/hyperpixel-init
sudo chmod +x /usr/bin/hyperpixel-touch
sudo chmod +x /etc/init.d/hyperpixel-touch.sh
```

Then ensure the init script runs on startup:

```
sudo update-rc.d hyperpixel-touch.sh defaults 100
```

After a reboot, you should have a working 800x400 display with touchscreen support up and running!
