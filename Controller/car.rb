# encoding: utf-8
#require 'mysql2'

class CarController
	def self.AddCarInfo(con, build_id, row)
		major = row[:area_id].to_i
		carpos = row[:carpos]
		mac = ''

		# check if major exists

		con.query "INSERT INTO tb_build_carpos_info (build_id, major, mac, carpos, update_time)
				VALUES ('#{build_id}', #{major}, '#{mac}', '#{carpos}', current_timestamp)"
		con.query "commit"
	end

	def self.listCar(con, build_id)
		rs = con.query "SELECT  a.major, a.area_name, a.floor_num, c.carpos FROM tb_build_carpos_info c
				INNER JOIN tb_build_area a ON a.build_id=c.build_id and a.major=c.major
				WHERE c.build_id='#{build_id}' and c.carpos <> 'debug'"
		list = []
		rs.each{|row|
			list << row
		}
		list
	end

	def self.updateCarposPic(con, build_id, mac, carpos, major, floor_num, url)
                 rs= con.query "SELECT ful, carno, carno_his, url FROM tb_build_carpos_info
						WHERE build_id='#{build_id}' and mac = '#{mac}' and carpos='#{carpos}'"
                 row = rs.first
		if !row 
		#$log1.info "no find the mac+++++++++++++++++++++++++++"
                sql = "INSERT INTO tb_build_carpos_info
						(build_id, major, mac, carpos, update_time, carno, ful, url, carno_his,newpic)
						VALUES ('#{build_id}', #{major}, '#{mac}', '#{carpos}', current_timestamp,
						'N', '0', '#{url}', '','0')"
			con.query sql
			con.query "commit"
                else
		con.query "update tb_build_carpos_info set url='#{url}', newpic=newpic+1, update_time=current_timestamp WHERE build_id='#{build_id}' and mac = '#{mac}' and carpos='#{carpos}'"	
		con.query "commit"
		end
	end
         
	def self.updateDis(con, build_id, mac, carpos, major, dis)
	    rs = con.query "SELECT  url FROM tb_build_carpos_info
						WHERE build_id='#{build_id}' and mac = '#{mac}' and carpos = '#{carpos}'"
	    row = rs.first
	    if row
	   
		sql = "UPDATE tb_build_carpos_info SET dis='#{dis}'
						WHERE  build_id='#{build_id}' and mac='#{mac}' and carpos='#{carpos}'"
			
			con.query sql
			con.query "commit"
	    end
	end
	
	def self.updateCarposInfo(con, build_id, mac, carpos, major, floor_num, carno, url, ful,dis,opr)
		rs = con.query "SELECT ful, carno, carno_his, url FROM tb_build_carpos_info
						WHERE build_id='#{build_id}' and mac = '#{mac}' and carpos = '#{carpos}'"
              #
		row = rs.first
		if !row 
			his_list = []
			his_list << carno
			hs = his_list.join(',')
			#ful = 0
			#ful = 1 if carno && carno.length > 1
			sql = "INSERT INTO tb_build_carpos_info
						(build_id, major, mac, carpos, update_time, carno, ful, url, carno_his,dis,opr)
						VALUES ('#{build_id}', #{major}, '#{mac}', '#{carpos}', current_timestamp,
						'#{carno}', #{ful}, '#{url}', '#{hs}','#{dis}','#{opr}')"
			con.query sql
			con.query "commit"
			return nil, 1
		else 
			carno_his = row['carno_his']
			carno_store = row['carno'].force_encoding('utf-8')

			his_list = carno_his.split(',')
			his_hs = Hash.new

			#$log.info "------ #{mac} updateCarposInfo: his_list:#{his_list}, leng:#{his_list.length}"
			his_list.delete_at(0) if his_list.size >= 5
			his_list << carno

			his_list.each{|h|
				if his_hs[h]
					his_hs[h] += 1
				else
					his_hs[h] = 1
				end
			}
			fact_carno = ' '
			max = 0
			his_hs.each{|k,v|
				if v > max
					fact_carno = k
					max = v
				end
			}
			#ful = 0
			ch = his_list.join(',')
			#$log1.info "------ #{mac} updateCarposInfo: his:#{carno_his}, carno:#{carno}, fact:#{fact_carno}, car_store:#{carno_store}"

			sql = "UPDATE tb_build_carpos_info SET mac='#{mac}',
						carno='#{fact_carno}', ful=#{ful}, url='#{url}', carno_his='#{ch}',
						update_time=current_timestamp,dis='#{dis}',opr='#{opr}'
						WHERE  build_id='#{build_id}' and mac='#{mac}' and carpos='#{carpos}'"
			#$log.info sql if major == 3 && carpos == '03'
			con.query sql
			con.query "commit"
			#chg = 0
			
			#chg = 1 if carno_store != fact_carno #&& fact_carno.length > 1
			
			return fact_carno   #, chg
		end
	end
	
	def self.getCarposInfo(con, build_id, mac, carpos)
		rs = con.query "SELECT carpos, carno, ful, url, TIMESTAMPDIFF(second, update_time, NOW()) dt
						FROM tb_build_carpos_info 
						WHERE  build_id='#{build_id}' and mac = '#{mac}' and carpos='#{carpos}'"
		row = rs.first
		return row
	end
	
	
	
	def self.totCar(con, build_id, che, floor, ran)
		if che != nil
			sql = "SELECT count(i.carpos) cnt FROM tb_build_carpos_info i where i.build_id='#{build_id}'and i.carpos<>'debug'"
		elsif floor != nil
			sql = "SELECT count(i.carpos) cnt FROM tb_build_carpos_info i
				INNER JOIN tb_build_area a ON i.build_id=a.build_id and i.major=a.major
				WHERE i.build_id='#{build_id}' AND a.floor_num=#{floor.to_i} and i.carpos<>'debug'"
		elsif ran != nil
			sql = "SELECT count(i.carpos) cnt FROM tb_build_carpos_info i
				INNER JOIN tb_build_area a ON i.build_id=a.build_id and i.major=a.major
				WHERE i.build_id='#{build_id}' AND a.area_name='#{ran}' and i.carpos<>'debug'"
		else
			raise XError.new(505, 'Wrong che floor ran')
		end

		rs = con.query sql
		row = rs.first
		return row['cnt'].to_i
	end

	def self.totCarFul(con, build_id, che, floor, ran)
		condition = ' and i.ful = 1 and timestampdiff(second, i.update_time, now()) <= 60'
		if che != nil
			sql = "SELECT count(i.carpos) cnt FROM tb_build_carpos_info i where i.build_id='#{build_id}' and i.carpos<>'debug' #{condition}"
		elsif floor != nil
			sql = "SELECT count(i.carpos) cnt FROM tb_build_carpos_info i
				INNER JOIN tb_build_area a ON i.build_id=a.build_id and i.major=a.major
				WHERE i.build_id='#{build_id}' AND a.floor_num=#{floor.to_i} and i.carpos<>'debug' #{condition}"
		elsif ran != nil
			sql = "SELECT count(i.carpos) cnt FROM tb_build_carpos_info i
				INNER JOIN tb_build_area a ON i.build_id=a.build_id and i.major=a.major
				WHERE i.build_id='#{build_id}' AND a.area_name='#{ran}' and i.carpos<>'debug' #{condition}"
		else
			raise XError.new(505, 'Wrong che floor ran')
		end

		rs = con.query sql
		row = rs.first
		return row['cnt'].to_i
	end

	def self.totCarErr(con, build_id, che, floor, ran)
		condition = ' and timestampdiff(second, i.update_time, now()) > 60'
		if che != nil
			sql = "SELECT count(i.carpos) cnt FROM tb_build_carpos_info i where i.build_id='#{build_id}' and i.carpos<>'debug' #{condition}"
		elsif floor != nil
			sql = "SELECT count(i.carpos) cnt FROM tb_build_carpos_info i
				INNER JOIN tb_build_area a ON i.build_id=a.build_id and i.major=a.major
				WHERE i.build_id='#{build_id}' AND a.floor_num=#{floor.to_i} and i.carpos<>'debug' #{condition}"
		elsif ran != nil
			sql = "SELECT count(i.carpos) cnt FROM tb_build_carpos_info i
				INNER JOIN tb_build_area a ON i.build_id=a.build_id and i.major=a.major
				WHERE i.build_id='#{build_id}' AND a.area_name='#{ran}'and i.carpos<>'debug' #{condition}"
		else
			raise XError.new(505, 'Wrong che floor ran')
		end

		rs = con.query sql
		row = rs.first
		return row['cnt'].to_i
	end

	def self.get_detailInfo(con, build_id, che, floor, ran)
		ret = {}
		
		ret[:car] = totCar(con, build_id, che, floor, ran)
 		ret[:fil] = totCarFul(con, build_id, che, floor, ran)
		ret[:car_err] = totCarErr(con, build_id, che, floor, ran)
		
		ret[:emp] = ret[:car] - ret[:fil] - ret[:car_err]
               
		chart = get_car_log(con, build_id, che, floor, ran)
               
		
		ret[:car_chart] = chart[:fil]
			
		ret
	end

	def self.get_car_log(con, build_id, che, floor, ran)
		ret = {}
		fil = []
		err = []

		where = ''
		if che == 1
			where += "build_id='#{build_id}'and major is null and floor_num is null"
 			#$log1.info "#{where}"
		elsif floor != nil
			where += "build_id='#{build_id}' and floor_num=#{floor.to_i} and major is null"
		elsif ran != nil
			where += "build_id='#{build_id}' and floor_num is null and major=#{major}"
		else
			raise XError.new(505, 'Wrong che floor ran')
		end
		
		sql = "SELECT date_format(create_time, '%H') time, fil, err FROM tb_car_log
				WHERE #{where} 
				ORDER BY create_time desc limit 24"
	
		#$log1.info sql
		rs = con.query sql
		#$log1.info rs
		rs.each{|row|
			time = row['time'].to_s
			tfil = row['fil'].to_i
			terr = row['err'].to_i

			fil << {"time"=>time, "value"=>tfil}
			err << {"time"=>time, "value"=>terr}
		}
		ret[:fil] = fil
		ret[:err] = err

		ret
	end

	def self.getCarList(con, build_id, che, floor, ran, pag)
		pagesize = 20
		start = (pag - 1) * pagesize

		lmt = " order by i.carpos, i.carpos limit #{start}, #{pagesize}"
		slt = 'i.carpos, a.area_name lran, b.floor_name car_floor, i.ful, timestampdiff(second, i.update_time, now()) tm, i.carno carnum, i.url imgUrl'
		condition = ' and timestampdiff(second, i.update_time, now()) > 60'

		if che != nil
			sql = "SELECT #{slt}
				FROM tb_build_carpos_info i 
					INNER JOIN tb_build_area a INNER JOIN tb_build_floor b ON i.build_id=a.build_id and i.major=a.major
					and a.floor_num=b.floor_num
					where i.build_id='#{build_id}' and i.carpos<>'debug' #{lmt} "
		elsif floor != nil
			sql = "SELECT #{slt}
				FROM tb_build_carpos_info i 
					INNER JOIN tb_build_area a INNER JOIN tb_build_floor b ON i.build_id=a.build_id and i.major=a.major
					and a.floor_num=b.floor_num
					where i.build_id='#{build_id}' and a.floor_num=#{floor.to_i} and i.carpos<>'debug' #{lmt} "
		elsif ran != nil
			sql = "SELECT #{slt}
				FROM tb_build_carpos_info i 
					INNER JOIN tb_build_area a INNER JOIN tb_build_floor b ON i.build_id=a.build_id and i.major=a.major
					and a.floor_num=b.floor_num
					where i.build_id='#{build_id}' and a.area_name='#{ran}' and i.carpos<>'debug' #{lmt} "
		else
			raise XError.new(505, 'Wrong che floor ran')
		end

		list = []
		#$log.info sql
		rs = con.query sql
		rs.each{|row|
			list << row
		}
		list
	end

	def self.searchCarpos(con, build_id, search)
		cp = con.escape search
		sql = "SELECT i.carpos, a.area_name lran, b.floor_name car_floor, i.ful, 
			timestampdiff(second, i.update_time, now()) tm, i.carno carnum, i.url imgUrl
			FROM tb_build_carpos_info i
			INNER JOIN tb_build_area a INNER JOIN tb_build_floor b ON i.build_id=a.build_id and i.major=a.major and a.floor_num=b.floor_num
			WHERE i.carno='#{cp}'"
		#$log.info sql
		rs = con.query sql
		row = rs.first
		return row
	end
end


