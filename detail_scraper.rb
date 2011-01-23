#!/usr/bin/env ruby

require 'rubygems'
require 'mongo'
require 'nokogiri'
require 'yaml'
require 'open-uri'

def indices(file_index)
  filename = "casualties-#{file_index}.yml"
  return [] unless File.exists?(filename)
  yaml = File.read(filename)
  urls = YAML::load(yaml).map {|u| u.gsub("http://www.cwgc.org/casualty_details.aspx?casualty=","")}
end

def extract_data(dict,html)
  html.css("td").each do |cell|
    id = cell["id"]
    next unless id
    value = cell.content.strip
    dict[id.gsub("td_","")] = value
  end
end

def load(casualty_id)
  url = "http://www.cwgc.org/search/casualty_details.aspx?casualty=#{casualty_id}"
  doc = { "casualty_id" => casualty_id }
  open(url,"User-Agent" => "Boris the spider") do |s|
    extract_data(doc,Nokogiri::HTML(s))
  end
  return doc
end

conn = Mongo::Connection.new
db = conn.db("wargraves")
collection = db.collection("casualties")
collection.create_index([["casualty_id", Mongo::ASCENDING]],:unique=>true)

("ac".."zi").each do |index|
  indices(index).each do |i|
    collection.insert(load(i))
    puts "INSERTING #{i} FROM FILE #{index}"
  end
end
