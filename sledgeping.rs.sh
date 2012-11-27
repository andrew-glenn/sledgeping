#!/bin/bash
# SledgePing
# An updated version of hammerping.
# Andrew Glenn
#
# Version: 0.6
# Release: 2012.11.27

txtblk='\033[0;30m' # Black - Regular
txtred='\033[0;31m' # Red
txtgrn='\033[0;32m' # Green
txtylw='\033[0;33m' # Yellow
txtblu='\033[0;34m' # Blue
txtpur='\033[0;35m' # Purple
txtcyn='\033[0;36m' # Cyan
txtwht='\033[0;37m' # White
bldblk='\033[1;30m' # Black - Bold
bldred='\033[1;31m' # Red
bldgrn='\033[1;32m' # Green
bldylw='\033[1;33m' # Yellow
bldblu='\033[1;34m' # Blue
bldpur='\033[1;35m' # Purple
bldcyn='\033[1;36m' # Cyan
bldwht='\033[1;37m' # White
unkblk='\033[4;30m' # Black - Underline
undred='\033[4;31m' # Red
undgrn='\033[4;32m' # Green
undylw='\033[4;33m' # Yellow
undblu='\033[4;34m' # Blue
undpur='\033[4;35m' # Purple
undcyn='\033[4;36m' # Cyan
undwht='\033[4;37m' # White
bakblk='\033[40m'   # Black - Background
bakred='\033[41m'   # Red
bakgrn='\033[42m'   # Green
bakylw='\033[43m'   # Yellow
bakblu='\033[44m'   # Blue
bakpur='\033[45m'   # Purple
bakcyn='\033[46m'   # Cyan
bakwht='\033[47m'   # White
txtrst='\033[0m'    # Text Reset

function dot_update(){
    echo -ne "."
}

function successbox(){
    echo -e "[${bldylw}**${txtrst}] $@"
}

function infobox(){
    echo -e "[${bldcyn}??${txtrst}] $@"
}

function warningbox(){
    echo -e "[${bldred}!!${txtrst}] $@"
}


export script_input=$1

function datestamp(){
    echo $(date +'[%Y/%m/%d [%H.%m.%S]')
}

function usage(){
    echo "You did something wrong. Here's the manual..."
    echo
    echo "$0 [-n] [DEVICE NUMBER]" 
    echo 
    echo "-n : No Ping Needed"
    echo
}

function check_ping(){
    # Export the primary IP
    export primary_ip=$(ht -I $1 | egrep 'Primary IP' | awk '{print $3}')
    # While the server isn't responding to ping...
    while true; do
        if [ ! -z "$no_ping" ]; then
            echo "$(datestamp) $(infobox "PING isn't needed due to option passed")"
            break
        fi
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
        ssh -q bastion "nc -z ${primary_ip} 22" > /dev/null 2>&1
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
    if [ ! -z "$sp_ping_up" -a  ! -z "$sp_ssh_up" -o ! -z "$sp_ssh_up" -a ! -z "$no_ping" ]; then
        # log into the box.
        echo "$(datestamp) $(successbox "Connectivity Confirmed!")"
        ht $script_input
        exit 0
    else
        echo "$(datestamp) $(warningbox "NO DICE!")"
    fi
}

# Magic goes here. 

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

while getopts ":n" opt; do 
    case $opt in
        n)
            export no_ping="yes"
            shift 
            export script_input="$1"
        ;;
        \?)
            usage
        ;;
    esac
done


echo "$(datestamp) $(infobox "Checking ping on the server")"
check_ping $script_input

echo "$(datestamp) $(infobox "Checking ssh on the server")"
check_ssh

echo "$(datestamp) $(infobox "Logging into the server")"
access_server
