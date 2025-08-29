#!/bin/bash
check() {
    for cmd in "$@"; do
        printf "checking for %s... " "$cmd"
        if command -v "$cmd" >/dev/null 2>&1; then
            echo "found ($cmd)"
        else
            echo "not found"
            echo "Error: '$cmd' is missing. Aborting."
            exit 1
        fi
    done
}

check gcc g++ which tar zip sed meson make cmake ninja autoconf automake libtool pkg-config makeinfo gettext gperf bison flex git xz unzip file find cp mv rm ln svn nasm yasm
