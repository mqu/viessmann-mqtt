#!/usr/bin/ruby

libdir="/home/marc/ruby/lib"
$LOAD_PATH.unshift libdir

require 'sqlite3'

#
# specific and simplified interface to Sqlite and ViessmannSqlite to manage power statistics
#
class Sqlite

	def initialize db='db.sqlite'
		File.exists? db or throw "Sqlite database #{db} not found"
		@db=SQLite3::Database.new(db)
	end
	
	def select sql
		tries=5
		begin
			@db.select sql
		rescue => e
			puts "Sqlite::select(): received exception " + e.to_s
			puts  Time.now.strftime("%d/%m/%Y %H:%M\n")

			if (tries -= 1) > 0
				puts "Sqlite::select(): retring"
				sleep 0.5
				retry
			else
				puts "Sqlite::select(): max retrying ; aborting"
			end
		end
	end

	def execute sql
		tries=5
		begin
			# @db.select sql
			@db.execute sql
		rescue => e
			puts "Sqlite::execute(): received exception " + e.to_s
			puts  Time.now.strftime("%d/%m/%Y %H:%M\n")

			if (tries -= 1) > 0
				puts "Sqlite::execute(): retring"
				sleep 0.5
				retry
			else
				puts "Sqlite::execute(): max retrying ; aborting"
			end
		end
	end

	def get_all sql
		self.execute sql
	end

	def get_one sql
		# puts "Sqlite::get_one(#{sql})"
		res = self.execute sql
		throw "Sqlite : SQL error : should return only 1 row '#{sql}' but is #{res.size}" if res.size!=1
		res[0]
	end
	
	def _when _when=nil
		case _when
		
			when nil
				return ''
				
			when :today
				from = "datetime('now', 'localtime', 'start of day')"
				to   = "datetime('now', 'localtime')"

			when :yesterday
				from = "datetime('now', 'localtime', 'start of day', '-1 day')"
				to   = "datetime('now', 'localtime', 'start of day')"

			# weekday 0 ->sunday
			when :this_week
				from = "datetime('now', 'localtime', 'start of day',  'weekday 0')"
				to   = "datetime('now', 'localtime')"

			when :last_week
				from = "datetime('now', 'localtime', 'start of day',  'weekday 0', '-7 days')"
				to   = "datetime('now', 'localtime', 'start of day',  'weekday 0')"
  
			when :this_month
				from = "datetime('now', 'localtime', 'start of month')"
				to   = "datetime('now', 'localtime')"

			when :last_month
				from = "datetime('now', 'localtime', 'start of month', '-1 month')"
				to   = "datetime('now', 'localtime', 'start of month')"

			when :this_year
				from = "datetime('now', 'localtime', 'start of year')"
				to   = "datetime('now', 'localtime')"

			when :last_year
				from = "datetime('now', 'localtime', 'start of year', '-1 year')"
				to   = "datetime('now', 'localtime', 'start of year')"

			# return all values / AVG
			else
				throw "don't know what to do here ; case error:'#{_when}'"

		end
		
		where=sprintf(" WHERE time BETWEEN %s AND %s", from, to)

	end
end

# table initialisation (not dynamic)
#
#  CREATE TABLE `power` (
#    `power`INTEGER,
#    `time`DATETIME
#   );
#

class ViessmannSqlite < Sqlite

	def power_insert value
		sql = sprintf("insert into power values ( %d, DATETIME('now','localtime') );", value.to_i)
		self.execute sql
	end

	def select sql, _when
		where=self._when(_when)
		res=self.get_one(sql+ ' ' +where)
	end

	def count _when=nil
		sql="SELECT COUNT(power) FROM power"
		where=self._when(_when)
		self.array_error_and_0(self.get_one(sql+ ' ' +where))
	end

	# return 'power' AVG from table 'power'
	def avg _when=nil
		sql="SELECT AVG(power) FROM power"
		where=self._when(_when)
		self.array_error_and_0(self.get_one(sql+ ' ' +where))
	end

	# return 'power' SUM from table 'power'
	def sum _when=nil
		sql="SELECT SUM(power) FROM power"
		where=self._when(_when)
		self.array_error_and_0(self.get_one(sql+ ' ' +where))
	end
		
	def array_error_and_0 res
		return 0 if res==nil
		return 0 if res==[nil]
		return res[0]	
	end

	def group_by period
		case period
			when :day
				s='j'
			when :week
				s='W'
			when :month
				s='m'
			when :year
				s='y'
			else
				throw "don't know what to  do here with period=#{period.to_}"
		end
		
		sql=sprintf("
			SELECT strftime('%%%s', time) as day, SUM(power) 
			FROM power 
			GROUP BY strftime('%%%s', time);
			ORDER BY day LIMIT 100",
			s,s).gsub(/[\n\t]+/,' ').strip;
		self.get_all sql
	end

	def todo

	# http://stackoverflow.com/questions/9322313/how-to-group-by-week-no-and-get-start-date-and-end-date-for-the-week-number-in-s

	# group by weeks
	#   SELECT strftime('%W', time), SUM(power) FROM power
	#   GROUP BY strftime('%W', time);

	# group by day number
	#   SELECT strftime('%j', time), SUM(power) FROM power
	#   GROUP BY strftime('%j', time);
	
	end
end

# calculate from power % collected every minutes in sqlite power table.
# 
class ViessmanCalc

	def initialize power=19, price=0.05310

		@power=power  # power in kw

		# price for gaz in €/kwh
		# https://www.fournisseurs-electricite.com/france/169-infos/18348-prix-kwh-gaz
		@price=price # price by kwh

		@coef=1.0*@power/60  # power in watt/60
		@coef=@coef/100  # kw->w ; and percents -> gives kw/mn/percent
		# @coef=@coef*1.04        # coef d'ajustement compte gaz -> kw mesure par chaudiere

	end
	
	def kwh sum
		return (sum*@coef).round(2)
	end

	def price sum
		return (sum*@coef*@price).round(2)
	end
end
