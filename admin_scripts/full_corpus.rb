#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/lib_domain'
require File.dirname(__FILE__) + '/meta_kata'

kata_limit = 25
lang_limit = ["Java-1.8_JUnit", "Python-unittest"]
save_file = Dir.pwd.to_s + "/test.csv"

MetaKata.init_file(save_file)

dojo = create_dojo

count = 0
dojo.katas.each do |kata|
	if kata.exercise.name.to_s != "Verbal" && lang_limit.include?(kata.language.name.to_s)
		kata.avatars.active.each do |avatar|
			
			count += 1
			mk = MetaKata.new(kata, avatar)
			#Functions
			mk.calc_cycles
			#mk.calc_sloc
			#mk.coverage_metrics
			mk.print

			mk.save(save_file)

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
