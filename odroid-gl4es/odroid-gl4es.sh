#!/bin/bash

alarm_check_root() {
    if [ $(id -u) -ne 0 ]; then
        echo "You need to be root to execute this command." 1>&2
        exit 1
    fi
}

case "$1" in
    "toggle")
        alarm_check_root

        if grep "/usr/lib" /etc/ld.so.conf.d/gl4es.conf > /dev/null ; then
            echo "" > /etc/ld.so.conf.d/gl4es.conf
            echo "GL4ES Disabling..."
        else
            echo "/usr/lib/gl4es" > /etc/ld.so.conf.d/gl4es.conf
            echo "GL4ES Enabling..."
        fi

        ldconfig

        exit 0
        ;;
    "config")
        alarm_check_root
        nano /etc/profile.d/gl4es.sh

        exit 0
        ;;
    *)
        echo "Basic utility to administer gl4es."
        echo "Usage: gl4es-setup <command>"
        echo ""
        echo "COMMANDS:"
        echo ""
        echo "  toggle - Enable or disable gl4es OpenGL hi-jacking."
        echo ""
        echo "  config - Edit the environment variables related to gl4es."
        echo ""

        exit 0
esac
