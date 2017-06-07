# Hyper Pixel

Bear with us. A one-line installer is coming soon, but for now you'll need to do:

## Manual Setup

### LCD Display

First you'll need to grab the files from `requirements/boot` and place them in the relevant locations in `/boot` on your Pi.

You can do this either on your Pi, or by inserting your SD card into a host computer.

Next, add the following to the bottom of your /boot/config.txt

```
# Initialize Hyper Pixel at boot using an initramfs
initramfs hyperpixel-initramfs.cpio.gz followkernel

# Use a basic GPIO backlight driver with on/off support
dtoverlay=hyperpixel-gpio-backlight

# Disable i2c and spi, they clash with Hyper Pixel's pins
dtparam=i2c_arm=off
dtparam=spi=off

# LCD Settings
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
```

If you want to hotplug Hyper Pixel, place `requirements/usr/bin/hyperpixel` into `/usr/bin/` and run it with `hyperpixel` to initialize the LCD.

### Touch Screen

Make sure the `evdev` module is installed for Python: 

```
sudo apt-get install python-dev
sudo pip install evdev
```

Make sure you add `uinput` to `/etc/modules`, you can insert it manually with:

```
sudo modprobe uinput
```

Copy `requirements/usr/bin/hyperpixel-touch` to `/usr/bin`.

Make sure it's executable with: `sudo chmod +x /usr/bin/hyperpixel-touch`

Copy `requirements/etc/init.d/hyperpixel-touch.sh` to `/etc/init.d`.

Make sure it's executable with: `sudo chmod +x /etc/init.d/hyperpixel-touch.sh`

Then ensure it runs on startup:

```
sudo update-rc.d hyperpixel-touch.sh defaults 100
```