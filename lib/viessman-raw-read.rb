#!/usr/bin/ruby

require 'viessman-sock-reader'

class ViessmannRawTcpClient

	def initialize
		@v=ViessmannSockReader.new
	end

	def type_to_len type
		case type
			when :byte, :bool
				return 1

			when :short,:addr
				return 2

			when :int4, :addr4, :raw4
				return 4

			when :raw8, :addr8, :systime
				return 8
		end
	end

	def cmd cmd
		# puts "cmd : " + cmd
		@v.puts cmd.to_s
		@v.gets
	end

    # rs <addr> <value> - Raw Set Parameter by address 
	def raw_set value, addr, type
		addr = sprintf("0x%04X",addr) if addr.is_a? Fixnum
		v=self.cmd sprintf("rs %s %s", addr.to_s, len.to_s)
	end

	def systime v
		# sample packets :
		#[ 0x20, 0x15, 0x04, 0x11, 0x06, 0x19, 0x21, 0x26  ]
		#  0    1    2    3    4    5    6    7
		# 0,1 = 20.15 -> 2015
		# 2: month = 4=april
		# 3: day=11
		# 4=week day : 0=sunday, 1:monday, ...
		# 5=hour : 0x19 -> 19h
		# 6:min  : 0x21 -> 21mn
		# 7:sec  : 0x26 -> 26 seconds.
		# see : https://github.com/taupinfada/vcontrold/blob/master/unit.c#L137
		return sprintf("%02X/%02X/%02X%02X %02X:%02X:%02X", v[3].ord, v[2].ord, v[0].ord, v[1].ord, v[5].ord, v[6].ord, v[7].ord)
	end

	def raw_read addr, type=byte, mult=1
		addr = sprintf("0x%04X",addr) if addr.is_a? Fixnum
		len=self.type_to_len type

		# send a raw-get command to vitalk
		# rg <addr> <len> - Raw Get Parameter ; len limited to 8 bytes
		v=self.cmd sprintf("rg %s %s", addr.to_s, len.to_s)
		v=v.gsub('$','').split(';').collect{|x| x=x.to_i}

		case type
			when :byte
				return v[0].ord*mult
			when :addr
				return "0x"+v.pack("C*").unpack('s>')[0].to_s(16)
			when :short
				return 1.0*v.reverse.pack("C*").unpack('s>')[0]/mult
			when :int4
				return v.reverse.pack("C*").unpack('l>')[0]
			when :systime
				return systime v
			when :raw4, :raw8
				return v
			else
				throw "unsupported type:#{type} for ViessmannRawRead::raw_read() method"
		end

	end
end
