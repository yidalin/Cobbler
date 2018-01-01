#!/bin/bash

echo "alias ls='ls --color=always'" >> /etc/bashrc
tail -n 1 /etc/bashrc

if [ $(whoami)=='root' ]; then
    # For root
    echo 'PS1="\e[0;31m\u\e[m \e[1;30min\e[m \e[0;32m\H\e[m \e[1;30mat\e[m \e[1;36m\w\e[m \e[0;35m[\t]\e[m\n\$ "' >> /root/.bashrc
    tail -n 1 /root/.bashrc
else
    # For current
    echo 'PS1="\e[0;34m\u\e[m \e[1;30min\e[m \e[0;32m\H\e[m \e[1;30mat\e[m \e[1;36m\w\e[m \e[0;35m[\t]\e[m\n\$ "' >> ~/.bashrc
    tail -n 1 ~/.bashrc
fi
