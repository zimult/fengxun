# encoding: utf-8
#
require 'net/https'
require 'net/http'
require "open-uri"
require 'socket'
require 'date'
require 'fileutils'
require 'json'
require 'redis'
require 'iconv'
require 'rchardet'
require 'net/http/post/multipart'
require 'fileutils'
require 'rmagick'

require_relative 'imgb'
require_relative 'rkeys'
require_relative 'fx_config'
require_relative 'mysql2_conn'

require_relative 'Controller/build'
require_relative 'Controller/light'
require_relative 'Controller/floor'
require_relative 'Controller/area'
require_relative 'Controller/camera'
require_relative 'Controller/car'
require_relative 'Controller/config'


class BaseRequest
        attr_reader :con
        attr_reader :redis
        attr_reader :params
        attr_reader :env
        attr_reader :request

        def call()
                begin
                        ret = do_call()

                        ret
                rescue => e
                        #@con.query "rollback"
                        raise e
                ensure

                end

                ret
        end

	def rget(key)
		raise XError.new(505, 'redis not connect') if @redis == nil

		r = @redis.get(key)
		if r
			info = JSON.parse(r, {:symbolize_names=>true})
			return info
		else
			return nil
		end
	end

	def rset(key, value)
		raise XError.new(505, 'redis not connect') if @redis == nil

		info = value.to_json
		
		@redis.set(key, info)
	end

	def rhget(key, field)
		raise XError.new(505, 'redis not connect') if @redis == nil

		r = @redis.hget(key, field)

		r = r.force_encoding('utf-8') if r
		r
	end

	def rhgetall(key)
		raise XError.new(505, 'redis not connect') if @redis == nil

		r = @redis.hgetall(key)

		r
	end

	def rhset(key, field, value)
		raise XError.new(505, 'redis not connect') if @redis == nil

		@redis.hset(key, field, value)

		true
	end
end

class MyRedis
        attr_accessor :redis

        def initialize()
                @redis = nil
        end

        def self.get_conn()
                if !@redis || !@redis.connected?
                    self.connect
                end
                return @redis
        end
        def self.connect()
                #if $FansPieServerType == "DEBUG"
                @redis = Redis.new(:host => "127.0.0.1", :port => 6379)
                #else
                #    $redis = Redis.new(:url => "redis://:freeboxrd@10.163.179.172:8384")
                #end
        end
end

class PublicRequest < BaseRequest
        def initialize(session, sinatra_request, sinatra_env, params)
            @params = params
            @request = sinatra_request
            @env = sinatra_env
            @con = MysqlConn2::get_conn
            @redis = MyRedis::get_conn
        rescue => e
            raise e
        end
end


class SetdataRequest < PublicRequest
      def do_call()
          ret = {}
	  	
		$log1.info params[:data]
   	  str = "4154"
	  host = params[:IPaddress]  #'192.168.1.187'  
	  port = params[:port]
	  data = params[:data]
	  #temp = params[:data]
          #data = JSON.parse(temp, {:symbolize_names=>true})
	  build_id =data[:build_id]
	  floor_id =data[:floor]
          floor_num = FloorController::FindNumByID(con, build_id, floor_id)
    	  build_id = build_id[1,4].to_i
	   	if floor_num.to_i < 0
		   floor_num = floor_num.to_i*(-1) + 128
		else
		   floor_num = floor_num.to_i
		end
	  rannum = data[:rannum].to_i
    	  fmn = data[:fmn].to_i
	  freq = data[:feq].to_i
	  kittype = data[:kittype].to_i
    	  rgflag = data[:rgflag].to_i
    	  positional = data[:positional].to_i
    	  major = data[:major].to_i
    	  minor = data[:minor].to_i
        	if build_id >4095
		elsif build_id >255
		   str += "0"
		elsif build_id >15
		   str += "00"
		else
		   str +="000"
		end
	  	str += build_id.to_s(16)
		
	  	if floor_num < 15
		   str += "0"
		end
          	str += floor_num.to_s(16)
		
	  	if rannum < 15
		   str += "0"
		end
          	str += rannum.to_s(16)
		
		if fmn >4095
		elsif fmn >255
		   str += "0"
		elsif fmn >15
		   str += "00"
		else
		   str +="000"
		end
	 	 str += fmn.to_s(16)
		if freq <16
		 str += "0"
		end
		str += freq.to_s(16)

		if kittype<16
		 str += "0"
		end
		str += kittype.to_s(16)
		if rgflag < 16
		   str += "0"
		end
	  	str += rgflag.to_s(16)
          	
		if positional < 16
		   str += "0"
		end
	  	str += positional.to_s(16)
	  	
		if major >4095
                 
		elsif major >255
		  
		   str += "0"
		   
		elsif major >15
		   str += "00"
		else
		   str +="000"
		end
	  	  str += major.to_s(16)
        	  
		if minor >4095
		   
		elsif minor >255
		   
		   str += "0"
		   
		elsif minor >15
		   str += "00"
		else
		   str +="000"
		end
	 	   str += minor.to_s(16)
        	
		i=2
		str_s = "FY"
		crc = str[0,2].hex
		temp = str[0,2].hex
		str_s += temp.chr
		while i< str.length do
		   crc = crc ^ str[i,2].hex
		   temp = str[i,2].hex
		   str_s += temp.chr
		   i +=2
		end
		if crc < 15
		   str += "0"
		end
		str_s += crc.chr
		str += crc.to_s(16)
		
				
		#$log1.info strss 
	
		msg = str_s
	begin
		#s = TCPSocket.open(host, port)
		s = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
		#s.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)  
		timeval = [2, 0].pack("l_2")
		s.setsockopt(Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, timeval)
		s.setsockopt(Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, timeval)
		s.connect(Socket.pack_sockaddr_in(port, host))

		loop  do   
			r = s.send(msg,0)  
			#$log1.info "send return #{r}"
			buf = '0'*5
			count = MyLib.read(s.fileno, buf, 1024)
			#$log1.info count
			if count == -1
			#$log1.error 'Timeout'
			ret = {"result"=>1, "message"=>"数据发送错误!"}
			s.close
			end
			recv = "#{buf}"
			ack = recv[2]
                        if ack == "\x00"
                           backdata = 0
                           ret = {"result"=>0, "message"=>"配置成功!"}
			elsif ack == "\x03"
			   backdata = 3
		           ret = {"result"=>3, "message"=>"未插入模块!"}
			elsif ack == "\x04"
			   backdata = 4
			   ret = {"result"=>4, "message"=>"参数不匹配!"}
			else
			  backdata = 5
			  ret = {"result"=>1, "message"=>"数据发送错误!"}
			end
			#$log1.info backdata
			#ret = {"result"=>0, "message"=>"配置成功!"}#, "recv":"#{buf}"}
			break
		end  
		 
	rescue => e
		s.close
		ret = {"result"=>2, "message"=>"未找到调试工具!"}
	end
        s.close
	ret
      end
