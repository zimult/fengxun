require_relative 'floor'
require_relative 'area'

class BuildController
	def self.listBuild(con, build_id)
		list = []
		str = ""
		if build_id != nil
			str = "WHERE build_id = '#{build_id}'"	
		end

		sql = "SELECT build_id, build_name, build_type FROM tb_build #{str}"
		rs = con.query sql

		rs.each{|row|
			tmp = {}
			tmp[:build_id] = row['build_id']
			tmp[:build_name] = row['build_name'].force_encoding('utf-8')
			tmp[:build_type] = row['build_type']

			list << tmp
		}
		list
	end

	def self.getBuildName(con, build_id)
		rs = con.query "SELECT build_name FROM tb_build where build_id = '#{build_id}'"
		row = rs.first

		if !row
			return nil 
		else
			return row['build_name'].force_encoding('utf-8')
		end
	end

	
	def self.AddBuild(con, build_id, build_name, build_type)

		rs = con.query "SELECT build_name FROM tb_build WHERE build_id = '#{build_id}'"
		row = rs.first
		if row
			return 2
		end

		con.query "INSERT INTO tb_build (build_id, build_name, build_type) values ('#{build_id}', '#{build_name}', #{build_type})"
		con.query "commit"

		return 1
	end

	def self.AddFloorArea(con, build_id, floor_list, area_list)

		floor_list.each{|floor|
			floor_id = floor[:floor_id]
			floor_num = floor[:floor_num].to_i
			floor_name = floor[:floor_name]
			FloorController::AddBuildFloor(con, build_id, floor_id, floor_num,floor_name)
		}

		area_list.each{|area|
			floor_num = area[:floor_num].to_i
			area_id = area[:area_id].to_i
			area_name = area[:area_name].force_encoding('utf-8')

			floor_id = FloorController::FindIDByNum(con, build_id, floor_num)
			if floor_id != nil
				AreaController::AddBuildArea(con, build_id, floor_id, floor_num, area_id, area_name)
			else
				err = "AddFloorArea floor_id not found, floor_num:#{floor_num}"
				raise XError.new(410, err)
			end
		}

		return 1
	end

end
