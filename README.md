# GPU Accelerated Odroid N2 in ArchLinuxARM

Custom packages to enable gpu acceleration of Odroid N2 on
ArchLinuxARM, based on the packages done for Ubuntu 20.04 by
[tobetter](https://github.com/tobetter).

**Note:** The supplied Mali binary drivers for bifrost (which is the
code name of the model G52 gpu found on the Odroid N2), does not
supports X11 so the gpu acceleration will only work on wayland
compositors. There is ongoing work on a compatibility layer to make
the OpenGL ES part of the Mali binary driver work under X11 by
[OtherCrashOverride](https://github.com/OtherCrashOverride), more
details can be read on this
[post](https://forum.odroid.com/viewtopic.php?f=182&t=34751) at the
Odroid Forum.

## What Works?

Here is a list of what has been tested so far divided in 4 categories:

* YES = Usable and supports Xwayland + runs glmark2-es2-wayland
* PARTIALLY - Usable but Xwayland or glmark2-es2-wayland may not work
* SLOW - Seems to run but really slow (wayland not properly loaded?)
* NO - Doesn't starts

### List of Environments

| Environment    | Status     | Notes                                  |
| -------------- | ---------- | -------------------------------------- |
| Weston         | YES        | Everything seems to work!              |
| Sway           | PARTIALLY  | Crashes when running X applications.   |
| Enlightenment  | PARTIALLY  | X applications run but, glmark2-es2-wayland segfaults on a regular user account, under root strangely works so something is wrong on the permissions system. |
| KDE            | SLOW       | Kwayland and Xwayland processes running but everything is slow |
| Wayfire        | NO         |                                        |
| GNOME          | NO         |                                        |

## Requirements

First you will need to install **linux-aarch64** package or
more up to date **linux-aarch64-rc** which are both supported
by the Mali kernel driver (dkms-mali-bifrost):

```sh
sudo pacman -S linux-aarch64-rc
```

Then modify your /boot/boot.ini file to be able to boot from
this kernel, here is a working **boot.ini** example:

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

Don't forget to modify the booting device from:

> root=/dev/sda2

To the device that matches your setup.

## GPU Acceleration

Now we proceed to clone this repository:

```sh
git clone https://github.com/jgmdev/archlinux-odroid-n2
```

The first package that needs to be installed is the Mali kernel driver
which should be the **dkms-mali-bifrost** package:

```sh
cd dkms-mali-bifrost
makepkg
sudo pacman -U dkms-mali-bifrost-24.0-1-aarch64.pkg.tar.xz
```

Then you will need to install the user space binary driver known as
libMali.so, which interacts with the kernel driver part and is provided
by the **odroid-n2-libgl-wl** package:

```sh
cd odroid-n2-libgl-wl
makepkg
sudo pacman -U odroid-n2-libgl-wl-r16p0-1-aarch64.pkg.tar.zst
```

After installing these to packages you may restart the system to make
sure that the changes will take effect and after reboot swith to
a virtual terminal (CTRL+ALT+F2), login and launch:

```
weston
```

or

```
enlightenment_start
```

Does seem to be the only options for now.

## Weston

Weston is a limited desktop environment but it supports Xwayland,
just make sure to create a weston.ini file to enable it with
**xwayland=true**, here an example:

**~/.config/weston.ini**
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
```

You can create a custom launcher that initializes the neccesary
variables needed to run QT and GTK applications in wayland mode
and sets a specific GTK and icon theme for you. Here is another
example:

**west.sh**

```
#!/bin/bash

export QT_QPA_PLATFORM=wayland
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