end


class ConnectionRequest < PublicRequest
      def do_call()
	  ret = {}
          host = params[:IPaddress]  #'192.168.1.187'  
	  port = params[:port]
	#host = '127.0.0.1'
	#port = 8422
	  msg="\x41\x54\x02\x00\x00\x17" 
	abc= ""
      begin
		#s = TCPSocket.open(host, port)
		s = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
		#s.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)  
		timeval = [2, 0].pack("l_2")
		s.setsockopt(Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, timeval)
		s.setsockopt(Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, timeval)
		s.connect(Socket.pack_sockaddr_in(port, host))

		loop  do   
			r = s.send(msg,0)  
			
			buf = '0'*17
			count = MyLib.read(s.fileno, buf, 1024)
			#$log1.info count
			if count == -1
				#$log1.error 'Timeout'
			s.close
			else
			recv = "#{buf}"
			#$log1.info recv
			ret = {"result"=>1, "message"=>"连接成功!"}#, "recv":"#{buf}"}
                        break
			end
			
			
		end  
		 
	rescue => e
		s.close
		ret = {"result"=>0, "message"=>"连接失败!"}
	end
        s.close
	#$log1.info ret
	ret
       
      end
end


class ActiveRequest < PublicRequest
      def do_call()
	  ret = {}
          host = params[:IPaddress]  #'192.168.1.187'  
	  port = params[:port]
	  msg="\x46\x59\x41\x55\x61\x63\x74\x69\x76\x61\x74\x65\x0d" 
	begin
		#s = TCPSocket.open(host, port)
		s = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
		#s.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)  
		timeval = [2, 0].pack("l_2")
		s.setsockopt(Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, timeval)
		s.setsockopt(Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, timeval)
		s.connect(Socket.pack_sockaddr_in(port, host))

		loop  do   
			r = s.send(msg,0)  
			#$log1.info "send return #{r}"
			buf = ''
			count = MyLib.read(s.fileno, buf, 1024)
			if count == -1
			#$log1.error 'Timeout'
			s.close
			end
			ret = {"result"=>0, "message"=>"激活成功!"}#, "recv":"#{buf}"}
			break
		     end  
		 
		rescue => e
			s.close
			ret = {"result"=>1, "message"=>"激活失败!"}
		end
          s.close
	  #$log1.info ret
	  ret
       
      end
end



class UpFileRequest < PublicRequest
	def do_call()
		#if params['filename']
		#raise XError.new(505, 'Wrong parameter') if !params[:filename] || !params[:uploadfile]
		$log.info params
		blob = params['uploadfile'][:tempfile].read
		filename = params[:filename]
		filename2 = ''
		filename2 =  params['uploadfile'][:filename] if params['uploadfile'][:filename]
		$log.info "UpFileRequest : #{filename}, - #{filename2}"

		build_id = $building_id

		savefile = "serverb/#{filename2}"
		File.open(savefile, "wb") do |f|
			f.write(blob)
		end

		if params[:wifi_verson]
			wifi_verson = params[:wifi_verson]
			ConfigController::setConfig(@con, build_id, 'wifi_verson', wifi_verson)
		end
		if params[:g_verson]
			g_verson = params[:g_verson]
			ConfigController::setConfig(@con, build_id, 'g_verson', g_verson)
		end
		if params[:camera_verson]
			camera_verson = params[:camera_verson]
			ConfigController::setConfig(@con, build_id, 'camera_verson', camera_verson)
		end
		if params[:main_verson]
			main_verson = params[:main_verson]
			ConfigController::setConfig(@con, build_id, 'main_verson', main_verson)
		end
		if params[:update_flag]
			update_flag = params[:update_flag]
			ConfigController::setConfig(@con, build_id, 'update_flag', update_flag)
		end
		ret = {}
		url = "#{$myurl}/#{savefile}"
		ret[:url] = url
		ret[:result] = 1
		ret
	end
