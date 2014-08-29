#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/lib_domain'
require 'csv'

# SLOC, Time, Number of Sessions, Edited Lines
# Edited Lines > 0
# SLOC > 0

kata_limit = 600
path = Dir.pwd.to_s + "/raw_data.csv"
dataset = {}

# setup output files
if File.exist?(path)
	File.delete(path)
end
file = File.new(path, "a+")
file.puts("KataName,SLOC,NumSessions,secsInKata,EditedLines")

dojo = create_dojo

count = 0
dojo.katas.each do |kata|
	if kata.exercise.name.to_s != "Verbal"
		kata.avatars.active.each do |avatar|
			count += 1

			command = `./cloc-1.62.pl --by-file --quiet --sum-one --csv  #{avatar.path}sandbox/`
			csv = CSV.parse(command)

			#avatar.lights.each do |light|
			#	puts "time: " + (light.time - kata.created).to_s
			#end

			unless(csv.inspect() == "[]")
				if dataset.include?(csv[2][0])
					sloc = dataset[csv[2][0]]
					dataset[csv[2][0]] = sloc.to_i + csv[2][4].to_i
				else
					dataset[csv[2][0]] = csv[2][4]
				end
			end

			if count % 5 == 0
				print "."
			end
			
			if count % 200 == 0
				puts "[#{count}]"
			end
		end
	end
	break if count >= kata_limit
end
puts "[#{count}]"

dataset.each do |kata, sloc|
	puts "language: " + kata.to_s + ", SLOC: " + sloc.to_s
end