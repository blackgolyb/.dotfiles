#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

case $1 in
    "nsfw") TYPE="nsfw";;
    "sfw") TYPE="sfw";;
    "random")
        array[0]="nsfw"
        array[1]="sfw"
        size=${#array[@]}
        index=$(($RANDOM % $size))
        TYPE=${array[$index]}
        ;;
    *) TYPE="sfw";;
esac

URL="https://api.waifu.pics/${TYPE}/waifu"
HEIGHT="300px"
NEW_TYAN_FILE="$SCRIPT_DIR/new_tyan"
TYAN_FILE="$SCRIPT_DIR/tyan"

function update_waifu() {
    url=$(curl -s $URL | jq -r '.url')
    wget -q -O $NEW_TYAN_FILE $url
    cp $NEW_TYAN_FILE $TYAN_FILE
}

wezterm imgcat --height $HEIGHT $TYAN_FILE
update_waifu &
