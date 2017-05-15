# encoding: utf-8
#
require 'net/https'
require 'net/http'
require "open-uri"
require 'socket'
require 'date'
require 'fileutils'
require 'json'
require 'redis'
require 'iconv'
require 'rchardet'
require 'net/http/post/multipart'

#require_relative 'rkeys'
#require_relative 'fx_config'
#require_relative 'mysql2_conn'


$myurl = "http://192.168.0.100:8421"

def knum(file, cnt)
	rt = `curl http://127.0.0.1:8422/knum?file=12%2F30aea402fc70_121535_2.jpg`
	p rt
end

def knum2(file, cnt)
	card = ""
	state = 0
	cardno = "N"
	carColor = 0
	nColor = 0

	uri = URI('http://127.0.0.1:8422/knum')
	#fn = "#{mac}#{ed}"
	params = {:file=>file}
	uri.query = URI.encode_www_form(params)
	card = Net::HTTP.get(uri).force_encoding('GB2312')
	p card
	cd = card
	#card= Iconv.new('UTF8//IGNORE', 'GB2312//IGNORE').iconv(card)
	r = card.split(',')

	if r[0].length > 2
		state = 1 
		cardno = r[0].force_encoding('utf-8')
		nColor = r[3].force_encoding('utf-8') if r[3] 
		carColor = r[4].force_encoding('utf-8') if r[4]
	end

	#$log.info "-------- knum ret:#{r}"
	p "#{cnt}, r:#{r}"

	return state, cardno, nColor, carColor
end

##########
f = '12%2F30aea402fc70_121535_2.jpg'
for i in 0 .. 10000 do
	state, cardno, nColor, carColor = knum(f, i)
	p cardno
end
=begin
File.open('p.txt', 'r') do |ff|
	#for i in 0..5000 do
	#	k = i % 7 + 1
	#	filename = "#{k}.jpg"
	#	filename2 = "30aea402ff64_#{k}.jpg"
	#	state, cardno, nColor, carColor = knum(filename, i)
	#end
	i = 0
	while line = ff.gets
		file = line.gsub(/\s/, '')
		p file
		i += 1
		state, cardno, nColor, carColor = knum(file, i)
	end
end
=end
