#encoding=UTF-8
require 'logger'


tm = Time.now - 3600
fd = tm.strftime('%H')

p fd
fold = "/var/www/fx/pic/#{fd}"

cmd = "rm -rf #{fold}"
system cmd
p cmd

Dir::mkdir fold


#Dir.foreach(fold) do |f|
#	next if f.length < 3

#	`rm -rf #{fold}/#{f}`
#end

p "----- done"
