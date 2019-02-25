#!/usr/bin/ruby

require 'json'
require 'csv'

require_relative 'my-utils.rb'

$options[:fatal] = false

opt_parser = ProgramArgs.new(ARGV)
opt_parser.banner("usage: #{$0} /path/to/derivatives")
opt_parser.parse!

if ARGV.length != 2
  puts opt_parser
  exit
end

json_dir = ARGV[0]
derivatives_dir = ARGV[1]

$error_table = {}
def subject_err subject, message
  if !$error_table.include? message
    $error_table[message] = []
  end
  $error_table[message] = $error_table[message] << subject
  err "#{subject} #{message}"
end

def err_dump
  log "# Error summary"
  log ""
  $error_table.each do |key, value|
    log "# #{key}"
    log ""
    log "#{value.sort.join(" ")}"
    log ""
  end
end

# find all the subjects we will be checking
subjects = []
Dir.glob("#{derivatives_dir}/sub-CC*") do |subject_dir|
  next if subject_dir !~ /.*\/sub-(CC.*)/
  subject_id = $~[1]
  subjects << subject_id
end
log "found #{subjects.length} subjects in #{derivatives_dir}"

def load_json(json_dir, subject_id)
  json_file = "#{json_dir}/#{subject_id}.json"
  if !File.exist? json_file
    subject_err subject_id, "in derivatives, but no JSON"
    return nil
  end
  json = JSON.parse(open(json_file).read)

  # remove all sessions tagged `scan_disabled: 1`
  json.delete_if {|session| session['scan_disabled'] == '1'}

  return json
end

# for each, load the JSON, and sanity check against what we have in the
# filesystem
subjects.each do |subject_id|
  json = load_json json_dir, subject_id
  if json == nil
    next
  end

  # first, check that we have a session dir for each session in redcap
  json.each do |session|
    session_id = session["scan_validation"]
    if session_id !~ /\d+/ || session_id.to_i == 0
      subject_err "#{subject_id}-#{session_id}", "bad scan_validation field"
      next
    end

    session_dir = "#{derivatives_dir}/sub-#{subject_id}/ses-#{session_id}"
    if !File.exist? session_dir
      subject_err "#{subject_id}-#{session_id}", "in JSON but no dir"
    end
  end

  # now check that every session dir in derivatives_dir has an entry in redcap
  Dir.glob("#{derivatives_dir}/sub-#{subject_id}/ses-*") do |session_dir|
    next if session_dir !~ /.*\/ses-(.*)/
    session_id = $~[1]

    if session_id !~ /\d+/
      subject_err "#{subject_id}-#{session_id}", "bad session_id in dir"
      next
    end

    session = json.find_all {|x| x["scan_validation"] == session_id}
    if session.length == 0
      subject_err "#{subject_id}-#{session_id}", "dir but no JSON"
      next
    end 
    if session.length > 1
      subject_err "#{subject_id}-#{session_id}", "in JSON twice"
      next
    end 

    session = session[0]

    # and verify gender and age at scan

    age_at_scan = session["scan_ga_at_scan_weeks"]
    if age_at_scan !~ /\d+(\.\d+)?/
      subject_err "#{subject_id}-#{session_id}", "bad age at scan"
    end

    if age_at_scan.to_f < 10 || age_at_scan.to_f > 50
      subject_err "#{subject_id}-#{session_id}", "age at scan out of range"
    end

    age_at_birth = session["baby_ga_at_birth_weeks"]
    if age_at_birth !~ /\d+(\.\d+)?/
      subject_err "#{subject_id}-#{session_id}", "bad age at birth"
    end

    if age_at_birth.to_f < 10 || age_at_birth.to_f > 50
      subject_err "#{subject_id}-#{session_id}", "age at birth out of range"
    end

    gender = session["baby_gender"]
    if gender !~ /[MF]/
      subject_err "#{subject_id}-#{session_id}", "bad gender"
    end

  end

end

log "all done!"
err_dump
