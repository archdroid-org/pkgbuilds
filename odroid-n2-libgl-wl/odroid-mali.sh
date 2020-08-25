#!/bin/bash

alarm_check_root() {
    if [ $(id -u) -ne 0 ]; then
        echo "You need to be root to execute this command." 1>&2
        exit 1
    fi
}

case "$1" in
    "status")
        if grep "/usr/lib" /etc/ld.so.conf.d/mali.conf > /dev/null ; then
            echo "libMali Enabled"
        else
            echo "libMali Disabled"
        fi

        exit 0
        ;;
    "toggle")
        alarm_check_root

        if grep "/usr/lib" /etc/ld.so.conf.d/mali.conf > /dev/null ; then
            echo "libMali Disabling..."

            echo "" > /etc/ld.so.conf.d/mali.conf

            sed -i "/\/usr\/lib\/mali-egl\/libgbm-compat.so/d" /etc/ld.so.preload
            sed -i "/\/usr\/lib\/mali-egl\/libmali.so/d" /etc/ld.so.preload
        else
            echo "libMali Enabling..."

            echo "/usr/lib/mali-egl" > /etc/ld.so.conf.d/mali.conf

            sed -i "/\/usr\/lib\/mali-egl\/libgbm-compat.so/d" /etc/ld.so.preload
            echo "/usr/lib/mali-egl/libgbm-compat.so" >> /etc/ld.so.preload

            sed -i "/\/usr\/lib\/mali-egl\/libmali.so/d" /etc/ld.so.preload
            echo "/usr/lib/mali-egl/libmali.so" >> /etc/ld.so.preload
        fi

        ldconfig

        exit 0
        ;;
    "run")
        shift

        if grep "/usr/lib" /etc/ld.so.conf.d/mali.conf > /dev/null ; then
            $@
        else
            LD_PRELOAD="/usr/lib/mali-egl/libgbm-compat.so"
            LD_PRELOAD="$LD_PRELOAD /usr/lib/mali-egl/libmali.so" \
                LD_LIBRARY_PATH=/usr/lib/mesa-egl \
                $@
        fi

        exit 0
        ;;
    *)
        echo "Basic utility to enable/disable libMali."
        echo "Usage: odroid-mali <command>"
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
