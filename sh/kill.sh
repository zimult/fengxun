ps -ef | grep web1 | grep -v grep | awk '{print $2}' | xargs sudo kill
