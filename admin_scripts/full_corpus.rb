#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/lib_domain'
require File.dirname(__FILE__) + '/meta_kata'

kata_limit = 25
lang_limit = ["Java-1.8_JUnit", "Python-unittest"]
save_file = Dir.pwd.to_s + "/test.csv"

dojo = create_dojo
all_kata = Array.new

count = 0
dojo.katas.each do |kata|
	if kata.exercise.name.to_s != "Verbal" && lang_limit.include?(kata.language.name.to_s)
		kata.avatars.active.each do |avatar|
			count += 1

			mk = MetaKata.new
			mk.id = kata.id
			mk.language = kata.language.name
			mk.participants = kata.avatars.count
			mk.animal = avatar.name
			mk.startdate = kata.created
			mk.name = kata.exercise.name
			mk.path = avatar.path
			mk.totallights = avatar.lights.count
			mk.calc_sloc(avatar.path)
			mk.parse(avatar)

			all_kata.push(mk)

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

MetaKata.new.init_file(save_file)

all_kata.each do |kata|
	kata.save(save_file)
end