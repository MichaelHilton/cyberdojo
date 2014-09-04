#!/bin/bash

echo "Making the ram disk"
sudo mount -t tmpfs -o size=10G tmpfs /home/hugh/cyberdojo/katas/
echo "Copying files"
cp -Rv katas-hdd/* katas/