end

class GetVersonRequest < PublicRequest
	def do_call()
		build_id = $building_id
		ret = {}
		wifi_verson = ConfigController::loadConfig(con, build_id, 'wifi_verson')
		ret[:wifi_verson] = wifi_verson

		g_verson = ConfigController::loadConfig(con, build_id, 'g_verson')
		ret[:g_verson] = g_verson

		camera_verson = ConfigController::loadConfig(con, build_id, 'camera_verson')
		ret[:camera_verson] = camera_verson

		main_verson = ConfigController::loadConfig(con, build_id, 'main_verson')
		ret[:main_verson] = main_verson

		update_flag = ConfigController::loadConfig(con, build_id, 'update_flag')
		ret[:update_flag] = update_flag

		rt = {}
		rt[:result] = 1
		rt[:build_id] = build_id
		rt[:param] = ret
		rt
	end
end


class GetmacRequest < PublicRequest
	def do_call()
		build_id = $building_id
		ret = {}
                no = params[:no]
		mac = ConfigController::getmac(con, build_id, no)
		#ret[:mac] = mac	

		rt = {}
		rt[:result] = 1
		rt[:build_id] = build_id
		rt[:mac] = mac
               # $log1.info  rt
		rt
		
	end
end


class AddmacRequest < PublicRequest
	def do_call()
		build_id = $building_id
		ret = {}
                no = params[:no]
		mac = params[:mac]
		#$log1.info  mac
		mac = ConfigController::addmac(con, build_id, no, mac)
		#ret[:mac] = mac	

		rt = {}
		rt[:result] = 1
		#rt[:build_id] = build_id
		#rt[:mac] = mac
               # $log1.info  rt
		rt
		
	end
end


class UpPicRequest < PublicRequest
	def find_carpos(building_id, mac, index)

		#if index == 0	
		#	i = 1
		#else
		#	i = index + 1
		#	i = 1 if i > 3	
		#end
		i = index

		key = RKeys::get_cfg_key(building_id, mac, i)
		rt = rhgetall(key)
		$log.info "rhgetall #{key} end"

		rt
	end

	def check_debug_overtime(building_id, mac, cfg, tm)
		if cfg["debug"].to_i == 1 && tm - cfg["dbg_tm"].to_i > 1800
			#
			for i in 1..3 do
				key = RKeys::get_cfg_key(building_id, mac, i)
				rhset(key, 'debug', 0)
			end
		end
	end

	def get_head_param(info, seg)
		rt = nil
		cs = seg + '='
		idx1 = info.index(cs)
		len = cs.length+1
		if idx1
			str = info[idx1+len..-1]
			idx2 = str.index(';')
			rt = str[0..idx2-2] if idx2
		end
		rt
	end
	
	def do_call()
		blob = nil
		filename = "pic/"
		ed = ""
		head = ""
		index = 0

		if params['1.jpg']
			blob = params['1.jpg'][:tempfile].read
			head = params['1.jpg'][:head]
			ed = "_1.jpg"
			index = 1
		elsif params['2.jpg']
			blob = params['2.jpg'][:tempfile].read
			head = params['2.jpg'][:head]
			ed = "_2.jpg"
			index = 2
		elsif params['3.jpg']
			blob = params['3.jpg'][:tempfile].read
			head = params['3.jpg'][:head]
			ed = "_3.jpg"
			index = 3
		elsif params['0.jpg']
			blob = params['0.jpg'][:tempfile].read
			head = params['0.jpg'][:head]
			ed = "_0.jpg"
			index = 0
		else
			#$log.info params
			filename = ""
		end

		info = head.to_s
		#$log.info info
		
		building_id = $building_id
		mac = get_head_param(info, "MAC")
		find_index = get_head_param(info, "nextname")
		floor_num = get_head_param(info, "floor")
		major = get_head_param(info, "fenqu")
		
=begin		
		idx1 = info.index('MAC=')
		str = info[idx1+5..-1]
		idx2 = str.index(';')
		mac = str[0..idx2-2]

		carpos = ''
		idx1 = info.index('carpos=')
		if idx1
			str = info[idx1+8..-1]
			idx2 = str.index(';')
			carpos = str[0..idx2-2]
			carpos = "" if idx2<=2
		end

		building_id = $building_id
		idx1 = info.index('building_id=')
		if idx1
			str = info[idx1+13..-1]
			idx2 = str.index(';')
			#building_id = str[0..idx2-2]
			#building_id = "" if idx2<=2
		end

		find_index = 1
		idx1 = info.index('nextname=')
		if idx1
			str = info[idx1+10..-1]
			idx2 = str.index(';')
			find_index = str[0..idx2-2]
			$log.info("------- nextname is:#{find_index}")
		end
