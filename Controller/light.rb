# encoding: utf-8
#require 'mysql2'

class LightController
	def self.AddBuildLight(con, build_id, info)
                $log1.info info
		major = info[:area_id].to_i
		minor = info[:device_id].to_i
		floor_num = info[:floor_num].to_i
		mac = ''
		
		sql ="INSERT INTO tb_build_light_info (build_id, major, minor, mac, update_time)
			VALUES ('#{build_id}', #{major}, #{minor}, '#{mac}', current_timestamp)"
		#$log.info sql
		con.query sql

		rs = con.query "SELECT count(*) cnt FROM tb_build_light_setting 
				where build_id='#{build_id}' and major='#{major}'"
		row = rs.first
		cnt = row['cnt'].to_i
		if cnt == 0
			sql = "INSERT INTO tb_build_light_setting (build_id, floor_num, major, 
				lmd, lva, eng, ntm, mnl, mxl, mnl2, mxl2, update_time)
				values ('#{build_id}', '#{floor_num}', '#{major}', 
				#{$lmd}, #{$lva}, #{$eng}, '#{$ntm}', #{$mnl}, #{$mxl}, #{$mnl2}, #{$mxl2}, current_timestamp)"
			con.query sql
		end

		con.query "commit"
	end

	def self.FindMacByID(con, build_id,device_area,device_id)
		err = "and (timestampdiff(second, update_time, now()) < 60 )"
		rs = con.query "SELECT mac FROM tb_build_light_info WHERE build_id='#{build_id}' and major=#{device_area} and minor=#{device_id} #{err}"
		row = rs.first
		if row
			return row['mac'].force_encoding('utf-8')
		else
			return nil
		end
	end

	def self.saveLightInfo(con, lightinfo)
		build_id = lightinfo[:build_id]
		major = lightinfo[:major].to_i
		minor = lightinfo[:minor].to_i
		mac = lightinfo[:mac]
		tmp = lightinfo[:tmp].to_i
		lst = lightinfo[:lst].to_i
		errcode = lightinfo[:errcode].to_i

		#floor_num = getFloorNumByMajor(build_id, major)

		rs = con.query "SELECT tmp, lst, timestampdiff(second, update_time, now()) tm  
					FROM tb_build_light_info 
					where build_id='#{build_id}' and major=#{major} and minor=#{minor}"
		row = rs.first
		raise XError.new(506, 'no light found') if row == nil

		if row['tmp'].to_i != tmp || row['lst'].to_i != lst || row['tm'].to_i > 5

			sql = "UPDATE tb_build_light_info SET mac='#{mac}', tmp=#{tmp}, lst=#{lst}, errcode=#{errcode}, update_time=current_timestamp
				WHERE build_id='#{build_id}' and major=#{major} and minor=#{minor}"

			con.query sql
			con.query "commit"
		end
	end

	def self.getSetting(con, build_id, major)
		rs = con.query "SELECT lmd, lva, eng, ntm, mnl, mxl, mnl2, mxl2 FROM tb_build_light_setting
				WHERE build_id='#{build_id}' and major=#{major}"
		row = rs.first
		ret = nil
		if row
			ret = row
		end
		ret	
	end

	def self.getFloorNumByMajor(con, build_id, major)
		#rs = con.query "SELECT floor_num FROM tb_build_area where build_id='#{build_id}' AND major=#{major}"
	end

	def self.listLight(con, build_id)
		list = []
		rs = con.query "SELECT l.major area_id, a.area_name, l.minor device_id, l.floor_num FROM tb_build_light_info l
						INNER JOIN tb_build_area a ON a.build_id=l.build_id and a.major=l.major and a.floor_num=l.floor_num
						WHERE l.build_id='#{build_id}'"
		rs.each{|row|
			list << row
		}
		list
	end
        
	def self.getall(con, build_id, che, floor, ran)
		if che != nil
			sql = "SELECT count(*) cnt FROM tb_build_light_info where build_id='#{build_id}'"
		elsif floor != nil
			sql = "SELECT count(i.tmp) cnt FROM tb_build_light_info i
				INNER JOIN tb_build_area a ON i.build_id=a.build_id and i.major=a.major
				WHERE i.build_id='#{build_id}' AND a.floor_num=#{floor.to_i}"
		elsif ran != nil
			sql = "SELECT count(i.tmp) cnt FROM tb_build_light_info i
				INNER JOIN tb_build_area a ON i.build_id=a.build_id and i.major=a.major
				WHERE i.build_id='#{build_id}' AND a.area_name='#{ran}'"
		else
			raise XError.new(505, 'Wrong che floor ran')
		end
		
		#$log1.info sql
		rs = con.query sql
		row = rs.first
		cnt =  row['cnt'].to_i
		cnt
	end

	def self.getbad(con, build_id, che, floor, ran)
		err = "and (i.errcode <> 0 or timestampdiff(second, i.update_time, now()) > 60 )"
		if che != nil
			sql = "SELECT count(*) cnt FROM tb_build_light_info i where i.build_id='#{build_id}' #{err}"
		elsif floor != nil
			sql = "SELECT count(i.tmp) cnt FROM tb_build_light_info i
				INNER JOIN tb_build_area a ON i.build_id=a.build_id and i.major=a.major
				WHERE i.build_id='#{build_id}' AND a.floor_num=#{floor.to_i} #{err}"
		elsif ran != nil
			sql = "SELECT count(i.tmp) cnt FROM tb_build_light_info i
				INNER JOIN tb_build_area a ON i.build_id=a.build_id and i.major=a.major
				WHERE i.build_id='#{build_id}' AND a.area_name='#{ran}' #{err}"
		else
			raise XError.new(505, 'Wrong che floor ran')
		end
		
		#$log.info sql
		rs = con.query sql
		row = rs.first
		cnt =  row['cnt'].to_i
		cnt
	end
        def self.getactive(con, build_id, che, floor, ran)
                 list=[]
		if che != nil
			sql = "SELECT major rannum,minor fmn,timestampdiff(second, update_time, now()) err FROM tb_build_light_info where build_id='#{build_id}'"
		#elsif floor != nil
		#	sql = "SELECT count(i.tmp) cnt FROM tb_build_light_info i
		#		INNER JOIN tb_build_area a ON i.build_id=a.build_id and i.major=a.major
		#		WHERE i.build_id='#{build_id}' AND a.floor_num=#{floor.to_i}"
		elsif floor != nil
			sql = "SELECT minor fmn,timestampdiff(second, update_time, now()) err FROM tb_build_light_info i
				INNER JOIN tb_build_area a ON i.build_id=a.build_id and i.major=a.major 
				where i.build_id='#{build_id}' and a.floor_id = '#{floor}'"
		elsif ran != nil
			sql = "SELECT count(i.tmp) cnt FROM tb_build_light_info i
				INNER JOIN tb_build_area a ON i.build_id=a.build_id and i.major=a.major
				WHERE i.build_id='#{build_id}' AND a.area_name='#{ran}'"
		else
			raise XError.new(505, 'Wrong che floor ran')
		end
		
		#$log1.info sql
		rs = con.query sql
                rs.each{|row|
			list << row
		}
		list
		
	end
	def self.sumwat(con, build_id, che, floor, ran)
		gs = "sum(case when i.lst=0 THEN 0.8 
                                        when i.lst=1 THEN 3.8
                                        when i.lst=2 THEN 6.5
                                        when i.lst=3 THEN 9.2
                                        when i.lst=4 THEN 12.1
                                        when i.lst=5 THEN 14.9
                                        when i.lst=6 THEN 17.7
                                        when i.lst=7 THEN 20.5
                                        ELSE 0 END
                                 ) wat"

		if che != nil
			sql = "SELECT #{gs}
				FROM tb_build_light_info i where i.build_id='#{build_id}' and timestampdiff(second, i.update_time, now()) < 60"
		elsif floor != nil
			sql = "SELECT #{gs}
				FROM tb_build_light_info i
				INNER JOIN tb_build_area a ON i.build_id=a.build_id and i.major=a.major
				WHERE i.build_id='#{build_id}' AND a.floor_num=#{floor.to_i} and timestampdiff(second, i.update_time, now()) < 60"
		elsif ran != nil
			sql = "SELECT #{gs}
				FROM tb_build_light_info i
				INNER JOIN tb_build_area a ON i.build_id=a.build_id and i.major=a.major
				WHERE i.build_id='#{build_id}' AND a.area_name='#{ran}' and timestampdiff(second, i.update_time, now()) < 60"
		else
			raise XError.new(505, 'Wrong che floor ran')
		end
		
		#$log.info sql
		rs = con.query sql
		row = rs.first
		wat =  row['wat'].to_i
		wat
	end

	def self.getavg(con, build_id, che, floor, ran)
		sl = "sum(i.tmp) st, sum(i.lst) sl, count(i.errcode) tot"
		if che != nil
			sql = "SELECT #{sl} FROM tb_build_light_info i where i.build_id='#{build_id}' and timestampdiff(second, i.update_time, now()) < 60"
		elsif floor != nil
			sql = "SELECT #{sl} FROM tb_build_light_info i
				INNER JOIN tb_build_area a ON i.build_id=a.build_id and i.major=a.major
				WHERE i.build_id='#{build_id}' AND a.floor_num=#{floor.to_i} and timestampdiff(second, i.update_time, now()) < 60"
		elsif ran != nil
			sql = "SELECT #{sl} FROM tb_build_light_info i
				INNER JOIN tb_build_area a ON i.build_id=a.build_id and i.major=a.major
				WHERE i.build_id='#{build_id}' AND a.area_name='#{ran}' and timestampdiff(second, i.update_time, now()) < 60"
		else
			raise XError.new(505, 'Wrong che floor ran')
		end
		
		#$log.info sql
		rs = con.query sql
		row = rs.first
		st = row['st'].to_i
		sl = row['sl'].to_i
                sl = sl*100
		tot = row['tot'].to_i
		return st / tot, sl / tot
	end

	def self.listLight(con, build_id, che, floor, ran, pag)
		pagesize = 20
		start = (pag - 1) * pagesize
		lmt = " order by i.minor limit #{start}, #{pagesize}"

		#$log.info che

		if che != nil
			sql = "SELECT i.minor fmn, i.mac, i.tmp ftp, i.lst, i.errcode err, a.major lran, 
					timestampdiff(second, i.update_time, now()) ert, s.lmd
					FROM tb_build_light_info i 
					INNER JOIN tb_build_area a ON i.build_id=a.build_id and i.major=a.major
					INNER JOIN tb_build_light_setting s ON s.build_id=i.build_id and s.major=i.major
					where i.build_id='#{build_id}' #{lmt}"
		elsif floor != nil
			sql = "SELECT i.minor fmn, i.mac, i.tmp ftp, i.lst, i.errcode err, a.major lran, 
					timestampdiff(second, i.update_time, now()) ert, s.lmd
					FROM tb_build_light_info i 
					INNER JOIN tb_build_area a ON i.build_id=a.build_id and i.major=a.major
					INNER JOIN tb_build_light_setting s ON s.build_id=i.build_id and s.major=i.major
					where i.build_id='#{build_id}' and a.floor_num=#{floor.to_i} #{lmt}"
		elsif ran != nil
			sql = "SELECT i.minor fmn, i.mac, i.tmp ftp, i.lst, i.errcode err, a.major lran, 
					timestampdiff(second, i.update_time, now()) ert, s.lmd
					FROM tb_build_light_info i 
					INNER JOIN tb_build_area a ON i.build_id=a.build_id and i.major=a.major
					INNER JOIN tb_build_light_setting s ON s.build_id=i.build_id and s.major=i.major
					where i.build_id='#{build_id}' AND a.area_name='#{ran}' #{lmt}"
		else
			raise XError.new(505, 'Wrong che floor ran')
		end
		
		#$log.info sql
		rs = con.query sql
		list = []
		rs.each{|row|
			list << row
		}
		list
	end

	def self.listLightError(con, build_id, che, floor, ran, pag)
		pagesize = 20
		start = (pag - 1) * pagesize
		lmt = " order by i.minor limit #{start}, #{pagesize}"

		errif = " and (i.errcode<>0 or timestampdiff(second, i.update_time, now()) > 60)"

		#$log.info che

		if che != nil
			sql = "SELECT i.minor fmn, i.mac, i.tmp ftp, i.lst, i.errcode err, a.major lran, 
					timestampdiff(second, i.update_time, now()) ert, s.lmd
					FROM tb_build_light_info i 
					INNER JOIN tb_build_area a ON i.build_id=a.build_id and i.major=a.major
					INNER JOIN tb_build_light_setting s ON s.build_id=i.build_id and s.major=i.major
					where i.build_id='#{build_id}' #{errif} #{lmt}"
		elsif floor != nil
			sql = "SELECT i.minor fmn, i.mac, i.tmp ftp, i.lst, i.errcode err, a.major lran, 
					timestampdiff(second, i.update_time, now()) ert, s.lmd
					FROM tb_build_light_info i 
					INNER JOIN tb_build_area a ON i.build_id=a.build_id and i.major=a.major
					INNER JOIN tb_build_light_setting s ON s.build_id=i.build_id and s.major=i.major
					where i.build_id='#{build_id}' and a.floor_num=#{floor.to_i} #{errif} #{lmt}"
		elsif ran != nil
			sql = "SELECT i.minor fmn, i.mac, i.tmp ftp, i.lst, i.errcode err, a.major lran, 
					timestampdiff(second, i.update_time, now()) ert, s.lmd
					FROM tb_build_light_info i 
					INNER JOIN tb_build_area a ON i.build_id=a.build_id and i.major=a.major
					INNER JOIN tb_build_light_setting s ON s.build_id=i.build_id and s.major=i.major
					where i.build_id='#{build_id}' AND a.area_name='#{ran}' #{errif} #{lmt}"
		else
			raise XError.new(505, 'Wrong che floor ran')
		end
		
		#$log.info sql
		rs = con.query sql
		list = []
		rs.each{|row|
			list << row
		}
		list
	end

	def self.getLightLog(con, build_id, che, floor, ran, major)
		ret = {}
		wat = []
		alm = []
		atp = []

		where = ''
		if che == 1
			where += "build_id='#{build_id}'and major is null and floor_num is null"
		elsif floor != nil
			where += "build_id='#{build_id}' and floor_num=#{floor.to_i} and major is null"
		elsif ran != nil
			where += "build_id='#{build_id}' and floor_num is null and major=#{major}"
		else
			raise XError.new(505, 'Wrong che floor ran')
		end
		
		sql = "SELECT date_format(create_time, '%H') time, wat, temp, alm FROM tb_light_log
				WHERE #{where}
				ORDER BY create_time desc limit 24"	
		$log1.info sql
		rs = con.query sql
		rs.each{|row|
			time = row['time'].to_s
			twat = row['wat'].to_i
			ttemp = row['temp'].to_i
			talm = row['alm'].to_i

			wat << {"time"=>time, "value"=>twat}
			atp << {"time"=>time, "value"=>ttemp}
			alm << {"time"=>time, "value"=>talm}
		}
		ret[:wat] = wat
		ret[:atp] = atp
		ret[:alm] = alm
		ret
	end
end
