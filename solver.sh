#!/usr/bin/env bash

[ "$TEAM" ] || {
    echo "TEAM environment variable not set; using default value 'rainbow'."
    TEAM=rainbow
}

[ "$SERVER" ] || {
    echo "SERVER environment variable not set; using default value 'localhost:5000'."
    SERVER=localhost:5000
}

set -eu

solve_hash() {
    HASH=$1
    DIFFICULTY=$2
    LOW=$((10 ** (DIFFICULTY - 1)))
    HIGH=$((10 ** DIFFICULTY))
    for I in $(seq $LOW $HIGH); do
        TRYHASH=$(echo "$TEAM.$I" | sha256sum | awk '{print $1}')
        if [ "$TRYHASH" = "$HASH" ]; then
            echo "$I"
            return
        fi
    done
    echo "Failed to solve hash $HASH."
    exit 1
}

solve_challenge() {
    CHALLENGE=$1
    DIFFICULTY=$2
    SOLUTION=""
    for HASH in $(curl -fs "$SERVER/v1/team/$TEAM/challenge/$CHALLENGE.txt"); do
        SOLUTION=$SOLUTION$(solve_hash "$HASH" "$DIFFICULTY")
    done
    echo "$SOLUTION"
}

solve_all() {
    curl -fs localhost:5000/v1/challenges \
        | jq -r '.[] | [ .name, .difficulty ] | @tsv' \
        | while read -r CHALLENGE DIFFICULTY; do
            echo "Solving challenge $CHALLENGE with difficulty $DIFFICULTY."
            SOLUTION=$(solve_challenge "$CHALLENGE" "$DIFFICULTY")
            curl -fs "$SERVER/v1/team/$TEAM/challenge/$CHALLENGE" -H content-type:text/plain --data "$SOLUTION"
        done
}

solve_all
