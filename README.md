# GPU Accelerated Odroid N2/C4 in ArchLinuxARM

Custom packages to enable gpu acceleration of Odroid N2 on
ArchLinuxARM, based on the packages done for Ubuntu 20.04 by
[tobetter](https://github.com/tobetter).

__Note:__ The supplied Mali binary drivers for bifrost (which is the
code name of the G52 gpu model found on the Odroid N2), does not
supports X11 so the gpu acceleration will only work on wayland
compositors. There is work on a compatibility layer to make
the OpenGL ES part of the Mali binary driver work under X11 by
[OtherCrashOverride](https://github.com/OtherCrashOverride). More
details can be read on this
[post](https://forum.odroid.com/viewtopic.php?f=182&t=34751) at the
Odroid Forum.

## What Works?

Here is a list of what has been tested so far divided in 4 categories:

* __YES__ = Usable and supports Xwayland + runs glmark2-es2-wayland
* __PARTIALLY__ - Usable but Xwayland or glmark2-es2-wayland may not work
* __SLOW__ - Seems to run but really slow (wayland not properly loaded?)
* __NO__ - Doesn't starts

### List of Environments

| Environment    | Status     | Notes                                  |
| -------------- | ---------- | -------------------------------------- |
| GNOME          | YES        | Everything seems to work now!          |
| Weston         | YES        | Everything seems to work! Don't forget to enable xwayland on weston.ini |
| Sway           | PARTIALLY  | Crashes when running X applications.   |
| Enlightenment  | PARTIALLY  | X applications run but, glmark2-es2-wayland segfaults on a regular user account, under root strangely works so something is wrong on the permissions system. |
| KDE            | SLOW       | Kwayland and Xwayland processes running but everything is slow |
| Wayfire        | NO         |                                        |

## Requirements

First you will need to install __linux-aarch64__ package or
more up to date __linux-aarch64-rc__ which are both supported
and a requirement by the latest Mali kernel driver (dkms-mali-bifrost)
which was patched by __tobetter__ to work on these latest kernel
versions which are 5.6 and 5.7rc repectively:

```sh
sudo pacman -S linux-aarch64-rc
```

Then modify your /boot/boot.ini file to be able to boot from
this kernel, here is a working __boot.ini__ example:

```
ODROIDN2-UBOOT-CONFIG

# System Label
setenv bootlabel "ArchLinux"

# Default Console Device Setting
setenv condev "console=ttyAML0,115200n8"

# Boot Args
setenv bootargs "root=/dev/sda2 rootwait rw mitigations=off ${condev} ${amlogic} no_console_suspend fsck.repair=yes net.ifnames=0 clk_ignore_unused"

# Set load addresses
setenv dtb_loadaddr "0x20000000"
setenv loadaddr "0x1080000"
setenv initrd_loadaddr "0x3080000"

# Load kernel, dtb and initrd
load mmc ${devno}:1 ${loadaddr} /Image
load mmc ${devno}:1 ${dtb_loadaddr} /dtbs/amlogic/meson-g12b-odroid-n2.dtb
load mmc ${devno}:1 ${initrd_loadaddr} /initramfs-linux.uimg

# boot
booti ${loadaddr} ${initrd_loadaddr} ${dtb_loadaddr}
```

Don't forget to modify the root device from:

> root=/dev/sda2

To the device that matches your setup.

## GPU Acceleration

Now we proceed to clone this repository:

```sh
git clone https://github.com/jgmdev/archlinux-odroid-n2
```

The first package that needs to be installed is the Mali kernel driver
which should be the __dkms-mali-bifrost__ package:

```sh
cd dkms-mali-bifrost
makepkg
sudo pacman -U dkms-mali-bifrost-24.0-1-aarch64.pkg.tar.xz
```

Then you will need to install the user space binary driver known as
libMali.so, which interacts with the kernel driver part and is provided
by the __odroid-n2-libgl-wl__ package:

```sh
cd odroid-n2-libgl-wl
makepkg
sudo pacman -U odroid-n2-libgl-wl-r16p0-1-aarch64.pkg.tar.zst
```

After installing these two packages you may restart the system to make
sure that the changes will take effect. After reboot you should be
able to use one of the working environments listed before. You
can refer to the [ArchLinux Wayland](https://wiki.archlinux.org/index.php/Wayland)
wiki entry for installation instructions. The most lightweight
experience so far is with running weston. But the most complete
desktop environment would simply be GNOME.

## GNOME Performance Tips

Things you can do to decrease RAM usage of gnome and improve CPU
usage when the system is idle.

__Disable Trackers__ - The most important change

> Settings -> Search -> Turn Off

__Uninstall evolution data server__

```sh
sudo pacman -Rcs evolution-data-server
```

__Uninstall gnome software__

```sh
sudo pacman -Rcs gnome-software
```

Those changes should leave you a stable system.

## Weston

Weston is a limited desktop environment but it supports Xwayland which
makes it capable of running any application you may use. Make sure to
create a weston.ini file to enable it with __xwayland=true__ and
install __xorg-server-xwayland__, here an example:

__~/.config/weston.ini__
```
[core]
xwayland=true
idle-time=0

[terminal]
font=monospace
font-size=20

[keyboard]
keymap_rules=evdev
keymap_layout=us
keymap_variant=intl
keymap_model=pc105
numlock-on=true

[shell]
background-image=/path/to/some/background
background-type=scale
num-workspaces=4
cursor-theme=Adwaita
cursor-size=48

[launcher]
icon=/usr/share/icons/Adwaita/24x24/legacy/system-search.png
path=GDK_BACKEND=wayland PATH=/usr/bin:/home/alarm/Applications/bin /usr/bin/xfce4-appfinder

[launcher]
icon=/usr/share/icons/Adwaita/24x24/legacy/utilities-terminal.png
path=/usr/bin/weston-terminal

[launcher]
icon=/usr/share/icons/Adwaita/24x24/places/folder.png
path=GDK_BACKEND=wayland /usr/bin/thunar

[launcher]
icon=/usr/share/icons/hicolor/24x24/apps/firefox.png
path=GDK_BACKEND=wayland MOZ_ENABLE_WAYLAND=1 /usr/bin/firefox

[launcher]
icon=/usr/share/icons/hicolor/24x24/apps/chromium.png
path=GDK_BACKEND=x11 /usr/bin/chromium

[launcher]
icon=/usr/share/icons/hicolor/32x32/apps/geany.png
path=GDK_BACKEND=wayland /usr/bin/geany

[launcher]
icon=/usr/share/icons/Adwaita/24x24/devices/audio-headset.png
path=GDK_BACKEND=wayland /usr/bin/pavucontrol
```

__Note:__ I added environment variables to the launcher icons
because it seems that the weston launcher bar doesn't reads them from
the environment.

You can create a custom launcher script that initializes the neccesary
variables needed to run QT and GTK applications in wayland mode
and set a specific GTK and icon theme for you. Here is another
example:

__west.sh__

```sh
#!/bin/bash

export GDK_BACKEND=wayland
export QT_QPA_PLATFORM=wayland
export QT_STYLE_OVERRIDE="kvantum"
export SDL_VIDEODRIVER=wayland
export CLUTTER_BACKEND=wayland
export COGL_RENDERER=egl_wayland
export MOZ_ENABLE_WAYLAND=1

gnome_scheme=org.gnome.desktop.interface

gsettings set $gnome_scheme gtk-theme 'Arc-Dark'
gsettings set $gnome_scheme icon-theme 'Papirus-Dark'
gsettings set $gnome_scheme cursor-theme 'Adwaita'
gsettings set $gnome_scheme cursor-size '48'
gsettings set $gnome_scheme font-name 'Sans 16'

weston
```

Also notice, for QT applications I added __QT_STYLE_OVERRIDE="kvantum"__
to the example launcher script in order to have the same look as the GTK
ones. You have to install __kvantum-qt5__ package, then launch
__kvantummanager__ and select the theme you want to match with the
GTK applications.

You can read more about configuring weston on the
[ArchLinux Wiki](https://wiki.archlinux.org/index.php/Weston).

## Troubleshooting

Monitor screen resolution is not properly set with mainline kernel
and instead a lower resolution is used.

You can pass a parameter to the kernel to force a screen resolution
as explained on the [ArchLinux Wiki](https://wiki.archlinux.org/index.php/Kernel_mode_setting#Forcing_modes).
First you need to retrieve the proper display connector name by
executing the following code on your terminal emulator:

```sh
for p in /sys/class/drm/*/status; do con=${p%/status}; echo -n "${con#*/card?-}: "; cat $p; done
```

This code would return something like:

> HDMI-A-1

Then edit your __/boot/boot.ini__ and append to your bootargs a line like:

> video=HDMI-A-1:1920x1080@60

Which should look similar to:

> setenv bootargs "root=/dev/sda2 rootwait rw mitigations=off ${condev} ${amlogic} no_console_suspend fsck.repair=yes net.ifnames=0 clk_ignore_unused video=HDMI-A-1:1920x1080@60"