=end

		#$log.info "index:#{index}, #{building_id}, #{mac}, #{find_index}"
		cfg = nil
		if building_id.length > 0 && mac.length > 0
			cfg = find_carpos(building_id, mac, index)
			cfg_next = find_carpos(building_id, mac, find_index)
			#$log.info cfg
			carpos = cfg["carpos"] if cfg && cfg["carpos"]
		end

		filename = "pic/#{mac}#{ed}"

		if !blob
			$log.error "no file -----"
			return "KM#{index}0"
		end

		File.open(filename, "wb") do |f|
			f.write(blob)
		end

		filename2 = filename.gsub('.jpg', '.txt')

		# 识别车牌
		card = ""
		state = 0
		cardno = ""
		carColor = 0
		nColor = 0

		uri = URI('http://127.0.0.1:8422/knum')
		fn = "#{mac}#{ed}"

		params = {:file=>fn}
		uri.query = URI.encode_www_form(params)
		card = Net::HTTP.get(uri).force_encoding('GB2312')
		cd = card
		card= Iconv.new('UTF8//IGNORE', 'GB2312//IGNORE').iconv(card)
		r = card.split(',')

		if r[0].length > 2
			state = 1 
			cardno = r[0].force_encoding('utf-8')
			nColor = r[3].force_encoding('utf-8') if r[3] 
			carColor = r[4].force_encoding('utf-8') if r[4]
		end

		tm = Time.now.to_i

		#$log.info "---- #{filename}, #{filename2}, #{r} --- save."
		#File.delete(filename2) if File.exist?(filename2)

		# 记录数据
		key = RKeys::get_info_key(building_id, mac, index)

		carpos= Iconv.new('UTF8//IGNORE', 'GB2312//IGNORE').iconv(carpos)

		tmp = {}
		tmp[:mac] = mac
		tmp[:carpos] = carpos
		tmp[:index] = index
		tmp[:state] = state
		tmp[:carNumber] = cardno
		tmp[:tm] = tm
		tmp[:imgUrl] = "#{$myurl}/#{filename}" 
		rset(key, tmp)
		#$log.info "------- redis set key:#{key}, value:#{tmp}"

		if cfg != nil && cfg["carpos"]
			check_debug_overtime(building_id, mac, cfg, tm)

			x = cfg_next["x"]
			y = cfg_next["y"]
			dbg = cfg["debug"]
			win_type = "7"
			win_type = cfg["win_type"] if cfg["win_type"]

			if index == 0
				ret = "KM#{index}#{state},X:0,Y:0,debug:#{dbg},win_type:#{win_type}"
			else
				ret = "KM#{index}#{state},X:#{x},Y:#{y},debug:#{dbg},win_type:#{win_type}"
			end

			# set carpos cfg[:carpos]  full or empty
		else
			#ret = "KM#{index}#{state}"
			dbg = cfg_next["debug"] if cfg_next["debug"]
			ret = "KM#{index}#{state},X:0,Y:0,debug:#{dbg},win_type:7"
		end

		#$log1.info ret
		return ret
	end
end

class ListMacRequest < PublicRequest
	def list_mac(mac, buildingId)
		ret = []
		win_type = ''
		key = RKeys::get_cfg_key(buildingId, mac, 1)
		win_type = rhget(key, 'win_type')
			
		for i in 1..3 do
			# use buildingId
			key = RKeys::get_info_key(buildingId, mac, i)

			info = rget(key)
			if info
				tm2 = info[:tm]

				tm = Time.now.to_i
				info[:tm] = tm - tm2
				ret << info
			else 
				ret << {}
			end
		end

		rt = {}
		size = ret.length > 0 ? "1" : "0"
		rt[:token] = size
		rt[:param] = ret
		rt[:win_type] = win_type

		#$log.info rt
		rt
	end

	def do_call()
		#$log.info("listmac - #{params}")
		mac = params[:mac].force_encoding('utf-8')
		buildingId = $building_id
		buildingId = params[:building_id].force_encoding('utf-8') if params[:building_id]

		rt = list_mac(mac, buildingId)
		rt
	end
end

class CameraParamRequest < PublicRequest
	def do_call()
		#$log.info "CameraParamRequest:#{params}"

		mac = params[:mac].force_encoding('utf-8')
		building_id = $building_id
		debug = params[:debug].to_i

		ret = {}
		if debug == 1
			window = []
			tm = Time.now.to_i
			win_type = '7'
			for i in 1..3 do
				key = RKeys::get_cfg_key(building_id, mac, i)
				rt = rhgetall(key)

				if rt != nil && rt["carpos"]
					rhset(key, 'debug', 1) if rt["debug"].to_i == 0
					rhset(key, 'dbg_tm', tm)
					win_type = rhget(key, 'win_type')
				
					$log.info rt
				else
					if i == 1
						x = 0
						y = 490
					elsif i == 2
						x = 800
						y = 490
					elsif i == 3
						x = 1600
						y = 490
					else
						x = 10
						y = 20
					end

					rt = {}
					rt["carpos"] = "A101"
					rt["x"] = x
					rt["y"] = y
					rt["debug"] = 1
					rt["dbg_tm"] = tm

					#$log.info "CameraParamRequest hset key:#{key}, #{rt}"
					rhset(key, 'carpos', 'A101')
					rhset(key, 'x', x)
					rhset(key, 'y', y)
					rhset(key, 'debug', 1)
					rhset(key, 'dbg_tm', tm)
					rhset(key, 'win_type', win_type)
				end

				rt["carpos"] = rt["carpos"].force_encoding('utf-8') if rt["carpos"]
				window << rt
			end

			key0 = RKeys::get_info_key(building_id, mac, 0)
			r = rget(key0)
			tml = tm
			tml = r[:tm] if r != nil

			ret[:result] = 1
			ret[:window] = window
			ret[:win_type] = win_type
			ret[:big_pic] = "#{$myurl}/pic/#{mac}_0.jpg" 
			ret[:tm] = Time.now.to_i - tml

			#$log.info "CameraParamRequest:#{params} done, ret:#{ret}, #{r}"

			return ret
		else
			# exit debug mod
			for i in 1..3 do
				key = RKeys::get_cfg_key(building_id, mac, i)
				rt = rhgetall(key)

				if rt != nil
					rhset(key, 'debug', 0)
				end
			end	
			ret[:result] = 1

			return ret
		end
	end
