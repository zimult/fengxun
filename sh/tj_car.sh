#!/bin/bash

#############################

source ~/.profile
source ~/.bashrc
source ~/.bash_profile
source /etc/profile

#############################
cd "/var/www/fx"

cnt1=$(ps -ef | grep ruby | grep "tj_car" | wc -l)
if [ $cnt1 -lt 1 ]; then
        nohup /home/beefind/.rvm/rubies/ruby-2.3.3/bin/ruby tj_car.rb &
fi
