#!/usr/bin/ruby

# pull together the various sources of QC data we have at Imperial for the
# structural pipeline

require 'csv'

require_relative 'my-utils.rb'

vol = "/home/john/vol"

# Antonis' manual QC programme
antonis1 = "#{vol}/medic01/users/am411/dhcp-v2.3/manual-QC-serena/image_score.csv"
antonis2 = "#{vol}/medic01/users/am411/dhcp-v2.3/manual-QC/image_score.csv"
antonis3 = "#{vol}/medic01/users/am411/dhcp-v2.3/manual-QC/image_score_479_images.csv"

# struct pipeline output of 02 June 
struct_pipeline_dir = "#{vol}/dhcp-derived-data/derived_02Jun2018"
derivatives_dir = "#{struct_pipeline_dir}/derivatives"

# struct pipeline automated QC output
struct_qc = "#{struct_pipeline_dir}/reports/image_QC_measures.csv"

blacklist = [
  # 287 is still mysterious and is being investigated
  "CC00287BN16",

  # fetal trial subjects which we processed accidentally
  "CC00637XX19",
  "CC00642XX16",
  "CC00660XX09",
  "CC00668XX17",
  "CC00713XX12",
  "CC00714XX13",
  "CC00716XX15",
  "CC00736XX19",
  "CC00737XX20",

  # struct pipeline failure
  "CC00605XX11",
]

# all the names we display
names = [:tsv, :antonis1, :antonis2, :antonis3, :antonis, 
         :blacklist, :has_T2, :struct_qc_T1, :struct_qc_T2]

# a hash of hashes 
# scores["sub-CCxxx_ses-yyy"] == {antonis1: 12}
scores = Hash.new {|hash, key| hash[key] = {}}

# load the tsv as the "backbone" of the image set
CSV::foreach("#{struct_pipeline_dir}/tsv/combined.tsv", col_sep: "\t") do |row|
  subject = row[0]
  session = row[1]
  next if subject == "participant_id"

  scores["sub-#{subject}_ses-#{session}"][:tsv] = true
end

log "loading Antonis manual QC ..."

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

log "loading struct pipeline QC ..."
CSV::foreach(struct_qc) do |row|
  next if not row[0] =~ /(CC\d\d\d\d\d\w\w\d\d)/
  subject = row[0]
  session = row[1]
  tN = row[2]
  exists = row[6]

  scores["sub-#{subject}_ses-#{session}"][:"struct_qc_#{tN}"] = exists == "True"
end

# check we have some struct output
log "checking for t2 ..."
CSV::foreach("#{struct_pipeline_dir}/tsv/combined.tsv", col_sep: "\t") do |row|
  subject = row[0]
  session = row[1]
  next if subject == "participant_id"

  ses_dir = "#{derivatives_dir}/sub-#{subject}/ses-#{session}"
  t2_file = "#{ses_dir}/anat/sub-#{subject}_ses-#{session}_T2w.nii.gz"
  scores["sub-#{subject}_ses-#{session}"][:has_T2] = File.exists? t2_file

end

log "tagging blacklisted scans ..."
scores.each_pair do |key, value|
  key =~ /sub-(.*)_ses-(.*)/
  subject = $~[1]
  session = $~[2]

  if blacklist.include? subject
    scores[key][:blacklist] = false
  end
end

# we MUST have tsv data .. eg. just an antonis isn't enough
# make all nil tsv columns into FALSE
scores.each_pair do |key, value|
  if scores[key][:tsv].nil?
    scores[key][:tsv] = false
  end
end

# have a set of tests that can each be:
#   true - should pass
#   false - must fail
#   nil - no information
# then, ignoring nil values, we want all tests to AND true to accept

n_accept = 0
# colums we AND together
test_columns = [:tsv, :antonis, :blacklist, :has_T2, 
                :struct_qc_T1, :struct_qc_T2]
scores.each_pair do |key, value|
  accept = (test_columns.map {|x| value[x]}).reduce do |a, b|
    # like AND, but ignore nil values
    if a.nil?
      b
    elsif b.nil?
      a
    else
      a && b
    end
  end

  if ! accept.nil?
    value[:accept] = accept
    n_accept += 1 if accept
  end

end

puts "#{scores.count} scans"
puts "#{n_accept} scans accepted"
puts "#{scores.count - n_accept} scans rejected"
puts "meaning of columns:"
puts "   accept       -- all non-nil test columns are TRUE"
puts "   tsv          -- TRUE if we have redcap data for this scan"
puts "   antonis1     -- serena's scores from 2016"
puts "   antonis2     -- antonis' scores from 2016"
puts "   antonis3     -- antonis' scores from 2017"
puts "   antonis      -- TRUE if median antonis[1-3] >= 2"
puts "   blacklist    -- FALSE if subject has been blacklisted"
puts "   has_T2       -- TRUE if there's a T2 scan in struct output"
puts "   struct_qc_T1 -- TRUE if struct auto QC has T1 output"
puts "   struct_qc_T2 -- TRUE if struct auto QC has T2 output"

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

