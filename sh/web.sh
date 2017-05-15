#!/bin/bash

#############################

source ~/.profile

#source ~/.bash_profile

source /etc/profile

#############################
cd "/var/www/fx/pic"

cnt1=$(ps -ef | grep ruby | grep "webs" | wc -l)
if [ $cnt1 -lt 1 ]; then
	sudo nohup ./web1 &
fi
