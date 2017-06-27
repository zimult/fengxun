
require_relative 'fx_request'
require_relative 'Controller/build'
require_relative 'Controller/light'
require_relative 'Controller/floor'
require_relative 'Controller/area'

class AdminRequest < BaseRequest
        def initialize(session, sinatra_request, sinatra_env, params)
            @params = params
            @request = sinatra_request
            @env = sinatra_env
            @con = MysqlConn2::get_conn
            @redis = MyRedis::get_conn

	    if !isAdmin(params)
			#raise XError.new(404, 'NOT ADMIN USER')
	    end

        rescue => e
            raise e
        end

	def isAdmin(params)
		return false if !params[:request]

		# check if request is admin user and check randcode
		return true
	end
end

class BuildAddAdminRequest < AdminRequest
	def do_call()
                 #$log1.info "BuildAddAdminRequest: body:#{request.body.to_s}"
                #   $log.info "BuildAddAdminRequest: #{params}"
		$log1.info "JSON.parse: #{params}"
		raise XError.new(505, 'Wrong parameter') if !params[:addbuild]

		info = params[:addbuild]
               # $log1.info "BuildAddAdminRequest: #{params}"
                #$log1.info "JSON.parse: #{info},--- #{info.class}"
		addbuild = JSON.parse(info, {:symbolize_names=>true})
                           
                #addbuild = info

		build_id = addbuild[:build_id]
		build_name = addbuild[:build_name]
		build_type = addbuild[:build_type].to_i

		floor_list = addbuild[:floor_list]
		area_list = addbuild[:area_list]
                add_result=0
		add_result = BuildController::AddBuild(@con, build_id, build_name, build_type)
		result = 0
		if add_result == 1
                         #result=1
			result = BuildController::AddFloorArea(@con, build_id, floor_list, area_list)
		end

		ret = {}
		ret[:add_result] = add_result
		ret[:result] = result
		ret
	end
end

class BuildingFloorsRequest < PublicRequest
	def get_data(build_id)
		ret = {}
		result = 0 
		build_name = BuildController::getBuildName(@con, build_id)
		raise XError.new(500, 'biuld_id not found.')  if build_name == nil

		floor_list = FloorController::getFloorList(@con, build_id)
		area_list = AreaController::getAreaList(@con, build_id)

		result = 1
		ret[:result] = result
		ret[:floor_list] = floor_list
		ret[:area_list] = area_list

		ret
	end
	
	def do_call()
		$log.info "BuildingFloorsRequest: #{params}"
		raise XError.new(505, 'Wrong parameter') if !params[:user_id] || !params[:build_id] #|| !params[:access_token]

		# if user_id == 'test'
		build_id = params[:build_id]

		#
		return get_data(build_id)
	end
end

class LightSetModeRequest < AdminRequest

	def setMode(con, build_id, che, floor, ran, set)
		uinfo = ''
		st = 0
		$log.info set
		$log.info set.class
		$log.info set[:lmd]	
		$log.info set['lmd']	
	
		if set[:lmd] != nil
			lmd = set[:lmd].to_i
			uinfo += ',' if st == 1
			uinfo += "lmd=#{lmd}" 
			st = 1
		end
		if set[:lva] != nil
			lva = set[:lva].to_i
			uinfo += ',' if st == 1
			uinfo += "lva=#{lva}" 
			st = 1
		end
		if set[:eng] != nil
			eng = set[:eng].to_i
			uinfo += ',' if st == 1
			uinfo += "eng=#{eng}" 
			st = 1
		end
		if set[:ntm] != nil
			ntm = set[:ntm]
			uinfo += ',' if st == 1
			uinfo += "ntm='#{ntm}'"
			st = 1
		end
		if set[:mnl] != nil
			mnl = set[:mnl].to_i
			uinfo += ',' if st == 1
			uinfo += "mnl=#{mnl}" 
			st = 1
		end
		if set[:mxl] != nil
			mxl = set[:mxl].to_i
			uinfo += ',' if st == 1
			uinfo += "mxl=#{mxl}" 
			st = 1
		end
		if set[:mnl2] != nil
			mnl2 = set[:mnl2].to_i
			uinfo += ',' if st == 1
			uinfo += "mnl2=#{mnl2}" 
			st = 1
		end
		if set[:mxl2] != nil
			mxl2 = set[:mxl2].to_i
			uinfo += ',' if st == 1
			uinfo += "mxl2=#{mxl2}" 
			st = 1
		end
		
		if che == 1
			wh = "build_id = '#{build_id}'"	
		elsif floor != nil
			wh = "build_id = '#{build_id}' and floor_num=#{floor}"
		elsif ran != nil
			rs = con.query "SELECT major FROM tb_build_area 
						where build_id='#{build_id}' and area_name='#{ran}'"
			row = rs.first
			if row
				major = row['major'].to_i
				wh = "build_id = '#{build_id}' and major=#{major}"
			else
				raise XError(404, 'Wrong ran')
			end
		else
			raise XError(404, 'Wrong Parameter')
		end

		sql = "UPDATE tb_build_light_setting SET #{uinfo} WHERE #{wh}"	
		$log.info sql

		con.query sql
		con.query "commit"
		return 1
	end

	def do_call()
		$log1.info "LightSetModeRequest: #{params}"
		raise XError.new(505, 'Wrong parameter') if !params[:user_id] || !params[:build_id] || !params[:set]
