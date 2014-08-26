#!/usr/bin/env ruby

class MetaKata
	attr_accessor :id, :language, :participants, :animal, :startdate, :name, :path, :sloc, :ccnum, :branchcov, :statementcov, :totallights, :redlights, :greenlights, :amberlights, :cycles, :endingreen, :seconds, :transitions, :in_cycle

	def initialize(id = "0", language = "0", participants = "0", animal = "0", startdate = "0", name = "0", path = "0")
		@id = id
		@language = language
		@participants = participants
		@animal = animal
		@startdate = startdate
		@name = name
		@path = path
		@sloc = 0
		@ccnum = 0
		@branchcov = 0
		@statementcov = 0
		@totallights = 0
		@redlights = 0
		@greenlights = 0
		@amberlights = 0
		@cycles = 0
		@endingreen = false
		@seconds = 0
		@transitions = ""
		@in_cycle = false
	end

	def print
		if @id.nil?
			puts "..."
		else
			puts "id: #{@id}, language: #{@language}, name: #{@name}, participants: #{@participants}, path: #{@path}, startdate: #{@startdate}, seconds in kata: #{@seconds}, total lights: #{@totallights}, red lights: #{@redlights}, green lights: #{@greenlights}, amber lights: #{@amberlights}, sloc: #{@sloc}, code coverage num: #{@ccnum}, branch coverage: #{@branchcov}, statement coverage: #{@statementcov}, num cycles: #{@cycles}, ending in green: #{@endingreen}, transitions: #{@transitions}"
		end
	end

	def save(path)
		if File.exist?(path)
			File.delete(path)
		end
		f = File.new(path, "w+")

		f.puts("#{@id},#{@language},#{@name},#{@participants},#{@path},#{@startdate},#{@seconds},#{@totallights},#{@redlights},#{@greenlights},#{@amberlights},#{@sloc},#{@ccnum},#{@branchcov},#{@statementcov},#{@cycles},#{@endingreen},#{@transitions}")
	end

	private
	def addLight(colour, line_count, time_diff)
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

	private
	def endCycle(start_cycle_time, end_cycle_time, cycle_lines)
        return ";;" + start_cycle_time.to_s + ";;" + end_cycle_time.to_s + ";;" + (end_cycle_time - start_cycle_time).to_s + ";;" + cycle_lines.to_s + "]"
    end

    # can we refactor this to internally evaluate incoming lights via addLight and add cycle information as appropriate?
	def parseLight(nowColour, wasColour, num_cycles, startCycleTime, endCycleTime, startLightTime, endLightTime, line_count, transitions, cycle_lines)
        if @in_cycle == false
            if nowColour == "red"
                @transitions += "[" + addLight(nowColour, line_count, (endLightTime - startLightTime))
                @in_cycle = true
                return @cycles, endCycleTime, @transitions, cycle_lines        
            else
                #refactor
                return @cycles, endCycleTime, @transitions, cycle_lines        
            end
        else
            if nowColour == "green"
                @transitions +=  addLight(nowColour, line_count, (endLightTime - startLightTime)) 
                @transitions +=  endCycle(startCycleTime, endCycleTime, cycle_lines)
                cycle_lines = 0
                @in_cycle = false
                @cycles += 1
                return @cycles, endCycleTime, @transitions, cycle_lines        
            end
        end
        return @cycles, endCycleTime, @transitions, cycle_lines
    end

end