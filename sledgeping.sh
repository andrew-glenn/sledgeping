#!/bin/bash
# SledgePing
# An updated version of hammerping.
# Andrew Glenn
#
# Version: 1.2
# Release: 2012.11.27


export sshopts=''

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
    if [ -z ${nocolors} ]; then
        echo -e "[${bldylw}**${txtrst}] $@"
    else 
        echo "[**] $@"
    fi
}

function infobox(){
    if [ -z ${nocolors} ]; then
        echo -e "[${bldcyn}??${txtrst}] $@"
    else
        echo "[??] $@"
    fi
}

function warningbox(){
    if [ -z ${nocolors} ]; then
        echo -e "[${bldred}!!${txtrst}] $@"
    else
        echo "[!!] $@"
    fi
}


export port="22"
export user="root"

function datestamp(){
    echo $(date '+[%Y/%m/%d %H.%M.%S]')
}

function usage(){
    echo "You did something wrong. Here's the manual..."
    echo
    echo "$0 [-n] [-c] [-r] [-u user] [-p port] IP" 
    echo "Note: The IP address *MUST* be the last argument passed"
    echo 
    echo "-n : No Ping Needed. Cannot be used with [-r]"
    echo "-c : Disable color output"
    echo "-u : Specific username (defaults to 'root')"
    echo "-p : Specific port (defaults to '22', unless overwrote in local ssh configuration (~/.ssh/config))"
    echo "-r : Pending reboot - Allows Ping to succeed, then fail, then succeed, before testing SSH. Useful"
    echo "      for starting up $0 before rebooting a server. Cannot be used with [-n]"
    echo
}

function check_ping(){
    # Export the primary IP
    export primary_ip=$1 
    # While the server isn't responding to ping...
    while true; do
        # If we've passed the option to skip ping...
        if [ -n "$no_ping" ]; then
            echo "$(datestamp) $(infobox "PING isn't needed due to option passed")"
            break
        fi
        ping -q -c 3 $primary_ip 2>&1 > /dev/null
        return_code=$?
        # If we've pased the -r option, and ping is successful...
        if [ -n "$pendingreboot" -a "$return_code" -eq 0 ]; then
            # if we haven't provided an informational message...
            if [ -z "$dotnotice" ]; then
                echo "$(datestamp) $(infobox "it's up, waiting for it to reboot")"
                # Spam isn't fun, turn off this notice in the future.
                dotnotice=1
            # If This is the 2nd time through this function...
            elif [ -n "$never_gonna_give_you_up" ]; then
                # Unsetting $pendingreboot, so the box will show up - because, you know, it's back online (return code 0)
                unset pendingreboot
            else
                dot_update
                # Putting this here to unset the $dotnotice variable in the next if statement
                never_gonna_let_you_down=1
            fi
        fi
        
        # If we've passed the -r option AND the ping fails 
        if [ -n "$pendingreboot" -a "$return_code" -ne 0 ]; then
            # This is simply here so I can unset $dotnotice to reuse it. 
            if [ -n "$never_gonna_let_you_down" ]; then
                unset never_gonna_let_you_down
                unset dotnotice
            else
                echo "$(datestamp) $(warningbox "This box is down, but you passed the -r (reboot) option. This does not compute")"
                exit 1
            fi
            # If $dotnotice is zero (because I unset it above!)
            if [ -z "$dotnotice" ]; then
                echo
                echo "$(datestamp) $(infobox "it's down, waiting for it to come back up")"
                # Setting these two so I can unset $pendingreboot in the previous IF block when we go through the third time - after the box is back online
                never_gonna_give_you_up=1
                dotnotice=1
            else
                dot_update
            fi
        fi

        # If Ping succeeds, AND, either -r wasn't passed, or the variable has since been unset:
        if [ "$return_code" -eq 0 -a -z "$pendingreboot" ]; then
            export sp_ping_up="yes"
            echo
            echo "$(datestamp) $(successbox "PING is up!")"
            break
        fi
    done
}

function check_ssh(){
    # Checking SSH via the bastion...
    while true; do 
       nc -w 1 -z ${primary_ip} ${port} > /dev/null 2>&1
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
    if [ -n "$sp_ping_up" -a -n "$sp_ssh_up" -o -n "$sp_ssh_up" -a -n "$no_ping" ]; then
        # log into the box.
        echo "$(datestamp) $(infobox "Logging into the server.")"

       ssh ${sshopts} ${user}@${primary_ip} -p ${port}
        exit 0
    else
        echo "$(datestamp) $(warningbox "NO DICE!")"
    fi
}

function sanity_check(){
    if [ -n "${no_ping}" -a -n "${pendingreboot}" ]; then
        echo "$(datestamp) $(warningbox "ERROR! Cannot use [-n] and [-r] together!")"
        exit 1
    fi
}

function buh_bye(){
    echo
    echo "$(datestamp) $(warningbox "OUCH! Exiting.")"
    exit 2
}

trap buh_bye SIGINT
# Magic goes here. 

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

while getopts "u:p:ncr" opt; do 
    case $opt in
        n)
            export no_ping="yes"
        ;;
        u)
            export user=$OPTARG
        ;;
        p)
            export port=$OPTARG
        ;;
        c)
            export nocolors="yes"
        ;;
        r)
            export pendingreboot="yes"
        ;;
        \?)
            usage
        ;;
    esac
done
shift $((OPTIND - 1))
sanity_check

echo "$(datestamp) $(infobox "Checking ping on the server")"
check_ping $1

echo "$(datestamp) $(infobox "Checking ssh on the server")"
check_ssh

echo "$(datestamp) $(successbox "Connectivity Confirmed!")"
access_server
