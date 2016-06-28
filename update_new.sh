#!/bin/bash
#
# This is a script made to keep your computer up to
# date placing this script to /etc/cron.weekly/autoupdate.sh.
# This script updates your server automatically and informs
# you via email if the update was succesful or not.
#

#
# Set some constants
#
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
LIME_YELLOW=$(tput setaf 190)
POWDER_BLUE=$(tput setaf 153)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BRIGHT=$(tput bold)
NORMAL=$(tput sgr0)
BLINK=$(tput blink)
REVERSE=$(tput smso)
UNDERLINE=$(tput smul)

#
# Set defaults
#
me="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")" # Name of script
mailadd="carlmcalwane@hotmail.co.uk"    # “m” and “mailto” have optional arguments with default values.
logfile="/var/log/update_new.log"       # “l” and “logfile” have optional arguments with default values.
quiet="false"                           # “q” and “quiet” have no arguments, acting as sort of a flag.
verbose="true"                          # “v” and “verbose” have no arguments, acting as sort of a flag.
sendmail="true"                         # “s” and “sendmail” have no arguments, acting as sort of a flag.
doUpdate="true"                         # “u” and “doupdate” have no arguments, acting as sort of a flag.
doUpgrade="true"                        # “g” and “doupgrade” have no arguments, acting as sort of a flag.
doClean="true"                          # “c” and “doclean” have no arguments, acting as sort of a flag.
background="false"                      # “b” and “background” have no arguments, acting as sort of a flag.
showHelp="false"                        # “h” and “help” have no arguments, acting as sort of a flag.
showOptions="false"                     # “o” and “showoptions” have no arguments, acting as sort of a flag.

show_help()
{
    printf "%s\n" "Usage : "
    printf "%s\n\n" " ${me} [options]"
    printf "%s\n" "Options : "
    printf "%s\n" "-m, --mailto<=email>            Address to send notification email to.  (see also -s, --sendmail)"
    printf "%s\n" "                                default = '${mailadd}'"
    printf "%s\n" "-l, --logfile<=logfile name>    Logfile name."
    printf "%s\n" "                                default = /var/log/${me}.log.  '**NOLOG**' = no logging."
    printf "%s\n" "-q, --quiet                     Don't display any output to STDOUT"
    printf "%s\n" "-v, --verbose                   Use verbose logging and output"
    printf "%s\n" "-s, --sendmail<=true | false>   Send notification email to mailto address.  (see also -m, --mailto)"
    printf "%s\n" "                                default = '${sendmail}'. 'true' if parameter is ommited."
    printf "%s\n" "-u, --doupdate<=true | false>   Do 'apt-get update'."
    printf "%s\n" "                                default = '${doUpdate}'. 'true' if parameter is ommited."
    printf "%s\n" "-g, --doupgrade<=true | false>  Do 'apt-get upgrade'."
    printf "%s\n" "                                default = '${doUpgrade}'. 'true' if parameter is ommited."
    printf "%s\n" "-c, --doclean<=true | false>    Do 'apt-get autoremove'."
    printf "%s\n" "                                default = '${doClean}'. 'true' if parameter is ommited."
    printf "%s\n" "-b, --background<=true | false> Execute in background"
    printf "%s\n" "                                default = '${background}'. 'true' if parameter is ommited."
    printf "%s\n" "-h, --help                      Show this help."
    printf "%s\n" "-o, --showoptions               Show configured options."
}

#
# Get commandline options
#
TEMP=`getopt -o m::l::qvsu::g::c::bho --long mailto::,logfile::,quiet,verbose,sendmail,doupdate::,doupgrade::,doclean::,background,help,showoptions -n ${me} -- "$@"`
if [[ $? -ne 0 ]]; then # getopt reported failure
    echo "Try '${me} -h' or '${me} --help'"
    exit 1
fi

eval set -- "$TEMP"

# extract options and their arguments into variables.
while true ; do
    case "$1" in
        -m|--mailto)
            case "$2" in
                "") mailadd="${mailadd}" ; shift 2 ;;
                *) mailadd=$2 ; shift 2 ;;
            esac ;;
        -l|--logfile)
            case "$2" in
                "") logfile="/var/log/update_new.log" ; shift 2 ;;
                *) logfile=$2 ; shift 2 ;;
            esac ;;
        -u|--doupdate)
            case "$2" in
                ""|"true") doUpdate="true" ; shift 2 ;;
                "false") doUpdate="false" ; shift 2 ;;
                *) echo "Invalid Option : -u $2" ; shift 2 ;;
            esac ;;
        -g|--doupgrade)
            case "$2" in
                ""|"true") doUpgrade="true" ; shift 2 ;;
                "false") doUpgrade="false" ; shift 2 ;;
                *) echo "Invalid Option : -g $2" ; shift 2 ;;
            esac ;;
        -c|--doclean)
            case "$2" in
                ""|"true") doClean="true" ; shift 2 ;;
                "false") doClean="false" ; shift 2 ;;                
                *) echo "Invalid Option : -c $2" ; shift 2 ;;
            esac ;;
        -q|--quiet) quiet="true" ; shift ;;
        -v|--verbose) verbose="true" ; shift ;;
        -s|--sendmail) sendmail="true" ; shift ;;
        -b|--background) background="true" ; shift ;;
        -h|--help) showHelp="true" ; shift ;;
        -o|--showoptions) showOptions="true" ; shift ;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