end

class CameraConfigRequest < PublicRequest
	def do_call()
		#$log.info "CameraConfigRequest: body:#{request.body.to_s}"
		#$log.info "CameraConfigRequest: env:#{env}"
		#$log.info "CameraConfigRequest: #{params}"
		raise XError.new(505, 'Wrong parameter') if !params[:mac] || !params[:win_type] || !params[:window]

		#data = request.body.read
		#$log.info data
		#$log.info data.class
		#vars = env["rack.request.form_vars"]
		#$log.info vars
		#$log.info vars.class
		#info = JSON.parse(data, {:symbolize_names=>true})
		#info = params
		#$log.info "JSON.parse: #{info}"


		building_id = $building_id
		mac = params[:mac].force_encoding('utf-8')
		win_type = params[:win_type].force_encoding('utf-8')

		window = nil
		if params[:window]
			info = params[:window]
			window = JSON.parse(info, {:symbolize_names=>true})
			#$log.info "window.class:#{window.class}"
		end

		tm = Time.now.to_i
		for i in 1..3 do
			key = RKeys::get_cfg_key(building_id, mac, i)
			cfg = rhgetall(key)

			if window != nil
				carpos = window[i-1][:carpos]
				carpos.encode('utf-8')
				#$log.info "================ #{carpos}, encoding:#{carpos.encoding}"

				rhset(key, 'carpos', carpos)
				rhset(key, 'x', window[i-1][:x])
				rhset(key, 'y', window[i-1][:y])
			end

			rhset(key, 'debug', 0)	if !cfg["debug"]
			rhset(key, 'dbg_tm', tm) if cfg["debug"] && cfg["debug"].to_i == 1
			rhset(key, 'win_type', win_type)

			hh = rhget(key, 'carpos')
			#$log.info "================redis get #{hh}, encoding:#{hh.encoding}"
		end

		ret = {:result => 1}
		#$log.info "CameraConfigRequest: done"
		ret
	end
end

class LightParamRequest < PublicRequest
	def do_save(build_id, major, mac, pm)
		#raise XError.new(403, "Wrong Parameter")	

		minor = pm[:minor]
		tmp = pm[:tmp].to_i
		lst = pm[:lst].to_i
		errcode = pm[:errcode].to_i

		lightinfo = {}
		lightinfo[:build_id] = build_id
		lightinfo[:major] = major
		lightinfo[:minor] = minor
		lightinfo[:mac] = mac
		lightinfo[:tmp] = tmp
		lightinfo[:lst] = lst
		lightinfo[:errcode] = errcode

		ts = Time.now.to_f	
		LightController::saveLightInfo(con, lightinfo)
		te = Time.now.to_f	
		#$log1.info "----- LightParamRequest do_save build_id:#{build_id}, major:#{major}, mac:#{mac}, pm:#{pm} cost:#{te-ts}"
	end

	def get_ret(build_id, major, mac)
		ret = {}
		str = 'r:1,p:'
		ret[:date] = DateTime.parse(Time.now.to_s).strftime('%Y-%m-%d').to_s
		#str += ret[:date]
		#str += ','
		
		ret[:time] = DateTime.parse(Time.now.to_s).strftime('%H:%M:%S').to_s
		str += ret[:time]
		str += ','

		setting = LightController::getSetting(@con, build_id, major)
		#$log.info setting
		if setting != nil
			ret[:lmd] = setting['lmd']
			str += ret[:lmd].to_s
			str += ','
			ret[:ntm] = setting['ntm']
			str += ret[:ntm].to_s
			str += ','
			ret[:lva] = setting['lva']
			str += ret[:lva].to_s
			str += ','
			ret[:mnl] = setting['mnl']
			str += ret[:mnl].to_s
			str += ','
			ret[:mxl] = setting['mxl']
			str += ret[:mxl].to_s
			str += ','
			ret[:mnl2] = setting['mnl2']
			str += ret[:mnl2].to_s
			str += ','
			ret[:mxl2] = setting['mxl2']
			str += ret[:mxl2].to_s
			str += ','
			ret[:eng] = setting['eng']
			str += ret[:eng].to_s
			str += ','
		else

			raise XError.new(505, 'no setting')
			ret[:lmd] = 0
			str += ret[:lmd].to_s
			str += ','
			ret[:ntm] = '00000000'
			str += ret[:lmd].to_s
			str += ','
			ret[:lva] = 0
			str += ret[:lmd].to_s
			str += ','
			ret[:mnl] = 0
			str += ret[:lmd].to_s
			str += ','
			ret[:mxl] = 0
			str += ret[:lmd].to_s
			str += ','
			ret[:mnl2] = 0
			str += ret[:lmd].to_s
			str += ','
			ret[:mxl2] = 0
			str += ret[:lmd].to_s
			str += ','
			ret[:eng] = 0
			str += ret[:lmd].to_s
			str += ','
		end

		ret[:lrt] = $lrt
		str += $lrt.to_s
		str += ','
		ret[:yfx] = $yfx
		str += $yfx.to_s
		str += ','

		wifi_verson = ConfigController::loadConfig(con, build_id, 'wifi_verson')
		ret[:wifi_verson] = wifi_verson
		str += wifi_verson.to_s
		str += ','

		g_verson = ConfigController::loadConfig(con, build_id, 'g_verson')
		ret[:g_verson] = g_verson
		str += g_verson.to_s
		str += ','

		camera_verson = ConfigController::loadConfig(con, build_id, 'camera_verson')
		ret[:camera_verson] = camera_verson
		str += camera_verson.to_s
		str += ','

		main_verson = ConfigController::loadConfig(con, build_id, 'main_verson')
		ret[:main_verson] = main_verson
		str += main_verson.to_s
		str += ','

		update_flag = ConfigController::loadConfig(con, build_id, 'update_flag')
		ret[:update_flag] = update_flag
		str += update_flag.to_s
		str += ','
		#$log1.info str
		str
		#ret
		
	end
	
	def do_call()
		#$log1.info "LightParamRequest:#{params}"
		#$log.info params.class
		info = JSON.parse(params[:param], {:symbolize_names=>true})

		build_id = params[:build_id]
		major = params[:major]
		mac = params[:mac]
		arr = info 

		arr.each{|pm|
			do_save(build_id, major, mac, pm)
		}
		
		ret = get_ret(build_id, major, mac)
                #$log1.info ret
		ret
	end
