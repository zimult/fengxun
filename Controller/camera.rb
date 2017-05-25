# encoding: utf-8
#require 'mysql2'
#require '../imgb'

class CameraController

	def self.findCarpos(con, build_id, mac, index)
		rs = con.query "SELECT carpos, x, y, win_type FROM tb_camera_config
						WHERE build_id='#{build_id}' and mac='#{mac}' and seq=#{index}"
		row = rs.first
		return row
	end

	def self.getCameraOrigin(con, build_id, mac, carpos)
		rs = con.query "SELECT origin_pic, origin_hash FROM tb_camera_config
										WHERE build_id='#{build_id}' and mac='#{mac}' and carpos='#{carpos}'"
		row = rs.first
		row
	end
	
	def self.getCameraOriginByIndex(con, build_id, mac, index)
		rs = con.query "SELECT origin_pic, origin_hash, carpos FROM tb_camera_config
										WHERE build_id='#{build_id}' and mac='#{mac}' and seq=#{index}"
		row = rs.first
		row
	end

	def self.updateCameraOrogin(con, build_id, mac, carpos, opic, ohash)
		con.query "UPDATE tb_camera_config set origin_pic='#{opic}', origin_hash='#{ohash}'
					WHERE build_id='#{build_id}' and mac='#{mac}' and carpos='#{carpos}'"
		con.query "commit"
	end

	def self.updateCameraOroginByIndex(con, build_id, mac, index, opic, ohash)
		$log.info "#{ohash}, --#{ohash.length}"
		con.query "UPDATE tb_camera_config set origin_pic='#{opic}', origin_hash='#{ohash}'
					WHERE build_id='#{build_id}' and mac='#{mac}' and seq=#{index}"
		con.query "commit"
	end

	def self.setCameraConfig(con, build_id, mac, win_type, window)
                  i=1
                #$log1.info win_type
                if  win_type=='7'
                  num=4
                elsif win_type=='3'
   		  num=3
                  con.query "DELETE FROM tb_camera_config WHERE build_id='#{build_id}' and mac='#{mac}' and seq='3'"
                elsif win_type=='1'
                  num=2
		con.query "DELETE FROM tb_camera_config WHERE build_id='#{build_id}' and mac='#{mac}' and seq<>'1'"
                else
                  num=0
                end
		#for i in 1..3 do
                #con.query "DELETE FROM tb_camera_config WHERE build_id='#{build_id}' and mac='#{mac}'"	
		con.query "DELETE FROM tb_build_carpos_info WHERE build_id='#{build_id}' and mac='#{mac}' and carpos<>'debug'"
                while i<num do
			if window == nil
				x = nil
				y = nil
				carpos = nil			
				opic = nil
			else
				x = window[i-1][:x].to_s
				y = window[i-1][:y].to_s
				carpos = window[i-1][:carpos]
				opic = nil
				#opic = window[i-1][:opic].to_s if window[i-1][:opic]
			end
	
			rs = con.query "SELECT win_type FROM tb_camera_config 
							WHERE build_id='#{build_id}' and mac='#{mac}' and seq=#{i}"
			row = rs.first
			if row
				updateCameraConfig(con, build_id, mac, i, carpos, x, y, win_type, opic)
			else
				insertCameraConfig(con, build_id, mac, i, carpos, x, y, win_type, opic)
			end
                 i +=1
		end
	end
	
	def self.insertCameraConfig(con, build_id, mac, seq, carpos, x, y, win_type, opic)
		if carpos == nil
			if seq == 1
				x = '0'
				y = '480'
				carpos = 'A101'
			elsif seq == 2
				x = '800'
				y = '480'
				carpos = 'A102'
			elsif seq == 3
				x = '1600'
				y = '480'
				carpos = 'A103'
			else
				x = '10'
				y = '20'
				carpos = 'A000'
			end
		end	

		origin_pic = 'NULL'
		origin_pic = opic if opic
		origin_hash = 'NULL'
		if opic != nil
			origin_hash = ImgBB::calculate_threshold(opic, 16)
		end
	
		sql = "INSERT INTO tb_camera_config (build_id, mac, seq, carpos, x, y, win_type)
			VALUES ('#{build_id}', '#{mac}', #{seq}, '#{carpos}', '#{x}', '#{y}', '#{win_type}')"
					#'#{origin_pic}', '#{origin_hash}')"
		$log.info sql
		con.query sql
		con.query "commit"
	end
	
	def self.updateCameraConfig(con, build_id, mac, seq, carpos, x, y, win_type, opic)

		origin_pic = 'NULL'
		origin_pic = opic if opic
		origin_hash = 'NULL'
		if opic
			origin_hash = ImgBB::calculate_threshold(opic, 16)
		end
		
		set = "win_type='#{win_type}'"
		set += ", carpos='#{carpos}'" if carpos
		set += ", x='#{x}'" if x
		set += ", y='#{y}'" if y
		set += ", origin_pic='#{origin_pic}', origin_hash='#{origin_hash}'" if opic != nil
		where = "build_id='#{build_id}' and mac='#{mac}' and seq=#{seq}"
		
		sql = "UPDATE tb_camera_config set #{set} WHERE #{where}"
		$log.info sql
		con.query sql
		con.query "commit"
	end
	
	def self.listCameraConfig(con, build_id, mac)
		rs = con.query "SELECT count(*) cnt FROM tb_camera_config c WHERE c.build_id='#{build_id}' and c.mac='#{mac}' ORDER BY c.seq"
		row = rs.first
		cnt = row['cnt'].to_i
		if cnt <= 0
			setCameraConfig(con, build_id, mac, '7', nil)
		end

		list = []
		rs = con.query "SELECT c.seq `index`, c.carpos, c.win_type, c.x, c.y
					FROM tb_camera_config c WHERE c.build_id='#{build_id}' and c.mac='#{mac}' ORDER BY c.seq"
		rs.each{|row|
			list << row
		}
		list
	end

        def self.getCarpos(con, build_id, mac, index)
		rs = con.query "SELECT carpos FROM tb_camera_config 
						WHERE  build_id='#{build_id}' and mac = '#{mac}' and seq='#{index}'"
		row = rs.first
		return row
	end

	def self.showCameraConfig(con, build_id, mac)
		list = []
		rs = con.query "SELECT c.seq `index`, c.carpos, c.win_type, 
						i.url imgUrl, i.ful state, i.carno carNumber, i.mac,i.dis, 
						TIMESTAMPDIFF(second, i.update_time, NOW()) tm,
						c.origin_pic
						FROM tb_camera_config c
						INNER JOIN tb_build_carpos_info i ON i.build_id=c.build_id and i.mac=c.mac and i.carpos=c.carpos
						WHERE c.build_id='#{build_id}' and c.mac='#{mac}'
						ORDER BY c.seq"
		rs.each{|row|
			list << row
		}
		list
	end

	def self.setCameraDebug(con, build_id, mac, debug)
		rs = con.query "SELECT debug FROM tb_camera_debug where build_id='#{build_id}' and mac='#{mac}'"
		row = rs.first
		if !row
			con.query "INSERT INTO tb_camera_debug (build_id, mac, debug, dbg_tm)
						VALUES ('#{build_id}', '#{mac}', #{debug}, current_timestamp)"
		else
			con.query "UPDATE tb_camera_debug SET debug=#{debug}, dbg_tm=current_timestamp 
						WHERE build_id='#{build_id}' and mac='#{mac}'"
		end
		con.query "commit"		
	end
	
	def self.refreshDebugTime(con, build_id, mac)
		rs = con.query "SELECT debug FROM tb_camera_debug where build_id='#{build_id}' and mac='#{mac}'"
		row = rs.first
		if !row
			con.query "INSERT INTO tb_camera_debug (build_id, mac, debug, dbg_tm)
						VALUES ('#{build_id}', '#{mac}', 0, current_timestamp)"
		else
			if row['debug'].to_i == 1
				con.query "UPDATE tb_camera_debug SET dbg_tm=current_timestamp WHERE build_id='#{build_id}' and mac='#{mac}'"
			end
		end
		con.query "commit"
	end
	
	def self.getCameraDebug(con, build_id, mac)
		rs = con.query "SELECT debug, TIMESTAMPDIFF(second, dbg_tm, NOW()) dt FROM tb_camera_debug 
						WHERE build_id='#{build_id}' and mac='#{mac}'"
		row = rs.first
		return row
	end

	def self.check_debug_overtime(con, build_id, mac)
		row = getCameraDebug(con, build_id, mac)
		if row
			if row['debug'].to_i == 1 && row['dt'].to_i >= 1800
				con.query "UPDATE tb_camera_debug SET debug=0, dbg_tm=current_timestamp WHERE build_id='#{build_id}' and mac='#{mac}'"
				con.query "commit"
				return 0
			else
				return row['debug'].to_i
			end
		else
			return 0
		end
	end
end
