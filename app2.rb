#require_relative 'app'
require_relative 'fx_request'
require_relative 'fx_request_admin'
require_relative 'xerror'

get '/tlog' do
	begin

		req = TLogRequest.new(session, request, request.env, params)
		ret = req.call()
	rescue => e
		err = XError::format_error(e)
		$log1.error err
		ret = {:result => 0}
	end

	rt = ret.to_json
end

post '/listmac' do
	#ret = respack
	begin

		req = ListMac2Request.new(session, request, request.env, params)
		ret = req.call()
		#ret[:code] = 1 if ret[:result]
	rescue => e
		err = XError::format_error(e)

		#ret[:code] = 0
		#ret[:error] = err[:message]
		nl = []
		ret = {"token"=>"0", "param"=>nl}
		$log.error err
	end

	json_ret = jsonize(ret)
	$log.info json_ret
	json_ret
end

post '/sendBaseImage' do
	#ret = respack
	begin

		req = SendBaseImageRequest.new(session, request, request.env, params)
		ret = req.call()
		#ret[:code] = 1 if ret[:result]
	rescue => e
		err = XError::format_error(e)
		ret = {"result"=>0}
		$log.error err
	end

	json_ret = jsonize(ret)
	$log.info json_ret
	json_ret
end

post '/checkBaseImage' do
	#ret = respack
	begin

		req = CheckBaseImg2Request.new(session, request, request.env, params)
		ret = req.call()
		#ret[:code] = 1 if ret[:result]
	rescue => e
		err = XError::format_error(e)
		ret = {"result"=>0}
		$log.error err
	end

	json_ret = jsonize(ret)
	$log.info json_ret
	json_ret
end


post '/uploadpic' do
	#ret = respack
	begin

	#$log1.info "uploadpic begin"
	#$log.info request.env

		req = UpPic2Request.new(session, request, request.env, params)
		ret = req.call()
		#ret[:code] = 1 if ret[:result]
	rescue => e
		#ret[:code] = 0
		err = XError::format_error(e)
		#ret[:error] = err[:message]
		$log1.error err
		ret = "KM10"
	end

	#json_ret = jsonize(ret)
	$log.info "uploadpic ret:#{ret}, #{ret.class}"
	ret
end

post '/cameraConfig' do
        begin
                req = CameraConfig2Request.new(session, request, request.env, params)
                ret = req.call()
        rescue => e
                err = XError::format_error(e)
                $log1.error err
                ret = {:result => 0}
        end

        rt = ret.to_json
end

post '/cameraParam' do
	begin

		req = CameraParam2Request.new(session, request, request.env, params)
		ret = req.call()
		#ret[:code] = 1 if ret[:result]
	rescue => e
		err = XError::format_error(e)
		$log.error err
		ret = {:result => 0}
	end

	rt = ret.to_json
end

post '/admin/buildAdd' do
       #$log1.info params
	begin
		req = BuildAddAdminRequest.new(session, request, request.env, params)
		ret = req.call()
	rescue => e
		err = XError::format_error(e)
		#$log.error err
                $log1.error err
		ret = {:result => 0}
	end

	rt = ret.to_json
end

post '/buildingFloors' do
	begin
		req = BuildingFloorsRequest.new(session, request, request.env, params)
		ret = req.call()
	rescue => e
		err = XError::format_error(e)
		$log.error err
		ret = {:result => 0}
	end

	rt = ret.to_json
	
end

post '/lightSetMode' do
	begin
		req = LightSetModeRequest.new(session, request, request.env, params)
		ret = req.call()
	rescue => e
		err = XError::format_error(e)
		$log1.error err
                ret = {:result => 0}
	end

	rt = ret.to_json
	$log.info rt
	rt
end

post '/buildmangerList' do
	begin
		req = BuildManagerRequest.new(session, request, request.env, params)
		ret = req.call()
	rescue => e
		err = XError::format_error(e)
		$log.error err
		ret = {:result => 0}
	end

	rt = ret.to_json
end

