#!/usr/bin/env ruby
#TODO: create a not enough of a cycle with a line threshold 
#TODO: modularize TDD Classification from parseLight
#TODO: integrate code coverage / cyclomatic complexity tools

require File.dirname(__FILE__) + '/lib_domain'
require 'csv'

# displays data in screen-friendly format if true, csv format if false or blank
arg = (ARGV[0] || "")

def deleted_file(lines)
    lines.all? { |line| line[:type] === :deleted }
end

def new_file(lines)
    lines.all? { |line| line[:type] === :added }
end

def addLightData(colour, line_count, time_diff)
    return ("{" + colour + ":" + line_count.to_s + ":" + time_diff.to_s + "}")
end

def endCycleData(start_cycle_time, end_cycle_time, cycle_lines)
    return ";;" + start_cycle_time.to_s + ";;" + end_cycle_time.to_s + ";;" + (end_cycle_time - start_cycle_time).to_s + ";;" + cycle_lines.to_s + "]"
end

def parseLight(nowColour, wasColour, num_cycles, startCycleTime, endCycleTime, startLightTime, endLightTime, line_count, transitions, cycle_lines)
    if transitions.end_with?("]")
        transitions += "["
    end
    
    # locate cycle transitions and add '|' to designate

    if (nowColour == "red" || nowColour == "amber") && wasColour == "green"
        transitions +=  endCycleData(startCycleTime, endCycleTime, cycle_lines) + "["
        transitions +=  addLightData(nowColour, line_count, (endLightTime - startLightTime)) 
        cycle_lines = 0
        num_cycles += 1
        return num_cycles, endCycleTime, transitions, cycle_lines
    else
        transitions += addLightData(nowColour, line_count, (endLightTime - startLightTime)) 
        return num_cycles, startCycleTime, transitions, cycle_lines
    end    
end

def calcLines(avatar, was, now)
    # determine number of lines changed between lights
        line_count = 0;
        diff = avatar.tags[was.number].diff(now.number)
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

def categorize_colour(colour)
end

dojo = create_dojo

# temporary limiter for TESTING ONLY, remove all lines referencing 'lim' for full functionality
lim = 300
dojo.katas.each do |kata|
    language = kata.language.name
    lim -= 1
    if kata.exercise.name.to_s != "Verbal"
    
    if language == "Java-1.8_JUnit" || language == "Python-unittest"
        
        
        kata.avatars.active.each do |avatar|
            lights = avatar.lights
            num_lights = lights.count
            num_cycles = 1
            kata_line_count = 0
            num_red, num_green, num_amber = 0, 0, 0
            endsOnGreen = false
            start_cycle_time = kata.created
            start_light_time = kata.created
            cycle_lines = 0
            line_count = 0
            
            transitions = "["
            
            #parse first light
            num_cycles, start_cycle_time, transitions = parseLight(lights[0].colour.to_s, "none", num_cycles, start_cycle_time, lights[0].time, start_light_time, lights[0].time, line_count, transitions, cycle_lines)
            case lights[0].colour.to_s
                when "red"
                    num_red += 1
                when "green"
                    num_green += 1
                when "amber"
                    num_amber += 1
            end
            start_light_time = lights[0].time
            cycle_lines += line_count
            kata_line_count += line_count
            
            
            lights.each_cons(2) do |was,now|
                case now.colour.to_s
                    when "red"
                        num_red += 1
                    when "green"
                        num_green += 1
                    when "amber"
                        num_amber += 1
                end
           
                # determine number of lines changed between lights
                line_count = calcLines(avatar, was, now)
                
                #parse cycle data from current state of lights
                num_cycles, start_cycle_time, transitions = parseLight(now.colour.to_s, was.colour.to_s, num_cycles, start_cycle_time, was.time, start_light_time, now.time, line_count, transitions, cycle_lines)
                start_light_time = now.time
                cycle_lines += line_count
                kata_line_count += line_count
            end
                        
            if lights[lights.count - 1].colour.to_s.eql?("green")
                endsOnGreen = true
                transitions +=  endCycleData(start_cycle_time, lights[lights.count - 1].time , cycle_lines)
            else
                transitions += ";; NOT A CYCLE]"
                endsOnGreen = false
            end
          
            if language == "Java-1.8_JUnit"
                if File.exist?(avatar.path+ 'CodeCoverageReport.csv')
                    codeCoverageCSV = CSV.read(avatar.path+ 'CodeCoverageReport.csv')
                   branchCoverage =  codeCoverageCSV[2][6]
                    statementCoverage =  codeCoverageCSV[2][16]
                end
                cyclomaticComplexity = `./javancss "#{avatar.path + "sandbox/*.java"}" 2>/dev/null`
                cyclomaticComplexityNumber =  cyclomaticComplexity.scan(/\d/).join('')
            end
            if language == "Python-unittest"
                if File.exist?(avatar.path+ 'sandbox/pythonCodeCoverage.csv')
                    codeCoverageCSV = CSV.read(avatar.path+ 'sandbox/pythonCodeCoverage.csv')
                    #NOT SUPPORTED BY PYTHON LIBRARY
                    #branchCoverage =  codeCoverageCSV[1][6]
                    statementCoverage =  (codeCoverageCSV[1][3].to_f)/100
                    cyclomaticComplexityNumber = codeCoverageCSV[1][4]
                end
            end
            
            if arg == "true"
                printf("kata id:\t%s\nexercise:\t%s\nlanguage:\t%s\n", kata.id.to_s, kata.exercise.name.to_s, language)
                printf("avatar:\t\t%s [%s in kata]\n", avatar.name, kata.avatars.count.to_s)
                printf("path:\t\t%s\n", avatar.path)
                printf("num of lights:\t%s  =>  red:%s, green:%s, amber:%s\n", lights.count.to_s, num_red.to_s, num_green.to_s, num_amber.to_s)
                printf("num of cycles:\t%s\t\ttotal lines changed:%s\n", num_cycles.to_s, kata_line_count.to_s)
                printf("ends of green:\t%s\n", endsOnGreen)
                printf("Branch Coverage: \t%s \tstatement coverage:%s \tcyclomatic complexity Number %s\t",branchCoverage,statementCoverage,cyclomaticComplexityNumber)
                printf("total time: \t%s\n", lights[lights.count - 1].time - kata.created)
                printf("log:\t\t%s\n\n", transitions)
                else
                printf("%s,%s,%s,%s,%s,", kata.id.to_s, language, kata.exercise.name.to_s, kata.avatars.count.to_s, avatar.name)
                printf("%s,%s,%s,%s,%s,",avatar.path, lights.count.to_s, num_red.to_s, num_green.to_s, num_amber.to_s)
                printf("%s,%s,%s,", branchCoverage,statementCoverage,cyclomaticComplexityNumber)
                printf("%s,%s,%s,%s\n", num_cycles.to_s,(lights[lights.count - 1].time - kata.created).to_s, endsOnGreen, transitions)
            end
            end
       
        end
    
     end
     break if lim <= 0
end

