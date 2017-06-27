
# -*- coding: UTF-8 -*-
require 'logger'
require 'net/https'
require 'net/http'
require "open-uri"
require 'date'
require 'fileutils'
require 'json'
require 'net/http/post/multipart'
require 'eventmachine'
require 'iconv'
require 'rmagick'

require_relative 'imgb'
require_relative 'mysql2_conn'
require_relative 'fx_config'
require_relative 'Controller/car'
require_relative 'Controller/area'
require_relative 'Controller/camera'

$rd = 1
$rd = ARGV[0].to_i if ARGV[0]
if ARGV[1]
	port = ARGV[1].to_i
else
	port = 8422
end

$log = Logger.new("./log/dpic#{$rd}.log", 'daily')
$log.level = Logger::INFO
$log.info("---- dpic #{$rd} begin. ----")

def upload_s(building_id, floor_id, major, carpos, ful, fact_carno, filename)
	begin
		url = URI.parse('http://139.196.5.153:8080/SttingParam/upload')
		req = Net::HTTP::Post::Multipart.new url.path,
			"headImage" => UploadIO.new(File.new(filename), "image/jpeg", filename),
			"buildingID" => building_id,
                        #if floor_num.to_i > 0
			#"floorID" => "LS#{floor_num}",
                        #end
			"floorID" => floor_id,
			"carArea" => major,
			"carpos" => carpos,
			"ful" => ful,
			"carNumber" => fact_carno

                    #$log.info "+++++++++++++++++upload pic+++++++++++++++++++++"
		res = Net::HTTP.start(url.host, url.port) do |http| 
			response = http.request(req)
			#$log1.info response
		end
	rescue => e
		#err = XError::format_error(e)
		#$log1.error err
		$log.error e.message
		$log.error e.backtrace.inspect
		#raise e
	end	
end

def knum(file, port)
	card = ""
	state = 0
	cardno = "N"
	carColor = 0
	nColor = 0

	url = "http://127.0.0.1:#{port}/knum"

	#uri = URI('http://127.0.0.1:8422/knum')
	uri = URI(url)
	#fn = "#{mac}#{ed}"
	params = {:file=>file}
	uri.query = URI.encode_www_form(params)
	card = Net::HTTP.get(uri).force_encoding('utf-8')#.encode('utf-8', 'GB2312')
	r = card.split(',')
	#r = card.force_encoding('utf-8').split(',')
	if r[0].length > 2
		state = 1 
		cardno = r[0].force_encoding('utf-8')


		nColor = r[3].force_encoding('utf-8') if r[3] 
		carColor = r[4].force_encoding('utf-8') if r[4]
	end

	return state, cardno, nColor, carColor
end

