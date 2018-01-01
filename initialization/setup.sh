#!/bin/bash

if [ ! -f ./bashrc ]; then
    echo "The bashrc file not exist!"
    exit
fi

echo "Backup the ~/.bashrc to ~/.bashrc.bk"
mv ~/.bashrc ~/.bashrc.$(date +%Y%m%d-%H%M%S)
echo "Copy the new .bashrc to ~/.bashrc"
cp -a ./bashrc ~/.bashrc

ls -al ~ | grep ".bashrc"
