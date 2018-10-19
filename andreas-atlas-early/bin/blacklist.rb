#!/usr/bin/ruby

require 'csv'
require 'fileutils'
require 'vips'

$: << File.dirname(__FILE__)
require 'my-utils.rb'

# assuming this script is in root/bin, get root
root = File.dirname(File.dirname(File.expand_path(__FILE__)));

# config dir
config = "#{root}/inputs/config"

# load blacklist
log "loading blacklist ..."
blacklist = {}
CSV::foreach("#{config}/blacklist.csv") do |row|
  blacklist[row[0]] = true
end

# filter ages 
log "filtering ages.csv ..."
ages = []
CSV::foreach("#{config}/ages.csv") do |row|
  if ! blacklist.include? [row[0]] 
    ages << row
  end
end

CSV.open("#{config}/ages.csv", "wb") do |csv|
  ages.each {|row| csv << row}
end

# filter subjects 
log "filtering subjects.csv ..."
subjects = []
CSV::foreach("#{config}/subjects.csv") do |row|
  if ! blacklist.include? [row[0]] 
    subjects << row
  end
end

CSV.open("#{config}/subjects.csv", "wb") do |csv|
  subjects.each {|row| csv << row}
end
