#!/bin/bash

#############################

source ~/.profile

#source ~/.bash_profile

source /etc/profile

#############################
cd "/var/www/fx"

cnt1=$(ps -ef | grep ruby | grep "dpic" | wc -l)
if [ $cnt1 -lt 1 ]; then
        nohup ruby dpic.rb &
fi
