#!/usr/bin/env python3

# -*- coding: utf-8 -*-
# Copyright (c) 2014-18 Richard Hull and contributors
# See LICENSE.rst for details.
# PYTHON_ARGCOMPLETE_OK

"""
An analog clockface with date & time.
"""

from luma.core.interface.serial import i2c
from luma.core.render import canvas
from luma.oled.device import ssd1306, ssd1325, ssd1331, sh1106
from time import sleep
from PIL import ImageFont, ImageDraw, Image
import time
import datetime

serial = i2c(port=0, address=0x3C)
# device = sh1106(serial, rotate=0)
device = ssd1306(serial, rotate=2)

def main():
    today_last_time = "Unknown"
    while True:
        now = datetime.datetime.now()
        today_date = now.strftime("%d %b %y")
        today_time = now.strftime("%H:%M")
        if today_time != today_last_time:
            today_last_time = today_time
            with canvas(device) as draw:
                  font = ImageFont.truetype('/usr/share/fonts/truetype/dseg/DSEG7Modern-Bold.ttf', 36)
                  draw.text((0, 27), today_time, font=font, fill=1)
                  font = ImageFont.truetype('/usr/share/fonts/truetype/dseg/DSEG7Modern-Bold.ttf', 20)
                  draw.text((0, 0), today_date, font=font, fill=1)
        time.sleep(0.1)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
