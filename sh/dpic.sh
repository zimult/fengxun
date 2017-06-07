#!/bin/bash

#############################

source ~/.profile

source ~/.bashrc

source /etc/profile

#############################
cd "/var/www/fx"

#cnt1=$(ps -ef | grep ruby | grep "dpic" | wc -l)
#if [ $cnt1 -lt 1 ]; then
        nohup ruby dpic.rb 1 8422 &
        nohup ruby dpic.rb 2 8422 &
        nohup ruby dpic.rb 3 8422 &
        nohup ruby dpic.rb 4 8422 &
        nohup ruby dpic.rb 5 8423 &
        nohup ruby dpic.rb 6 8423 &
        nohup ruby dpic.rb 7 8423 &
        nohup ruby dpic.rb 8 8423 &
#fi
