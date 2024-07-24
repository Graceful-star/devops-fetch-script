#!/bin/bash

LOG_FILE="/var/log/devopsfetch.log"

while true; do
    output=$(/usr/local/bin/devopsfetch.sh)
    echo "$(date): $output" >> "$LOG_FILE"
    sleep 300  # Run every 5 minutes
done