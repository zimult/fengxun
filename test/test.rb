require 'socket'
require 'ffi'
require 'json'

require_relative '../xerror'

module MyLib
	extend FFI::Library
	ffi_lib FFI::Library::LIBC
	attach_function :puts, [ :string ], :int
	attach_function :read, [ :int, :string, :int ], :int
	#attach_function :printf, [ :string ], :int
end

timen = Time.new
p timen.strftime('%H%M%S')

url = "http://192.168.0.100:8421/pic/00/30aea402fa38_0.jpg"
idx = url.index('pic/')
file = url[idx+4..-1]
p file

w = '7'
if w == '7'
	p w
elsif w == '0'
	p '0'
else
	p ''
end

MyLib.puts 'Hello, World using libc!'

host = '127.0.0.1'
port = 8422
msg="\x48\x56\x78"  
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
		p "send return #{r}"

		buf = ''	
		#buf = "\0" * 1024
		#p buf
		count = MyLib.read(s.fileno, buf, 1024)
		if count == -1
			#p 'Timeout'
			raise XError.new(100, 'Timeout')
		end
		s.close
		ret = {"result"=>1, "send"=>r, "recv":"#{buf}"}
	end   
rescue => e
	p XError::format_error(e)
	p e.backtrace.inspect

	ret = {"result"=>0}
end
rt = ret.to_json
p rt
