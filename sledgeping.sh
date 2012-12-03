#!/bin/bash
# SledgePing
# Designed to make logging into a server after a reboot much easier.
#
# Andrew Glenn
#
# Inquiries can be sent to andrew at andrewglenn dot net
#
### Begin Software License.
#
# This program is free software: you can redistribute it and/or modify
# it under the GNU General Public License as published by the 
# Free Software Foundation, either version 3 of the License, or (at your option)
# any later version.
# 
# http://www.gnu.org/licenses/gpl-3.0.html
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# No Warranty or guarantee or suitability exists for the software.
# Use at your own risk. The author is not responsible if your system breaks.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
### End Software License.
#
# Version: 1.6b
# Release: 2012.11.29
version="1.6b"

export sshopts='-o'
export expect_path="/usr/bin"
export nc_path="/bin"

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
    echo "Version: $version"
    echo
    echo "$0 is designed to make logging into a server post-reboot much easier."
    echo "It monitors ping and SSH connectivity and logs in only after both have been confirmed"
    echo "This allows the administrator to focus on other things while the server reboots..."
    echo "...rather than babysitting the connection"
    echo
    echo "$0 [-n] [-c] [-r] [-d] [-e] [-u user] [-p port] IP" 
    echo "Note: The IP address *MUST* be the last argument passed"
    echo 
    echo "-n : No Ping Needed. Cannot be used with [-r]"
    echo
    echo "-c : Disable color output"
    echo
    echo "-u : Specific username (defaults to 'root')"
    echo
    echo "-p : Specific port (defaults to '22', unless overwrote in local ssh configuration (~/.ssh/config))"
    echo
    echo "-r : Pending reboot - Allows Ping to succeed, then fail, then succeed, before testing SSH. Useful"
    echo "      for starting up $0 before rebooting a server. Cannot be used with [-n]"
    echo
    echo "-d : Don't login to the device once we've determined it's up."
    echo "      Only print the SSH String"
    echo
    echo "-e : Use expect to login to the device once connectivity has been"
    echo "      confirmed. The password will be stored in an env variable and unset "
    echo "      after use"
    echo
    echo "Exit Codes:"
    echo "  0: All is well"
    echo "  1: Something went wrong"
    echo
}

function check_command(){
    if [ ! -f "$@" ]; then
        echo "$(datestamp) $(warningbox "Hey! $@ isn't available! Please install it!")"
        buh_bye
    fi
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
    # If PING and SSH are good, or SSH is good and PING is ignored:
    if [ -n "${sp_ping_up}" -a -n "${sp_ssh_up}" -o -n "${sp_ssh_up}" -a -n "${no_ping}" ]; then
        # Check if the user wants to use 'expect' to login to the server.
        if [ -n "${expect_passed}" ]; then 
            expect_login
        fi

        # Otherwise, log into the box.
        ## If we've passed the -d flag, then only print out the login string. Don't login.  
        ## Why in the world we'd download this script only to login ourselves is beyond me.
        ## But hey, sure, why not. :) 
        if [ -n "$nologin" ]; then
            echo -e "$(datestamp)  $(infobox "Your SSH Login String is: \n\n\t\tssh ${sshopts} ${user}@${primary_ip} -p ${port}\r\n")"
        else
        ## Otherwise, login to the server. 
            echo "$(datestamp) $(infobox "Logging into the server.")"
            ssh ${sshopts} ${user}@${primary_ip} -p ${port}
        fi

        exit 0
    else
        echo "$(datestamp) $(warningbox "NO DICE!")"
    fi
}
# This function is futile. Checking for sanity. Seriously?!

function sanity_check(){
    # Checking the existance of commands. Exit if they don't exist. 
    
    # Only check if -e is passed. 
    if [ -n "${expect_passed}" ]; then
        check_command "$expect_path/expect"
    fi

    check_command "$nc_path/nc"

    # If -n and -r are passed together, puke.

    if [ -n "${no_ping}" -a -n "${pendingreboot}" ]; then
        echo "$(datestamp) $(warningbox "ERROR! Cannot use [-n] and [-r] together!")"
        exit 1
    fi

    # If -e is passed, check to ensure the 'expect' binary is installed.
    # Assumming that check passes muster, then grab the password that we'll need to login
    if [ -n "${expect_passed}" ]; then
        if [ ! -x "${expect_path}/expect" ]; then
            echo "$(datestamp) $(warningbox "ERROR! ${expect_path}/expect doesn't exist or isn't executable. Please investigate!")"
            buh_bye
        fi
        # Grabbing user/pass info
        echo -e "Please enter your password:"
        echo -en "# "
        stty -echo
        read server_password;
        stty echo
        echo
        
        if [ -n "${server_password}" ]; then 
            export server_password
        fi
        
    fi

    if [ "${sshopts}" == "-o" ]; then
        export unset sshopts
    fi
}

function expect_login(){
    # Logging into the server automatically. 
    if [ -n ${port} ]; then
        sshport="-p ${port}"
    fi
    if [ -n ${expect_login} ]; then
        if [ -n ${sshopts} ]; then
            sshopts="${sshopts} \"StrictHostKeyChecking no\""
        else
            sshopts="-o \"StrictHostKeyChecking no\""
        fi
        ${expect_path}/expect <<- NOSOUP
            set timeout 20
            spawn ssh ${sshopts} ${user}@${primary_ip} ${sshport}
            expect "*?assword:*"
            send -- "$server_password\r"
            interact
NOSOUP
        exit 0
    fi
}

function buh_bye(){
    # Boom goes the dynamite!
    echo "$(datestamp) $(warningbox "OUCH! Exiting.")"
    exit 1
}

function housekeeping(){
    # Bulk unsetting colors
    # I really don't want to type all of this out, soo...
    for color in {txt,bld,unk,bak}{blk,red,grn,ylw,blu,pur,cyn,wht}; do 
        unset $color
    done
    unset color version sshopts txtrst port user primary_ip     \
            return_code dotnotice never_gonna_let_you_down      \
            never_gonna_give_you_up dotnotice sp_ping_up        \
            sp_ssh_up no_ping user port nocolors pendingreboot  \
            OPTARG opt datestamp nologin expectpath sshport     \
            expect_passed
}


trap buh_bye SIGINT

# Magic goes here. 
# AKA: Starting the main routine. 

if [ $# -eq 0 ]; then
    usage
    exit 0
fi

while getopts "u:p:ncrde" opt; do 
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
        d)
            export nologin="yes"
        ;;
        e)
            export expect_passed="yes"
        ;;
        \?)
            usage
        ;;
    esac
done
shift $((OPTIND - 1))
sanity_check

echo "$(datestamp) $(infobox "Checking ping on the server.")"
check_ping $1

echo "$(datestamp) $(infobox "Checking ssh on the server.")"
check_ssh

echo "$(datestamp) $(successbox "Connectivity Confirmed!")"
access_server

echo "$(datestamp) $(infobox "Doing housekeeping tasks.")"
housekeeping
