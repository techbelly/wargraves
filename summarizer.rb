#!/usr/bin/env ruby

require 'rubygems'
require 'mongo'
require 'csv'

conn = Mongo::Connection.new
db = conn.db("wargraves")
collection = db.collection("casualties")

def summary(collection,field)
  summary = collection.group(:key=> [field],
                        :initial => {:count=>0}, 
                        :reduce=>"function(o,p) {p.count++; }")
  hist = Hash.new(0)
  
  summary.each {|h|
    group = h[field.to_s]
    if block_given?
      group = yield group
    end
    value = h["count"]
    hist[group] += value.to_i
  }
  hist
end

def as_csv(file,collection,&block)
  keys = collection.keys.compact.sort
  if block
    keys = keys.sort_by &block
  end
  keys.each do |k|
    file.puts CSV.generate_line([k,collection[k]])
  end
end

File.open("nationalities.csv","w") do |f|
  as_csv(f,summary(collection,:nationality))
end

File.open("deaths.csv","w") do |f|
  as_csv(f,   summary(collection,:death)) do |date| 
                day,month,year = date.split("/"); [year,month,day].join("")
              end
end
File.open("ages.csv","w") do |f|
  as_csv(f,summary(collection,:age) {|a| a.nil? ? nil : a.to_i})
end
File.open("ranks.csv","w") do |f|
  as_csv(f,summary(collection,:rank) {|g| g.gsub(/\(.*\)/,"").strip })
end