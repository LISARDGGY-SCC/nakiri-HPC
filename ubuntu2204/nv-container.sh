#!/bin/bash
set -e
set -o pipefail

NAME='NVIDIA Container Toolkit'

GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'



function preprocess() {
    echo -e "${GREEN}--- ${NAME} Pre-process ---${RESET}"
    
    sudo DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends curl gnupg2
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    sudo sed -i -e '/experimental/ s/^#//g' /etc/apt/sources.list.d/nvidia-container-toolkit.list
    
    echo -e "${GREEN}--- ${NAME} Pre-process complete ---${RESET}\n"
}

function install() {
    echo -e "${GREEN}--- ${NAME} Install ---${RESET}"
    
    export NVIDIA_CONTAINER_TOOLKIT_VERSION=1.18.0-1
    sudo DEBIAN_FRONTEND=noninteractive apt install -y \
        nvidia-container-toolkit=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
        nvidia-container-toolkit-base=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
        libnvidia-container-tools=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
        libnvidia-container1=${NVIDIA_CONTAINER_TOOLKIT_VERSION}
    
    echo -e "${GREEN}--- ${NAME} Install complete ---${RESET}\n"
}

function postprocess() {
    echo -e "${GREEN}--- ${NAME} Post-process ---${RESET}"
    
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker
    
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