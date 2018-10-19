#!/usr/bin/ruby

require 'csv'
require 'fileutils'
require 'vips'

$: << File.dirname(__FILE__)
require 'my-utils.rb'

# assuming this script is in root/bin, get root
root = File.dirname(File.dirname(File.expand_path(__FILE__)));

# where we read the reference brain from
reference = "#{root}/etc/reference"

# where we write the DOFs we calculate
dofs = "#{root}/inputs/global/dof"
FileUtils.mkdir_p dofs

# all the scans we process
ages = "#{root}/inputs/config/ages.csv"

# struct pipeline output
images = "#{root}/inputs/images"

# bad brains
bad_subjects = %w(136 191 284 326 530 576 605 617 618 621 661 666 747 792 805)

log "testing dofs in #{dofs}"

CSV::foreach(ages) do |row|
  subject_ses = row[0]
  age_at_scan = row[1]

  subject_ses =~ /(.*)-(.*)/
  subject = $~[1]
  session = $~[2]
  dof = "#{dofs}/#{subject}-#{session}.dof.gz"

  if subject !~ /CC(\d+)([A-Z]{2})(\d{2})/
    err "bad subject #{subject}"
    next
  end
  subject_id = $~[1].to_i.to_s

  log "subject_id = #{subject_id}"

  if !bad_subjects.include? subject_id
    next
  end

  cmd = <<~EOF
      rview  #{reference}/serag-t40.nii.gz \
        #{images}/t2w/#{subject}-#{session}.nii.gz \
        #{dof} 
  EOF

  log "executing: #{cmd}"
  if ! system "#{cmd}"
    err "failed!"
  end
end

log "done!"
