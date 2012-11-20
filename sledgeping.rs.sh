#!/bin/bash
# SledgePing
# An updated version of hammerping.
# Andrew Glenn
#
# Version: 0.2
# Release: 2012.11.20

txtblk='\e[0;30m' # Black - Regular
txtred='\e[0;31m' # Red
txtgrn='\e[0;32m' # Green
txtylw='\e[0;33m' # Yellow
txtblu='\e[0;34m' # Blue
txtpur='\e[0;35m' # Purple
txtcyn='\e[0;36m' # Cyan
txtwht='\e[0;37m' # White
bldblk='\e[1;30m' # Black - Bold
bldred='\e[1;31m' # Red
bldgrn='\e[1;32m' # Green
bldylw='\e[1;33m' # Yellow
bldblu='\e[1;34m' # Blue
bldpur='\e[1;35m' # Purple
bldcyn='\e[1;36m' # Cyan
bldwht='\e[1;37m' # White
unkblk='\e[4;30m' # Black - Underline
undred='\e[4;31m' # Red
undgrn='\e[4;32m' # Green
undylw='\e[4;33m' # Yellow
undblu='\e[4;34m' # Blue
undpur='\e[4;35m' # Purple
undcyn='\e[4;36m' # Cyan
undwht='\e[4;37m' # White
bakblk='\e[40m'   # Black - Background
bakred='\e[41m'   # Red
bakgrn='\e[42m'   # Green
bakylw='\e[43m'   # Yellow
bakblu='\e[44m'   # Blue
bakpur='\e[45m'   # Purple
bakcyn='\e[46m'   # Cyan
bakwht='\e[47m'   # White
txtrst='\e[0m'    # Text Reset

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
    echo $(date +[%Y/%m/%d]\ [%H.%m.%S])
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
