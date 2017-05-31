#!/bin/bash

#############################

source ~/.profile

source ~/.bashrc

source /etc/profile

#############################
cd "/var/www/fx"

#cnt1=$(ps -ef | grep ruby | grep "dpic" | wc -l)
#if [ $cnt1 -lt 1 ]; then
        nohup ruby dpic.rb 1 &
        nohup ruby dpic.rb 2 &
        nohup ruby dpic.rb 3 &
        nohup ruby dpic.rb 4 &
        nohup ruby dpic.rb 5 &
        nohup ruby dpic.rb 6 &
        nohup ruby dpic.rb 7 &
        nohup ruby dpic.rb 8 &
#fi
