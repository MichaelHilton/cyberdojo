#!/usr/bin/env ruby

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


def parseLight(nowColour, wasColour, num_cycles, startCycleTime, endCycleTime, startLightTime, endLightTime, line_count, transitions, eof, cycle_lines)
    # locate cycle transitions and add '|' to designate
    if eof
        if nowColour == "green"
            transitions += "{" + wasColour + ":" + line_count.to_s + ":" + (endLightTime - startLightTime).to_s + "}{" + nowColour + ":" + line_count.to_s + ":" + (endLightTime - startLightTime).to_s + "}"
            transitions += ";;" + startCycleTime.to_s + ";;" + endCycleTime.to_s + ";;" + (endCycleTime - startCycleTime).to_s + ";;" + cycle_lines.to_s + "]"
            num_cycles += 1
            return num_cycles, endCycleTime, transitions, cycle_lines
        else 
            transitions += "{" + wasColour + ":" + line_count.to_s + ":" + (endLightTime - startLightTime).to_s + "}" + "{" + nowColour + ":" + line_count.to_s +  ":" + (endLightTime - startLightTime).to_s + "}"
            transitions += ";; NOT A CYCLE]"
            return num_cycles, endCycleTime, transitions, cycle_lines
        end
    elsif (nowColour == "red" || nowColour == "amber") && wasColour == "green"
        transitions += "{" + wasColour + ":" + line_count.to_s + ":" + (endLightTime - startLightTime).to_s + "}"
        transitions += ";;" + startCycleTime.to_s + ";;" + endCycleTime.to_s + ";;" + (endCycleTime - startCycleTime).to_s + ";;" + cycle_lines.to_s + "]["
        cycle_lines = 0
        num_cycles += 1
        return num_cycles, endCycleTime, transitions, cycle_lines
    else
        transitions += "{" + wasColour.to_s + ":" + line_count.to_s + ":" + (endLightTime - startLightTime).to_s + "}"
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
            end
        end
        return line_count
end


dojo = create_dojo

# temporary limiter for TESTING ONLY, remove all lines referencing 'lim' for full functionality
lim = 10
dojo.katas.each do |kata|
    language = kata.language.name
    
    if language == "Java-1.8_JUnit" || language == "Python-unittest"
        lim -= 1
        
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
            
            transitions = "["
            lights.each_cons(2) do |was,now|
                case was.colour.to_s
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
                num_cycles, start_cycle_time, transitions = parseLight(now.colour.to_s, was.colour.to_s, num_cycles, start_cycle_time, was.time, start_light_time, was.time, line_count, transitions, false, cycle_lines)
                start_light_time = was.time
                cycle_lines += line_count
                kata_line_count += line_count
            end
            
            # handle last light that was examined by consecutive loop above
            case lights[lights.count-1].colour.to_s
                when "red"
                num_red += 1
                when "green"
                num_green += 1
                endsOnGreen = true
                when "amber"
                num_amber += 1
            end

            line_count = calcLines(avatar, lights[lights.count - 2], lights[lights.count - 1])
            num_cycles, start_cycle_time, transitions = parseLight(lights[lights.count - 1].colour.to_s, lights[lights.count - 2].colour.to_s, num_cycles, start_cycle_time, lights[lights.count - 1].time, start_light_time, lights[lights.count - 1].time, line_count, transitions, true, cycle_lines)

            
            if language == "Java-1.8_JUnit"
                if File.exist?(avatar.path+ 'CodeCoverageReport.csv')
                    codeCoverageCSV = CSV.read(avatar.path+ 'CodeCoverageReport.csv')
                   branchCoverage =  codeCoverageCSV[2][6]
                    statementCoverage =  codeCoverageCSV[2][16]
                end
                cyclomaticComplexity = `./javancss "#{avatar.path + "sandbox/*.java"}" 2>/dev/null`
          
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
                printf("%s,%s,%s", branchCoverage,statementCoverage,cyclomaticComplexityNumber)
                printf("%s,%s,%s\n", num_cycles.to_s, endsOnGreen, transitions)
            end
        end
        
    end
    break if lim <= 0
end

