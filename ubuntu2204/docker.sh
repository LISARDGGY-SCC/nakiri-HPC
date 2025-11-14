#!/bin/bash
set -e
set -o pipefail

NAME='Docker'

GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

export DEBIAN_FRONTEND=noninteractive

function preprocess() {
    echo -e "${GREEN}--- ${NAME} Pre-process ---${RESET}"
    
    # Add Docker's official GPG key:
    sudo apt install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    sudo tee /etc/apt/sources.list.d/docker.sources << EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
    
    echo -e "${GREEN}--- ${NAME} Pre-process complete ---${RESET}\n"
}

function install() {
    echo -e "${GREEN}--- ${NAME} Install ---${RESET}"
    
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    echo -e "${GREEN}--- ${NAME} Install complete ---${RESET}\n"
}

function postprocess() {
    echo -e "${GREEN}--- ${NAME} Post-process ---${RESET}"
    
    (sudo groupadd docker || true)
    sudo usermod -aG docker "${SUDO_USER:-$(whoami)}"
    
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