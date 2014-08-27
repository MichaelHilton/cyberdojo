#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/lib_domain'
require 'csv'

class MetaKata
	attr_reader :sloc, :ccnum, :branchcov, :statementcov, :redlights, :greenlights, :amberlights, :cycles, :ends_green, :transitions, :id, :language, :participants, :animal, :start_date, :name, :path, :totallights, :total_time

	def initialize(kata, avatar)
		@kata = kata
		@avatar = avatar
		@path = avatar.path

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
		@redlights = 0
		@greenlights = 0
		@amberlights = 0
		@cycles = 0
		@ends_green = false
		@total_time = avatar.lights[avatar.lights.count - 1].time - kata.created
		@transitions = ""
		@in_cycle = false
		@cycle_lines = 0
	end

	def print
		if @id.nil?
			puts "..."
		else
			puts "id: #{@id}, language: #{@language}, name: #{@name}, participants: #{@participants}, path: #{@path}, start date: #{@start_date}, seconds in kata: #{@total_time}, total lights: #{@totallights}, red lights: #{@redlights}, green lights: #{@greenlights}, amber lights: #{@amberlights}, sloc: #{@sloc}, edited lines: #{@edited_lines}, code coverage num: #{@ccnum}, branch coverage: #{@branchcov}, statement coverage: #{@statementcov}, num cycles: #{@cycles}, ending in green: #{@ends_green}, transitions: #{@transitions}"
		end
	end

	def save(save_path)
		if File.exist?(save_path)
			File.delete(save_path)
		end
		f = File.new(save_path, "w+")

		f.puts("#{@id},#{@language},#{@name},#{@participants},#{@path},#{@start_date},#{@total_time},#{@totallights},#{@redlights},#{@greenlights},#{@amberlights},#{@sloc},#{@edited_lines},#{@ccnum},#{@branchcov},#{@statementcov},#{@cycles},#{@ends_green},#{@transitions}")
	end

	def add_light(colour, line_count, time_diff)
		case colour.to_s
		when "red"
			@redlights += 1
		when "green"
			@greenlights += 1
		when "amber"
			@amberlights += 1
        end
        @transitions += "{" + colour.to_s + ":" + line_count.to_s + ":" + time_diff.to_s + "}"
	end

	def endCycle(endcycle)
        return "," + @start_cycle.to_s + "," + endcycle.to_s + "," + (endcycle - @start_cycle.to_i).to_s + ",`" + @cycle_lines.to_s + "]"
    end

	def deleted_file(lines)
    	lines.all? { |line| line[:type] === :deleted }
	end

	def new_file(lines)
    	lines.all? { |line| line[:type] === :added }
	end

	def calc_sloc
		# Lines of Code (using sloccount)
		allFiles =  Dir.entries(@path.to_s + "sandbox")
		allFiles.each do |currFile|
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

    	@avatar.lights.each do |curr|
    		line_count = calc_lines(prev, curr)
    		@cycle_lines += line_count
			@edited_lines += line_count

			if @in_cycle == false
            	if curr.colour.to_s == "red"
            		# Begin cycle
            		@transitions += "["
            		@in_cycle = true 
            	else
            		# Refactor cycle
            		# TODO
            	end
            end

    		if prev.nil?
    			add_light(curr.colour, line_count, (curr.time - @start_date))
    		else
    			add_light(curr.colour, line_count, (curr.time - prev.time))
			end

			if @in_cycle == true
				if curr.colour.to_s == "green"
					# End cycle
	                @transitions +=  endCycle(curr.time)
	                @start_cycle = curr.time
	                @cycle_lines = 0
	                @in_cycle = false
	                @cycles += 1    
                end  
            end

    		prev = curr
    	end #End of For Each

    	if @avatar.lights[@avatar.lights.count - 1].colour.to_s == "green"
    		@ends_green = true
    	else
    		@ends_green = false
    		@transitions += "NOT A CYCLE]"
    	end
    end

    def coverage_metrics
    	case @language.to_s
    	when "Java-1.8_Unit"
    		if File.exist?(@path + 'CodeCoverageReport.csv')
    			codeCoverageCSV = CSV.read(@path + 'CodeCoverageReport.csv')
                branchCoverage =  codeCoverageCSV[2][6]
                statementCoverage =  codeCoverageCSV[2][16]
    		end
    		cyclomaticComplexity = `.javancss "#{@path + "sandbox/*.java"}" 2>/dev/null`
    		@ccnum = cyclomaticComplexity.scan(/\d/).join('')
    	when "Python-unittest"
    		if File.exist?(path + 'sandbox/pythonCodeCoverage.csv')
	    		codeCoverageCSV = CSV.read(@path+ 'sandbox/pythonCodeCoverage.csv')
				#NOT SUPPORTED BY PYTHON LIBRARY
	            #branchCoverage =  codeCoverageCSV[1][6]
	            statementCoverage =  (codeCoverageCSV[1][3].to_f)/100
	    		codeCoverageCSV = CSV.read(@path+ 'sandbox/pythonCodeCoverage.csv')
	            @ccnum = codeCoverageCSV[1][4]
        	end
    	end
    end

    private :add_light, :endCycle, :new_file, :deleted_file, :calc_lines

end