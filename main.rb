#!/usr/bin/ruby

# $DEBUG=true  # for threads errors - http://stackoverflow.com/questions/524019/how-to-get-error-messages-from-ruby-threads

libs=['.', '..', '../lib', 'lib'].each do |lib|
	$LOAD_PATH.unshift lib
end

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
end

@config=nil

# viessmann-mqtt.yaml config file search path :
# - 1 : /etc/
# - 1 : $HOME/.config/
# - 2 : $HOME/viessmann/etc/
[
	"/etc/",
	sprintf("%s/etc/", File.dirname(File.expand_path(__FILE__))),
	sprintf("%s/.config/", ENV['HOME'])	
].reverse.each do |dir|
	file="#{dir}/viessmann-mqtt.yaml"
	if File.exist? file
		if @config==nil
			@config=parse_yaml(file)
		else
			@config.deep_merge parse_yaml(file)
		end
	end
end

throw "sorry : did not found any viessmann-mqtt.yaml configuration file : you need to create one." unless @config

# extra include_path
@config['ruby']['include_path'].split(';').each do |d|
	$LOAD_PATH.unshift d
end

@config[:global][:dir]=File.dirname(File.expand_path(__FILE__))+'/' if @config[:global][:dir]=='auto'

# replace $dir
@config[:global][:sqlite][:db]=@config[:global][:sqlite][:db].gsub('$dir/', @config[:global][:dir])
@config[:global][:startup]=@config[:global][:startup].gsub('$dir/', @config[:global][:dir])
@config[:global][:var][:pid]=@config[:global][:var][:pid].gsub('$dir/', @config[:global][:dir])

# update PID file
file=sprintf("%svar/pid/%s.pid", @config[:global][:dir], File.basename($0.gsub('.rb', '')))
@config[:global][:pid_file]=file
File.write(file, sprintf("%d\n",Process.pid))

# auto-delete pid file at exit
at_exit do
	File.unlink @config[:global][:pid_file]
end