end


##################################
# use mysql instead of redis
##################################
class CameraConfig2Request < PublicRequest
	def do_call()
		#$log.info "CameraConfigRequest: body:#{request.body.to_s}"
		#$log.info "CameraConfigRequest: env:#{env}"
		$log.info "CameraConfigRequest: #{params}"
		raise XError.new(505, 'Wrong parameter') if !params[:mac] || !params[:win_type]

		#data = request.body.read
		#$log.info data
		#$log.info data.class
		#vars = env["rack.request.form_vars"]
		#$log.info vars
		#$log.info vars.class
		#info = JSON.parse(data, {:symbolize_names=>true})
		#info = params
		#$log.info "JSON.parse: #{info}"


		build_id = $building_id
		mac = params[:mac].force_encoding('utf-8')
		win_type = params[:win_type].force_encoding('utf-8')

		window = nil
		if params[:window]
			info = params[:window]
			window = JSON.parse(info, {:symbolize_names=>true})
		end
		
		CameraController::setCameraConfig(con, build_id, mac, win_type, window)
		CameraController::refreshDebugTime(con, build_id, mac)

		ret = {:result => 1}
		$log.info "CameraConfigRequest: done"
		ret
	end
end

class CameraParam2Request < PublicRequest
	def do_call()
		$log.info "CameraParamRequest:#{params}"
		ret = {}
		mac = params[:mac].force_encoding('utf-8')
		build_id = $building_id
		debug = params[:debug].to_i
		
		if debug == 1
			window = CameraController::listCameraConfig(@con, build_id, mac) #创建默认列表

			#$log1.info window
			ret[:result] = 1
			ret[:window] = window
			ret[:win_type] = '7'
			ret[:win_type] = window[0]['win_type'] if window && window.length > 0
			
			CameraController::setCameraDebug(@con, build_id, mac, 1)
			cp = CarController::getCarposInfo(@con, build_id, mac, 'debug')
			ret[:big_pic] = ''
			ret[:big_pic] = cp['url'] if cp 
			ret[:tm] = 0
			ret[:tm] = cp['dt'] if cp
			return ret
		else
			CameraController::setCameraDebug(@con, build_id, mac, 0)
			ret[:result] = 1
			return ret
		end

	end
end

class ListMac2Request < PublicRequest
	def list_mac(mac, build_id)
		ret = []
		win_type = '7'
		ret = CameraController::showCameraConfig(@con, build_id, mac)
		win_type = ret[0]['win_type'] if ret && ret.length > 0
		#cameraDebug = CameraController::getCameraDebug(@con, build_id, mac)

		rt = {}
		size = ret.length > 0 ? "1" : "0"
		rt[:token] = size
		rt[:param] = ret
		rt[:win_type] = win_type

		rt
	end

	def do_call()
		#$log.info("listmac - #{params}")
		mac = params[:mac].force_encoding('utf-8')
		build_id = $building_id
		build_id = params[:building_id].force_encoding('utf-8') if params[:building_id]

		rt = list_mac(mac, build_id)
		rt
	end
end


class LightIDToMacRequest < PublicRequest
      def do_call()
		ret = {}
		build_id = $building_id
		device_area = params[:device_area]
		device_id = params[:device_id]
		mac = LightController::FindMacByID(@con,build_id,device_area,device_id)
		if mac != nil
		ret[:result] = 1
		ret[:mac] = mac
		else
		ret[:result] = 0
		end
		ret
	end
end


class SendBaseImageRequest < PublicRequest
	def do_call()
		$log1.info "SendBaseImageRequest:#{params}"
		ret = {}
		mac = params[:mac].force_encoding('utf-8')
		build_id = $building_id
		index = params[:index].to_i
		imgUrl = params[:imgUrl].force_encoding('utf-8')
		
		idx = imgUrl.index('pic')
		filename = imgUrl[idx..-1]
		$log1.info filename
		if File.exist?(filename)
			img =  Magick::Image.read(filename).first  
			width = img.columns.to_i  
			height = img.rows.to_i
			thumb = img.crop(160,0,width-320, height-140)  
			thumb.write(filename)
			ohash = ImgBB::calculate_threshold(filename, 16)
			basename = File.basename(imgUrl)
			cpath = "ori_pic/"
			ofile = cpath + basename
			FileUtils.cp(filename, cpath)
			CameraController::updateCameraOroginByIndex(@con, build_id, mac, index, ofile, ohash)
			ret[:result] = 1
			ret[:url] = "#{$myurl}/#{ofile}"
		else
			ret[:result] = 0
		end
		
		ret
	end