#!params[:access_token] || 

		# if user_id == 'test'

		rt = {}
		che = nil
		che = 1 if params[:che]
		rt[:che] = params[:che] if params[:che]
		floor = nil
		floor = params[:floor].to_i if params[:floor]
		rt[:floor] = params[:floor] if params[:floor]
		ran = nil
		ran = params[:ran].force_encoding('utf-8') if params[:ran]
		rt[:ran] = params[:ran] if params[:ran]

		set = params[:set]
		set = JSON.parse(params[:set], {:symbolize_names=>true})
		build_id = params[:build_id].to_s
		
		ret = setMode(@con, build_id, che, floor, ran, set)
		rt[:success] = ret
		rt[:result] = 1
		rt[:build_id] = $building_id
		rt	
	end
end

class BuildManagerRequest < AdminRequest
	def do_call()
		$log.info "BuildManagerRequest: #{params}"
		raise XError.new(505, 'Wrong parameter') if !params[:request] # || !params[:build_id]

		build_id = nil
		list = BuildController::listBuild(@con, build_id)
		ret = {}
		ret[:result] = 1
		ret[:build_count] = list.size
		ret[:build_list] = list
		ret
	end
end

class BuildManagerDetailRequest < AdminRequest
	def do_call()
		$log.info "BuildManagerDetailRequest: #{params}"
		raise XError.new(505, 'Wrong parameter') if !params[:request] || !params[:build_id]

		build_id = params[:build_id].to_i

		list = BuildController::listBuild(@con, build_id)
		ret = {}

		ret[:result] = 1
		if list.length > 0
			ret[:build_id] = list[0][:build_id]
			ret[:build_name] = list[0][:build_name]
			ret[:build_type] = list[0][:build_type]

			floor_list = FloorController::listFloor(@con, build_id)
			area_list = AreaController::listArea(@con, build_id)

			ret[:floor_list] = floor_list
			ret[:area_list] = area_list
		else
			ret[:result] = 0
		end

		ret
	end
end

class BuildAddDeviceListRequest < AdminRequest
	def do_call()
		#$log1.info "BuildAddDeviceListRequest: #{params}"
		raise XError.new(505, 'Wrong parameter') if !params[:request] || !params[:build_id] || !params[:device_list]
	
		build_id = params[:build_id]

		device_list = JSON.parse(params[:device_list], {:symbolize_names=>true})
		#$log1.info device_list
		
		addBuildLight(build_id, device_list)
		
		ret = {}
		ret[:result] = 1
		ret[:add_result] = 1
		ret
	end
	
	def addBuildLight(build_id, device_list)
		device_list.each{|row|
			LightController::AddBuildLight(@con, build_id, row)
		}
	end
end

class BuildGetDeviceListRequest < AdminRequest
	def do_call()
		$log.info "BuildGetDeviceListRequest: #{params}"
		raise XError.new(505, 'Wrong parameter') if !params[:request] || !params[:build_id]
		
		build_id = params[:build_id].to_i

		list = LightController::listLight(@con, build_id)
		ret = {}
		ret[:result] = 1
		ret[:device_list] = list
		ret
	end
end

class BuildAddCarListRequest < AdminRequest
	def do_call()
		$log.info "BuildAddCarListRequest: #{params}"
		raise XError.new(505, 'Wrong parameter') if !params[:request] || !params[:build_id] || !params[:car_list]

		build_id = params[:build_id]
		car_list = JSON.parse(params[:car_list], {:symbolize_names=>true})
		$log.info device_list
		
		addCarList(build_id, car_list)
		
		ret = {}
		ret[:result] = 1
		ret[:add_result] = 1
		ret
	end

	def addCarList(build_id, car_list)
		car_list.each{|row|
			CarController::AddCarInfo(@con, build_id, row)
		}
	end
