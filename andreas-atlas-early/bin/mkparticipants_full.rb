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
