#!/usr/bin/env python

import os
import signal
import sys
import time

from datetime import datetime
from threading import Timer

try:
    from evdev import uinput, UInput, AbsInfo, ecodes as e
except ImportError:
    exit("This service requires the evdev module\nInstall with: sudo pip install evdev")

try:
    import RPi.GPIO as gpio
except ImportError:
    exit("This service requires the RPi.GPIO module\nInstall with: sudo pip install RPi.GPIO")

try:
    import smbus
except ImportError:
    exit("This service requires the smbus module\nInstall with: sudo apt-get install python-smbus")


os.system("sudo modprobe uinput")

DAEMON = True

CAPABILITIES = {
    e.EV_ABS : (
        (e.ABS_X, AbsInfo(value=0, min=0, max=800, fuzz=0, flat=0, resolution=1)),
        (e.ABS_Y, AbsInfo(value=0, min=0, max=480, fuzz=0, flat=0, resolution=1)),
        (e.ABS_MT_SLOT, AbsInfo(value=0, min=0, max=1, fuzz=0, flat=0, resolution=0)),
        (e.ABS_MT_TRACKING_ID, AbsInfo(value=0, min=0, max=65535, fuzz=0, flat=0, resolution=0)),
        (e.ABS_MT_POSITION_X, AbsInfo(value=0, min=0, max=800, fuzz=0, flat=0, resolution=0)),
        (e.ABS_MT_POSITION_Y, AbsInfo(value=0, min=0, max=480, fuzz=0, flat=0, resolution=0)),
    ),
    e.EV_KEY : [
        e.BTN_TOUCH, 
    ]
}

PIDFILE = "/var/run/hyperpixel-touch.pid"
LOGFILE = "/var/log/hyperpixel-touch.log"

if DAEMON:
    try:
        pid = os.fork()
        if pid > 0:
            sys.exit(0)

    except OSError, e:
        print("Fork #1 failed: {} ({})".format(e.errno, e.strerror))
        sys.exit(1)

    os.chdir("/")
    os.setsid()
    os.umask(0)

    try:
        pid = os.fork()
        if pid > 0:
            fpid = open(PIDFILE, 'w')
            fpid.write(str(pid))
            fpid.close()
            sys.exit(0)
    except OSError, e:
        print("Fork #2 failed: {} ({})".format(e.errno, e.strerror))
        sys.exit(1)

    si = file("/dev/null", 'r')
    so = file(LOGFILE, 'a+')
    se = file("/dev/null", 'a+', 0)

    os.dup2(si.fileno(), sys.stdin.fileno())
    os.dup2(so.fileno(), sys.stdout.fileno())
    os.dup2(se.fileno(), sys.stderr.fileno())

def log(msg):
    sys.stdout.write(str(datetime.now()))
    sys.stdout.write(": ")
    sys.stdout.write(msg)
    sys.stdout.write("\n")
    sys.stdout.flush()

try:
    ui = UInput(CAPABILITIES, name="Touchscreen", bustype=e.BUS_USB)

except uinput.UInputError as e:
    sys.stdout.write(e.message)
    sys.stdout.write("Have you tried running as root? sudo {}".format(sys.argv[0]))
    sys.exit(0)

INT = 27
ADDR = 0x5c

gpio.setmode(gpio.BCM)
gpio.setwarnings(False)
gpio.setup(INT, gpio.IN)

bus = smbus.SMBus(3)

last_status_one = last_status_two = False
last_status_x1 = last_status_y1 = last_status_x2 = last_status_y2 = 0

touch_one_start = None
touch_two_start = None
touch_one_end = 0
touch_two_end = 0
last_x1 = last_y1 = -1
last_x2 = last_y2 = -1

