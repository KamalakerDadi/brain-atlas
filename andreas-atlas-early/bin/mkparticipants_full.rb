#!/usr/bin/ruby

require 'csv'

# we need images that the struct pipeline has run on, since we need tissue
# labels ... we must therefore read from
base = "/vol/dhcp-derived-data/derived_02Jun2018"

def err msg
  STDERR.puts msg 
end

err "scanning #{base} ..."

puts "participant_id session_id gender birth_ga scan_date age_at_scan"

CSV::foreach("#{base}/participants.tsv", col_sep: " ") do |row|
  next if row[0] == "participant_id"

  subject = row[0]
  gender = row[1]
  birth_ga = row[2].to_f

  # puts "#{subject}, #{gender}, #{birth_ga}" 

  session_file = "#{base}/derivatives/sub-#{subject}/sub-#{subject}_sessions.tsv"
  if ! File.exist? session_file
    err "#{session_file} not found"
    next
  end

  CSV::foreach(session_file, col_sep: " ") do |row|
    next if row[0] == "session_id"

    session = row[0]
    scan_date = row[1]
    age_at_scan = row[2].to_f

    src = "#{base}/derivatives/sub-#{subject}/ses-#{session}/anat"
    t1 = "#{src}/sub-#{subject}_ses-#{session}_T1w.nii.gz"
    t2 = "#{src}/sub-#{subject}_ses-#{session}_T2w.nii.gz"

    if !File.exist? t1
      err "#{t1} source image not found"
      next
    end

    if !File.exist? t2
      err "#{t2} source image not found"
      next
    end

    puts "#{subject} #{session} #{gender} #{birth_ga} #{scan_date} #{age_at_scan}"

  end

end
