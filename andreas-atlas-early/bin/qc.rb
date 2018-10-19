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

# all the names we load
names = [:antonis1, :antonis2, :antonis3, :kingsT1, :kingsT2, 
         :structT1, :structT2]

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

def median(array)
  sorted = array.sort
  len = sorted.length
  (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
end

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

# accept if:
#     median antonis score >= 3
#  OR if not antonis available, then
#     kingsT1 and kingsT2 pass
#
# look for strange scans: 
#   - accept, but struct pipeline fails
#   - don't accept, struct pipeline passes
struct_should_fail_but_passes = []
struct_should_pass_but_fails = []
n_accept = 0
scores.each_pair do |key, value|
  antonis = get_antonis(value)
  if antonis > 0
    accept = antonis >= 3
  else
    accept = value.key?(:kingsT1) && value.key?(:kingsT2)
  end
  value[:accept] = accept
  n_accept += 1 if accept

  if accept && (!value.key?(:structT1) || !value.key?(:structT2))
    value[:should_pass_but_fails] = true
    struct_should_pass_but_fails << key
  end

  if !accept && (value.key?(:structT1) && value.key?(:structT2))
    value[:should_fail_but_passes] = true
    struct_should_fail_but_passes << key
  end

end

puts "#{n_accept} scans accepted"
puts "#{scores.count - n_accept} scans rejected"

puts "should fail but pass struct pipeline:"
struct_should_fail_but_passes.sort.each do |x|
  x =~ /sub-(.*)_ses-(.*)/
  subject = $~[1]
  session = $~[2]
  puts "#{subject}-#{session}"
end

puts "should pass but fail struct pipeline:"
struct_should_pass_but_fails.sort.each do |x|
  x =~ /sub-(.*)_ses-(.*)/
  subject = $~[1]
  session = $~[2]
  puts "#{subject}-#{session}"
end

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




  
