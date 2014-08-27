#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/lib_domain'
require 'csv'

class MetaKata
	attr_accessor :id, :language, :participants, :animal, :startdate, :name, :path, :totallights
	attr_reader :sloc, :ccnum, :branchcov, :statementcov, :redlights, :greenlights, :amberlights, :cycles, :endingreen, :seconds, :transitions

	def initialize(id = "0", language = "0", participants = "0", animal = "0", startdate = "0", name = "0", path = "0")
		@id = id
		@language = language
		@participants = participants
		@animal = animal
		@startdate = startdate
		@startcycle = startdate
		@name = name
		@path = path
		@sloc = 0
		@edited_lines = 0
		@ccnum = ""
		@branchcov = ""
		@statementcov = ""
		@totallights = 0
		@redlights = 0
		@greenlights = 0
		@amberlights = 0
		@cycles = 0
		@endingreen = false
		@seconds = 0
		@transitions = ""
		@in_cycle = false
		@cycle_lines = 0
	end

	def print
		if @id.nil?
			puts "..."
		else
			puts "id: #{@id}, language: #{@language}, name: #{@name}, participants: #{@participants}, path: #{@path}, startdate: #{@startdate}, seconds in kata: #{@seconds}, total lights: #{@totallights}, red lights: #{@redlights}, green lights: #{@greenlights}, amber lights: #{@amberlights}, sloc: #{@sloc}, edited lines: #{@edited_lines}, code coverage num: #{@ccnum}, branch coverage: #{@branchcov}, statement coverage: #{@statementcov}, num cycles: #{@cycles}, ending in green: #{@endingreen}, transitions: #{@transitions}"
		end
	end

	def save(path)
		f = File.new(path, "a+")
		f.puts("#{@id},#{@language},#{@name},#{@participants},#{@path},#{@startdate},#{@seconds},#{@totallights},#{@redlights},#{@greenlights},#{@amberlights},#{@sloc},#{@edited_lines},#{@ccnum},#{@branchcov},#{@statementcov},#{@cycles},#{@endingreen},#{@transitions}")
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

	def deleted_file(lines)
    	lines.all? { |line| line[:type] === :deleted }
	end

	def new_file(lines)
    	lines.all? { |line| line[:type] === :added }
	end

	def calc_sloc(path)
		# Lines of Code (using sloccount)
		allFiles =  Dir.entries(path.to_s + "sandbox")
		allFiles.each do |currFile|
			isFile = currFile.to_s =~ /\.java$|\.py$|\.c$|\.cpp$|\.js$|\.h$|\.hpp$/i
			
			unless isFile.nil?
				file = path.to_s + "sandbox/" + currFile.to_s
				# the `shell command` does not capture error messages sent to stderr
        
				command = `sloccount --details #{file}`
				value = command.split("\n").last
				@sloc += value.split(" ").first.to_i
			end
		end
	end

	def calc_lines(avatar, prev, curr)
	    # determine number of lines changed between lights
	    line_count = 0;

	    if prev.nil?
		    diff = avatar.tags[0].diff(curr.number)
		else
			diff = avatar.tags[prev.number].diff(curr.number)
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

    def parse(avatar)
    	calc_sloc(avatar.path)
    	prev = nil

    	avatar.lights.each do |curr|
    		line_count = calc_lines(avatar, prev, curr)
    		@cycle_lines += line_count
			@edited_lines += line_count

			if @in_cycle == false
            	if curr.colour.to_s == "red"
            		# Begin cycle
            		@transitions += "["
            		@in_cycle = true 
            	else
            		# Refactor cycle
            	end
            end

    		if prev.nil?
    			add_light(curr.colour, line_count, (curr.time - @startdate))
    		else
    			add_light(curr.colour, line_count, (curr.time - prev.time))
			end

			if @in_cycle == true
				if curr.colour.to_s == "green"
					# End cycle
					cycle_info = "<<" + @startcycle.to_s + ":" + curr.time.to_s + ":" + (curr.time - @startcycle.to_i).to_s + ":" + @cycle_lines.to_s + ">>]"
	                @transitions +=  cycle_info
	                @startcycle = curr.time
	                @cycle_lines = 0
	                @in_cycle = false
	                @cycles += 1    
                end  
            end

    		prev = curr
    	end
    end

    def coverage_metrics(path)
    	case @language.to_s
    	when "Java-1.8_Unit"
    		if File.exist?(path + 'CodeCoverageReport.csv')
    			codeCoverageCSV = CSV.read(path + 'CodeCoverageReport.csv')
                branchCoverage =  codeCoverageCSV[2][6]
                statementCoverage =  codeCoverageCSV[2][16]
    		end
    		cyclomaticComplexity = `.javancss "#{path + "sandbox/*.java"}" 2>/dev/null`
    		@ccnum = cyclomaticComplexity.scan(/\d/).join('')
    	when "Python-unittest"
    		if File.exist?(path + 'sandbox/pythonCodeCoverage.csv')
	    		codeCoverageCSV = CSV.read(avatar.path+ 'sandbox/pythonCodeCoverage.csv')
				#NOT SUPPORTED BY PYTHON LIBRARY
	            #branchCoverage =  codeCoverageCSV[1][6]
	            statementCoverage =  (codeCoverageCSV[1][3].to_f)/100
	    		codeCoverageCSV = CSV.read(avatar.path+ 'sandbox/pythonCodeCoverage.csv')
	            @ccnum = codeCoverageCSV[1][4]
        	end
    	end
    end

    private :add_light, :new_file, :deleted_file

end