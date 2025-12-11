#!/bin/bash

# Script metadata
NAME="Swap File Creator"
DESC="Create and configure swap file for system memory"

DATA=4

get_choose() {
    read -p "Enter num swap (GB): " DATA
}

get_choose

echo "-> Start create swap file $DATA GB..."
echo "-> Disable use swap..."
swapoff -a

echo "-> Allocate swapfile..."
dd if=/dev/zero of=/swapfile bs=1G count="$DATA" status=progress

echo "-> Give root-only permission to it..."
chmod 600 /swapfile

echo "-> Mark the file as SWAP space."
mkswap /swapfile

echo "-> Enable the SWAP"
swapon /swapfile

echo "-> Swap show"
swapon --show

echo "-> Create and enable Swap file $DATA GB success!!"
