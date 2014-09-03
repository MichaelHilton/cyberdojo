#!/usr/bin/env ruby

INPUT = './corpus_withTestFails.csv'
OUTPUT = './corpus_withTestFails_scored.csv'
KATA_LIMIT = 150000
SUPP_LANGS = ["Java-1.8_JUnit", "Python-unittest"]
DEBUG = false

#Data Ordering Constants
ID = 0
LANGUAGE = 1
KATA = 2
PARTICIPANTS = 3
ANIMAL = 4
PATH = 5
DATE = 6
TOTAL_TIME = 7
TOTAL_LIGHTS = 8
RED_LIGHTS = 9
GREEN_LIGHTS = 10
AMBER_LIGHTS = 11
#CONSECUTIVE_REDS = 12
TOTAL_LINES = 12
LINES_EDITED = 13
TOTAL_TESTS = 14
TOTAL_RUN_TESTS = 15
TOTAL_FAILS = 16
CYCLO_COMPLEX = 17
BRANCH_COVERAGE = 18
STATEMENT_COVERAGE = 19
CYCLES = 20
ENDS_ON_GREEN = 21
LIGHT_DATA = 22
CYCLE_JSON = 23

count = 0

f = File.open(OUTPUT, "w")

#Process each kata
File.readlines(INPUT).each_with_index do |kata, index|

	#Write header and skip to next line
	if index == 0
		kata = kata.chomp
		f.puts("#{kata}|TDDScore")
		next
	end

	#Split metrics into an Array
	metric = kata.split('|')

	#Skip if lang not supported
	next unless SUPP_LANGS.include?metric[LANGUAGE]

	#Skip if covereage == NA
	next if metric[STATEMENT_COVERAGE] == "NA"

	#Skip if not FizzBuzz
	#next if metric[KATA] == "FizzBuzz"

	#Skip if cycles is under a minimum
	#next if metric[CYCLES].to_i < 8

	#Not excluded so increment counter
	count += 1

	#==BEGIN SCORING METRICS==
	tdd_score = 0
	code_coverage = 0
	cycle_score = 0
	edit_score = 0
	time_score = 0
	test_score = 0

unless metric[CYCLES].to_i == 0

	#CODE COVERAGE SCORE
	code_coverage = metric[STATEMENT_COVERAGE].to_f

	#CYCLE SCORE
	unless metric[CYCLES].to_f > metric[TOTAL_LINES].to_f

		#total cycles / total lines (ideally normalized based on the language)
		cycle_score = 1 - ((0.3 - (metric[CYCLES].to_f / metric[TOTAL_LINES].to_f)) * 2).abs
		cycle_score = 0 if cycle_score < 0
		cycle_score = 1 if cycle_score > 1

	end

	#EDIT SCORE
	unless metric[LINES_EDITED].to_f < metric[CYCLES].to_f

		#lines edited / cycles
		edit_score = 1 - (((metric[LINES_EDITED].to_f / metric[CYCLES].to_f) - 25).abs / 100)
		edit_score = 0 if edit_score < 0
		edit_score = 1 if edit_score > 1

	end

	#TIME SCORE
	#total time / cycles
	if (metric[TOTAL_TIME].to_f / metric[CYCLES].to_f) <= 30
		time_score = 1
	else
		time_score = (1 - (((metric[TOTAL_TIME].to_f / metric[CYCLES].to_f) - 30) / (15 * 60)))
	end
	time_score = 0 if time_score < 0
	time_score = 1 if time_score > 1

	#TEST_SCORE
	if metric[TOTAL_TESTS].to_i == metric[CYCLES].to_i
		test_score = 1
	elsif metric[TOTAL_TESTS].to_i > metric[CYCLES].to_i
		test_score = (1 - ((((metric[TOTAL_TESTS].to_f - metric[CYCLES].to_f) / metric[CYCLES].to_f) * 30) / 100))
	else
		test_score = (1 - ((((metric[CYCLES].to_f - metric[TOTAL_TESTS].to_f) / metric[CYCLES].to_f) * 100) / 100))
	end
	test_score = 0 if test_score < 0
	test_score = 1 if test_score > 1

end
	#==END SCORING METRICS==

	#==BEGIN SCORE CALCULATION==
	tdd_score = (((code_coverage) + (cycle_score) + (edit_score) + (time_score) + (test_score)) / 5) * 100
	#==END SCORE CALCULATION==

	#Debug
	if DEBUG == true
		puts metric[ID]
		puts "cycles: #{metric[CYCLES]}, lines: #{metric[TOTAL_LINES]} edits: #{metric[LINES_EDITED]}, time: #{metric[TOTAL_TIME]}, tests: #{metric[TOTAL_TESTS]}"
		puts "Coverage: #{code_coverage}"
		puts "Cycle: #{cycle_score}"
		puts "Edit: #{edit_score}"
		puts "Time: #{time_score}"
		puts "Test: #{test_score}"
		puts "SCORE: #{tdd_score}"
		puts
	end

	#File Output
	kata = kata.chomp
	f.puts("#{kata}|#{tdd_score}")

	#Break if limit has been hit
	break if count >= KATA_LIMIT
end
