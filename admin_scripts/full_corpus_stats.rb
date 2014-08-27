#!/usr/bin/env ruby
#PRORITY
#TODO: create a not enough of a cycle with a line threshold 
#TODO: modularize TDD Classification from parseLight
#TODO: Total lines of code

#NON-PRIORITY
#TODO: find lines for first Light
#RUN THIS IN MAC TO GET RID OF MD% ERRORS : PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
require File.dirname(__FILE__) + '/lib_domain'
require 'csv'

class Full_corpus_stats
    
    def initialize
        @in_cycle = false
    end
    
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
        if @in_cycle == false
            if nowColour == "red"
                transitions += "[" + addLightData(nowColour, line_count, (endLightTime - startLightTime))
                @in_cycle = true
                return num_cycles, endCycleTime, transitions, cycle_lines        
            else
                #refactor
                return num_cycles, endCycleTime, transitions, cycle_lines        
            end
        else
            if nowColour == "green"
                transitions +=  addLightData(nowColour, line_count, (endLightTime - startLightTime)) 
                transitions +=  endCycleData(startCycleTime, endCycleTime, cycle_lines)
                cycle_lines = 0
                @in_cycle = false
                num_cycles += 1
                return num_cycles, endCycleTime, transitions, cycle_lines        
            end
        end
        return num_cycles, endCycleTime, transitions, cycle_lines
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
    
    
    def full_parse(arg)
        
        dojo = create_dojo
        
        
        # limiter that halts after 'lim' number of katas
        lim = 1000
        count = 0
        all_katas = Array.new()
        kata_meta = "KataID,Language,NumParticipants,Animal,StartDate,KataName,Path,SLOC,CCNum,BranchCoverage,StatementCoverage,TotalLights,RedLights,GreenLights,AmberLights,NumberCycles,EndsInGreen,secsInKata,TransitionString"
        all_katas.push(kata_meta)


        dojo.katas.each do |kata|
            @in_cycle = false
            language = kata.language.name
            
            if kata.exercise.name.to_s != "Verbal" && (language == "Java-1.8_JUnit" || language == "Python-unittest")
                count += 1
        
        
                kata.avatars.active.each do |avatar|
                    
                    #kata_meta = [kata.id.to_s, language.to_s, kata.avatars.count.to_s, avatar.name.to_s, kata.created.to_s, kata.exercise.name.to_s, avatar.path.to_s, avatar.lights.count.to_s]
                    kata_meta = kata.id.to_s
                    kata_meta +=","
                    kata_meta += language.to_s
                    kata_meta +=","
                    kata_meta += kata.avatars.count.to_s
                    kata_meta +=","
                    kata_meta += avatar.name.to_s
                    kata_meta +=","
                    kata_meta += kata.created.to_s
                    kata_meta +=","
                    kata_meta += kata.exercise.name.to_s
                    kata_meta +=","
                    kata_meta += avatar.path.to_s
                    kata_meta +=","
                    
                    
                    lights = avatar.lights
                    num_cycles = 0
                    kata_line_count = 0
                    num_red, num_green, num_amber = 0, 0, 0
                    endsOnGreen = false
                    start_cycle_time = kata.created
                    start_light_time = kata.created
                    cycle_lines = 0
                    line_count = 0
                    loc_count = 0
                    transitions = ""   
                    
                    allFiles =  Dir.entries(avatar.path+"sandbox")
                    allFiles.each do |currFile|
                        isFile = currFile.to_s =~ /\.java$|\.py$|\.c$|\.cpp$|\.js$|\.h$|\.hpp$/i
                        unless isFile.nil?
                            file = avatar.path.to_s + "sandbox/" + currFile.to_s
                            # the `shell command` does not capture error messages sent to stderr
        
                            command = `sloccount --details #{file}`
                            value = command.split("\n").last
                            loc_count += value.split(" ").first.to_i
                        end
                    end
        
                    kata_meta += loc_count.to_s
                    kata_meta += ","
                    
                    #parse first light
                    num_cycles, start_cycle_time, transitions, cycle_lines = parseLight(lights[0].colour.to_s, "none", num_cycles, start_cycle_time, lights[0].time, start_light_time, lights[0].time, line_count, transitions, cycle_lines)
                    case lights[0].colour.to_s
                        when "red"
                            num_red += 1
                        when "green"
                            num_green += 1
                        when "amber"
                            num_amber += 1
                    end
                    start_light_time = lights[0].time
                    
                    #TODO these need to be instantiated
                    #cycle_lines += line_count
                    #kata_line_count += line_count
                    
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
                        num_cycles, start_cycle_time, transitions, cycle_lines = parseLight(now.colour.to_s, was.colour.to_s, num_cycles, start_cycle_time, was.time, start_light_time, now.time, line_count, transitions, cycle_lines)
                        
                        start_light_time = now.time
                        cycle_lines += line_count
                        kata_line_count += line_count
                    end
                                
                    if lights[lights.count - 1].colour.to_s.eql?("green")
                        endsOnGreen = true
                        #num_cycles += 1
                        transitions +=  endCycleData(start_cycle_time, lights[lights.count - 1].time , cycle_lines)
                    else
                        transitions += ";; NOT A CYCLE]"
                        endsOnGreen = false
                    end
                  
                    if language == "Java-1.8_JUnit"
                        if File.exist?(avatar.path+ 'CodeCoverageReport.csv')
                            
                                codeCoverageCSV = CSV.read(avatar.path+ 'CodeCoverageReport.csv')
                                #puts "CODECOVERAGE"
                                #puts codeCoverageCSV.inspect()
                                unless(codeCoverageCSV.inspect() == "[]")
                                    #puts codeCoverageCSV[2]
                                    #puts "WOOOHOOOO"
                                    branchCoverage =  codeCoverageCSV[2][6]
                                    statementCoverage =  codeCoverageCSV[2][16]
                                end
                                #branchCoverage =  codeCoverageCSV[2][6]
                                #statementCoverage =  codeCoverageCSV[2][16]
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
                    #kata_meta.push(cyclomaticComplexityNumber.to_s, statementCoverage.to_s, branchCoverage.to_s)
                    #kata_meta.push(num_red.to_s, num_green.to_s, num_amber.to_s, num_cycles.to_s, endsOnGreen)
                    #kata_meta.push((lights[lights.count - 1].time - kata.created).to_s)
                    #kata_meta.push(transitions)
                    
                    kata_meta +=cyclomaticComplexityNumber.to_s
                    kata_meta += ","
                    kata_meta += statementCoverage.to_s
                    kata_meta +=","
                    kata_meta += branchCoverage.to_s
                    kata_meta += ","
                    kata_meta +=avatar.lights.count.to_s
                    kata_meta += ","
                    kata_meta += num_red.to_s+","+ num_green.to_s+","+ num_amber.to_s+","+ num_cycles.to_s+","+endsOnGreen.to_s+","
                    kata_meta += ((lights[lights.count - 1].time - kata.created).to_s) +","
                    kata_meta += transitions
                    kata_meta += "\n"
                    
                    all_katas.push(kata_meta)
                end
        
                if count % 10 == 0
                    print '.'
                end
                if count % 100 == 0
                    print '+'
                end
        
                break if count == lim   
            end
        end
        
