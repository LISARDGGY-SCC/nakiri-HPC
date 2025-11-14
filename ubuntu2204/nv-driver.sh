#!/bin/bash
set -e
set -o pipefail

NAME='NVIDIA Driver'

GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'



function preprocess() {
    echo -e "${GREEN}--- ${NAME} Pre-process ---${RESET}"
    
    echo "blacklist nouveau" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
    echo "options nouveau modeset=0" | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf
    sudo update-initramfs -u
    (sudo modprobe -r nouveau || echo "nouveau module not loaded or could not be removed.")

    apt install -y linux-headers-$(uname -r)
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
    dpkg -i cuda-keyring_1.1-1_all.deb
    rm cuda-keyring_1.1-1_all.deb
    
    echo -e "${GREEN}--- ${NAME} Pre-process complete ---${RESET}\n"
}

function install() {
    echo -e "${GREEN}--- ${NAME} Install ---${RESET}"
    
    sudo DEBIAN_FRONTEND=noninteractive apt install -y nvidia-driver-580
    
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