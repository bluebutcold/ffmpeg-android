#!/bin/bash
check() {
    for cmd in "$@"; do
        printf "checking for %s... " "$cmd"
        sleep 0.1
        if command -v "$cmd" >/dev/null 2>&1; then
            echo "found"
        else
            echo "not found"
            echo "Error: '$cmd' is missing. Aborting."
            exit 1
        fi
    done
}

check gcc g++ which curl wget tar zip sed meson make cmake ninja autoconf automake libtool pkg-config makeinfo gettext gperf bison flex git xz unzip file find cp mv rm ln svn nasm yasm