end

class BuildGetCarListRequest < AdminRequest
	def do_call()
		$log.info "BuildGetCarListRequest: #{params}"
		raise XError.new(505, 'Wrong parameter') if !params[:request] || !params[:build_id]
		
		build_id = params[:build_id].to_i

		list = CarController::listCar(@con, build_id)
		ret = {}
		ret[:result] = 1
		ret[:car_list] = list
		ret
	end
end

class BuildingListRequest < PublicRequest
	def do_call()
		raise XError.new(505, 'Wrong parameter') if !params[:user_id]

		user_id = params[:user_id]

		build_id = nil
		list = BuildController::listBuild(con, build_id)
		ret = {}
		ret[:result] = 1
		ret[:buildList] = list
		ret
	end
end

class LightSystemRequest < AdminRequest
	def calcLightInfo(build_id, che, floor, ran)
		ret = {}
		par = {}
		ret[:build_id] = build_id
		ret[:che] = che if che != nil
		ret[:floor] = floor if floor != nil
		ret[:ran] = ran if ran != nil
		
		all = LightController::getall(@con, build_id, che, floor, ran)
		par[:all] = all.to_s
		bad = LightController::getbad(@con, build_id, che, floor, ran)
		par[:bad] = bad.to_s
		wat = LightController::sumwat(@con, build_id, che, floor, ran)
		par[:wat] = wat.to_s

		atp, alm = LightController::getavg(@con, build_id, che, floor, ran)
		par[:atp] = atp.to_s
		par[:alm] = alm.to_s

		if ran != nil
			major = AreaController::getMajorByName(@con, build_id, ran)
			raise XError.new(3, "ran #{ran} not found.") if major == nil
			info = LightController::getSetting(@con, build_id, major)
			raise XError.new(3, "ran #{ran} setting not found.") if info == nil

			par[:ntm] = info['ntm'].to_s
			par[:lmd] = info['lmd'].to_s
			par[:lva] = info['lva'].to_s
			par[:eng] = info['eng'].to_s
			par[:mnl] = info['mnl'].to_s
			par[:mxl] = info['mxl'].to_s
			par[:mnl2] = info['mnl2'].to_s
			par[:mxl2] = info['mxl2'].to_s

			#chart = LightController::getLightLog(@con, build_id, che, floor, ran, major)

			#par[:wat_chart] = chart[:wat]
			#par[:temp_chart] = chart[:atp]
			#par[:light_chart] = chart[:alm]
		end
                if che !=nil
			chart = LightController::getLightLog(@con, build_id, che, floor, ran, major)

			par[:wat_chart] = chart[:wat]
			par[:temp_chart] = chart[:atp]
			par[:light_chart] = chart[:alm]
                end

		ret[:par] = par
		ret[:result] = 1
		ret
	end

	def do_call()
		$log1.info "LightSystemRequest - params:#{params}"
		raise XError.new(505, 'Wrong parameter') if !params[:user_id] || !params[:build_id]

		build_id = params[:build_id]
		che = nil
		che = 1 if params[:che]
		#rt[:che] = params[:che] if params[:che]
		floor = nil
		floor = params[:floor].to_i if params[:floor]
		#rt[:floor] = params[:floor] if params[:floor]
		ran = nil
		ran = params[:ran].force_encoding('utf-8') if params[:ran]
		#rt[:ran] = params[:ran] if params[:ran]

		ret = calcLightInfo(build_id, che, floor, ran)
		ret
	end
end

class LightListRequest < AdminRequest
	def do_call()
		raise XError.new(505, 'Wrong parameter') if !params[:user_id] || !params[:build_id] || !params[:pag]
		rt = {}

		build_id = params[:build_id]
		rt[:build_id] = build_id
		che = nil
		che = 1 if params[:che]
		rt[:che] = params[:che] if params[:che]
		floor = nil
		floor = params[:floor].to_i if params[:floor]
		rt[:floor] = params[:floor] if params[:floor]
		ran = nil
		ran = params[:ran].force_encoding('utf-8') if params[:ran]
		rt[:ran] = params[:ran] if params[:ran]

		pag = params[:pag].to_i
		rt[:pag] = params[:pag]

		list = LightController::listLight(@con, build_id, che, floor, ran, pag)

		rt[:lis] = list
		rt[:result] = 1

		rt
	end
end

