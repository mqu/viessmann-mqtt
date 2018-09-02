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

def main mqtt, opts, v
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
		puts "topic=#{topic}/#{message}"
		case topic
		
		when /temp\/room\/normal/
			puts "setting normal-temp : #{message}"
			v.set :norm_room_temp, message.to_i

		when /temp\/room\/low/
			puts "setting reduce-temp : #{message}"
			v.set :red_room_temp, message.to_i

		when /settings\/eco-mode/
			puts "setting eco-mode : #{message}"
			if(message.to_i==1)
				puts "1"
				v.set :eco_mode, message.to_i				
				v.set :party_mode, 0				
			else
				puts "2"
				v.set :eco_mode, message.to_i
			end
		when /settings\/party-mode/
			puts "setting party-mode : #{message}"
			if(message.to_i==1)
				puts "1"
				v.set :eco_mode, 0				
				v.set :party_mode, 1				
			else
				puts "2"
				v.set :party_mode, 0
			end

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


while true do
	begin
		client.connect() do |mqtt|
			puts "connected to MQTT server"
			main mqtt, opts, v
		end 
	rescue MQTT::ProtocolException, Errno::ECONNREFUSED  => e # may receive MQTT::ProtocolException ; Errno::ECONNREFUSED
		puts "exception from MQTT ; retrying ..."
		puts e.to_s
		pp e
		sleep 5
		# retry to connect and process
		retry
	end
	
	# we may never get here.
	puts "disconnected from MQTT ; trying to reconnect"
	sleep 5
end

exit 0

client.connect() do |mqtt|
   puts "connected"
   main mqtt, opts, v
end
