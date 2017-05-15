#encoding=UTF-8
require 'logger'

require_relative 'mysql2_conn'
require_relative 'fx_config'
require_relative 'Controller/car'

$log = Logger.new("./log/tj_car.log", 'daily')
$log.level = Logger::INFO
$log.info("---- tj_car begin. ----")

def make_data(con, build_id, floor_num, ran, major)
	che = 0
	che = 1 if floor_num == nil && ran == nil
	fn = floor_num
	fn = 'NULL' if floor_num == nil
	mj = major
	mj = 'NULL' if ran == nil

	fil = CarController::totCarFul(con, build_id, che, floor_num, ran)
	err = CarController::totCarErr(con, build_id, che, floor_num, ran)

	rs = con.query "SELECT count(*) cnt FROM tb_car_log
					where build_id='#{build_id}' and floor_num=#{fn} and major=#{mj} 
					and create_time=CONCAT(DATE_FORMAT(now(), '%Y%m%d%H'), '0000')"
	row = rs.first
	cnt = row['cnt'].to_i
	if cnt <= 0
		con.query "INSERT INTO tb_car_log (build_id, floor_num, major, create_time, fil, err)
					VALUES ('#{build_id}', #{fn}, #{mj}, CONCAT(DATE_FORMAT(now(), '%Y%m%d%H'), '0000'), #{fil}, #{err})"
		con.query "commit"
	end
end

con = MysqlConn2::get_conn
build_id = $building_id

begin

	# 删除 7 天前的数据
	con.query "DELETE FROM tb_car_log where create_time < date_sub(now(), interval 7 day)"
	
	# 计算当前数据
	# major
	rs = con.query "SELECT major, area_name FROM tb_build_area WHERE build_id='#{build_id}' order by major"
	rs.each{|row|
		ran = row['area_name'].force_encoding('utf-8')
		major = row['major'].to_i

		make_data(con, build_id, nil, ran, major)
	}

	# floor
	rs = con.query "SELECT floor_num FROM tb_build_floor WHERE build_id='#{build_id}' order by floor_num desc"
	rs.each{|row|
		floor_num = row['floor_num'].to_i

		make_data(con, build_id, floor_num, nil, nil)
	}

	# all
	make_data(con, build_id, nil, nil, nil)

rescue Exception => e
	$log.error e.message
	$log.error e.backtrace.inspect
	con.query "rollback"
end

$log.info("---- tj_car end. ----")
con.close