function verboseLogOutput()
{
    prefix="${YELLOW}[update_new] $(date +"%d-%m-%Y %H:%M":%S)${NORMAL}"
    IN=""
    if [ -n "$1" ] ; then
        msg="$(echo -e "${1}" |  sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g")"
        if [ ${verbose} == "true" ] || [ ${logfile} <> "**NOLOG**" ] ; then
            if [ ${verbose} == "true" ] ; then
                printf "%s : %s\n" "${prefix}" "${msg}" | tee -a ${tmpfile}
            else
                printf "%s : %s\n" "${prefix}$" "${msg}" >> ${tmpfile}
            fi
        fi
    else
        while read -r answer; do
            msg="$(echo -e "${answer}" |  sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g")"
            if [ ${verbose} == "true" ] || [ ${logfile} <> "**NOLOG**" ] ; then
                if [ ${verbose} == "true" ] ; then
                    printf "%s : %s\n" "${prefix}" "${msg}" | tee -a ${tmpfile}
                else
                    printf "%s : %s\n" "${prefix}" "${msg}" >> ${tmpfile}
                fi
            fi
        done
    fi

}

function logOutput()
{
    prefix="${YELLOW}[update_new] $(date +"%d-%m-%Y %H:%M":%S)${NORMAL}"
    IN=""
    if [ -n "${1}" ] ; then
        msg="$(echo -e "${1}" |  sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g")"
        if [ ${logfile} <> "**NOLOG**" ] ; then
            printf "%s : %s\n" "${prefix}" "${msg}" | tee -a ${tmpfile}
        fi
    else
        while read -r answer; do
            msg="$(echo -e "${answer}" |  sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g")"
            if [ ${logfile} <> "**NOLOG**" ] ; then
                printf "%s : %s\n" "${prefix}" "${msg}" | tee -a ${tmpfile}
            fi
        done
    fi
}

show_options()
{
    printf " mailadd = ${mailadd} \n logfile = ${logfile} \n quiet = ${quiet} \n verbose = ${verbose} \n"
    printf " sendmail = ${sendmail} \n doUpdate = ${doUpdate} \n doUpgrade = ${doUpgrade} \n doClean = ${doClean} \n"
    printf " background = ${background} \n showHelp = ${showHelp} \n showOptions = ${showOptions} \n"
}

update_new() 
{
    #
    # Create a temporary path in /tmp to write a temporary log
    # file. No need to edit.
    #
    tmpfile=$(mktemp)
    tmpfile2=$(mktemp)

    #
    # I quiet option selected, then divert STDOUT to /dev/null.
    #
    if [ ${quiet} == 'true' ] ; then
        exec 1>/dev/null
    fi

    #
    # If logfile dose not exist and logging is enabled,
    # then create it and make it world rw.
    #
    if [ ! ${logfile} == "**NOLOG**" ] ; then
        if [ ! -e ${logfile} ] ; then
            sudo touch ${logfile}
            sudo chmod a+rw ${logfile}
        fi
    fi

    #
    # Run the commands to update the system and write the log
    # file at the same time.
    #

    verboseLogOutput "update_new - Rundate `date`"

    if [ ${doUpdate} == "true" ] ; then
        logOutput "Running : apt-get update"
        sudo apt-get update 2>&1 | verboseLogOutput
    else
        verboseLogOutput "Skipping : apt-get update"
    fi
        
    if [ ${doUpgrade} == "true" ] ; then
        logOutput "Running : apt-get upgrade"  
        sudo apt-get -y upgrade 2>&1 | verboseLogOutput 
    else
        verboseLogOutput "Skipping : apt-get upgrade"
    fi
                
    if [ ${doClean} == "true" ] ; then
        logOutput "Running : apt-get autoremove"  
        sudo apt-get -y autoremove 2>&1 | verboseLogOutput
    else 
        verboseLogOutput "Skipping : apt-get autoremove"
    fi

    #
    # I get a lot of escaped new lines in my output. so the following
    # removes them. this could be greatly improved
    #
    cat ${tmpfile} | sed 's/\r\r/\n/g'|sed 's/\r//g' > ${tmpfile2}
    mv ${tmpfile2} ${tmpfile}

    #
    # Send the temporary log via mail. The fact if the upgrade
    # was succesful or not is written in the subject field.
    #
    if grep -q 'E: \|W: ' ${tmpfile} ; then
    	subj="update_new on ${HOSTNAME}: *** Problems upgrading your server*** $(date)"
    else
        subj="update_new on ${HOSTNAME}: Upgraded your server succesfully $(date)"
    fi

    #
    # now log the output and send the email
    #
    if [ ${sendmail} == "true" ] ; then
        logOutput "Mailing Results - ${subj}  To ${mailadd}" 
    else
        verboseLogOutput "NOT Mailing Results - ${subj}  To ${mailadd}"
    fi

    if [ ${logfile} <> "**NOLOG**" ] ; then
        cat ${tmpfile} >> ${logfile}
    fi

    if [ $sendmail == "true" ] ; then
#        sendmail -fupdate_new@1stcallhelp.co.uk -s "${subj}" ${mailadd} < ${tmpfile} | logOutput
#        cat "${tmpfile}" | mail -s "${subj}" -r "Carl McAwane<carl@1stcallhelp.co.uk>" "${mailadd}" | logOutput
        cat "${tmpfile}" | /home/carl/bin/ansi2html.sh | /home/carl/bin/fnsendmail.sh "${mailadd}" "update_new<update_new@dell.1stcallhelp.co.uk>"
    fi

    #
    # Remove the temporary log file in temporary path.
    #
    verboseLogOutput "Cleaning up"
    rm -f ${tmpfile} ${tmpfile2} 2>&1 | tee -a ${logfile}
}

if [ ${showHelp} == "true" ] ; then
    show_help
    exit 0
fi

if [ $showOptions == "true" ] ; then
    show_options $*
    exit 0
fi

if [[ $EUID -eq 0 ]]; then
    if ( $background == "true" ) ; then
        update_new $* &
    else 
        update_new $*
    fi
else
    printf "%s\n" "${me} must be run as root." >&2
    exit 1
fi