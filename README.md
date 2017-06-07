# Hyper Pixel

Bear with us. A one-line installer is coming soon, but for now you'll need to do:

## Manual Setup

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