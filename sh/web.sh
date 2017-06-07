#!/bin/bash

#############################

source ~/.profile

source ~/.bashrc

source /etc/profile

#############################
cd "/var/www/fx/pic"

#cnt1=$(ps -ef | grep ruby | grep "dpic" | wc -l)
#if [ $cnt1 -lt 1 ]; then
        sudo nohup ./web1 8422 &
        sudo nohup ./web1 8423 &
#fi
