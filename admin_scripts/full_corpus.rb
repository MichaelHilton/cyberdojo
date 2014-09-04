#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/lib_domain'
require File.dirname(__FILE__) + '/meta_kata'
require 'thread'

SAVE_FILE = Dir.pwd.to_s + "/corpus.csv"

MetaKata.init_file(save_file)
dojo = create_dojo
results = Array.new
work_q = Queue.new

dojo.katas.each do |kata|
	if kata.exercise.name.to_s != "Verbal"
		kata.avatars.active.each { |avatar| work_q.push avatar }
	end
end

#Work
workers = (0...8).map do
	Thread.new do
		begin
			while avatar = work_q.pop(true)
				mk = MetaKata.new(kata, avatar)

				#Functions
				mk.calc_cycles
				mk.calc_sloc
				mk.coverage_metrics
				mk.count_tests

				#Debugging
				mk.to_screen

				#File Output
				results.push(mk.final_output)

				print "."
			end
		rescue ThreadError
		end
	end
end
workers.map(&:join)

#Save
f = File.new(SAVE_FILE, "a+")
results.each do |result|
	f.puts(result)
end
