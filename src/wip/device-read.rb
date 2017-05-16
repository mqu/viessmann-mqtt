#!/usr/bin/ruby

libdir="../../lib"
$LOAD_PATH.unshift libdir


# read device.yaml
require 'pp'
require 'yaml'

require 'viessman-raw-read.rb'

class ViessmanCommand

	def initialize name, opts
		@name=name
		@opts=opts
	end

	def self.to_hex val, digits=4
		sprintf("0x%0#{digits}X", val)
	end

	def name
		@name
	end
	
	# mandatory field
	def addr
		throw "mandatory field 'addr' for #{@name} command" unless  @opts.key? :addr
		return @opts[:addr]
	end

	def type
		throw "mandatory field 'type' for #{@name} command" unless  @opts.key? :type
		return @opts[:type][0]
	end

	def mode default=:ro
		throw "mandatory field 'mode' for #{@name} command" unless  @opts.key? :type
		return @opts[:type][1]
	end

	def mult default=1
		return @opts[:mult] if @opts.key? :mult
		return default
	end

	# commands categories
	def cat default=[]
		return @opts[:cat] if @opts.key? :cat
		return default
	end
	alias category cat

	def unit default=''
		return @opts[:unit] if @opts.key? :unit
		return default
	end

	def enums default=[]
		return @opts[:enums] if @opts.key? :enums
		return default
	end


	def description default=''
		return @opts[:description] if @opts.key? :description
		return default
	end

	def path default=nil
		throw "mandatory field 'path' for #{@name} command" unless  @opts.key? :type
		return @opts[:path] if @opts.key? :path
	end

	def in_range? value
		return self.range.include? value
	end

	def range default=[]
		return Range.new(@opts[:range][0], @opts[:range][1]) if @opts.key? :range
		return default
	end

	def raw_read viessmann
		if self.type==:enum
			return self.enums[viessmann.raw_read self.addr, self.type]
		else
			return viessmann.raw_read self.addr, self.type, self.mult
		end
	end

	# fixme
	def to_text v
	  return sprintf("0x%04X : %s (%s) : %s", 
			   self.addr, 
			   self.mode,
			   self.type,
			   self.raw_read(v)
				)
	end

end


class Hash
    def deep_merge(second)
        merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
        self.merge(second, &merger)
    end

	def _symbolize(obj, k=nil)
		
		return obj if k=='description'
		return obj if obj.is_a? Fixnum

		return obj.inject({}){|memo,(k,v)| memo[k.to_sym] =  _symbolize(v, k); memo} if obj.is_a? Hash
		return obj.inject([]){|memo,v    | memo           << _symbolize(v, k); memo} if obj.is_a? Array

		if obj.is_a?(String) && obj.tr(' -','_').downcase.match(/^[a-zA-Z][a-zA-Z_]+/)
				return obj.tr(' -', '_').downcase.to_sym
		end	
		return obj
	end

    def symbolize
		_symbolize self
    end
end

class Viessman

	def initialize file

		# handler to vitalk raw read and get
		@v=ViessmannRawTcpClient.new
		
		# 
		@conf=parse_yaml(file).symbolize

		@commands={}

		@conf[:addr].each do |k,v|
			@commands[k]=ViessmanCommand.new(k, v)
		end
	end
	def method_missing(sym, *args)
		return @commands[sym].raw_read(@v) if @commands.key? sym
		throw "error : unkown command(method) (#{sym})"
	end

	def parse_yaml file
		begin
			return YAML.load(File.open(file))
		rescue ArgumentError => e
		  puts "Could not parse YAML file (#{file}: #{e.message}"
		  exit 0
		end
	end

	def get key
		throw "error" unless @commands.key? key
		return @commands[key].raw_read(@v)
	end

	def cmd key
		pp key
		throw "cmd(): error : unknown key value #" unless @commands.key? key
		return @commands[key]
	end

	def methods
		@commands.keys
	end
	
	def raw_read addr, type, mult=nil
		return @v.raw_read(addr, type.to_sym) if mult==nil
		return @v.raw_read(addr, type.to_sym)/mult
	end

	def raw_write addr, type, value, mult=nil
		return @v.raw_write(addr, type.to_sym, value) if mult==nil
		return @v.raw_write(addr, type.to_sym, value*mult)
	end
	
	def each
		@commands.each do |k,cmd|
			yield cmd
		end
	end
end

v=Viessman.new 'device-20CB.yaml'

# outdoor_temp=#{v.raw_read 0x0800, :short, 10}"
# pp v.raw_read 0x0800, :byte, 10.0
# pp v.raw_read '0x0800', 'byte', 10.0

# normal room temp
# pp v.raw_read 0x23060, 'byte', 10.0

#  curve_slope:
# pp v.raw_read 0x27D3, :short, 10
# pp v.raw_write 0x27D3, :short, 1.1, 10
# pp v.raw_read 0x27D3, :short, 10

#  reduce_room_temp:
#    addr:	0x2307
#    type:	[byte,rw]
# pp v.raw_read 0x2307, :byte
# pp v.raw_write 0x2307, :byte, 13
# pp v.raw_read 0x2307, :byte

# eco_mode : 0x2331
# pp v.raw_read 0x2331, :byte

# party_mode : 0x2330
# pp v.raw_read 0x2330, :byte
# pp v.raw_write 0x2330, :bool, true
# pp v.raw_read 0x2330, :byte

# mode
#pp pp v.raw_read 0x2323, :byte
# pp pp v.raw_write 0x2323, :byte, 2
# pp pp v.raw_read 0x2323, :byte


# device-id
# puts "device_id=#{v.raw_read 0x00F8, :addr}"

# https://github.com/smbunn/Viessmann-Control/blob/master/vito-old.xml#L294
# https://sourceforge.net/p/vcontrold/code/HEAD/tree/branches/vcontrold_fn_ipv6/xml-32/xml_p300/vito.xml#l1072

list= [
 [0x2000, 0x2008, 0x2010, 0x2018, 0x2020, 0x2028, 0x2030],
 [0x2100, 0x2108, 0x2110, 0x2118, 0x2120, 0x2128, 0x2130],
 [0x2200, 0x2208, 0x2210, 0x2218, 0x2220, 0x2228, 0x2230]
]

list.each do |l|
  l.each do |addr|
     pp v.raw_read addr, :raw8
  end
end
exit 0


# for earch commands ...
v.each do |cmd|

  puts sprintf("0x%04X : %s (%s) : %s : %s\n", 
           cmd.addr, 
           cmd.mode,
           cmd.type,
           cmd.name,
           v.get(cmd.name)
           )
   
end

exit 0

