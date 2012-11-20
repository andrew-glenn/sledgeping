#!/bin/bash
# SledgePing
# An updated version of hammerping.
# Andrew Glenn
#
# Version: 0.1
# Release: 2012.11.19

export script_input=$1

source ~/bin/magicmarker.sh

function datestamp(){
    echo $(date +[%Y/%m/%d]\ [%H.%m.%S])
}

function check_ping(){
    # Export the primary IP
    export primary_ip=$(ht -I $script_input | egrep 'Primary IP' | awk '{print $3}')

    # While the server isn't responding to ping...
    while true; do
        ping -q -c 3 -i .5 $primary_ip 2>&1 > /dev/null
        if [ $? -eq 0 ]; then
            export sp_ping_up="yes"
            # Break out and continue on to the next function
            echo "$(datestamp) $(successbox "PING is up!")"
            break
        else
            dot_update
            sleep 1
        fi
    done
}

function check_ssh(){
    # Checking SSH via the bastion...
    while true; do 
        ssh -q bastion "echo \"EOF\" | nc -w 2 ${primary_ip} 22" 2>&1 > /dev/null
        if [ $? -eq 0 ]; then
            export sp_ssh_up="yes"
            # Break out and continue to the next function
            echo "$(datestamp) $(successbox "SSH is up!")"
            break
        else
            dot_update
            sleep 1
        fi
    done
}

function access_server(){
    # Quick sanity checking...
    if [ ! -z "$sp_ping_up" -a  ! -z "$sp_ssh_up" ]; then
        # log into the box.
        echo "$(datestamp) $(successbox "Connectivity Confirmed!")"
        ht $script_input
        exit 0
    else
        echo "$(datestamp) $(warningbox "NO DICE!")"
    fi
}

# Magic goes here. 

echo "$(datestamp) $(infobox "Checking ping on the server")"
check_ping $1

echo "$(datestamp) $(infobox "Checking ssh on the server")"
check_ssh

echo "$(datestamp) $(infobox "Logging into the server")"
access_server
