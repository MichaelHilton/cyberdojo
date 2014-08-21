#!/usr/bin/env ruby

# A ruby script to display the count of
#   dojos per day
#   dojos per language
#   dojos per exercise
# to see the ids of all counted dojos (in their catagories)
# append true to the command line

require File.dirname(__FILE__) + '/lib_domain'

show_ids = (ARGV[0] || "false")

def deleted_file(lines)
    lines.all? { |line| line[:type] === :deleted }
end

def new_file(lines)
    lines.all? { |line| line[:type] === :added }
end


$dot_count = 0
dojo = create_dojo

$stop_at = 10000000

puts
days,weekdays,languages,exercises = { },{ },{ },{ }
dot_count = 0
exceptions = [ ]
cyclomaticComplexity = ""
$stop_at = 500
dojo.katas.each do |kata|
    begin
        $dot_count += 1
        language = kata.language.name
        
        #puts language
        
        kata.avatars.active.each do |avatar|
            #puts avatar.path
            #end
        
        if language == "Python-unittest"
            puts avatar.path
            
            allFiles =  Dir.entries(avatar.path+"sandbox")
            fileNames = []
            allFiles.each do |currFile|
                #puts currFile
                pythonFile = currFile.to_s =~ /.py/i
                #puts pythonFile
                
                unless pythonFile.nil?
                    #fileNameParts = currFile.split('.')
                    #currTestClass = fileNameParts.first
                    #puts currFile
                    fileNames.push(avatar.path+"sandbox/"+currFile)
                    
                end
                
            end
            puts  "FILENAMES:"
            #puts fileNames
            
            File.open("#{avatar.path}sandbox/pythonFiles.txt", "w+") do |f|
                f.puts(fileNames)
            end

           `rm .figleaf`
           `./figleaf_bin/figleaf #{avatar.path}sandbox/test*.py`
           `./figleaf_bin/figleaf2html -f #{avatar.path}sandbox/pythonFiles.txt -d #{avatar.path}sandbox/pythonCodeCoverage .figleaf`
            #puts `./figleaf_bin/figleaf #{avatar.path}sandbox/test*.py`
            
            
            
        end
    
        if language == "Java-1.8_JUnitAAA"

#   kata.avatars.active.each do |avatar|
                unless  File.exist?(avatar.path+ 'CodeCoverageReport.csv')
                
                puts avatar.path
                #                copyCommand =  "cp "+avatar.path + "sandbox/*.java ./calcCodeCovg/tempDir"
                `rm ./calcCodeCovg/src/*`
                `rm -r ./calcCodeCovg/isrc/*`
                `rm -r ./calcCodeCovg/report.csv`
                `rm -r ./*.clf`

                `cp #{avatar.path}sandbox/*.java ./calcCodeCovg/src`
                allFiles =  Dir.entries("./calcCodeCovg/src/")
                currTestClass = ""
                allFiles.each do |currFile|
                    puts currFile
                    initialLoc = currFile.to_s =~ /test/i
                    #puts initialLoc
                    unless initialLoc.nil?
                        fileNameParts = currFile.split('.')
                        currTestClass = fileNameParts.first
                        puts currTestClass
                    end
                end
                `java -jar ./calcCodeCovg/libs/codecover-batch.jar instrument --root-directory ./calcCodeCovg/src --destination ./calcCodeCovg/isrc --container ./calcCodeCovg/src/con.xml --language java --charset UTF-8`
                
                `javac -cp ./calcCodeCovg/libs/*:./calcCodeCovg/isrc ./calcCodeCovg/isrc/*.java`
                
                puts `java -cp ./calcCodeCovg/libs/*:./calcCodeCovg/isrc org.junit.runner.JUnitCore #{currTestClass}`
                
                `java -jar ./calcCodeCovg/libs/codecover-batch.jar analyze --container ./calcCodeCovg/src/con.xml --coverage-log *.clf --name test1`
               
               puts `java -jar ./calcCodeCovg/libs/codecover-batch.jar report --container ./calcCodeCovg/src/con.xml --destination ./calcCodeCovg/report.csv --session test1 --template ./calcCodeCovg/report-templates/CSV_Report.xml`
               
               `cp ./calcCodeCovg/report.csv #{avatar.path}CodeCoverageReport.csv `
               end
            end
        end
        rescue Exception => error
        exceptions << error.message
       
    end
    #dot_count += 1
     break if $dot_count >= $stop_at
     #print "\r " + dots(dot_count)
end
puts
puts


