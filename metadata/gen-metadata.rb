#!/usr/bin/ruby

require 'json'
require 'csv'

require_relative 'my-utils.rb'

$options[:fatal] = false

opt_parser = ProgramArgs.new(ARGV)
opt_parser.banner("usage: #{$0} out-dir json-dir")
opt_parser.parse!

if ARGV.length != 2
  puts opt_parser
  exit
end

out_dir = ARGV[0]
json_dir = ARGV[1]

def load_json(json_dir, subject_id)
  json_file = "#{json_dir}/#{subject_id}.json"
  if !File.exist? json_file
    err "in derivatives, but no JSON"
    return nil
  end
  json = JSON.parse(open(json_file).read)

  # remove all sessions tagged `scan_disabled: 1`
  json.delete_if {|session| session['scan_disabled'] == '1'}

  json
end

combined_name = "#{out_dir}/combined.tsv"
CSV.open(combined_name, "w", col_sep: "\t") do |combined_tsv|
  combined_tsv << [
    "participant_id", 
    "session_id", 
    "gender", 
    "birth_ga", 
    "age_at_scan"
  ]

  part_name = "#{out_dir}/participants.tsv"
  CSV.open(part_name, "w", col_sep: "\t") do |participants_tsv|
    participants_tsv << ["participant_id", "gender", "birth_ga"]

    Dir.glob("#{json_dir}/CC*.json") do |subject_dir|
      next if subject_dir !~ /.*\/(CC.*)\.json/
      subject_id = $~[1]

      json = load_json json_dir, subject_id
      next if json == nil

      gender = nil
      age_at_birth = nil
      sess_name = "#{out_dir}/sub-#{subject_id}_sessions.tsv"
      CSV.open(sess_name, "w", col_sep: "\t") do |sessions_tsv|
        sessions_tsv << ["session_id", "age_at_scan"]
        json.each do |session|
          session_id = session["scan_validation"]
          age_at_scan = session["scan_ga_at_scan_weeks"]
          age_at_birth = session["baby_ga_at_birth_weeks"]
          gender = session["baby_gender"] == "F" ? "Female" : "Male"

          if session_id !~ /\d+/ || session_id.to_i == 0
            err "#{subject_id}-#{session_id} bad session_id"
            next
          end

          sessions_tsv << [session_id, age_at_scan]
          combined_tsv << [
            subject_id, 
            session_id, 
            gender, 
            age_at_birth, 
            age_at_scan
          ]
        end
      end

      participants_tsv << [subject_id, gender, age_at_birth]
    end
  end
end
