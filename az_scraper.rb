#!/usr/bin/env ruby

require 'search_results'
require 'yaml'

("a".."z").each do |letter|
  begin
    ("#{letter}a".."#{letter}z").each do |s|
      puts "Getting results for: #{s}"
      path = "http://www.cwgc.org/search/SearchResults.aspx?=casualty"+
         "&surname=#{s}&initials=&war=2&"+
         "yearfrom=1941&yearto=1941&force=Air&nationality="
      sr = SearchResults.new(path)
      casualties = sr.all_casualties
      unless casualties.empty?
        File.open("casualties-#{s}.yml",'w') {|out| YAML.dump(casualties, out)}
      end
    end
  rescue Exception => e
    puts "** Error crawling #{e.inspect}"
  end
end