#!/usr/bin/ruby

require 'csv'

from_week = ARGV[1].to_f
to_week = ARGV[2].to_f

age_hist = Array.new(to_week - from_week, 0)

CSV::foreach(ARGV[0], col_sep: "\t") do |row|
  next if row[0] == "participant_id"

  subject = row[0]
  session = row[1]
  gender = row[2]
  birth_ga = row[3].to_f
  age_at_scan = row[4].to_f

  if age_at_scan >= from_week && age_at_scan < to_week
    puts "#{subject}-#{session}, #{age_at_scan}"
    age_hist[(age_at_scan - from_week).to_i] += 1
  end

end

puts "week frequency"
age_hist.each_index do |i|
  puts "  #{i + from_week}  #{age_hist[i]}"
end