end

class CheckBaseImg2Request < PublicRequest
	def do_call()
		$log1.info "checkBaseImg2Request:#{params}"
		ret = {}
		mac = params[:mac].force_encoding('utf-8')
		build_id = $building_id
		index = params[:index].to_i
		
		info = CameraController::getCameraOriginByIndex(@con, build_id, mac, index)
		if info
			ret[:result] = 1
			ret[:carpos] = info['carpos']
			ret[:imgUrl] = "#{$myurl}/#{info['origin_pic']}"
			
			carinfo = CarController::getCarposInfo(@con, build_id, mac, info['carpos'])
			#$log.info carinfo
			if carinfo && info['origin_hash'] != nil && carinfo['url'] != nil
				ret[:currUrl] = carinfo['url']
				idx = carinfo['url'].index('pic')
				file = carinfo['url'][idx..-1]
				if File.exist?(file)
					chash = ImgBB::calculate_threshold(file, 16)
					dis = ImgBB::haming_dist(chash, info['origin_hash'])
				else
					dis = 9999
				end

				ret[:dis] = dis
			else
				ret[:currUrl] = ""
				ret[:dis] = 9999
			end
		else
			ret[:result] = 0
		end

		ret
	end
end

class UpPic2Request < PublicRequest
	def find_carpos(building_id, mac, index)

		i = index

		key = RKeys::get_cfg_key(building_id, mac, i)
		rt = rhgetall(key)
		#$log.info "rhgetall #{key} end"

		rt
	end

	def get_head_param(info, seg)
		rt = nil
		cs = seg + '='
		idx1 = info.index(cs)
		len = cs.length+1
		if idx1
			str = info[idx1+len..-1]
			idx2 = str.index(';')
			rt = str[0..idx2-2] if idx2
		end
		rt
	end

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


		res = Net::HTTP.start(url.host, url.port) do |http| 
			response = http.request(req)
			#$log1.info response
		end
	rescue => e
		err = XError::format_error(e)
		#$log1.error err
	end	
	end

	def knum(fn)
		# 识别车牌
		card = ""
		state = 0
		cardno = "N"
		carColor = 0
		nColor = 0

		uri = URI('http://127.0.0.1:8422/knum')
		#fn = "#{mac}#{ed}"
		params = {:file=>fn}
		uri.query = URI.encode_www_form(params)
		card = Net::HTTP.get(uri)
		#cd = card
		#card= Iconv.new('UTF8//IGNORE', 'GB2312//IGNORE').iconv(card)
		#r = card.split(',')
		r = card.force_encoding('utf-8').split(',')
		#r = card.force_encoding('GB2312').split(',')

		if r[0].length > 2
			state = 1 
			cardno = r[0].force_encoding('utf-8')
			nColor = r[3].force_encoding('utf-8') if r[3] 
			carColor = r[4].force_encoding('utf-8') if r[4]
		end

		#$log.info "-------- knum ret:#{r}"

		return state, cardno, nColor, carColor
	end
	
	def do_call()
		ts = Time.now.to_f
		blob = nil
		filename = "pic/"
		ed = ""
		head = ""
		index = 0

		if params['1.jpg']
			blob = params['1.jpg'][:tempfile].read
			head = params['1.jpg'][:head]
			ed = "_1.jpg"
			index = 1
		elsif params['2.jpg']
			blob = params['2.jpg'][:tempfile].read
			head = params['2.jpg'][:head]
			ed = "_2.jpg"
			index = 2
		elsif params['3.jpg']
			blob = params['3.jpg'][:tempfile].read
			head = params['3.jpg'][:head]
			ed = "_3.jpg"
			index = 3
		elsif params['0.jpg']
			blob = params['0.jpg'][:tempfile].read
			head = params['0.jpg'][:head]
			ed = "_0.jpg"
			index = 0
		else
			#$log.info params
			filename = ""
		end

		info = head.to_s
		#$log1.info "+++++++++++++++++++++#{info}"
		
		building_id = $building_id
		mac = get_head_param(info, "MAC")
		find_index = get_head_param(info, "nextname")
		floor_num = get_head_param(info, "floor")
		major = get_head_param(info, "fenqu")
		ori = get_head_param(info, "ori")
		major = 0 if major == nil

		tc = Time.now.to_f
		cost = tc - ts
		ts = tc

		carpos = ''
		if building_id.length > 0 && mac.length > 0
			cfg = CameraController::findCarpos(@con, building_id, mac, index)
			cfg_next = CameraController::findCarpos(@con, building_id, mac, find_index)
			if cfg
				carpos = cfg["carpos"] if cfg && cfg["carpos"]
			end
		end
		carpos = 'debug' if index == 0

		if !blob
			$log1.error "no file -----"
			return "KM#{index}0"
		end

		if ori != nil	# set origin_pic
			# set camera. origin_pic
			op = CameraController::getCameraOrigin(@con, building_id, mac, carpos)
			if op != nil
				filename = "ori_pic/#{mac}#{ed}"

				File.open(filename, "wb") do |f|
					f.write(blob)
				end

				oahash = ImgBB::calculate_threshold(filename, 16)
				CameraController::updateCameraOrogin(@con, building_id, mac, carpos, filename, ohash)
			end
		end
	
		tm = Time.new
		tf = tm.strftime('%H')
		tmf = tm.strftime('%H%M%S')

		filename = "pic/#{tf}/#{mac}_#{tmf}#{ed}"

		File.open(filename, "wb") do |f|
			f.write(blob)
		end
		filename2 = filename.gsub('.jpg', '.txt')

		# 识别车牌
		state = 0
		cardno = ''
		chg = 0	
		fact_carno = cardno
		url = "#{$myurl}/#{filename}"
		fn = filename[4..-1]
		CarController::updateCarposPic(con, building_id, mac, carpos, major, floor_num, url)
