ps -ef | grep dpic | grep -v grep | awk '{print $2}' | xargs sudo kill -9
