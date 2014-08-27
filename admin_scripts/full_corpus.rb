#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/lib_domain'
require File.dirname(__FILE__) + '/meta_kata'

kata_limit = 25
lang_limit = ["Java-1.8_JUnit", "Python-unittest"]

dojo = create_dojo

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
			mk.parse(avatar)

			mk.print
		end
	end

	break if count >= kata_limit
end




=begin
mk.id = "234324"
mk.name = "FizzBuzz"
mk.language = "Java_1.8_-_JUnit"
mk.addLight("red", 3, 32)
mk.addLight("green", 9, 144)
mk.print

mk.save(Dir.pwd.to_s+"/test.csv")
=end