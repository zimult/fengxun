# encoding: utf-8
#require 'mysql2'

class XError < RuntimeError
		attr_accessor :errno
		attr_accessor :parameters

		def initialize(code, var=nil)
				@errno = code
				@parameters = var
		end

		def self.format_error(e)
			#$log.info ("------ format_error.")
			ret = {:errno=>0, :params=>nil, :message=>'', :trace=>''}
			if e.is_a?(XError)
				ret[:errno]	 = e.errno
				ret[:params]	= e.parameters
				ret[:message] = e.parameters
			#elsif e.is_a?(Mysql2::Error)
			#	ret[:errno]	 = 1001
			#	ret[:params]	= e.errno
			#	ret[:message] = "处理失败" #e.error
			else
				ret[:errno]	 = 2001
				ret[:message] = e.message
			end
		ret[:trace]	 = e.backtrace.join("||")
		return ret
	end
	
end 
