#!/usr/bin/env bash
#
# Get - Password Store Extension (https://www.passwordstore.org/)
#
# MIT License
#
# Copyright (c) 2023 Simon H Moore <simon@simonhugh.xyz>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

_usage="Usage: $(basename $0) get [-p] [-c] [-n] [-q] [-t] [-i] [-f] [-F] pass-name [character list]"
_help="$_usage
    -p              Print value (default)
    -c              Send value to clipboard
    -n              Send as notification
    -q              Open as qr code
    -t              Type value
    -i              Interpret value
    -f              Print field name with value
    -F              Only print field name
    -h              Print this help message
"

# send to clipboard using wl-copy or xclip
clip(){
    if [ -n "$WAYLAND_DISPLAY" ]; then
        wl-copy
    else
        xclip
    fi
}

# type out using wtype or xdotool
type(){
    if [ -n "$WAYLAND_DISPLAY" ]; then
        setsid sh -c "wtype -s 200 -d 20 '$1' &"
    elif [ -n "$DISPLAY" ]; then
        setsid sh -c "xdotool sleep 0.2 type --clearmodifiers '$1' &"
    fi
}

# get the nth characters
nth(){
    value="$1"
    shift
    numbers="$@"

    if [ "$printfield" == 1 ]; then
        field="$( printf "%s" "$value" | cut -d':' -f1 | sed 's/.*/&:/' )"
        value="$( printf "%s" "$value" | sed 's/^[^:][^:]*:[[:space:]]*//' | cut -c "$numbers" )"
        paste -d' ' <(printf "%s\n" "$field") <(printf "%s\n" "$value")
    else
        printf "%s" "$value" | cut -c "$numbers"
    fi

}

format(){
    value="$1"
    otpstring="$( printf "%s" "$value" | grep "^otpauth:.*" )"

    if [ "$interpret" == 1 ] && [ -n "$otpstring" ]; then
        otp="$( pass otp "$FILE" )"
        value="$( printf "%s" "$value" | sed "s|${otpstring}|otpauth: ${otp}|" )"
    fi

    # only print field name
    if [ "$novalue" == 1 ]; then
        value="$( printf "%s" "$value" | sed "s/:.*$//" )"

    # print fieldname with value
    elif [ "$printfield" == 1 ]; then
        value="$( printf "%s" "$value" )"

    # print only value
    else
        value="$( printf "%s" "$value" | sed "s/^[^:]*:[[:space:]]*//")"

        if [ "$interpret" != 1 ] && [ -n "$otpstring" ]; then
            otpheadless="$( printf "%s" "$otpstring" | sed 's/otpauth://' )"
            value="$( printf "%s" "$value" | sed "s|${otpheadless}|otpauth:&|" )"
        fi
    fi

        printf "%s" "$value"
}

# get value from pass file
get(){
    field="$1"
    file="$2"
    content="$( pass show "$file" )"

    # pass is a special field name to print first line
    if [ "$1" = "pass" ]; then
        printf "%s" "$content" | head -n 1
    else
        printf "%s" "$( printf "%s" "$content" | grep -i "^${field}[^:]*:..*$" )"
    fi

}

while getopts 'hpcnqtifF' OPTION; do
    case "$OPTION" in
    p) print=1 ;;
    c) clip=1 ;;
    n) notify=1 ;;
    q) qr=1 ;;
    t) type=1 ;;
    i) interpret=1 ;;
    f) printfield=1 ;;
    F) novalue=1 ;;
    h) printf "%s" "$_help" ; exit;;
    esac
    shift "$(($OPTIND -1))"
done

FIELD="$1"
FILE="$2"
value="$( get "$FIELD" "$FILE" )"
shift 2

value="$( format "$value" )"

# get nth characters
[ $# -gt 0 ] && value="$( nth "$value" $@ )"

# default to print
[ -z "${print}${clip}${notify}${qr}${type}" ] && print=1

if [ -n "$value" ]; then
    [ "$print" = 1 ] && printf "%s\n" "$value"
    [ "$clip" = 1 ] && printf "%s\n" "$value" | clip
    [ "$notify" = 1 ] && notify-send "PASS: $FILE" "$value"
    [ "$qr" = 1 ] && setsid -f sh -c "qrencode '$value' -s 8 -o - | imv - &"
    [ "$type" = 1 ] && type "$value"
    exit 0
else
    exit 1
fi
