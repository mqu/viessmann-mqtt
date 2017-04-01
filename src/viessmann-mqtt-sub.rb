#!/usr/bin/ruby

$LOAD_PATH.unshift("#{File.dirname(File.expand_path(__FILE__))}/..")

require "main.rb"

require "pp"
require 'mqtt'

# my libraries
require 'stack.rb'
require 'viessman-sock-reader.rb'
require 'timer.rb'

at_exit do
	puts "script exiting ... ; time: " + Time.now.strftime("%d/%m/%Y %H:%M\n")
end

v=ViessmannSockReader.new
timer=Timer.new

client = MQTT::Client.new
client.host = @config[:mqtt][:host]
client.port = @config[:mqtt][:port]
client.username = @config[:mqtt][:user]
client.password = @config[:mqtt][:password]

# options for MQTT subject
opts={
	:location => @config[:mqtt][:location],
	:device => {
		:name => @config[:mqtt][:device][:name],
		:type => @config[:mqtt][:device][:type]
	}
}


client.connect() do |mqtt|
   puts "connected"
 
   base=sprintf('v1/%s/objects/%s', opts[:location], opts[:device][:name])
   puts "base=#{base}\n"

   topics=[]
   topics << sprintf("%s/data/settings/power/mode", base)
   topics << sprintf("%s/data/settings/temp/room/normal", base)
   topics << sprintf("%s/data/settings/temp/room/low", base)
   topics << sprintf("%s/data/settings/eco-mode", base)
   topics << sprintf("%s/data/settings/party-mode", base)

   puts "subscribing topics="
   pp topics

   mqtt.subscribe(topics)

   while true  do

	mqtt.get do |topic,message|
	
		case topic
		
		when /temp\/room\/normal/
			puts "setting normal-temp : #{message}"
			v.set :norm_room_temp, message.to_i

		when /temp\/room\/low/
			puts "setting reduce-temp : #{message}"
			v.set :red_room_temp, message.to_i

		when /settings\/eco-mode/
			puts "setting eco-mode : #{message}"
			v.set :eco_mode, message.to_i

		when /settings\/party-mode/
			puts "setting party-mode : #{message}"
			v.set :party_mode, message.to_i

		when /power\/mode/
			  # Block is executed for every message received
			  puts "received #{topic}=#{message}"
			  case message
				when '0'
				   puts 'off'
				   v.set :mode, 0
				when '1'
				   puts 'on'
				   v.set :mode, 2
				else
					puts "did not understood command ...?"
			  end
		end
	end

	STDOUT.flush

	timer.sleep 60
   end
   
end
