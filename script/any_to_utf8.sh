#!/bin/bash

while read line
do

    CHARSET="$(file -bi "$line" | awk -F "=" '{print $2}')"

    if [ "$CHARSET" != utf-8 ]; then
        iconv -f "$CHARSET" -t utf8 "$line" -o "$line.new"
        mv -f "$line.new" "$line"
    fi
done < "${1:-/dev/stdin}"
