#!/usr/bin/env sh

case $1 in
    "update")
        ;;
    "")
        echo "You shoud provide option"
        ;;
    *)
        echo "No option $1"
esac
