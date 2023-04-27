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

_usage="Usage: $(basename $0) get [-p] [-c] [-n] [-q] pass-name"
_help="$_usage
    -p              Print value (default)
    -c              Send value to clipboard
    -n              Send as notification
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

# get value from pass file
get(){
    field="$1"
    file="$2"
    content="$( pass show "$file" )"

    # pass is a special field name to print first line
    if [ "$1" = "pass" ]; then
        printf "%s" "$content" | head -n 1
    else
        printf "%s" "$( printf "%s" "$content" | grep -i "^${field}[^:]*:..*$" | sed "s/^${field}[^:]*:[[:space:]]*//" )"
    fi

}

while getopts 'hpcn' OPTION; do
    case "$OPTION" in
    p) print=1 ;;
    c) clip=1 ;;
    n) notify=1 ;;
    h) printf "%s" "$_help" ; exit;;
    esac
    shift "$(($OPTIND -1))"
done

FIELD="$1"
FILE="$2"
value="$( get "$FIELD" "$FILE" )"
shift 2

# default to print
[ -z "${print}${clip}" ] && print=1

if [ -n "$value" ]; then
    [ "$print" = 1 ] && printf "%s\n" "$value"
    [ "$clip" = 1 ] && printf "%s\n" "$value" | clip
    [ "$notify" = 1 ] && notify-send "PASS: $FILE" "$value"
else
    exit 1
fi
