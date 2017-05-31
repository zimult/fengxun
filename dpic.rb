
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

def knum(file)
	card = ""
	state = 0
	cardno = "N"
	carColor = 0
	nColor = 0

	uri = URI('http://127.0.0.1:8422/knum')
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

def deal_data(con, rd)
begin
	ts = Time.now.to_f
	#$log.info "---- deal_data start."
  condition = ' and timestampdiff(second, update_time, now()) <= 60'
	rs = con.query "select build_id, major, mac, carpos, url, ful, carno_his, carno,newpic,opr
						FROM tb_build_carpos_info
						WHERE newpic > 0
						and rd = #{rd} #{condition}"
	cnt = 0
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
    		opr = row ['opr']
		last_carno = row['carno'].force_encoding('utf-8')

		cal_filename =	"cal_pic/#{mac}_#{carpos}"

		t1 = Time.now.to_f

		$log.info "++++++++++++++++++ deal start - url:#{url},carpos:#{carpos},opr:#{opr},newpic:#{newpic}"
		
		idx = url.index('pic/')
		file = url[idx+4..-1]
		filename = url[idx..-1]
    ful = 0
    upload_chg = 0
    chg = 0

    if opr == '0' #dis operate
      #裁剪图片
#$log.info "++++++1111111111111111111+++#{mac}+++"
        img =  Magick::Image.read(filename).first
        width = img.columns.to_i
        height = img.rows.to_i
        thumb = img.crop(160,0,width-320, height-140)
        thumb.write(cal_filename)
      #图片对比
        op = CameraController::getCameraOrigin(con, build_id, mac, carpos)
        if op && op['origin_hash'] != nil
          o_ahash = op['origin_hash']
          curr_ahash = ImgBB::calculate_threshold(cal_filename, 16)
          dis = ImgBB::haming_dist(o_ahash, curr_ahash)
          ful = 1 if dis > $fx_picdiff
          CarController::updateDis(con, build_id, mac, carpos, major, dis)
          $log.info "~~~~~~ check pic diff - dis:#{dis},last_ful:#{last_ful},ful:#{ful},#{mac}"
        end
        dis = 0 if dis == nil
        if ful == 1
$log.info "++++++2222222222222#{mac}22222++++++"
          $log.info "----------- knum pic:#{file}"
          state, cardno, nColor, carColor = knum(file)
          $log.info "----------- knum pic:#{file} return cardno:#{cardno}"
          if cardno.length > 1 #&& last_carno != cardno   # have car no
            state = 1
            opr = 1
            fact_carno, chg = CarController::updateCarposInfo(
                con, build_id, mac, carpos, major, -9999, cardno, url, ful, dis, opr)
            chg = 1
            upload_chg = 1 if fact_carno.length > 1
            #opr = 1 if fact_carno.length > 1
		#$log.info "+++++++++++++++++++++ fact_carno:#{fact_carno}, opr:#{opr}++++++++#{mac}++++++++++"
          else
            state = 0
            cardno = 'N'
            nColor = 0
            carColor = 0
            upload_chg = 1 if last_ful != ful
            chg = 1 if last_ful != ful || last_carno != cardno
	   fact_carno = cardno
          end
        else
$log.info "++++++333333333333333333333333+++#{mac}+++"
          ful = 0
          cardno = 'N'
          upload_chg = 1 if last_ful != ful || last_carno != cardno
          chg = 1 if last_ful != ful || last_carno != cardno
	  fact_carno = cardno
        end
        t2 = Time.now.to_f
	#$log.info "----------------------------#{mac}--------------------- cost:#{t2-t1}"
    else #
      #识别车牌
$log.info "++++++444444444444444444+++#{mac}+++"
      state, cardno, nColor, carColor = knum(file)
      #$log.info "----------- knum pic:#{file} return cardno:#{cardno}"
      dis = 0 if dis == nil
      if cardno.length > 1 #&& last_carno != cardno
        state = 1
        ful = 1
        fact_carno, chg = CarController::updateCarposInfo(
            con, build_id, mac, carpos, major, -9999, cardno, url, ful, dis, opr)
        chg = 1 if last_ful != ful
        upload_chg = 1 if fact_carno.length > 1 && last_carno != fact_carno
        #fact_carno = cardno
        #if last_carno != cardno
          #upload_chg = 1
       # end
      else
	$log.info "++++++5555555555555555++++#{mac}++"
		state = 0
		ful = 0
		cardno = 'N'
		nColor = 0
		carColor = 0
		img =  Magick::Image.read(filename).first
		width = img.columns.to_i
		height = img.rows.to_i
		thumb = img.crop(160,0,width-320, height-140)
		thumb.write(cal_filename)

		op = CameraController::getCameraOrigin(con, build_id, mac, carpos)
		if op && op['origin_hash'] != nil
		  o_ahash = op['origin_hash']
		  curr_ahash = ImgBB::calculate_threshold(cal_filename, 16)
		  dis = ImgBB::haming_dist(o_ahash, curr_ahash)
		  ful = 1 if dis > $fx_picdiff
		  CarController::updateDis(con, build_id, mac, carpos, major, dis)
		  #$log.info "~~~~~~ check pic diff - dis:#{dis},last_ful:#{last_ful},ful:#{ful},#{mac}"
		end
		 opr = 0 if ful == 0
		 chg = 1 if last_ful != ful || last_carno != cardno
		 upload_chg = 1 if last_ful != ful
		fact_carno = cardno
		#t2 = Time.now.to_f
		#$log.info "++++++++++++++++++++++++++++++++++++++++++++ cost:#{t2-t1}"
      end
      end
      ########################################
$log.info "+++++++++++++#{mac}++++++++++++chg:#{chg}+++++++++ upload:#{upload_chg}"
      if upload_chg == 1
	#fact_carno = cardno
        ful = 1 if fact_carno.length > 1
        
        mr = AreaController::getFloorByMajor(con, build_id, major)
        if mr != nil
          floor_id = mr['floor_id']
          upload_s(build_id, floor_id, major, carpos, ful, fact_carno, filename)
          $log.info "uploads_s data-----#{mac}------- #{build_id},#{major},#{carpos},#{ful},fact_no:#{fact_carno}"
        end
      end
      if chg == 1
        fact_carno, chg = CarController::updateCarposInfo(
            con, build_id, mac, carpos, major, -9999, cardno, url, ful, dis, opr)
        #$log.info "------- updateCarposInfo return #{carpos}, mac:#{mac}, carpos:#{carpos}, major:#{major}, #{fact_carno} ful:#{ful}"

      else
        fact_carno = cardno
      end
   # end


		con.query "update tb_build_carpos_info set newpic=0 
			WHERE build_id='#{build_id}' and mac='#{mac}' and carpos='#{carpos}'"	
		con.query "commit"

		$log.info "++++++++++++++++++ deal end - url:#{url}"
	}
	te = Time.now.to_f
	$log.info "---- deal_data done #{cnt} cost:#{te - ts}."
rescue Exception => e
	$log.error e.message
	$log.error e.backtrace.inspect

	con.query "rollback"

	#if e.message
		#system "/var/www/fx/sh/web.sh"
		#retry
	#end
end
end


############################
con = MysqlConn2::get_conn

EM.run{
	EM.add_periodic_timer(1) {
		deal_data(con, $rd)
	}
}

$log.info("---- dpic end. ----")
