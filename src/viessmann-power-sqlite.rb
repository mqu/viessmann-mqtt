#!/usr/bin/ruby

$LOAD_PATH.unshift("#{File.dirname(File.expand_path(__FILE__))}/..")
require "main.rb"

require "pp"
require 'socket'

# my libraries
require 'stack.rb'
require 'timer.rb'
require 'viessman-sock-reader.rb'
require 'sqlite.rb'

#
# insert into Sqlite database every minute : viessmann heater power
# 
# 


timer=Timer.new
v=ViessmannSockReader.new
s=StackSize.new 20
db=ViessmannSqlite.new @config[:global][:sqlite][:db]

at_exit do
	puts "script exiting ... ; time: " + Time.now.strftime("%d/%m/%Y %H:%M\n")
end

# sub thread to collect power every 6 seconds and insert in a limited stack (10) to get average
Thread.new {

	while true do

		p=v.get(:power).to_i
		s.push p
		# puts "main : #{p}"
		timer.sleep 3

	end
}

# main thread : every minutes : get power average and insert into sqlite DB.
while true

	timer.sleep 60
	t=Time.now.to_i
	# sql = sprintf("insert into power values ( %d, DATETIME('now','localtime') );", s.avg.round(2), t)
	db.power_insert s.avg.round(2)

	STDOUT.flush

end

