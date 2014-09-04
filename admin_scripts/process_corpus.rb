#!/usr/bin/env ruby

#For optimal processing use JRuby via RVM
#Requires the Gem: 'thread'
#Install: 'gem install thread'

require File.dirname(__FILE__) + '/lib_domain'
require File.dirname(__FILE__) + '/meta_kata'
require 'thread/pool'

#Debugging
DEBUG = false
KATA_LIMIT = 15000
#LANG_LIMIT = ["Java-1.8_JUnit", "Python-unittest"]

#Constants
SAVE_FILE = Dir.pwd.to_s + "/corpus.csv"
THREAD_MIN = 4
THREAD_MAX = 24

#Initialization
MetaKata.init_file(SAVE_FILE)
workers = Thread.pool(THREAD_MIN, THREAD_MAX)
workers.auto_trim!
dojo = create_dojo
results = Array.new
work_queue = Array.new
semaphore = Mutex.new

#Timing
beginning_time = Time.now

#Queue
print "\nPopulating Work Queue\n"
count = 0
dojo.katas.each do |kata|
	unless kata.exercise.name.to_s == "Verbal" #&& lang_limit.include?(kata.language.name.to_s)
		kata.avatars.active.each do |avatar|
			work_queue.push([kata, avatar])
			count += 1
			print "\r " + dots(count)
			break if count >= KATA_LIMIT
		end
		break if count >= KATA_LIMIT
	end
	break if count >= KATA_LIMIT
end

#Worker Threads
print "\nProcessing #{work_queue.size} Katas\n"
count = 0
work_queue.each do |kata, avatar|
	mk = MetaKata.new(kata, avatar)
	workers.process {
		begin
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
				print "\r " + dots(count)
			}
		rescue ThreadError => e
			print "\n\nERROR: #{e} #{e.message}\n\n"
		end	
	}
end

#Wait on Threads to Finish
workers.shutdown

#Save
print "\nSaving Data to File\n"
f = File.new(SAVE_FILE, "a+")
results.each do |result|
	f.puts(result)
end

#Done
end_time = Time.now
elapsed_time = (end_time - beginning_time).to_i
print "\nFinished with #{count} katas processed in #{elapsed_time / 60} minutes and #{elapsed_time % 60} seconds\n\n"
