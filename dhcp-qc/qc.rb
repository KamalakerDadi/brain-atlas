#!/usr/bin/ruby

# pull together the various sources of QC data we have

require 'csv'

$: << File.dirname(__FILE__)
require 'my-utils.rb'

vol = "/home/john/vol"

# Antonis' manual QC programme
antonis1 = "#{vol}/medic01/users/am411/dhcp-v2.3/manual-QC-serena/image_score.csv"
antonis2 = "#{vol}/medic01/users/am411/dhcp-v2.3/manual-QC/image_score.csv"
antonis3 = "#{vol}/medic01/users/am411/dhcp-v2.3/manual-QC/image_score_479_images.csv"

# King's QC spreadsheet
kings = "#{vol}/dhcp-reconstructed-images/UpdatedReconstructions/ReconstructionsRelease03/INF/dHCPRelease03.csv"

# struct pipeline automated QC output
struct = "#{vol}/dhcp-derived-data/derived_02Jun2018/QC_reports/reports/image_QC_measures.csv"

# struct pipeline of 02 June has run
struct_pipeline_dir = "#{vol}/dhcp-derived-data/derived_02Jun2018"

# Matteo's blacklist ... severe failures reported in 
# neoDmri_incFindings.pdf, email of 31 oct 18
matteo_blacklist = [
  "sub-CC00605XX11_ses-172700",
  "sub-CC00605XX11_ses-187700",
  "sub-CC00689XX22_ses-199800",
  "sub-CC00894XX21_ses-3020",
  "sub-CC00578AN18_ses-164900"
]

# the QC sheet from Matteo's google docs spreadsheet as a CSV
matteo_qc = "/home/john/GIT/brain-atlas/andreas-atlas-early/bin/matteo-10dec18.csv"

# sean's QC 
sean_qc = "/home/john/GIT/brain-atlas/andreas-atlas-early/bin/sean-18jan19-fmri_qc.csv"

# all the names we display
names = [:antonis1, :antonis2, :antonis3, :antonis, 
         :has_struct,
         :matteo, :matteo_qc, 
         :sean_qc]

log "loading Antonis manual QC ..."

# a hash of hashes 
# scores["sub-CCxxx_ses-yyy"] == {antonis1: 12}
scores = Hash.new {|hash, key| hash[key] = {}}

CSV::foreach(antonis1) do |row|
  next if not row[0] =~ /(.*)-(.*)/
  subject = $~[1]
  session = $~[2]

  scores["sub-#{subject}_ses-#{session}"][:antonis1] = row[1].to_i
end

CSV::foreach(antonis2) do |row|
  next if not row[0] =~ /(.*)-(.*)/
  subject = $~[1]
  session = $~[2]

  scores["sub-#{subject}_ses-#{session}"][:antonis2] = row[1].to_i
end

CSV::foreach(antonis3) do |row|
  next if not row[0] =~ /(.*)-(.*)/
  subject = $~[1]
  session = $~[2]

  scores["sub-#{subject}_ses-#{session}"][:antonis3] = row[1].to_i
end

