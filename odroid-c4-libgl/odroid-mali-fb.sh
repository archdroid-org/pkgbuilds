#!/bin/bash

alarm_check_root() {
    if [ $(id -u) -ne 0 ]; then
        echo "You need to be root to execute this command." 1>&2
        exit 1
    fi
}

case "$1" in
    "status")
        if grep "/usr/lib" /etc/ld.so.conf.d/mali-fb.conf > /dev/null ; then
            echo "libMali Framebuffer Enabled"
        else
            echo "libMali Framebuffer Disabled"
        fi

        exit 0
        ;;
    "toggle")
        alarm_check_root

        if [ -e "/etc/ld.so.conf.d/mali-wl.conf" ]; then
            if grep "/usr/lib" /etc/ld.so.conf.d/mali-wl.conf > /dev/null ; then
                echo "libMali Wayland version is enabled, please disable it first."
                exit 1
            fi
        fi

        if grep "/usr/lib" /etc/ld.so.conf.d/mali-fb.conf > /dev/null ; then
            echo "libMali Framebuffer Disabling..."

            echo "" > /etc/ld.so.conf.d/mali-fb.conf

            echo -n "Do you want to also disable the fbdev driver [y/N]: "
            read DISABLE_FBDEV
            if [ "$DISABLE_FBDEV" = "y" ]; then
                echo "" > /etc/X11/xorg.conf.d/60-fbdev.conf
            fi
        else
            echo "libMali Framebuffer Enabling..."

            echo "/usr/lib/mali-egl-fb" > /etc/ld.so.conf.d/mali-fb.conf

            echo -n "Do you want to also enable the fbdev driver [y/N]: "
            read ENABLE_FBDEV
            if [ "$ENABLE_FBDEV" = "y" ]; then
                echo 'Section "Device"' > /etc/X11/xorg.conf.d/60-fbdev.conf
                echo '    Identifier  "Framebuffer"' >> /etc/X11/xorg.conf.d/60-fbdev.conf
                echo '    Driver      "fbdev"' >> /etc/X11/xorg.conf.d/60-fbdev.conf
                echo '    Option      "fbdev" "/dev/fb0"' >> /etc/X11/xorg.conf.d/60-fbdev.conf
                echo 'EndSection' >> /etc/X11/xorg.conf.d/60-fbdev.conf
            fi
        fi

        ldconfig

        exit 0
        ;;
    "run")
        shift

        if [ -e "/etc/ld.so.conf.d/mali-wl.conf" ]; then
            if grep "/usr/lib" /etc/ld.so.conf.d/mali-wl.conf > /dev/null ; then
                echo "Error: conflicting libMali Wayland is enabled, disable it first."
                exit 1
            fi
        fi

        if grep "/usr/lib" /etc/ld.so.conf.d/mali-fb.conf > /dev/null ; then
            LD_PRELOAD="/usr/lib/mali-egl-fb/libmali.so" $@
        else
            LD_PRELOAD="/usr/lib/mali-egl-fb/libmali.so" \
                LD_LIBRARY_PATH=/usr/lib/mesa-egl-fb \
                $@
        fi

        exit 0
        ;;
    *)
        echo "Basic utility to enable/disable libMali Framebuffer."
        echo "Usage: odroid-mali-fb <command>"
        echo ""
        echo "COMMANDS:"
        echo ""
        echo "  status - Print the libMali activation status."
        echo ""
        echo "  toggle - Enable or disable libMali."
        echo ""
        echo "  run <command> - Run a command with libMali enabled "
        echo "                  even if libMali is Disabled."
        echo ""

        exit 0
esac
