# encoding: utf-8
#require 'mysql2'

class AreaController
	def self.listArea(con, build_id)
		list = []
		rs = con.query "SELECT floor_id, floor_num, major area_id, area_name FROM tb_build_area where build_id = '#{build_id}'"
		rs.each{|row|
			list << row	
		}
		list
	end

	def self.AddBuildArea(con, build_id, floor_id, floor_num, area_id, area_name)
		con.query "INSERT INTO tb_build_area (build_id, floor_id, floor_num, major, area_name)
				VALUES ('#{build_id}', '#{floor_id}', #{floor_num}, #{area_id}, '#{area_name}')"
		con.query "commit"
	end

	def self.getAreaList(con, build_id)
		list = []
		rs = con.query "SELECT area_name FROM tb_build_area WHERE build_id='#{build_id}' order by major"
		rs.each{|row|
			list << row['area_name'].force_encoding('utf-8')
		}

		list
	end

	def self.getMajorByName(con, build_id, area_name)
		rs = con.query "SELECT major FROM tb_build_area where build_id='#{build_id}' AND area_name='#{area_name}'"
		row = rs.first
		if row
			return row['major'].to_i
		else
			return nil
		end
	end

	def self.getFloorByMajor(con, build_id, major)

		rs = con.query "SELECT floor_id, floor_num FROM tb_build_area
						WHERE build_id='#{build_id}' and major=#{major}"
		row = rs.first
		return row
	end
end
