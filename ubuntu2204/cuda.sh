#!/bin/bash
set -e
set -o pipefail

NAME='NVIDIA CUDA Toolkit'

GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'



function preprocess() {
    echo -e "${GREEN}--- ${NAME} Pre-process ---${RESET}"
    
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
    sudo dpkg -i cuda-keyring_1.1-1_all.deb
    rm cuda-keyring_1.1-1_all.deb
    
    echo -e "${GREEN}--- ${NAME} Pre-process complete ---${RESET}\n"
}

function install() {
    echo -e "${GREEN}--- ${NAME} Install ---${RESET}"
    
    sudo DEBIAN_FRONTEND=noninteractive apt-get -y install cuda-runtime-13.0 cuda-compiler-13.0 cuda-libraries-dev-13.0
    
    echo -e "${GREEN}--- ${NAME} Install complete ---${RESET}\n"
}

function postprocess() {
    echo -e "${GREEN}--- ${NAME} Post-process ---${RESET}"
    
    echo 'export PATH=/usr/local/cuda-13.0/bin${PATH:+:${PATH}}' >> ~/.bashrc
    echo 'export LD_LIBRARY_PATH=/usr/local/cuda-13.0/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}' >> ~/.bashrc
    
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
    sudo apt-get update
    preprocess
    sudo apt-get update
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