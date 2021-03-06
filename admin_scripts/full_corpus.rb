#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/lib_domain'
require File.dirname(__FILE__) + '/meta_kata'
require 'thread'

#Debugging
DEBUG = false
KATA_LIMIT = 250000000
LANG_LIMIT = ["Java-1.8_JUnit", "Python-unittest"]

#Constants
SAVE_FILE = Dir.pwd.to_s + "/corpus.csv"
THREADS = 8

#Variables
MetaKata.init_file(SAVE_FILE)
dojo = create_dojo
results = Array.new
work_queue = Queue.new
semaphore = Mutex.new

#Timing
beginning_time = Time.now

#Queue
print "\nPopulating Work Queue\n"
count = 0
dojo.katas.each do |kata|
	if kata.exercise.name.to_s != "Verbal" #&& lang_limit.include?(kata.language.name.to_s)
		kata.avatars.active.each do |avatar|
			work_queue.push([kata, avatar])
			count += 1
		end
		print "\r " + dots(count)

		break if count >= KATA_LIMIT
	end
	break if count >= KATA_LIMIT
end

#Work
print "\nProcessing Katas\n"
count = 0
#Create Threads
workers = (0...THREADS).map do
	Thread.new do
		begin
			while work = work_queue.pop(true) rescue nil
				mk = MetaKata.new(work[0], work[1])

				#Functions
				mk.calc_cycles
				mk.calc_sloc
				mk.coverage_metrics
				mk.count_tests

				#Debugging
				mk.to_screen if DEBUG == true

				#File Output
				results.push(mk.final_output)

				#Print Progress Count
				semaphore.synchronize {
					count += 1
				}
				print "\r " + dots(count)
			end
		rescue ThreadError => e
			print e
		end
	end
end

#Join remaining workers
#workers.map(&:join)
workers.each { |w| w.join }

#Save
f = File.new(SAVE_FILE, "a+")
results.each do |result|
	f.puts(result)
end

#Done
end_time = Time.now
elapsed_time = (end_time - beginning_time).to_i
print "\nFinished with #{count} katas processed in #{elapsed_time / 60} minutes and #{elapsed_time % 60} seconds\n"
