#encoding=UTF-8
require 'logger'

$log = Logger.new("./log/clear.log", 'daily')
$log.level = Logger::INFO

tm = Time.now - 3600
fd = tm.strftime('%H')

$log.info("---- clear #{fd} begin. ----")

fold = "/var/www/fx/pic/#{fd}"

#cmd = "rm -rf #{fold}"
#system cmd
#p cmd

#Dir::mkdir fold


Dir.foreach(fold) do |f|
	next if f.length < 3

	`rm -rf #{fold}/#{f}`
end

$log.info "----- done"
