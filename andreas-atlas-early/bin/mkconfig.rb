#!/usr/bin/ruby

require 'csv'

from_week = ARGV[1].to_f
to_week = ARGV[2].to_f

CSV::foreach(ARGV[0], col_sep: " ") do |row|
  next if row[0] == "participant_id"

  subject = row[0]
  session = row[1]
  gender = row[2]
  birth_ga = row[3].to_f
  scan_date = row[4]
  age_at_scan = row[5].to_f

  if age_at_scan >= from_week && age_at_scan < to_week
    puts "#{subject}-#{session}, #{age_at_scan}"
  end

end
