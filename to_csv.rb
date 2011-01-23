#!/usr/bin/env ruby

require 'rubygems'
require 'mongo'
require 'csv'

conn = Mongo::Connection.new
db = conn.db("wargraves")
collection = db.collection("casualties")

cursor = collection.find()

out = File.open("casualties.csv","w")
fields = ["casualty_id", "name", "citation", "age", "death", "regiment", "nationality", "service", "awards", "initials", "unittext2", "rank", "information", "grave", "type", "cemetery", "unittext", "regiment2"]

out.puts CSV.generate_line(fields)
cursor.each do |r|
  values = fields.map {|f|
    if r[f]
      r[f]
    else
      ""
    end
  }
  out.puts CSV.generate_line(values)
end

out.close