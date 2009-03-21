#!/usr/bin/env ruby

require 'search_results'
require 'yaml'

casualties = []
letter = 'z'
begin
  ("#{letter}a".."#{letter}z").each do |s|
    puts "Getting results for: #{s}"
    path = "http://www.cwgc.org/search/SearchResults.aspx?=casualty"+
       "&surname=#{s}&initials=&war=2&"+
       "yearfrom=1941&yearto=1941&force=Army&nationality="
    sr = SearchResults.new(path)
    casualties = casualties + sr.all_casualties
  end
rescue Exception => e
  puts "** Error crawling #{e.inspect}"
end

File.open("casualties-#{letter}.yml",'w') {|out| YAML.dump(casualties, out)}
