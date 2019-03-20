#!/usr/bin/ruby

require 'csv'
require_relative 'my-utils'

opt_parser = ProgramArgs.new(ARGV)
opt_parser.banner("usage: #{$0} combined.tsv /path/to/derivatives ...")
opt_parser.parse!

if ARGV.length < 2
  puts opt_parser
  exit
end

combined = {}
CSV::foreach(ARGV[0], col_sep: "\t") do |row|
  next if row[0] == "participant_id"

  subject = row[0]
  session = row[1]
  gender = row[2]
  birth_ga = row[3].to_f
  age_at_scan = row[4].to_f
  key = "#{subject}-#{session}"

  if combined.include? key
    err "#{key} duplicate key"
    next
  end

  combined[key] = {
    subject: subject,
    session: session,
    gender: gender,
    birth_ga: birth_ga,
    age_at_scan: age_at_scan,
  }

end

vol = "/home/john/vol"

# Antonis' manual QC programme
antonis1 = "#{vol}/medic01/users/am411/dhcp-v2.3/manual-QC-serena/image_score.csv"
antonis2 = "#{vol}/medic01/users/am411/dhcp-v2.3/manual-QC/image_score.csv"
antonis3 = "#{vol}/medic01/users/am411/dhcp-v2.3/manual-QC/image_score_479_images.csv"

log "loading Antonis manual QC ..."

scores = Hash.new {|hash, key| hash[key] = {}}

CSV::foreach(antonis1) do |row|
  next if not row[0] =~ /(.*)-(.*)/
  subject = $~[1]
  session = $~[2]
  key = "#{subject}-#{session}"

  scores[key][:antonis1] = row[1].to_i
end

CSV::foreach(antonis2) do |row|
  next if not row[0] =~ /(.*)-(.*)/
  subject = $~[1]
  session = $~[2]
  key = "#{subject}-#{session}"

  scores[key][:antonis2] = row[1].to_i
end

CSV::foreach(antonis3) do |row|
  next if not row[0] =~ /(.*)-(.*)/
  subject = $~[1]
  session = $~[2]
  key = "#{subject}-#{session}"

  scores[key][:antonis3] = row[1].to_i
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
    scores[key][:antonis] = antonis_score
  end
end

log "writing participants_full.tsv ..."
CSV.open("participants_full.tsv", "w", col_sep: "\t") do |participants_full|
  participants_full << [
    "participant_id", 
    "session_id", 
    "gender", 
    "birth_ga", 
    "age_at_scan"
  ]

  ARGV[1..-1].each do |base|
    Dir::glob("#{base}/sub-*").each do |subject_dir|
      next if subject_dir !~ /.*\/sub-(CC.*)/
      subject = $~[1]

      Dir.glob("#{subject_dir}/ses-*") do |session_dir|
        next if session_dir !~ /.*\/ses-(.*)/
        session = $~[1]

        key = "#{subject}-#{session}"

        root = "#{session_dir}/anat/sub-#{subject}_ses-#{session}"
        if ! File::exist? "#{root}_T1w.nii.gz"
          log "#{key} no T1 image"
          next
        end
        if ! File::exist? "#{root}_T2w.nii.gz"
          log "#{key} no T2 image"
          next
        end

        if ! combined.include? key
          log "#{key} no metadata"
          next
        end
        metadata = combined[key]

        if metadata[:age_at_scan] < metadata[:birth_ga]
          log "#{key} fetal scan"
          next
        end

        if scores[key] && scores[key][:antonis] && scores[key][:antonis] < 3
          log "#{key} bad antonis score"
          next
        end

        participants_full << [
          subject, 
          session, 
          metadata[:gender],
          metadata[:birth_ga], 
          metadata[:age_at_scan]
        ]
      end
    end
  end
end
