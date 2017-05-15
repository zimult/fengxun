# encoding: utf-8
#require 'mysql2'

class ConfigController
	def self.setConfig(con, build_id, name, value)
		con.query "INSERT INTO tb_config (`name`, `value`, `updatetime`) VALUES ('#{name}', '#{value}', current_timestamp)
				ON DUPLICATE KEY update value='#{value}', updatetime=current_timestamp"	
		con.query "commit"
	end

	def self.loadConfig(con, build_id, name)
		rs = con.query "SELECT name, value FROM tb_config where name = '#{name}'"
		row = rs.first
		
		if row
			return row['value']
		else
			return '0'
		end
	end
       
	def self.getmac(con, build_id, no)
		rs = con.query "SELECT mac FROM tb_build_mac where build_id = '#{build_id}' and no = '#{no}'"
		row = rs.first
		
		if row
			return row['mac']
		else
			return '0'
		end
	end

	def self.addmac(con, build_id, no, mac)
		con.query "INSERT INTO tb_build_mac (`build_id`, `no`, `mac`) VALUES ('#{build_id}', '#{no}','#{mac}')
				ON DUPLICATE KEY update mac='#{mac}', build_id='#{build_id}'"	
		con.query "commit"
		
	end	

	def self.listConfig(con, build_id)
		rs = con.query "SELECT name, value FROM tb_config"
		list = []
		rs.each{|row|
			list << row
		}
		list
	end
end
