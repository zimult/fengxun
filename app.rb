require 'rubygems'
require 'sinatra'
require 'thin'
require 'sinatra/base'
#require 'sinatra/reloader' if development?
require 'json'
require 'date'
require 'haml'
require 'logger'
require 'rufus-scheduler'
require 'socket'
require 'ffi'

require_relative 'app2'
require_relative 'fx_request'
require_relative 'xerror'
require_relative 'mysock'

#module LibC
#  extend DL::Importer
#  dlload 'libc.so.6'
#  extern 'long read(int, void *, long)'
#end
module MyLib
	extend FFI::Library
	ffi_lib FFI::Library::LIBC
	#attach_function :puts, [ :string ], :int
	attach_function :read, [ :int, :string, :int ], :int
	#attach_function :printf, [ :string ], :int
end

configure do
	set :bind, '0.0.0.0'
	#set :port, 4568
	set :server, "thin"

	enable :logging
	disable :flash
	disable :sessions
	use Rack::Session::Cookie,
	:key => 'key',
	:secret => 'jtwmydtsgx',
	:expire_after => $FansPieLoginExpire, # In seconds
	# DONT KNOW WHY IT WON'T WORK, COMMENT OUT DOMAIN ENABLES COOKIES
	# #   :domain => $FansPieDomain, 
	:path => '/'
	set :scheduler, Rufus::Scheduler.new
	$log = Logger.new('./log/fx.log', 'daily')
	$log.level = Logger::INFO

	$log1 = Logger.new('./log/fx1.log', 'daily')
	$log1.level = Logger::INFO
	#Qiniu.establish_connection! :access_key => $qiniu_access_key, :secret_key => $qiniu_secret_key

       # scheduler.cron '/1 * * * *' do
        #$log1.info "beefind test!"
        #scheduler.join
end

set :environment, :production

def respack
	{:code=>false, :result=>nil, :error=>nil, :time=>DateTime.now.strftime("%Y-%m-%d %H:%M:%S")}
end
def jsonize(indata)
	#indata.to_s.encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'})
	data = indata.to_json
	#deflated = Zlib::Deflate.deflate(data)
	#data = Zlib::Inflate.inflate(deflated)
	#  $log.info("#{deflated.size}, #{data.size}")
	return data
rescue Encoding::UndefinedConversionError
	puts $!.error_char.dump
	p $!.error_char.encoding
end

get '/sock' do
	host = '127.0.0.1'
	port = 8422
	msg="\x48\x56\x78"  
	$log1.info "/sock"

	sock = connect_sock(host, port)
	$log1.info "connect_sock ret:${sock}"

	sock.close
end


post '/connection' do
        $log1.info params
	begin
		req = ConnectionRequest.new(session, request, request.env, params)
		ret = req.call()
	rescue => e
		err = XError::format_error(e)
		$log1.error err
		ret = {:result => 0}
	end
	json_ret = jsonize(ret)
	json_ret	
end

post '/Setdata' do
        $log1.info params
	begin
		req = SetdataRequest.new(session, request, request.env, params)
		ret = req.call()
	rescue => e
		err = XError::format_error(e)
		$log1.error err
		ret = {:result => 0}
	end
	json_ret = jsonize(ret)
	json_ret	
end

post '/active' do
        $log1.info params
	begin
		req = ActiveRequest.new(session, request, request.env, params)
		ret = req.call()
	rescue => e
		err = XError::format_error(e)
		$log1.error err
		ret = {:result => 0}
	end
	json_ret = jsonize(ret)
	json_ret	
end


get '/hello' do
		filename = "/var/www/fx/pic/240ac401cc10_3.jpg"
		filename2 = "pic/240ac401cc10_3.txt"
		card = "AAAAA"
	

		sleep(0.03)
		$log.info "---- #{filename}, #{filename2}, #{card} save."
		return card
end

get '/pict' do
	uri = URI('http://127.0.0.1:8422/knum')
	fn = "240ac401cc10_1.jpg"
	params = {:file=>fn}
	uri.query = URI.encode_www_form(params)
	response = Net::HTTP.get(uri)
	response
end

post '/listmac2' do
	#ret = respack
	begin

		req = ListMacRequest.new(session, request, request.env, params)
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
	json_ret
end

post '/uploadpic2' do
	#ret = respack
	begin

	$log.info "uploadpic begin"
	#$log.info request.env

		req = UpPicRequest.new(session, request, request.env, params)
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
	#$log.info "uploadpic ret:#{ret}"
	ret
end

post '/update/postfile' do
	begin

		$log.info "postfile begin"

		req = UpFileRequest.new(session, request, request.env, params)
		ret = req.call()
	rescue => e
		err = XError::format_error(e)
		$log1.error err
		ret = {:result => 0}
	end

	json_ret = jsonize(ret)
	#$log.info "postfile ret:#{json_ret}"
	json_ret
end


post '/getmac' do
      begin
 		req = GetmacRequest.new(session, request, request.env, params)
		ret = req.call()
      rescue => e
		#ret[:code] = 0
		err = XError::format_error(e)
		#ret[:error] = err[:message]
		$log1.error err
      end
        json_ret = jsonize(ret)
	$log1.info json_ret
	json_ret
end


post '/addmac' do
      begin
 		req = AddmacRequest.new(session, request, request.env, params)
		ret = req.call()
      rescue => e
		#ret[:code] = 0
		err = XError::format_error(e)
		#ret[:error] = err[:message]
		$log1.error err
      end
        json_ret = jsonize(ret)
	$log1.info json_ret
	json_ret
end


post '/update/getverson' do
	begin

		$log.info "getverson begin"
		req = GetVersonRequest.new(session, request, request.env, params)
		ret = req.call()
	rescue => e
		err = XError::format_error(e)
		$log.error err
		ret = {:result => 0}
	end

	json_ret = jsonize(ret)
	$log.info "getverson ret:#{json_ret}"
	json_ret
end

post '/cameraConfig2' do
	begin

		req = CameraConfigRequest.new(session, request, request.env, params)
		ret = req.call()
	rescue => e
		err = XError::format_error(e)
		$log.error err
		ret = {:result => 0}
	end

	rt = ret.to_json
end

post '/lightParam' do

	begin
		req = LightParamRequest.new(session, request, request.env, params)
		ret = req.call()
	rescue => e
		err = XError::format_error(e)
		$log.error err
		ret = 'r:0'
	end

	return ret
end

post '/login' do
	"success"
end

