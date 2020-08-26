#!/bin/bash

alarm_check_root() {
    if [ $(id -u) -ne 0 ]; then
        echo "You need to be root to execute this command." 1>&2
        exit 1
    fi
}

case "$1" in
    "status")
        if grep "/usr/lib" /etc/ld.so.conf.d/mali-wl.conf > /dev/null ; then
            echo "libMali Wayland Enabled"
        else
            echo "libMali Wayland Disabled"
        fi

        exit 0
        ;;
    "toggle")
        alarm_check_root

        if [ -e "/etc/ld.so.conf.d/mali-fb.conf" ]; then
            if grep "/usr/lib" /etc/ld.so.conf.d/mali-fb.conf > /dev/null ; then
                echo "libMali Framebuffer version is enabled, please disable it first."
                exit 1
            fi
        fi

        if grep "/usr/lib" /etc/ld.so.conf.d/mali-wl.conf > /dev/null ; then
            echo "libMali Wayland Disabling..."

            echo "" > /etc/ld.so.conf.d/mali-wl.conf

            sed -i "/\/usr\/lib\/mali-egl-wl\/libgbm-compat.so/d" /etc/ld.so.preload
            sed -i "/\/usr\/lib\/mali-egl-wl\/libmali.so/d" /etc/ld.so.preload
        else
            echo "libMali Wayland Enabling..."

            echo "/usr/lib/mali-egl-wl" > /etc/ld.so.conf.d/mali-wl.conf

            sed -i "/\/usr\/lib\/mali-egl-wl\/libgbm-compat.so/d" /etc/ld.so.preload
            echo "/usr/lib/mali-egl-wl/libgbm-compat.so" >> /etc/ld.so.preload

            sed -i "/\/usr\/lib\/mali-egl-wl\/libmali.so/d" /etc/ld.so.preload
            echo "/usr/lib/mali-egl-wl/libmali.so" >> /etc/ld.so.preload
        fi

        ldconfig

        exit 0
        ;;
    "run")
        shift

        if [ -e "/etc/ld.so.conf.d/mali-fb.conf" ]; then
            if grep "/usr/lib" /etc/ld.so.conf.d/mali-fb.conf > /dev/null ; then
                echo "Error: conflicting libMali Framebuffer is enabled, disable it first."
                exit 1
            fi
        fi

        if grep "/usr/lib" /etc/ld.so.conf.d/mali-wl.conf > /dev/null ; then
            $@
        else
            LD_PRELOAD="/usr/lib/mali-egl-wl/libgbm-compat.so"
            LD_PRELOAD="$LD_PRELOAD /usr/lib/mali-egl-wl/libmali.so" \
                LD_LIBRARY_PATH=/usr/lib/mesa-egl-wl \
                $@
        fi

        exit 0
        ;;
    *)
        echo "Basic utility to enable/disable libMali Wayland."
        echo "Usage: odroid-mali-wl <command>"
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