def deal_data(con, rd, port)
begin
	ts = Time.now.to_f
	#$log.info "---- deal_data start."
	condition = ' and timestampdiff(second, update_time, now()) <= 60'
	rs = con.query "select build_id, major, mac, carpos, url, ful, carno_his, carno,newpic 
						FROM tb_build_carpos_info
						WHERE newpic > 0
						and rd = #{rd} #{condition}"
	cnt = 0
	list = []
	rs.each{|row|
		cnt += 1
		build_id = row['build_id']
		major = row['major']
		mac = row['mac']
		carpos = row['carpos'].force_encoding('utf-8')
		url = row['url']
		last_ful = row['ful'].to_i
		carno_his = row['carno_his'].force_encoding('utf-8')
		newpic = row['newpic']
		last_carno = row['carno'].force_encoding('utf-8')

		cal_filename =	"cal_pic/#{mac}_#{carpos}"

		t1 = Time.now.to_f
		opr = 0
		$log.info "++++++++++++++++++ deal start - url:#{url},newpic:#{newpic}"
		
		idx = url.index('pic/')
		file = url[idx+4..-1]
		filename = url[idx..-1]
			$log.info "#{idx},#{file},#{filename}"

		if !File.exists?(filename)
			# not deal
		else
			img =  Magick::Image.read(filename).first  
			width = img.columns.to_i  
			height = img.rows.to_i
			thumb = img.crop(160,0,width-320, height-140)  
			#thumb.write(cal_filename)
			w=thumb.columns 
			h= thumb.rows
                    	cal_img = thumb.resize(w*0.1,h*0.1)
			
			img_width = cal_img.columns			
			img_height = cal_img.rows

			t2 = Time.now.to_f
			$log.info "++++++++++++++++++ crop - url:#{url} cost:#{t2-t1}"
			t1 = t2

			# compare with origin_pic
			ful = 0
			carden = 0
             	   cardno = last_carno
			fact_carno = last_carno
			total_pixel = img_width * img_height
			sum = 0
			op = CameraController::getCameraOrigin(con, build_id, mac, carpos)
			if op && op['origin_hash'] != nil
				#o_ahash = op['origin_hash']
				#curr_ahash = ImgBB::calculate_threshold(cal_filename, 16)
				#dis = ImgBB::haming_dist(o_ahash, curr_ahash)
				ori_imgurl = op['origin_pic']
				ori_img =  Magick::Image.read(ori_imgurl).first
				(0..img_width-1).each do |x|
				    (0..img_height-1).each do |y|
					pixel1 = cal_img.pixel_color(x, y)
					pixel2 = ori_img.pixel_color(x, y)
				    red1 = pixel1.red >> 8
				    green1 = pixel1.green >> 8
				    blue1 =pixel1.blue >> 8
				    red2 = pixel2.red >> 8
				    green2 = pixel2.green >> 8
				    blue2 =pixel2.blue >> 8
				    red_dis = (red1-red2).abs
				    green_dis = (green1-green2).abs
				    blue_dis = (blue1-blue2).abs
				     if red_dis > 30 || green_dis > 30 || blue_dis > 30
				      sum += 1 
				     end
				    end
				end
   				dis = 100*sum/total_pixel
			$log.info "~~~~~~ check pic diff - #{mac},dis:#{dis},sum:#{sum},#{total_pixel}"

				ful = 1 if dis > $fx_picdiff
				carden = 1 if dis > 25
				CarController::updateDis(con, build_id, mac, carpos, major, dis)
				t2 = Time.now.to_f
				$log.info "~~~~~~ check pic diff - dis:#{dis},last_ful:#{last_ful},ful:#{ful} cost:#{t2-t1}"
				t2 = t1
			end

			if carden == 1
				##$log.info "----------- knum pic:#{file}"
				state, cardno, nColor, carColor = knum(file, port)
				t2 = Time.now.to_f
				$log.info "----------- knum pic:#{file} return cardno:#{cardno} cost:#{t2-t1}"
				t2 = t1
			else
				state = 0
				cardno = 'N'
				nColor = 0
				carColor = 0
			end
			dis = 0 if dis == nil
			chg = 0
            upchg = 0
			chg = 1 if last_ful != ful || last_carno != cardno
			#$log.info "*******************chg:#{chg}"

      if chg == 1
        ful = 1 if cardno.length > 1
        fact_carno = CarController::updateCarposInfo(
            con, build_id, mac, carpos, major, -9999, cardno, url, ful,dis,opr)
        t2 = Time.now.to_f
        $log.info "return #{cardno}, mac:#{mac}, chg:#{chg},#{last_ful}, ful:#{ful},last_carno:#{last_carno}, cost:#{t2-t1}"
        t2 = t1
      end
      upchg = 1 if last_ful != ful || last_carno != fact_carno && fact_carno.length > 1
	 #upchg = 1 
      if upchg == 1
        t1 = Time.now.to_f
        mr = AreaController::getFloorByMajor(con, build_id, major)
        if mr != nil
          floor_id = mr['floor_id']
          upload_s(build_id, floor_id, major, carpos, ful, fact_carno, filename)
          t2 = Time.now.to_f
          $log.info "uploads data------------ #{build_id},#{major},#{carpos},#{ful},#{fact_carno}, cost:#{t2-t1}"
          t2 = t1
        end
      end
		end

		t1 = Time.now.to_f
		sql =  "update tb_build_carpos_info set newpic=0 
					WHERE build_id='#{build_id}' and major=#{major} and carpos='#{carpos}' and mac='#{mac}'"
		con.query sql
		con.query "commit"
		
		t2 = Time.now.to_f
		$log.info "update newpic ------ #{con} cost:#{t2-t1}"

		#list << sql
	}
	te = Time.now.to_f
	$log.info "---- deal_data done #{cnt} cost:#{te - ts}."
rescue Exception => e
	$log.error e.message
	$log.error e.backtrace.inspect

	con.query "rollback"
end
end


############################
con = MysqlConn2::get_conn

EM.run{
	EM.add_periodic_timer(1) {
		deal_data(con, $rd, port)
	}
}

$log.info("---- dpic end. ----")
