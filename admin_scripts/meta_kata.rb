#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/lib_domain'
require 'csv'

class MetaKata
	attr_reader :sloc, :ccnum, :branchcov, :statementcov, :redlights, :greenlights, :amberlights, :cycles, :ends_green, :transitions, :id, :language, :participants, :animal, :start_date, :name, :path, :totallights, :total_time, :total_lines, :totaltests

	def initialize(kata, avatar)
		@kata = kata
		@avatar = avatar
		@path = avatar.path

		@TIME_CEILING = 1200 # Time Ceiling in Seconds Per Light

		@id = kata.id
		@language = kata.language.name
		@participants = kata.avatars.count
		@animal = avatar.name
		@start_date = kata.created
		@start_cycle = start_date
		@name = kata.exercise.name
		@path = avatar.path
		@sloc = 0
		@edited_lines = 0
		@ccnum = ""
		@branchcov = ""
		@statementcov = ""
		@totallights = avatar.lights.count
		@totaltests = 0
		@redlights = 0
		@greenlights = 0
		@amberlights = 0
		@cycles = 0
		@ends_green = false
		@total_time = 0
		@transitions = ""
		@cycle_lines = 0
	end

	def print
		puts "id: #{@id}, language: #{@language}, name: #{@name}, participants: #{@participants}, path: #{@path}, start date: #{@start_date}, seconds in kata: #{@total_time}, total lights: #{@totallights}, red lights: #{@redlights}, green lights: #{@greenlights}, amber lights: #{@amberlights}, sloc: #{@sloc}, edited lines: #{@edited_lines}, total tests: #{@totaltests}, code coverage: #{@ccnum}, branch coverage: #{@branchcov}, statement coverage: #{@statementcov}, num cycles: #{@cycles}, ending in green: #{@ends_green}, #{@transitions}"
	end

	def self.init_file(path)
		if File.exist?(path)
			File.delete(path)
		end

		f = File.new(path, "a+")
		f.puts("KataID,Language,KataName,NumParticipants,Animal,Path,StartDate,secsInKata,TotalLights,RedLights,GreenLights,AmberLights,SLOC,EditedLines,TotalTests,CCNum,BranchCoverage,StatementCoverage,NumCycles,EndsInGreen,LightData")
	end

	def save(path)
		#TEMP FIX UNTIL OTHER LANG ARE SUPPORTED IN CYCLE LOGIC
		supported_langs = ['Java-1.8_JUnit', 'Python-unittest']
		unless supported_langs.include?(@language)
			@cycles = "NA"
		end
		#END TEMP FIX

		f = File.new(path, "a+")
		f.puts("#{@id},#{@language},#{@name},#{@participants},#{@animal},#{@path},#{@start_date},#{@total_time},#{@totallights},#{@redlights},#{@greenlights},#{@amberlights},#{@sloc},#{@edited_lines},#{@totaltests},#{@ccnum},#{@branchcov},#{@statementcov},#{@cycles},#{@ends_green},#{@transitions}")
	end

	def deleted_file(lines)
    	lines.all? { |line| line[:type] === :deleted }
	end

	def new_file(lines)
    	lines.all? { |line| line[:type] === :added }
	end

	def calc_sloc
		#command = `./cloc-1.62.pl --by-file --quiet --sum-one --csv  #{avatar.path}sandbox/`
		#	csv = CSV.parse(command)


		# Lines of Code (using sloccount)
		Dir.entries(@path.to_s + "sandbox").each do |currFile|
			isFile = currFile.to_s =~ /\.java$|\.py$|\.c$|\.cpp$|\.js$|\.h$|\.hpp$/i
			
			unless isFile.nil?
				file = @path.to_s + "sandbox/" + currFile.to_s
				# the `shell command` does not capture error messages sent to stderr
        
				command = `sloccount --details #{file}`
				value = command.split("\n").last
				@sloc += value.split(" ").first.to_i
			end
		end
	end

	def count_tests
		Dir.entries(@path.to_s + "sandbox").each do |currFile|
			isFile = currFile.to_s =~ /\.java$|\.py$|\.c$|\.cpp$|\.js$|\.h$|\.hpp$/i
			
			unless isFile.nil?
				file = @path.to_s + "sandbox/" + currFile.to_s
				case @language.to_s
				when "Java-1.8_JUnit"
					@totaltests += File.open(file).read.scan(/@Test/).count
				when "Python-unittest"
					if File.open(file).read.scan(/import unittest/).count > 0
						@totaltests += File.open(file).read.scan(/def/).count
					end
				else
					@totaltests = nil
				end
			end
		end
	end

	def calc_lines(prev, curr)
	    # determine number of lines changed between lights
	    line_count = 0;

	    if prev.nil?
		    diff = @avatar.tags[0].diff(curr.number)
		else
			diff = @avatar.tags[prev.number].diff(curr.number)
		end

		diff.each do |filename,lines|
		    non_code_filenames = [ 'output', 'cyber-dojo.sh', 'instructions' ]
		    if !non_code_filenames.include?(filename) && !deleted_file(lines) && !new_file(lines)
		        line_count += lines.count { |line| line[:type] === :added }
		        line_count += lines.count { |line| line[:type] === :deleted }
		        #TODO: ADD A FILES CHANGED PER CYCLE COUNTER
		    end
		end

	    return line_count
	end

    def calc_cycles
    	prev = nil
        test_change = false
        prod_change = false
        in_cycle = false
        cycle = ""
        cycle_lights = Array.new

        @avatar.lights.each_with_index do |curr, index|

            #Push light to queue
            cycle_lights.push(curr)
            
            #Aquire file changes from light
            if prev.nil?
                diff = @avatar.tags[0].diff(curr.number)
            else
                diff = @avatar.tags[prev.number].diff(curr.number)
            end

            #Check for changes to Test or Prod code
            diff.each do |filename,content|
                non_code_filenames = [ 'output', 'cyber-dojo.sh', 'instructions' ]
                unless non_code_filenames.include?(filename)
                    if content.count { |line| line[:type] === :added } > 0 || content.count { |line| line[:type] === :deleted } > 0
                        if (filename.include? "Test") || (filename.include? "test")
                            test_change = true
                        else
                            prod_change = true
                        end
                    end
                end
            end #End of For Each

            #Green indicates end of cycle, Also process if at last light
            if curr.colour.to_s == "green" || index == @avatar.lights.count - 1
                #Determine the type of cycle
                if (test_change && !prod_change) || (!test_change && prod_change) || (!test_change && !prod_change)
                    cycle = "R" #Refactor if changes are exclusive to production or test files
                else
                	if in_cycle == true
                    	cycle = "TP" #Test-Prod
                    else
                    	cycle = "R"
                    end
                end

                # Process Metrics & Output Data
                cycle_lights.each do |light|

                    #Count Lines Modified in Light & Cycle
                    line_count = calc_lines(prev, light) #Lines Modified in Light
                    @cycle_lines += line_count #Total Lines Modified in Cycle
                    @edited_lines += line_count #Total Lines Modified in Kata

                    #Determine Time Spent in Light
                    if prev.nil?
                        time_diff = light.time - @start_date
                    else
                        time_diff = light.time - prev.time
                    end

                    #Time Ceiling
                    if time_diff > @TIME_CEILING
                        time_diff = @TIME_CEILING
                    end

                    #Increment Total Time
                    @total_time += time_diff
                    
                    #Count Types of Lights
                    case light.colour.to_s
                    when "red"
                        @redlights += 1
                    when "green"
                        @greenlights += 1
                    when "amber"
                        @amberlights += 1
                    end                    

                    #Output
                    if cycle == "TP"
                        @transitions += "+" + "{" + light.colour.to_s + ":" + line_count.to_s + ":" + time_diff.to_s + "}"
                    elsif cycle == "R"
                        @transitions += "~" + "{" + light.colour.to_s + ":" + line_count.to_s + ":" + time_diff.to_s + "}"
                    end

                    #Assign current to previous
                    prev = light
                end #End of For Each

                #End Cycle Info
                if cycle == "TP"
                    #cycle_info = "<<" + @start_cycle.to_s + "|" + curr.time.to_s + "|" + (curr.time - @start_cycle.to_i).to_s + "|" + @cycle_lines.to_s + ">>]"
                    #@transitions += cycle_info
                    @start_cycle = curr.time
                    @cycle_lines = 0
                    @cycles += 1
                #elsif cycle == "R"
                	#Refactor
                end

                #Reset Cycle Metrics
                test_change = false
        		prod_change = false
        		in_cycle = false
        		cycle_lights.clear 
                    
            elsif curr.colour.to_s == "red"
            	in_cycle = true
            end #End of "If Green"

        end #End of For Each

        if @avatar.lights[@avatar.lights.count - 1].colour.to_s == "green"
            @ends_green = true
        else
            @ends_green = false
            #@transitions += "NOT A CYCLE]"
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