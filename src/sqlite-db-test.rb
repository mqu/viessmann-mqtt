#!/usr/bin/ruby

$LOAD_PATH.unshift("#{File.dirname(File.expand_path(__FILE__))}/..")
require "main.rb"
require 'sqlite.rb'


db=ViessmannSqlite.new 'viessmann.sqlite'
calc=ViessmanCalc.new 19   # power : 19kw

[ :day, :week, :month, :year].each do |by|

	puts "group by : " + by.to_s
	db.group_by(by).each do |e|
		puts sprintf("- %s : %s kwh / %s€ \n", e[0].to_s, 
			calc.kwh(e[1].to_i), calc.price(e[1].to_i))
	end
	puts "\n"
end


[	:today, :yesterday, 
	:this_week, :last_week,
	:this_month, :last_month, 
	:this_year, :last_year
].each do |_when|
	sum=db.sum(_when)
	puts sprintf("%s: %s kwh / %s€\n", _when.to_s, calc.kwh(sum), calc.price(sum))
end
