#!/usr/bin/ruby

$LOAD_PATH.unshift("#{File.dirname(File.expand_path(__FILE__))}/..")
require "main.rb"

device=Dir.glob(@config[:vitalk][:device])[0]

while true
	# puts 'plop'
	
	unless File.exist? device
		now=Time.now.strftime("%d/%m/%Y %H:%M:%S\n")
		puts sprintf("usb-monitoring : USB device not found (%s) ; restarting / %s", device, now)
		
		# run restart script
		system sprintf("%s restart", @config[:global][:startup])
		exit 0
	end
	STDOUT.flush
	sleep 15
end