class LightErrorListRequest < AdminRequest
	def do_call()
		raise XError.new(505, 'Wrong parameter') if !params[:user_id] || !params[:build_id] || !params[:pag]
		rt = {}

		build_id = params[:build_id]
		rt[:build_id] = build_id
		che = nil
		che = 1 if params[:che]
		rt[:che] = params[:che] if params[:che]
		floor = nil
		floor = params[:floor].to_i if params[:floor]
		rt[:floor] = params[:floor] if params[:floor]
		ran = nil
		ran = params[:ran].force_encoding('utf-8') if params[:ran]
		rt[:ran] = params[:ran] if params[:ran]

		pag = params[:pag].to_i
		rt[:pag] = params[:pag]

		list = LightController::listLightError(@con, build_id, che, floor, ran, pag)

		rt[:error_list] = list
		rt[:result] = 1

		rt
	end
end


class LightActiveRequest < AdminRequest
	def do_call()
		$log1.info "LightActiveRequest: #{params}"
		raise XError.new(505, 'Wrong parameter') if !params[:floor] || !params[:build_id] #|| !params[:pag]
		rt = {}

		build_id = params[:build_id]
		rt[:build_id] = build_id
		che = nil
		che = 1 if params[:che]
		
		floor = nil
		floor = params[:floor] if params[:floor]
		rt[:floor] = params[:floor] if params[:floor]
		ran = nil
		#ran = params[:ran].force_encoding('utf-8') if params[:ran]
		#rt[:ran] = params[:ran] if params[:ran]

		#pag = params[:pag].to_i
		#rt[:pag] = params[:pag]

		list = LightController::getactive(@con, build_id, che, floor, ran)

		
		rt[:result] = 1
                rt[:build_id] = build_id
		rt[:che] = params[:che] if params[:che]
                rt[:config_list] = list

		rt
	end
end


class CarSystemRequest < AdminRequest        
	def do_call()
               # $log1.info "CarSystemRequest: #{params}"
                raise XError.new(505, 'Wrong parameter') if !params[:build_id]
		rt = {}

		build_id = params[:build_id]
		rt[:build_id] = build_id
		che = nil
		che = 1 if params[:che]
		rt[:che] = params[:che] if params[:che]
		floor = nil
		floor = params[:floor].to_i if params[:floor]
		rt[:floor] = params[:floor] if params[:floor]
		ran = nil
		ran = params[:ran].force_encoding('utf-8') if params[:ran]
		rt[:ran] = params[:ran] if params[:ran]

		ret = CarController::get_detailInfo(@con, build_id, che, floor, ran)
		rt[:car_par] = ret
		rt[:result] = 1
		rt	
	end
end

class CarListRequest < AdminRequest
	def do_call()

		raise XError.new(505, 'Wrong parameter') if !params[:user_id] || !params[:build_id] || !params[:pag]
		rt = {}

		build_id = params[:build_id]
		rt[:build_id] = build_id
		che = nil
		che = 1 if params[:che]
		rt[:che] = params[:che] if params[:che]
		floor = nil
		floor = params[:floor].to_i if params[:floor]
		rt[:floor] = params[:floor] if params[:floor]
		ran = nil
		ran = params[:ran].force_encoding('utf-8') if params[:ran]
		rt[:ran] = params[:ran] if params[:ran]

		pag = params[:pag].to_i
		rt[:pag] = params[:pag]

		ret = CarController::getCarList(@con, build_id, che, floor, ran, pag)
		rt[:car_list] = ret
		rt[:result] = 1
		rt	
	end
end

class SearchCarposRequest < AdminRequest
	def do_call()
		raise XError.new(505, 'Wrong parameter') if !params[:user_id] || !params[:build_id] || !params[:search]
		rt = {}

		build_id = params[:build_id]
		rt[:build_id] = build_id
		search = params[:search]
		rt[:search] = search
		rt[:result] = 1

		ret = CarController::searchCarpos(@con, build_id, search)
		if ret == nil
			rt[:param] = {} 
			rt[:search_result] = 0
		else
			rt[:param] = ret
			rt[:search_result] = 1
		end

		rt	
	end
end

class OriginPicRequest < PublicRequest
	def do_call()
		if params['uploadfile']
		end

		building_id = $building_id
		info = head.to_s
		
		mac = get_head_param(info, "MAC")
		floor_num = get_head_param(info, "floor")
		major = get_head_param(info, "fenqu")

		major = 0 if major == nil
	end
end

class TLogRequest < PublicRequest
	def do_call

		chart = LightController::getLightLog(@con, 'B0003', 1, nil, nil, nil)
		$log1.info chart
		chart
	end
end