def median(array)
  sorted = array.sort
  len = sorted.length
  (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
end

# calculate median antonis for a row ... 0 for unknown
def get_antonis(value)
  values = []
  [:antonis1, :antonis2, :antonis3].each do |antonis|
    values << value[antonis] if value.key? antonis
  end
  
  if values.length == 0 
    return 0
  else
    median values
  end
end

scores.each_pair do |key, value|
  antonis_score = get_antonis(value) 

  if antonis_score != 0
    scores[key][:antonis] = antonis_score >= 2
  end
end

log "loading King's QC ..."

whitelist = ["CC00769XX19", "CC00723XX14"]
CSV::foreach(kings) do |row|
  next if not row[1] =~ /(CC\d\d\d\d\d\w\w\d\d)(.*)/
  subject = $~[1]
  notes = $~[2]
  session = row[2]
  t2 = row[3]
  t1 = row[5]

  # any notes in the dCHPid column seem to mean errors, except for two scans
  # which we whitelist
  next if !whitelist.include?(subject) && notes.length > 0 

  scores["sub-#{subject}_ses-#{session}"][:kingsT1] = (t1 =~ /OK(.*)/) != nil
  scores["sub-#{subject}_ses-#{session}"][:kingsT2] = (t2 =~ /OK(.*)/) != nil
end

log "loading struct pipeline QC ..."
CSV::foreach(struct) do |row|
  next if not row[0] =~ /(CC\d\d\d\d\d\w\w\d\d)/
  subject = row[0]
  session = row[1]
  tN = row[2]
  exists = row[6]

  scores["sub-#{subject}_ses-#{session}"][:"struct#{tN}"] = exists == "True"
end

log "tagging matteo's blacklisted scans ..."
matteo_blacklist.each do |key|
  scores[key][:matteo] = false
end

log "loading matteo's QC ..."
n_matteo = 0
CSV::foreach(matteo_qc) do |row|
  next if not row[1] =~ /(CC\d\d\d\d\d\w\w\d\d)/
  next if row[2] == "na"
  subject = row[1]
  session = row[2]
  pass = row[6].to_i == 1
  scores["sub-#{subject}_ses-#{session}"][:matteo_qc] = pass
  n_matteo += 1
end
puts "#{n_matteo} matteo successes"

log "loading sean's QC ..."
n_sean = 0
CSV::foreach(sean_qc) do |row|
  next if not row[1] =~ /(CC\d\d\d\d\d\w\w\d\d)/
  subject = row[1]
  session = row[2]
  pass = row[10] != "True"
  scores["sub-#{subject}_ses-#{session}"][:sean_qc] = pass
  n_sean += 1
end
puts "#{n_sean} sean successes"

# This went of part.tsv ... instead, just for now, work from the dir struct
# log "finding images in struct output with at least T2 ..."
# CSV::foreach(struct_pipeline_dir + "/participants.tsv", col_sep: " ") do |row|
#   next if not row[0] =~ /(CC\d\d\d\d\d\w\w\d\d)/
#   subject = row[0]
#   subject_dir = struct_pipeline_dir + "/derivatives/sub-#{subject}"
#   next if !File.exists?(subject_dir)
# 
#   # look for the subdir and get the session ids
#   CSV::foreach(subject_dir + "/sub-#{subject}_sessions.tsv", 
#     col_sep: " ") do |row|
#     next if row[0] == "session_id"
#     session = row[0]
# 
#     session_dir = subject_dir + "/ses-#{session}"
#     if File.exists?(session_dir + 
#       "/anat/sub-#{subject}_ses-#{session}_T2w.nii.gz")
#       scores["sub-#{subject}_ses-#{session}"][:has_struct] = true
#     end
#   end
# end

log "finding images in struct output with at least T2 ..."
n_struct = 0
Dir::glob("#{struct_pipeline_dir}/derivatives/sub-*") do |subject_dir|
  next if subject_dir !~ /.*\/sub-(CC.*)/
  subject = $~[1]

  Dir::glob("#{subject_dir}/ses-*") do |session_dir|
    next if session_dir !~ /.*\/ses-(.*)/
    session = $~[1]

    t2_file = "#{session_dir}/anat/sub-#{subject}_ses-#{session}_T2w.nii.gz"
    if !File.exists?(t2_file)
      puts "#{session_dir} exists, but there's no T2!"
    end

    scores["sub-#{subject}_ses-#{session}"][:has_struct] = true
    n_struct += 1
  end
end
puts "#{n_struct} struct pipeline successes"

# have a set of tests that can each be:
#   true - we think this scan is OK
#   false - we think it's bad
#   nil - no information
# then, ignoring nil values, we want all tests to AND true to accept

n_accept = 0
scores.each_pair do |key, value|
  matteo_test = value[:matteo]
  matteo_qc_test = value[:matteo_qc] == true
  sean_qc_test = value[:sean_qc] == true
  has_struct_test = value[:has_struct] 
  antonis_test = value[:antonis] 

  # set of criteria we test
  accept = [
#            matteo_test, 
            matteo_qc_test, 
            sean_qc_test, 
            has_struct_test, 
            antonis_test
           ].reduce do |a, b|
    # like AND, but ignore nil values
#    if a.nil?
#      b
#    elsif b.nil?
#      a
#    else
#      a && b
#    end
     a && b
  end

  if ! accept.nil?
    value[:accept] = accept
    n_accept += 1 if accept
  end

end

puts "#{scores.count} scans"
puts "#{n_accept} scans accepted"
puts "#{scores.count - n_accept} scans rejected"

puts "subject,session,accept,#{names.join(',')}"
scores.keys.sort.each do |key|
  key =~ /sub-(.*)_ses-(.*)/
  subject = $~[1]
  session = $~[2]
  print "#{subject},#{session},#{scores[key][:accept]},"
  names.each do |name|
    print "#{scores[key][name]},"
  end
  print "\n"
end

