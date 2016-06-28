#!/bin/bash
if [[ $# -eq 0 ]] ; then
    echo "Running Update"
    sudo apt-get update
    echo " "
    echo " "
    echo " "
    echo "Running Dist Upgrade"
    sudo apt-get dist-upgrade -y
    echo " "
    echo " "
    echo " "
    echo "Running Auto Remove"
    sudo apt-get autoremove -y
    echo " "
    echo " "
    echo " "
    echo "Running Auto Clean"
    sudo apt-get autoclean -y
else

    case "$1" in
        all)
            $0 1stcallhelp.co.uk &
            $0 advent.1stcallhelp.co.uk &
            $0 pi.1stcallhelp.co.uk &
            $0 compaq.1stcallhelp.co.uk
            echo "Waiting for jobs to finish..."
            wait
            ;;

        *)
            echo "Running ssh $1 ~/bin/update"
            ssh -o ConnectTimeout=1 -o BatchMode=yes -o StrictHostKeyChecking=no $1 ~/bin/update 2>&1 | tee ~/log/$1_update.log
            ;;
    esac

fi