=begin
		$log.info "------- +++++ knum"
		state, cardno, nColor, carColor = knum(fn)
		$log.info "------- +++++ knum end, cardno:#{cardno}"

		tc = Time.now.to_f
		cost = tc - ts
		ts = tc
		$log.info "-------------------- tc 3 cost:#{cost}"  if cost > 0.013

		tm = Time.now.to_i

		# 记录数据

		if carpos.length > 1
			fact_carno, chg = CarController::updateCarposInfo(con, building_id, mac, carpos, major, floor_num, cardno, url)
			$log.info "------- updateCarposInfo return #{fact_carno}"
		else
			fact_carno = cardno
		end


		tc = Time.now.to_f
		cost = tc - ts
		ts = tc
		$log.info "-------------------- tc 4 cost:#{cost}" if cost > 0.013
=end
		state = 0
		sta = 0
		sta1 = 0
		sta2 = 0
		sta3 = 0
		build_id = building_id
		if cfg != nil && cfg["carpos"]
			win_type = cfg["win_type"]
			#$log1.info "---------------------win_type:#{win_type}-------------------------------------"
			if win_type == '1'

				 carinfo = CarController::getCarposInfo(@con, build_id, mac, carpos)
				 state = carinfo['ful'] if carinfo
		        elsif win_type == '3'
				 cp = nil
				 index = 1
				 cp = CameraController::getCarpos(@con, build_id, mac, index)
				 carpos = cp["carpos"] if cp && cp["carpos"]
				 carinfo = CarController::getCarposInfo(@con, build_id, mac, carpos)
				 sta1 = carinfo['ful'].to_i if carinfo
				 cp = nil
				 index =2
				 cp = CameraController::getCarpos(@con, build_id, mac,index)
				 carpos = cp["carpos"] if cp && cp["carpos"]
				 carinfo = CarController::getCarposInfo(@con, build_id, mac, carpos)
				 sta2 = carinfo['ful'].to_i if carinfo
				 sta = sta1 + sta2 *2
				 state = sta.to_s
			elsif win_type == '7'
				  cp = nil
				  index = 1	
				  cp = CameraController::getCarpos(@con, build_id, mac, index)
				  carpos = cp["carpos"] if cp && cp["carpos"]
				  carinfo = CarController::getCarposInfo(@con, build_id, mac, carpos)
				  sta1 = carinfo['ful'].to_i if carinfo
				  cp = nil
				  index = 2
				  cp = CameraController::getCarpos(@con, build_id, mac, index)
				  carpos = cp["carpos"] if cp && cp["carpos"]
				  carinfo = CarController::getCarposInfo(@con, build_id, mac, carpos)
				  sta2 = carinfo['ful'].to_i if carinfo
				  cp = nil
				  index = 3
				  cp = CameraController::getCarpos(@con, build_id, mac, index)
				  carpos = cp["carpos"] if cp && cp["carpos"]
				  carinfo = CarController::getCarposInfo(@con, build_id, mac, carpos)
				  sta3 = carinfo['ful'].to_i if carinfo
				  sta = sta1 + sta2 *2 + sta3 * 4
				  state = sta.to_s
			end
		end
		#carinfo = CarController::getCarposInfo(@con, build_id, mac, carpos)
		#state = carinfo['ful'] if carinfo

		dbg = CameraController::check_debug_overtime(@con, building_id, mac)
		if cfg != nil && cfg["carpos"]
                  	if cfg_next !=nil
			   x = cfg_next["x"].to_i 
                        else
			   x = 0 
                        end
			if cfg_next !=nil
			   y = cfg_next["y"].to_i 
			else
			   y = 0
			end
			win_type = cfg["win_type"]
			dbg = 0 if !dbg

			if index == 0
				ret = "KM#{index}#{state},X:0,Y:0,debug:#{dbg},win_type:#{win_type}"
			else
				ret = "KM#{index}#{state},X:#{x},Y:#{y},debug:#{dbg},win_type:#{win_type}"
			end

			# set carpos cfg[:carpos]  full or empty
		else
			dbg = 0 if !dbg
			ret = "KM#{index}#{state},X:0,Y:0,debug:#{dbg},win_type:1"
		end

		#chg = 1
		if chg == 1 && index > 0
			ful = 0
			ful = 1 if fact_carno.length > 1
			floor_id = FloorController::FindIDByNum(@con, building_id, floor_num)
			upload_s(building_id, floor_id, major, carpos, ful, fact_carno, filename)
		end
		$log.info "------ uploadpic carpos:#{carpos} mac:#{mac} done."
		return ret
	end
end