def write_status(x1, y1, touch_one, x2, y2, touch_two):
    global last_status_one, last_status_two, last_status_x1, last_status_y1, last_status_x2, last_status_y2

    if touch_one:
        ui.write(e.EV_ABS, e.ABS_MT_SLOT, 0)

        if not last_status_one: # Contact one press
            ui.write(e.EV_ABS, e.ABS_MT_TRACKING_ID, 0)
            ui.write(e.EV_ABS, e.ABS_MT_POSITION_X, x1)
            ui.write(e.EV_ABS, e.ABS_MT_POSITION_Y, y1)
            ui.write(e.EV_KEY, e.BTN_TOUCH, 1)
            ui.write(e.EV_ABS, e.ABS_X, x1)
            ui.write(e.EV_ABS, e.ABS_Y, y1)

        elif not last_status_one or (x1, y1) != (last_status_x1, last_status_y1):
            if x1 != last_status_x1: ui.write(e.EV_ABS, e.ABS_X, x1)
            if y1 != last_status_y1: ui.write(e.EV_ABS, e.ABS_Y, y1)
            ui.write(e.EV_ABS, e.ABS_MT_POSITION_X, x1)
            ui.write(e.EV_ABS, e.ABS_MT_POSITION_Y, y1)

        last_status_x1 = x1
        last_status_y1 = y1

        last_status_one = True

        ui.write(e.EV_SYN, e.SYN_REPORT, 0)
        ui.syn()

    elif not touch_one and last_status_one: # Contact one release
        ui.write(e.EV_ABS, e.ABS_MT_SLOT, 0)
        ui.write(e.EV_ABS, e.ABS_MT_TRACKING_ID, -1)
        ui.write(e.EV_KEY, e.BTN_TOUCH, 0)
        last_status_one = False

        ui.write(e.EV_SYN, e.SYN_REPORT, 0)
        ui.syn()


    if touch_two:
        ui.write(e.EV_ABS, e.ABS_MT_SLOT, 1)

        if not last_status_two: # Contact one press
            ui.write(e.EV_ABS, e.ABS_MT_TRACKING_ID, 1)
            ui.write(e.EV_ABS, e.ABS_MT_POSITION_X, x2)
            ui.write(e.EV_ABS, e.ABS_MT_POSITION_Y, y2)
            ui.write(e.EV_KEY, e.BTN_TOUCH, 1)
            ui.write(e.EV_ABS, e.ABS_X, x2)
            ui.write(e.EV_ABS, e.ABS_Y, y2)

        elif not last_status_two or (x2, y2) != (last_status_x2, last_status_y2):
            if x2 != last_status_x2: ui.write(e.EV_ABS, e.ABS_X, x2)
            if y2 != last_status_y2: ui.write(e.EV_ABS, e.ABS_Y, y2)
            ui.write(e.EV_ABS, e.ABS_MT_POSITION_X, x2)
            ui.write(e.EV_ABS, e.ABS_MT_POSITION_Y, y2)

        last_status_x2 = x2
        last_status_y2 = y2

        last_status_two = True

        ui.write(e.EV_SYN, e.SYN_REPORT, 0)
        ui.syn()

    elif not touch_two and last_status_two: # Contact one release
        ui.write(e.EV_ABS, e.ABS_MT_SLOT, 1)
        ui.write(e.EV_ABS, e.ABS_MT_TRACKING_ID, -1)
        ui.write(e.EV_KEY, e.BTN_TOUCH, 0)
        last_status_two = False

        ui.write(e.EV_SYN, e.SYN_REPORT, 0)
        ui.syn()

def is_touch_on(x,y):
    # Pick the nearest touch lines to the coordinates
    x_line = int(x/57.2)
    y_line = int(y/60.01)

    assert ( 0 <= x_line <= 13)
    assert ( 0 <= y_line <= 7)

    # Read ADC values for those lines
    x_adc = bus.read_word_data(ADDR, x_line*2+16)
    y_adc = bus.read_word_data(ADDR, y_line*2)

    if x_adc > 100 or y_adc > 100:
        return True
    else:
        return False

def touch_finished(x1,y1,x2,y2):
    global touch_one_start, touch_two_start, touch_one_end, touch_two_end

    touch_one_dur = 0
    touch_two_dur = 0

    if touch_one_start and (x1,y1) == (0,0):
        touch_one_dur = time.time()-touch_one_start
    
        touch_one_end = time.time()
        touch_one_start = None

    if touch_two_start and (x2,y2) == (0,0):
        touch_two_dur = time.time()-touch_two_start
    
        touch_two_end = time.time()
        touch_two_start = None

def smbus_read_touch():
    global ioerr_count, touch_one_start, touch_two_start
    global last_x1, last_y1, last_x2, last_y2

    try:
        data = bus.read_i2c_block_data(ADDR, 0x40, 8)

        x1 = data[0] | (data[4] << 8)
        y1 = data[1] | (data[5] << 8)
        x2 = data[2] | (data[6] << 8)
        y2 = data[3] | (data[7] << 8)

        if x2 and y2:

            if ( touch_two_start and (x2, y2) != (last_x2, last_y2) ) or is_touch_on(x2, y2):
                if not touch_two_start:
                    touch_two_start = time.time()
            else:
                if touch_two_start:
                    touch_finished(x1,y1,x2,y2)

            last_x2 = x2
            last_y2 = y2


        if x1 and y1:

            if ( touch_one_start and (x1, y1) != (last_x1, last_y1) ) or is_touch_on(x1, y1):
                if not touch_one_start:
                    touch_one_start = time.time()
            else:
                if touch_one_start:
                    touch_finished(x1,y1,x2,y2)

            last_x1 = x1
            last_y1 = y1


        if (x2==0 and y2==0 and touch_two_start) or (x1==0 and y1==0 and touch_one_start):
            touch_finished(x1,y1,x2,y2)

        write_status(800-x1, 480-y1, touch_one_start is not None, 800-x2, 480-y2, touch_two_start is not None)


    except IOError as e:
        print("Probably IOerror {}".format(e))
        ioerr_count += 1

bus.write_byte_data(0x5c,0x6e,0b00001110)

log("HyperPixel Touch daemon running...")

try:
    while True:
        if gpio.input(INT) or touch_one_start or touch_two_start:
            smbus_read_touch()

        time.sleep(0.003)

except KeyboardInterrupt:
    pass

log("HyperPixel Touch daemon shutting down...")

ui.close()
