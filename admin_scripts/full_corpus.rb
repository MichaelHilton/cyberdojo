#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/lib_domain'
require File.dirname(__FILE__) + '/meta_kata'
require 'thread'

#Constants
SAVE_FILE = Dir.pwd.to_s + "/corpus.csv"
THREADS = 8

#Variables
MetaKata.init_file(SAVE_FILE)
dojo = create_dojo
results = Array.new
work_queue = Queue.new

#Queue
print "\nPopulating Work Queue"
dojo.katas.each do |kata|
	if kata.exercise.name.to_s != "Verbal"
		kata.avatars.active.each do |avatar|
			work_queue.push([kata, avatar])
		end
		print "."
	end
end
print "\nDone Populating Work Queue\n"

#Work
print "\nProcessing Katas"
#Create Threads
workers = (0...THREADS).map do
	Thread.new do
		begin
			while work = work_queue.pop(true)
				mk = MetaKata.new(work[0], work[1])

				#Functions
				mk.calc_cycles
				mk.calc_sloc
				mk.coverage_metrics
				mk.count_tests

				#Debugging
				#mk.to_screen

				#File Output
				results.push(mk.final_output)

				print "."
			end
		rescue ThreadError
			puts "THREAD ERROR"
		end
	end
end
workers.map(&:join)

#Save
f = File.new(SAVE_FILE, "a+")
results.each do |result|
	f.puts(result)
end
