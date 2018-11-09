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
images = "/vol/dhcp-derived-data/derived_02Jun2018/derivatives"

# tmp area
tmp = "#{root}/tmp"
FileUtils.mkdir_p tmp

log "generating dofs in #{dofs}"

CSV::foreach(ages) do |row|
  subject_ses = row[0]
  age_at_scan = row[1]

  subject_ses =~ /(.*)-(.*)/
  subject = $~[1]
  session = $~[2]

  dofout = "#{dofs}/#{subject}-#{session}.dof.gz"

  if ! File.exist? dofout
    log "processing #{subject} #{session} ..."

    # make a bs+cb mask 
    inputs = "#{images}/sub-#{subject}/ses-#{session}/anat"

    # in tissue-labels, stem is 8, cerebellum is 6
    file = "#{inputs}/sub-#{subject}_ses-#{session}_drawem_tissue_labels.nii.gz"
    tissue_labels = Vips::Image.new_from_file file

    cbbs_mask = ((tissue_labels == 8) | (tissue_labels == 6)) * (100.0 / 255.0)
    cbbs_mask = cbbs_mask.cast('uchar')
    file = "#{tmp}/sub-#{subject}_ses-#{session}_bs+cb.nii.gz"
    cbbs_mask.write_to_file file

    # run mirtk register to generate the dof
    cmd = <<~EOF
        mirtk register \
          -image #{reference}/serag-t40.nii.gz \
          -mask #{reference}/serag-t40-bs+cb.nii.gz \
          -image #{inputs}/sub-#{subject}_ses-#{session}_T2w.nii.gz \
          -mask #{tmp}/sub-#{subject}_ses-#{session}_bs+cb.nii.gz \
          -dofout #{dofout} \
          -model Rigid+Affine \
          -v 0
    EOF

    log "executing: #{cmd}"
    if ! system "#{cmd}"
      err "failed!"
    end
  end
end

log "done!"