post '/buildmangerList' do
	begin
		req = BuildManagerRequest.new(session, request, request.env, params)
		ret = req.call()
	rescue => e
		err = XError::format_error(e)
		$log.error err
		ret = {:result => 0}
	end

	rt = ret.to_json
end

post '/buldmanagerDetail' do
	begin
		req = BuildManagerDetailRequest.new(session, request, request.env, params)
		ret = req.call()
	rescue => e
		err = XError::format_error(e)
		$log.error err
		ret = {:result => 0}
	end

	rt = ret.to_json
end

post '/buildAddDeviceList' do
	begin
		req = BuildAddDeviceListRequest.new(session, request, request.env, params)
		ret = req.call()
	rescue => e
		err = XError::format_error(e)
		$log1.error err
		ret = {:result => 0}
	end

	rt = ret.to_json
end

post '/buildAddCarList' do
	begin
		req = BuildAddCarListRequest.new(session, request, request.env, params)
		ret = req.call()
	rescue => e
		err = XError::format_error(e)
		$log.error err
		ret = {:result => 0}
	end

	rt = ret.to_json
end

post '/buildGetCarList' do
	begin
		req = BuildGetCarListRequest.new(session, request, request.env, params)
		ret = req.call()
	rescue => e
		err = XError::format_error(e)
		$log.error err
		ret = {:result => 0}
	end

	rt = ret.to_json
end

post '/buildGetDeviceList' do
	begin
		req = BuildGetDeviceListRequest.new(session, request, request.env, params)
		ret = req.call()
	rescue => e
		err = XError::format_error(e)
		$log.error err
		ret = {:result => 0}
	end

	rt = ret.to_json
end

post '/buildingList' do
        
	begin
		req = BuildingListRequest.new(session, request, request.env, params)
		ret = req.call()
	rescue => e
		err = XError::format_error(e)
		$log1.error err
		ret = {:result => 0}
	end

	rt = ret.to_json
end

post  '/lightSystem' do
	begin
		req = LightSystemRequest.new(session, request, request.env, params)
		ret = req.call()
	rescue => e
		err = XError::format_error(e)
		$log1.error err
		ret = {:result => 0}
	end

	rt = ret.to_json
end

post '/lightList' do
	begin
		req = LightListRequest.new(session, request, request.env, params)
		ret = req.call()
	rescue => e
		err = XError::format_error(e)
		$log.error err
		ret = {:result => 0}
	end

	rt = ret.to_json

end

post '/lightErrorList' do
	begin
		req = LightErrorListRequest.new(session, request, request.env, params)
		ret = req.call()
	rescue => e
		err = XError::format_error(e)
		$log.error err
		ret = {:result => 0}
	end

	rt = ret.to_json

end

post '/lightActive' do
         $log1.info params
	begin
		req = LightActiveRequest.new(session, request, request.env, params)
		ret = req.call()
	rescue => e
		err = XError::format_error(e)
		$log1.error err
		ret = {:result => 0}
	end
        $log1.info ret.to_json
	rt = ret.to_json

end


post '/carSystem' do
      
	begin
		req = CarSystemRequest.new(session, request, request.env, params)
		ret = req.call()
	rescue => e
		err = XError::format_error(e)
		$log1.error err
		ret = {:result => 0}
	end

	rt = ret.to_json
end

post '/carList' do
	begin
		req = CarListRequest.new(session, request, request.env, params)
		ret = req.call()
	rescue => e
		err = XError::format_error(e)
		$log1.error err
		ret = {:result => 0}
	end

	rt = ret.to_json
end

post '/searchCarpos' do
	begin
		req = SearchCarposRequest.new(session, request, request.env, params)
		ret = req.call()
	rescue => e
		err = XError::format_error(e)
		$log1.error err
		ret = {:result => 0}
	end

	rt = ret.to_json
end

post '/originPic' do
	begin
		req = OriginPicRequest.new(session, request, request.env, params)
		ret = req.call()
	rescue => e
		err = XError::format_error(e)
		$log1.error err
		ret = "rt:0"
	end

	ret
end