=begin
                        printf("kata id:\t%s\nexercise:\t%s\nlanguage:\t%s\n", kata.id.to_s, kata.exercise.name.to_s, language)
                        printf("avatar:\t\t%s [%s in kata]\n", avatar.name, kata.avatars.count.to_s)
                        printf("path:\t\t%s\n", avatar.path)
                        printf("num of lights:\t%s  =>  red:%s, green:%s, amber:%s\n", lights.count.to_s, num_red.to_s, num_green.to_s, num_amber.to_s)
                        printf("num of cycles:\t%s\t\ttotal lines changed:%s\n", num_cycles.to_s, kata_line_count.to_s)
                        printf("ends of green:\t%s\n", endsOnGreen)
                        printf("Branch Coverage: \t%s \tstatement coverage:%s \tcyclomatic complexity Number %s\t",branchCoverage,statementCoverage,cyclomaticComplexityNumber)
                        printf("total time: \t%s\n", lights[lights.count - 1].time - kata.created)
                        printf("log:\t\t%s\n\n", transitions)
=end
        
        path = Dir.pwd.to_s+"/corpus.csv"
        if File.exist?(path)
            File.delete(path)
        end
        f = File.new(path, "w+")
        f.puts(all_katas)
        #puts all_katas
        puts "[done]"
    end
end