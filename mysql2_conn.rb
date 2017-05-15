#
require 'mysql2'

$mmDBHost = '127.0.0.1'
$mmDBUser = 'root'
$mmDBPasswd = 'star'
$mmDBDatabase = 'beefind'

class MysqlConn2
	attr_accessor :con

	def self.get_conn()

		if @con == nil
			@con = Mysql2::Client.new(:host => $mmDBHost , :username => $mmDBUser, :password => $mmDBPasswd, :port => 33006,
				:database => $mmDBDatabase, :flags => Mysql2::Client::MULTI_STATEMENTS, :reconnect => true)

		end
		
		@con
	end

	def initialize()
		@con = nil
	end

	def close()
		@con.close
	end
end

