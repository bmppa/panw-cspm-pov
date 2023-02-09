#!/bin/bash

# The input for this script is the IP address of the machine to be scanned.

i=0
SECONDS=0

while true; do
    output=$(nc -vz -w5 $1 22 2>&1)
    if [[ $? != 0 ]]
     then
        duration=$SECONDS
        echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
        exit
    fi
    echo "$i: $output"
    sleep 5
    i=$[$i+1]
done
