#!/bin/sh
set -eu

TEAM=$1
CHALLENGE=$2
DIFFICULTY=$3
SERVER=$4

LOW=$((10**($DIFFICULTY-1)))
HIGH=$((10**$DIFFICULTY))

SOLUTION=""

for HASH in $(curl -fs http://$SERVER/v1/team/$TEAM/challenge/$CHALLENGE.txt); do
    echo "$HASH"
    THISHASH=FAIL
    for I in $(seq $LOW $HIGH); do
        TRYHASH=$(echo "$TEAM.$I" | sha256sum | awk '{print $1}')
        if [ "$TRYHASH" = "$HASH" ]; then
            THISHASH=$I
            SOLUTION=$SOLUTION$I
        fi
    done
    echo "$THISHASH"
    if [ "$THISHASH" = "FAIL" ]; then
        exit 1
    fi
done

echo $SOLUTION
