#encoding=UTF-8
require 'rmagick'

require 'digest/md5'
require 'fastimage'

include Magick

$bin='01'
$oct='01234567'
$dec='0123456789'
$hex='0123456789abcdef'
$allow='abcdefghijklmnopqrstuvwxyz'
$allup='ABCDEFGHIJKLMNOPQRSTUVWXYZ'
$alpha='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
$alphanum='0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'

class ImgBB

	def self.decode(input, source)
		base = source.length
		digits = input.chars
		(input.length-1).downto(0).inject(0) do |total, power|
			#将字符串转换成10进制的数，先找出某字符在进制中的index，这样就得到一个10进制的数，再乘以几进制对应的几（2进制就乘以2，7进制就乘以7）与位数，如果是千位，则是base的3次方，如果是万位，就是4次方
			total + source.index(digits.shift) * base ** power
		end
	end

	def self.encode(number, target)
		base = target.length
		return target[0] if number == 0
		#通过log这个函数得到位数，比如log（268，10）==2.4281347940287885，可以得到这是个3位数，百位为2，十位为1，个位为0.
		max_power = Math.log(number,base).floor
		remainder = number
		result = max_power.downto(0).inject('') do |r, power|
			#先除以最大位数对应的值（即几进制的几的当前位数的次方）得到最大位数的字符，依次计算，即可得到 所有位数对应的字符
			current, remainder = remainder.divmod(base ** power)
			r << target[current]
		end
		result
	end

	def self.convert(input, source, target)
		encode( decode(input, source), target )
	end

def self.calculate_threshold(img_fn, size)
		begin

			dir_name = File.dirname(img_fn)

			extname = File.extname(img_fn)

			if extname == "gif" or extname == "GIF"
				# gif 比对2帧
			end

			imglist = Magick::Image.read(img_fn)

			rt = []

			imglist.each{ |img|

				img.scale!(size, size)
				img = img.quantize(256, Magick::GRAYColorspace)
				#img = antialias(img)
				img = img.negate(true)

				# record negative image
				newname = File.basename(img_fn, ".*") + "_ck" + File.extname(img_fn)
				#img.write(newname)

				rows = img.rows
				cols = img.columns

				pixels = img.export_pixels(0, 0, cols, rows, "I").map { |p| p / 256 }

				total_pixels = pixels.size
				#p total_pixels
				#p pixels

				#avg_pixels = sum(pixels)
				sum = 0
				pixels.each { |a| sum+=a }
				#p sum
				avg = sum / total_pixels
				#p avg

				result = ''
				pixels.each {|p|
					if p > avg
						result += '1'
					else
						result += '0'
					end
				}

				rt << result
			}

			return rt[0]
		rescue Exception => e
			if $log
				$log.error e.message
				$log.error e.backtrace.inspect
			else
				p e.message
				p e.backtrace.inspect
			end

			return nil
		end
	end

	def self.haming_dist(str1, str2)
		dis = 0
		for i in 0..str1.length-1 do
			if str2[i] && str2[i] == str1[i]
			else    
				dis += 1
			end     
		end         
		dis         
	end

end
