#!/usr/bin/env ruby

INPUT = './corpus.csv'
OUTPUT = './corpus_scored.csv'
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
TOTAL_LINES = 12
LINES_EDITED = 13
TOTAL_TESTS = 14
CYCLO_COMPLEX = 15
BRANCH_COVERAGE = 16
STATEMENT_COVERAGE = 17
CYCLES = 18
ENDS_ON_GREEN = 19
LIGHT_DATA = 20
CYCLE_JSON = 21

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

	#Not excluded so increment counter
	count += 1

	#==BEGIN SCORING METRICS==
	tdd_score = 0
	code_coverage = 0
	cycle_score = 0
	edit_score = 0
	time_score = 0
	test_score = 0

	#CODE COVERAGE SCORE
	#already provided
	code_coverage = metric[STATEMENT_COVERAGE].to_f

	unless metric[TOTAL_LINES] == 0

		#CYCLE SCORE
		#total cycles / total lines (ideally normalized based on the language)
		cycle_score = (0.25 - (metric[CYCLES].to_f / metric[TOTAL_LINES].to_f)).abs * 4

	end

	unless metric[CYCLES].to_i == 0

		#EDIT SCORE
		#lines edited / cycles
		edit_score = (25 - (metric[LINES_EDITED].to_f / metric[CYCLES].to_f)).abs / 100

		#TIME SCORE
		#total time / cycles
		time_score = 30 / (30 - (metric[TOTAL_TIME].to_f / metric[CYCLES].to_f)).abs

		#TEST SCORE
		#total tests / cycles
		test_score = (1 - (metric[CYCLES].to_f - metric[TOTAL_TESTS].to_f).abs / metric[CYCLES].to_f).abs

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
