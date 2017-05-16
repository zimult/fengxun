#encoding=UTF-8
#require 'rmagick'

$bin='01'
$oct='01234567'
$dec='0123456789'
$hex='0123456789abcdef'
$allow='abcdefghijklmnopqrstuvwxyz'
$allup='ABCDEFGHIJKLMNOPQRSTUVWXYZ'
$alpha='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
$alphanum='0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'

def decode(input, source)
	base = source.length
	digits = input.chars
	(input.length-1).downto(0).inject(0) do |total, power|
		#将字符串转换成10进制的数，先找出某字符在进制中的index，这样就得到一个10进制的数，再乘以几进制对应的几（2进制就乘以2，7进制就乘以7）与位数，如果是千位，则是base的3次方，如果是万位，就是4次方
		total + source.index(digits.shift) * base ** power
	end
end

def encode(number, target)
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

def convert(input, source, target)
	encode( decode(input, source), target )
end
