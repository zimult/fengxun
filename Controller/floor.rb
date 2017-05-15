# encoding: utf-8
#require 'mysql2'

class FloorController
	def self.listFloor(con, build_id)
		list = []
		rs = con.query "SELECT floor_id, floor_num FROM tb_build_floor where build_id = '#{build_id}'"
		rs.each{|row|
			list << row	
		}
		list
	end

	def self.AddBuildFloor(con, build_id, floor_id, floor_num,floor_name)
		con.query "INSERT INTO tb_build_floor (build_id, floor_id, floor_num,floor_name)
				VALUES ('#{build_id}', '#{floor_id}', #{floor_num},'#{floor_name}')
				ON DUPLICATE KEY UPDATE floor_id = '#{floor_id}'"
		con.query "commit"
	end

	def self.FindIDByNum(con, build_id, floor_num)
		rs = con.query "SELECT floor_id FROM tb_build_floor WHERE build_id='#{build_id}' and floor_num=#{floor_num}"
		row = rs.first
		if row
			return row['floor_id'].force_encoding('utf-8')
		else
			return nil
		end
	end

	def self.FindNumByID(con, build_id, floor_id)
		rs = con.query "SELECT floor_num FROM tb_build_floor WHERE build_id='#{build_id}' and floor_id='#{floor_id}'"
		row = rs.first
		if row
			return row['floor_num'].to_i
		else
			return nil
		end
	end

	def self.getFloorList(con, build_id)
		list = []
		rs = con.query "SELECT floor_num,floor_name FROM tb_build_floor WHERE build_id='#{build_id}' order by floor_num DESC"
		rs.each{|row|
			tmp = {}
			tmp[:floor_num] = row['floor_num']
			
			tmp[:floor_name] = row['floor_name']

			list << tmp
			
		}

		list
	end
end
