#!/bin/bash
set -e
set -o pipefail

NAME='Singularity CE'

GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

export DEBIAN_FRONTEND=noninteractive

function preprocess() {
    echo -e "${GREEN}--- ${NAME} Pre-process ---${RESET}"
    
    # === Add preprocess of your installation ===
    # ex. Prerequistes, Depends or any thing you need to do before apt update
    # DON'T DO sudo apt update HERE
    
    echo -e "${GREEN}--- ${NAME} Pre-process complete ---${RESET}\n"
}

function install() {
    echo -e "${GREEN}--- ${NAME} Install ---${RESET}"
    
    wget https://github.com/sylabs/singularity/releases/download/v4.3.4/singularity-ce_4.3.4-jammy_amd64.deb
    sudo apt install -y ./singularity-ce_4.3.4-jammy_amd64.deb
    rm -rf ./singularity-ce_4.3.4-jammy_amd64.deb
    
    echo -e "${GREEN}--- ${NAME} Install complete ---${RESET}\n"
}

function postprocess() {
    echo -e "${GREEN}--- ${NAME} Post-process ---${RESET}"
    
    # === Add postprocess of your installation ===
    # ex. Setting enviroment or any thing you need to do after installation
    
    echo -e "${GREEN}--- ${NAME} Post-process complete ---${RESET}\n"
}

function usage() {
    echo "usage: $0 [pre|install|post]"
    echo "  --pre:          Pre-process only"
    echo "  --install:      Install only"
    echo "  --post:         Post-process only"
    echo "  no argument:    Pre-process -> Install -> Post-process)"
    exit 1
}

if [ "$#" -eq 0 ]; then
    sudo apt update
    preprocess
    sudo apt update
    install
    postprocess
elif [ "$#" -eq 1 ]; then
    case "$1" in
        --pre)
            preprocess
            ;;
        --install)
            install
            ;;
        --post)
            postprocess
            ;;
        --help)
            usage
            ;;
        *)
            echo -e "${RED}ERROR: Unknow argument '$1'${RESET}"
            usage
            ;;
    esac
else
    echo -e "${RED}ERROR: Unknow argument '$1'${RESET}"
    usage
fi

exit 0