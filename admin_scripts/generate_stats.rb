#!/usr/bin/env ruby

load 'full_corpus_stats.rb'

# displays data in screen-friendly format if true, csv format if false or blank
arg = (ARGV[0] || "")
    
session = Full_corpus_stats.new
session.full_parse(arg)