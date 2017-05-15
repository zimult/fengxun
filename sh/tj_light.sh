#!/bin/bash

#############################

source ~/.profile

source ~/.bash_profile

source /etc/profile

#############################
cd "/var/www/fx"

cnt1=$(ps -ef | grep ruby | grep "tj_light" | wc -l)
if [ $cnt1 -lt 1 ]; then
        nohup ruby tj_light.rb &
fi
