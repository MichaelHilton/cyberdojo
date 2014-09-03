#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/lib_domain'
require 'csv'

class MetaKata
	attr_reader :sloc, :ccnum, :branchcov, :statementcov, :redlights, :greenlights, :amberlights, :cycles, :ends_green, :transitions, :id, :language, :participants, :animal, :start_date, :name, :path, :totallights, :total_time, :total_lines, :totaltests, :runtests, :runtestfails, :test_loc, :production_loc

	def initialize(kata, avatar)
		@kata = kata
		@avatar = avatar
		@path = avatar.path

		@TIME_CEILING = 1200 # Time Ceiling in Seconds Per Light
		@supp_test_langs = ["Java-1.8_JUnit", "Java-1.8_Mockito", "Java-1.8_Approval", "Java-1.8_Powermockito", "Python-unittest", "Python-pytest", "Ruby-TestUnit", "Ruby-Rspec", "C++-assert", "C++-GoogleTest", "C++-CppUTest", "C++-Catch", "C-assert", "Go-testing", "Javascript-assert", "C#-NUnit", "PHP-PHPUnit", "Perl-TestSimple", "CoffeeScript-jasmine", "Erlang-eunit", "Haskell-hunit", "Scala-scalatest", "Clojure-.test", "Groovy-JUnit", "Groovy-Spock"]
		@supp_fail_langs = ["Java-1.8_JUnit"]

		@id = kata.id
		@language = kata.language.name
		@participants = kata.avatars.count
		@animal = avatar.name
		@start_date = kata.created
		@name = kata.exercise.name
		@path = avatar.path
		@sloc = 0
		@test_loc = 0
		@production_loc = 0
		@edited_lines = 0
		@ccnum = ""
		@branchcov = ""
		@statementcov = ""
		@totallights = avatar.lights.count
		@totaltests = 0
		@runtests = 0
		@runtestfails = 0
		@redlights = 0
		@greenlights = 0
		@amberlights = 0
		@consecutive_reds = 0
		@cycles = 0
		@ends_green = 0
		@total_time = 0
		@transitions = ""
		@json_cycles = ""
		@json_tests = ""

	end

	def to_screen
		#Set NA for Metrics not available
		@totaltests = "NA" unless @supp_test_langs.include?@language
		@runtestfails = "NA" unless @supp_fail_langs.include?@language
		@ccnum = "NA" if @ccnum == ""
		@branchcov = "NA" if @branchcov == ""
		@statementcov = "NA" if @statementcov == ""

		puts "id: #{@id}, language: #{@language}, name: #{@name}, participants: #{@participants}, path: #{@path}, start date: #{@start_date}, seconds in kata: #{@total_time}, total lights: #{@totallights}, red lights: #{@redlights}, green lights: #{@greenlights}, amber lights: #{@amberlights}, consecutive reds: #{@consecutive_reds}, sloc: #{@sloc}, test_loc: #{@test_loc}, production_loc: #{@production_loc}, edited lines: #{@edited_lines}, total tests: #{@totaltests}, total run tests: #{runtests}, run test fails: #{runtestfails}, code coverage: #{@ccnum}, branch coverage: #{@branchcov}, statement coverage: #{@statementcov}, num cycles: #{@cycles}, ending in green: #{@ends_green}, light data: #{@transitions}, json cycles: #{@json_cycles}"
	end

	def self.init_file(path)
		if File.exist?(path)
			File.delete(path)
		end

		f = File.new(path, "a+")
		f.puts("KataID|Language|KataName|NumParticipants|Animal|Path|StartDate|secsInKata|TotalLights|RedLights|GreenLights|AmberLights|ConsecutiveReds|SLOC|EditedLines|TotalTests|TotalRunTests|RunTestFails|CCNum|BranchCoverage|StatementCoverage|NumCycles|EndsInGreen|LightData|JsonCycles")
	end

	def save(path)
		#Set NA for Metrics not available
		@totaltests = "NA" unless @supp_test_langs.include?@language
		@runtestfails = "NA" unless @supp_fail_langs.include?@language		
		@ccnum = "NA" if @ccnum == ""
		@branchcov = "NA" if @branchcov == ""
		@statementcov = "NA" if @statementcov == ""

		f = File.new(path, "a+")
		f.puts("#{@id}|#{@language}|#{@name}|#{@participants}|#{@animal}|#{@path}|#{@start_date}|#{@total_time}|#{@totallights}|#{@redlights}|#{@greenlights}|#{@amberlights}|#{@consecutive_reds}|#{@sloc}|#{@edited_lines}|#{@totaltests}|#{@runtests}|#{@runtestfails}|#{@ccnum}|#{@branchcov}|#{@statementcov}|#{@cycles}|#{@ends_green}|#{@transitions}|#{@json_cycles}")
	end

	def deleted_file(lines)
    	return lines.all? { |line| line[:type] === :deleted }
	end

	def new_file(lines)
    	return lines.all? { |line| line[:type] === :added }
	end

	def calc_sloc
		dataset = {}
		Dir.entries(@path.to_s + "sandbox").each do |currFile|
			isFile = currFile.to_s =~ /\.java$|\.py$|\.c$|\.cpp$|\.js$|\.php$|\.rb$|\.hs$|\.clj$|\.go$|\.scala$|\.coffee$|\.cs$|\.groovy$\.erl$/i			
			unless isFile.nil?
				file = @path.to_s + "sandbox/" + currFile.to_s			
				command = `./cloc-1.62.pl --by-file --quiet --sum-one --exclude-list-file=./clocignore --csv #{file}`
				csv = CSV.parse(command)
				unless(csv.inspect() == "[]")						
					if @language.to_s == "Java-1.8_JUnit"
					if File.open(file).read.scan(/junit/).count > 0
							@test_loc = @test_loc + csv[2][4].to_i
						else						
							@production_loc = @production_loc + csv[2][4].to_i
						end
					end
					@sloc = @sloc + csv[2][4].to_i	
				end
			end
		end
	end

	def count_tests
		Dir.entries(@path.to_s + "sandbox").each do |currFile|
			isFile = currFile.to_s =~ /\.java$|\.py$|\.c$|\.cpp$|\.js$|\.php$|\.rb$|\.hs$|\.clj$|\.go$|\.scala$|\.coffee$|\.cs$|\.groovy$\.erl$/i
			
			unless isFile.nil?
				file = @path.to_s + "sandbox/" + currFile.to_s
				case @language.to_s
				when "Java-1.8_JUnit"
					if File.open(file).read.scan(/junit/).count > 0					
						@totaltests += File.open(file).read.scan(/@Test/).count
					end
				when "Java-1.8_Mockito"
					if File.open(file).read.scan(/org\.mockito/).count > 0					
						@totaltests += File.open(file).read.scan(/@Test/).count
					end
				when "Java-1.8_Powermockito"
					if File.open(file).read.scan(/org\.powermock/).count > 0					
						@totaltests += File.open(file).read.scan(/@Test/).count
					end
				when "Java-1.8_Approval"
					if File.open(file).read.scan(/org\.approvaltests/).count > 0					
						@totaltests += File.open(file).read.scan(/@Test/).count
					end					
				when "Python-unittest"
					if File.open(file).read.scan(/unittest/).count > 0
						@totaltests += File.open(file).read.scan(/def /).count
					end
				when "Python-pytest"
					if file.include?"test"
						@totaltests += File.open(file).read.scan(/def /).count
					end					
				when "Ruby-TestUnit"
					if File.open(file).read.scan(/test\/unit/).count > 0
						@totaltests += File.open(file).read.scan(/def /).count
					end
				when "Ruby-Rspec"
					if File.open(file).read.scan(/describe/).count > 0
						@totaltests += File.open(file).read.scan(/it /).count
					end
				when "C++-assert"
					if File.open(file).read.scan(/cassert/).count > 0
						@totaltests += File.open(file).read.scan(/static void /).count
					end
				when "C++-GoogleTest"
					if File.open(file).read.scan(/gtest\.h/).count > 0
						@totaltests += File.open(file).read.scan(/TEST\(/).count
					end
				when "C++-CppUTest"
					if File.open(file).read.scan(/CppUTest/).count > 0
						@totaltests += File.open(file).read.scan(/TEST\(/).count
					end
				when "C++-Catch"
					if File.open(file).read.scan(/catch\.hpp/).count > 0
						@totaltests += File.open(file).read.scan(/TEST_CASE\(/).count
					end				
				when "C-assert"
					if File.open(file).read.scan(/assert\.h/).count > 0
						@totaltests += File.open(file).read.scan(/static void /).count
					end								
				when "Go-testing"
					if File.open(file).read.scan(/testing/).count > 0
						@totaltests += File.open(file).read.scan(/func /).count
					end
				when "Javascript-assert"
					if File.open(file).read.scan(/assert/).count > 0
						@totaltests += File.open(file).read.scan(/assert/).count - 2 #2 extra because of library include line
					end					
				when "C#-NUnit"
					if File.open(file).read.scan(/NUnit\.Framework/).count > 0
						@totaltests += File.open(file).read.scan(/\[Test\]/).count
					end
				when "PHP-PHPUnit"
					if File.open(file).read.scan(/PHPUnit_Framework_TestCase/).count > 0
						@totaltests += File.open(file).read.scan(/function /).count
					end
				when "Perl-TestSimple"
					if File.open(file).read.scan(/use Test/).count > 0
						@totaltests += File.open(file).read.scan(/is/).count
					end
				when "CoffeeScript-jasmine"
					if File.open(file).read.scan(/jasmine-node/).count > 0
						@totaltests += File.open(file).read.scan(/it/).count
					end
				when "Erlang-eunit"
					if File.open(file).read.scan(/eunit\.hrl/).count > 0
						@totaltests += File.open(file).read.scan(/test\(\)/).count
					end
				when "Haskell-hunit"
					if File.open(file).read.scan(/Test\.HUnit/).count > 0
						@totaltests += File.open(file).read.scan(/TestCase/).count
					end
				when "Scala-scalatest"
					if File.open(file).read.scan(/org\.scalatest/).count > 0
						@totaltests += File.open(file).read.scan(/test\(/).count
					end
				when "Clojure-.test"
					if File.open(file).read.scan(/clojure\.test/).count > 0
						@totaltests += File.open(file).read.scan(/deftest/).count
					end
				when "Groovy-JUnit"
					if File.open(file).read.scan(/org\.junit/).count > 0
						@totaltests += File.open(file).read.scan(/@Test/).count
					end
				when "Groovy-Spock"
					if File.open(file).read.scan(/spock\.lang/).count > 0
						@totaltests += File.open(file).read.scan(/def /).count - 1 #1 extra because of object def
					end
				else
					@totaltests = "NA"
				end
			end
		end
	end

	def count_fails(prev, curr)

		#Take Diff
	    if prev.nil? #If no previous light use the beginning
		    diff = @avatar.tags[0].diff(curr.number)
		else
			diff = @avatar.tags[prev.number].diff(curr.number)
		end

		diff.each do |filename, content|
			if filename.include?"output"
				content.each do |line|

					case @language.to_s
					when "Java-1.8_JUnit"
						re = /\{:type=>:(added|same), :line=>\"Tests run: (?<tests>\d+),  Failures: (?<fails>\d+)\", :number=>\d+\}/
						result = re.match(line.to_s)
						
						unless result.nil?
							@runtests += result['tests'].to_i
							@runtestfails += result['fails'].to_i
						end
					end
				end
			end
		end

	end

	def calc_lines(prev, curr)
	    # determine number of lines changed between lights
	    test_count = 0
	    code_count = 0
	    is_test = false

	    if prev.nil? #If no previous light use the beginning
		    diff = @avatar.tags[0].diff(curr.number)
		else
			diff = @avatar.tags[prev.number].diff(curr.number)
		end

		diff.each do |filename,lines|

			isFile = filename.match(/\.java$|\.py$|\.c$|\.cpp$|\.js$|\.php$|\.rb$|\.hs$|\.clj$|\.go$|\.scala$|\.coffee$|\.cs$|\.groovy$\.erl$/i)

		    unless isFile.nil? || deleted_file(lines) || new_file(lines)
		    	lines.each do |line|
					case @language.to_s
					when "Java-1.8_JUnit"
						is_test = true if /junit/.match(line.to_s)
					when "Java-1.8_Mockito"
						is_test = true if /org\.mockito/.match(line.to_s)
					when "Java-1.8_Powermockito"
						is_test = true if /org\.powermock/.match(line.to_s)
					when "Java-1.8_Approval"
						is_test = true if /org\.approvaltests/.match(line.to_s)			
					when "Python-unittest"
						is_test = true if /unittest/.match(line.to_s)
					when "Python-pytest"
						is_test = true if filename.include?"test"			
					when "Ruby-TestUnit"
						is_test = true if /test\/unit/.match(line.to_s)
					when "Ruby-Rspec"
						is_test = true if /describe/.match(line.to_s)
					when "C++-assert"
						is_test = true if /cassert/.match(line.to_s)
					when "C++-GoogleTest"
						is_test = true if /gtest\.h/.match(line.to_s)
					when "C++-CppUTest"
						is_test = true if /CppUTest/.match(line.to_s)
					when "C++-Catch"
						is_test = true if /catch\.hpp/.match(line.to_s)		
					when "C-assert"
						is_test = true if /assert\.h/.match(line.to_s)							
					when "Go-testing"
						is_test = true if /testing/.match(line.to_s)
					when "Javascript-assert"
						is_test = true if /assert/.match(line.to_s)				
					when "C#-NUnit"
						is_test = true if /NUnit\.Framework/.match(line.to_s)
					when "PHP-PHPUnit"
						is_test = true if /PHPUnit_Framework_TestCase/.match(line.to_s)
					when "Perl-TestSimple"
						is_test = true if /use Test/.match(line.to_s)
					when "CoffeeScript-jasmine"
						is_test = true if /jasmine-node/.match(line.to_s)
					when "Erlang-eunit"
						is_test = true if /eunit\.hrl/.match(line.to_s)
					when "Haskell-hunit"
						is_test = true if /Test\.HUnit/.match(line.to_s)
					when "Scala-scalatest"
						is_test = true if /org\.scalatest/.match(line.to_s)
					when "Clojure-.test"
						is_test = true if /clojure\.test/.match(line.to_s)
					when "Groovy-JUnit"
						is_test = true if /org\.junit/.match(line.to_s)
					when "Groovy-Spock"
						is_test = true if /spock\.lang/.match(line.to_s)
					else
						#Language not supported
					end

					break if is_test == true
		    	end #End of Lines For Each

		    	#POSSIBLE TODO: Add bag to check for double counting of edited lines
				if is_test
		        	test_count += lines.count { |line| line[:type] === :added }
		        	test_count += lines.count { |line| line[:type] === :deleted }
		        else
		    		code_count += lines.count { |line| line[:type] === :added }
		        	code_count += lines.count { |line| line[:type] === :deleted }
		        end
		        
		        is_test = false		    	
		    end #End of Unless statment
		end #End of Diff For Each

	    return test_count, code_count
	end

    def calc_cycles
    	prev_outer = nil
    	prev_cycle_end = nil
        test_change = false
        prod_change = false
        in_cycle = false
        cycle = ""
        cycle_lights = Array.new
        cycle_test_edits = 0
        cycle_code_edits = 0
		cycle_total_edits = 0          
		cycle_test_change = 0
		cycle_code_change = 0
        cycle_reds = 0
        cycle_time = 0		
        first_cycle = true

        #Start Json Array
        @json_cycles += '['

        @avatar.lights.each_with_index do |curr, index|

            #Push light to queue
            cycle_lights.push(curr)
            
            #Aquire file changes from light
            if prev_outer.nil?
                diff = @avatar.tags[0].diff(curr.number)
                test_change = true
            else
                diff = @avatar.tags[prev_outer.number].diff(curr.number)
            end

            #Check for changes to Test or Prod code
            diff.each do |filename,content|
                non_code_filenames = [ 'output', 'cyber-dojo.sh', 'instructions' ]
                unless non_code_filenames.include?(filename)
                    if content.count { |line| line[:type] === :added } > 0 || content.count { |line| line[:type] === :deleted } > 0
                    	#Check if file is a Test
                        if (filename.include?"Test") || (filename.include?"test") || (filename.include?"Spec") || (filename.include?"spec") || (filename.include?".t") || (filename.include?"Step") || (filename.include?"step")
                            test_change = true
                        else
                            prod_change = true
                        end
                    end
                end
            end #End of Diff For Each

            #Green indicates end of cycle, also process if at last light
            if curr.colour.to_s == "green" || index == @avatar.lights.count - 1

                #Determine the type of cycle
                if (test_change && !prod_change) || (!test_change && prod_change) || (!test_change && !prod_change)
                    cycle = "R" #Refactor if changes are exclusive to production or test files
                else
                	if in_cycle == true && curr.colour.to_s == "green"
                    	cycle = "TP" #Test-Prod
                    else
                    	cycle = "R"
                    end
                end

                #Begin Json Cycle Light Data
                if cycle == "TP"
                	if first_cycle == true
						@json_cycles += '{"lights":['
						first_cycle = false
					else
						@json_cycles += ',{"lights":['
					end
				end

				prev = nil
                # Process Metrics & Output Data
                cycle_lights.each_with_index do |light, light_index|

                    #Count Lines Modified in Light, Cycle & Kata
                    #Lines Modified in Light
                    if prev.nil? #If no previous light in this cycle use the last cycle's end
                    	test_edits, code_edits = calc_lines(prev_cycle_end, light)
                    else
                    	test_edits, code_edits = calc_lines(prev, light)
                    end
                	#Total Lines Modified in Cycle    
                    cycle_test_edits += test_edits
                    cycle_code_edits += code_edits
                	#Total Lines Modified in Kata    
                    @edited_lines += test_edits
                    @edited_lines += code_edits
                    light_edits = code_edits + test_edits
                    cycle_total_edits += light_edits

                    #Determine Time Spent in Light
                    if prev_cycle_end.nil? && prev.nil? #If the first light of the Kata
                        time_diff = light.time - @start_date
                    else
                    	if prev.nil? #If the first light of the Cycle
                    		time_diff = light.time - prev_cycle_end.time
                    	else
                        	time_diff = light.time - prev.time
                        end
                    end

                    #Drop Time if it hits the Time Ceiling
                    if time_diff > @TIME_CEILING
                        time_diff = 0
                    end

                    #Increment Time
                    @total_time += time_diff
                    cycle_time += time_diff
                    
                    #Count Types of Lights
                    case light.colour.to_s
                    when "red"
                        @redlights += 1
                        cycle_reds += 1
                    when "green"
                        @greenlights += 1
                    when "amber"
                        @amberlights += 1
                    end

                    #Count Failed Tests
                    if prev.nil? #If no previous light in this cycle use the last cycle's end
                    	count_fails(prev_cycle_end, light)
                    else
                    	count_fails(prev, light)
                    end                    

                    #Eliminate Unsupported Stats
					unless @supp_test_langs.include?@language
						light_edits = "NA"
						test_edits = "NA"
						code_edits = "NA"
						cycle_total_edits = "NA"
						cycle_test_edits = "NA"
						cycle_code_edits = "NA"
						cycle_test_change = "NA"
						cycle_code_change = "NA"
					end

                    #Output
                    if (cycle == "TP")
                    	if light_index == 0
                    		@json_cycles += '{"color":"'
                    	else
                    		@json_cycles += ',{"color":"'
                    	end
                    	@json_cycles += light.colour.to_s + '","totalEdits":' + light_edits.to_s + ',"testEdits":' + test_edits.to_s + ',"codeEdits":' + code_edits.to_s + ',"time":' + time_diff.to_s + '}'
                        @transitions += "+" + "{" + light.colour.to_s + ":" + light_edits.to_s + ":" + test_edits.to_s + ":" + code_edits.to_s + ":" + time_diff.to_s + "}"
                    elsif cycle == "R"
                        @transitions += "~" + "{" + light.colour.to_s + ":" + light_edits.to_s + ":" + test_edits.to_s + ":" + code_edits.to_s + ":" + time_diff.to_s + "}"
                    end

                    #Assign current light to previous
                    prev = light
                end #End of For Each

                #If this was a TP Cycle then process it accordingly
                if cycle == "TP"
                	#Set consecutive reds if new maximum
	                if cycle_reds > @consecutive_reds
   	             		@consecutive_reds = cycle_reds
  	            	end
  	            	#Count changes to Test and Code from diff of entire cycle
  	            	cycle_test_change, cycle_code_change = calc_lines(prev_cycle_end, curr)
  	            	#Output Json Cycle Summary
                	@json_cycles += '],"totalCycleEdits":' + cycle_total_edits.to_s + ',"totalCycleTestEdits":' + cycle_test_edits.to_s + ',"totalCycleCodeEdits":' + cycle_code_edits.to_s + ',"cycleTestChanges":' + cycle_test_change.to_s + ',"cycleCodeChanges":' + cycle_code_change.to_s + ',"totalCycleTime":' + cycle_time.to_s + '}'
                	#Increment Cycle Counter
                    @cycles += 1
                #elsif cycle == "R"
                	#Refactor
                end

                #Reset Cycle Metrics
                test_change = false
        		prod_change = false
        		in_cycle = false
        		cycle_test_change = 0
        		cycle_code_change = 0
        		cycle_test_edits = 0
        		cycle_code_edits = 0  
        		cycle_total_edits = 0      		
        		cycle_time = 0
        		cycle_reds = 0
        		cycle_lights.clear

        		prev_cycle_end = curr
                    
            elsif curr.colour.to_s == "red"
            	in_cycle = true
            end #End of "If Green"

            prev_outer = curr

        end #End of For Each

        #End Json Array
        @json_cycles += ']'

        #Determine if Kata Ends on Green
        if @avatar.lights[@avatar.lights.count - 1].colour.to_s == "green"
            @ends_green = 1
        else
            @ends_green = 0
        end

    end

	def coverage_metrics
		case @language.to_s
		when "Java-1.8_JUnit"
			if File.exist?(@path + 'CodeCoverageReport.csv')
				codeCoverageCSV = CSV.read(@path + 'CodeCoverageReport.csv')
				unless(codeCoverageCSV.inspect() == "[]")
					@branchcov = codeCoverageCSV[2][6]
					@statementcov = codeCoverageCSV[2][16]
				end
			end
			cyclomaticComplexity = `./javancss "#{@path + "sandbox/*.java"}" 2>/dev/null`
			@ccnum = cyclomaticComplexity.scan(/\d/).join('')
		when "Python-unittest"
			if File.exist?(path + 'sandbox/pythonCodeCoverage.csv')
				codeCoverageCSV = CSV.read(@path+ 'sandbox/pythonCodeCoverage.csv')
				#NOT SUPPORTED BY PYTHON LIBRARY
				#branchCoverage = codeCoverageCSV[1][6]
				@statementcov = (codeCoverageCSV[1][3].to_f)/100
				codeCoverageCSV = CSV.read(@path+ 'sandbox/pythonCodeCoverage.csv')
				@ccnum = codeCoverageCSV[1][4]
			end
		end
	end

	private :new_file, :deleted_file, :calc_lines

end