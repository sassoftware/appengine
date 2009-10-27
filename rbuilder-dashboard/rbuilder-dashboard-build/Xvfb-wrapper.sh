#!/bin/sh
#
# Copyright (c) 2008 rPath, Inc.
# All rights reserved
#
# This could probably be done more elegantly in Python...

pid=''
for ((d=0; d < 20; d++)); do
    DISPLAY=:$d
    Xvfb -ac $DISPLAY 2>&1 &
    sleep 2
    jobs -l %1 > /dev/null
    pid=$(jobs -l %1 2>&1 | grep Running | awk '{print $2}')
    if [ -z "$pid" ]; then
        continue
    fi
    if ps $pid > /dev/null 2>&1; then
        break
    fi
done

if [ -z "$pid" ]; then
    echo "unable to start Xvfb" 2>&1
    exit 1
fi

trap "kill -9 $pid" SIGINT SIGTERM EXIT

export DISPLAY=$DISPLAY

$*
