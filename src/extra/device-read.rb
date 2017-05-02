#!/usr/bin/ruby

# read device.yaml
require 'pp'
require 'yaml'

def parse_yaml file

	begin
	  content=YAML.load(File.open(file))
	rescue ArgumentError => e
	  puts "Could not parse YAML file (#{file}: #{e.message}"
	  exit 0
	end
	return content
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

file='device.yaml'
conf=parse_yaml(file).symbolize

pp conf
pp conf[:addr][:mode]
