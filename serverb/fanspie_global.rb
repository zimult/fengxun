# encoding: utf-8
require_relative 'fanspie_const'
require_relative 'fanspie_connection_pool'
require_relative 'fanspie_exception'
require_relative 'fanspie_errmsg'
require 'mysql'
require 'cgi'
require 'base64'
	
module FansPie

	@@the_connectionpool = nil

	@@is_testing = false

	@@filtered_word_list = nil
	
	@@administrator_user_list = nil
	@@assistant_user_list = nil

	def self.connect
		if !@@the_connectionpool
	 		@@the_connectionpool = ConnectionPool.new
	end

	@@the_connectionpool.alloc
	end
	
	def self.disconn
	if @@the_connectionpool.release == true
		@@the_connectionpool = nil
	end
	end
	
	def self.filter_word(sentence)
	# disabled temporarily
=begin
	@@filtered_word_list = File.binread('filtered_word.txt').force_encoding('utf-8').split(',').map(&:strip) if !@@filtered_word_list

	@@filtered_word_list.each {|word|
		sentence.gsub!(word, "*"*word.length)
	}
=end
	sentence
	end

	def self.check_assistant(user_id)
		if !@@assistant_user_list
			@@assistant_user_list = File.binread('assistant_user.txt').force_encoding('utf-8').split(',').map(&:strip) 
		end

		@@assistant_user_list.each {|word|
			if( user_id.to_s.include?(word) == true )
				return true
			end
		}
		return false
	end
	def self.check_administrator(user_id)
		if !@@administrator_user_list
			@@administrator_user_list = File.binread('administrator_user.txt').force_encoding('utf-8').split(',').map(&:strip) 
		end

		@@administrator_user_list.each {|word|
			if( user_id.to_s.include?(word) == true )
				return true
			end
		}
		return false
	end
	
	def self.check_word(sentence)
		if !@@filtered_word_list
			@@filtered_word_list = File.binread('filtered_word.txt').force_encoding('utf-8').split(',').map(&:strip) 
		end

		@@filtered_word_list.each {|word|
			if( sentence.include?(word) == true )
				return false
			end
		}
		return true
	end

	def self.get_fanspie_asseturl(cnd)
	date = Time.now
	use = date.strftime("%d").to_i
	if (use%2 == 1)
		return $FansPieAssetURL1
	else
		return $FansPieAssetURL2
	end
	end

	def self.is_testuser(user_id)
		if (user_id == 44300 || 
			user_id == 3660 ||
			user_id == 3655 ||
			user_id == 3656 ||
			user_id == 3657 ||
			user_id == 2196 ||
			user_id == 2262 )
			return true
		else
			return false
		end
	end
	
	# Format error message
	def self.format_error(e)
		ret = {:errno=>0, :params=>nil, :message=>'', :trace=>''}
		if e.is_a?(FansPie::FansPieError)
			ret[:errno] 	= e.errno
			ret[:params] 	= e.parameters
			ret[:message] = e.parameters
		elsif e.is_a?(Mysql::Error)
			ret[:errno]		= FansPie::ErrMySql
			ret[:params]	= e.errno
			ret[:message] = e.error
		else
			ret[:errno]		= FansPie::ErrSystem
			ret[:message] = e.message
#			ret[:message] = ERR_SYS_EXCEPTION
		end
		ret[:trace] 	= e.backtrace.join("||")
		return ret		
	end
	
	def unicode_utf8(unicode_string) 
		unicode_string.gsub(/\\u\w{4}/) do |s|
			str = s.sub(/\\u/, "").hex.to_s(2) 
			if str.length < 8 
				CGI.unescape(str.to_i(2).to_s(16).insert(0, "%")) 
			else 
				arr = str.reverse.scan(/\w{0,6}/).reverse.select{|a| a != ""}.map{|b| b.reverse} 
				hex = lambda do |s| 
					(arr.first == s ? "1" * arr.length + "0" * (8 - arr.length - s.length) + s : "10" + s).to_i(2).to_s(16).insert(0, "%") 
				end 
				CGI.unescape(arr.map(&hex).join) 
			end 
		end 
	end 
	
	def URLDecode(str) 
		#str.gsub!(/%[a-fA-F0-9]{2}/) { |x| x = x[1..2].hex.chr } 
		CGI.unescape(str)
		#Base64.decode64(str)
	end

	def URLEncode(str) 
		#str.gsub!(/[^\w$&\-+.,\/:;=?@]/) { |x| x = format("%%%x", x[0]) } 
		CGI.escape(str)
		#str
		#Base64.encode64(str)
	end


	def gen_random_string(length)
	o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
	string = (0...length).map { o[rand(o.length)] }.join
	end

	def self.set_testing(test)
	@@is_testing = test
	end

	def self.is_testing()
	return @@is_testing
	end
end
