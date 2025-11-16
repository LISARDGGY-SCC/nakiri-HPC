#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
INSTALLER_DIR="${SCRIPT_DIR}/ubuntu2204"

chmod +x ${INSTALLER_DIR}/*.sh

GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

usage() {
    echo "Usage: $0 [installer1] [installer2] ..."
    echo "Avalable installer:"
    # 尋找 commands 目錄下的 .sh 檔案，並移除路徑和 .sh 副檔名
    ls -1 "${INSTALLER_DIR}"/*.sh | sed -e 's|.*/||' -e 's|\.sh$||' -e 's|template||' | xargs -I{} echo "  -" {}
    exit 1
}

if [ "$#" -eq 0 ]; then
    echo -e "${RED}ERROR: Need at least one installer${RESET}"
    usage
fi

# Check argument
for installer in "$@"; do
    script_file="${INSTALLER_DIR}/${installer}.sh"

    if ! [ -f "$script_file" ]; then
        echo "----------------------------"
        echo -e "${RED}ERROR: File '${installer}'.sh not found.${RESET}"
        usage
        exit 1
    fi
done

# Pre-process all
sudo apt update
for installer in "$@"; do
    script_file="${INSTALLER_DIR}/${installer}.sh"

    if [ -f "$script_file" ] && [ -x "$script_file" ]; then
        echo "----------------------------"
        sudo "$script_file" --pre
    else
        echo "----------------------------"
        echo -e "${RED}ERROR: File '${installer}'.sh not found.${RESET}"
    fi
done

# Install all
sudo apt update
for installer in "$@"; do
    script_file="${INSTALLER_DIR}/${installer}.sh"

    if [ -f "$script_file" ] && [ -x "$script_file" ]; then
        echo "----------------------------"
        sudo "$script_file" --install
    else
        echo "----------------------------"
        echo -e "${RED}ERROR: File '${installer}'.sh not found.${RESET}"
    fi
done

# Post-process all
for installer in "$@"; do
    script_file="${INSTALLER_DIR}/${installer}.sh"

    if [ -f "$script_file" ] && [ -x "$script_file" ]; then
        echo "----------------------------"
        sudo "$script_file" --post
    else
        echo "----------------------------"
        echo -e "${RED}ERROR: File '${installer}'.sh not found.${RESET}"
    fi
done

echo -e "${GREEN}All installation completed${RESET}"