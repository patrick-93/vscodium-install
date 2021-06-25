#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
    echo "Must be ran as root user"
    exit 1
fi

# Get URL to download latest version
URL=$(curl -s https://api.github.com/repos/VSCodium/vscodium/releases/latest \
    | grep "VSCodium-linux-x64" \
    | grep -v sha256 \
    | tail -n 1 \
    | awk '{ print $2 }' \
    )
URL=${URL:1:-1} # trim quotes

cd /tmp && wget $URL

if [[ ${?} -gt 0 ]]; then
	echo "Error downloading the latest VSCodium version"
    exit 1
fi

# Download succeeded, check for current install, make backup if exists
if [[ $(ls /usr/share/vscodium-bin) ]]; then
    mv /usr/share/vscodium-bin /usr/share/vscodium-bin-bak
fi

mkdir /usr/share/vscodium-bin

tar xzvf $(ls /tmp | grep VSCodium) --directory /usr/share/vscodium-bin

if [[ ${?} -gt 0 ]]; then # Extract failed, delete and move the backup to original
    rm -rf /usr/share/vscodium-bin/
    rm -rf /tmp/$(ls /tmp | grep VSCodium)
    mv /usr/share/vscodium-bin-bak /usr/share/vscodium-bin
	echo "Extracting the new VSCodium failed, backing out and restoring old files"
    exit 1
fi

# Check is shortcut is present in /usr/bin/

if [[ $(ls /usr/bin | grep codium) ]]; then
    echo "codium shortcut found"
else
    ln -s /usr/share/vscodium-bin/codium /usr/bin/codium
fi


#### CLEANUP
rm -rf /usr/share/vscodium-bin-bak/
rm -f /tmp/$(ls /tmp | grep VSCodium)
