#!/usr/bin/ruby

require 'csv'
require 'fileutils.rb'

# assuming this script is in root/bin, get root
root = File.dirname(File.dirname(File.expand_path(__FILE__)));

# we need images that the struct pipeline has run on, since we need tissue
# and struct labels ... we must therefore read from
base = "/home/john/vol/dhcp-derived-data/derived_02Jun2018"

FileUtils.mkdir_p "#{root}/inputs/images/t1w"
FileUtils.mkdir_p "#{root}/inputs/images/t2w"
FileUtils.mkdir_p "#{root}/inputs/labels/tissues"
FileUtils.mkdir_p "#{root}/inputs/labels/structures"

CSV::foreach(ARGV[0], col_sep: " ") do |row|
  subject_ses = row[0]

  subject_ses =~ /(.*)-(.*)/
  subject = $~[1]
  session = $~[2]

  puts "#{subject} #{session} ..."

  src = "#{base}/derivatives/sub-#{subject}/ses-#{session}/anat"
  t1_src = "#{src}/sub-#{subject}_ses-#{session}_T1w.nii.gz"
  t2_src = "#{src}/sub-#{subject}_ses-#{session}_T2w.nii.gz"
  tissues_src = "#{src}/sub-#{subject}_ses-#{session}_drawem_tissue_labels.nii.gz"
  struct_src = "#{src}/sub-#{subject}_ses-#{session}_drawem_all_labels.nii.gz"

  dst = "#{root}/inputs"
  t1_dst = "#{dst}/images/t1w/#{subject}-#{session}.nii.gz"
  t2_dst = "#{dst}/images/t2w/#{subject}-#{session}.nii.gz"
  tissues_dst = "#{dst}/labels/tissues/#{subject}-#{session}.nii.gz"
  struct_dst = "#{dst}/labels/structures/#{subject}-#{session}.nii.gz"

  FileUtils::cp t1_src, t1_dst
  FileUtils::cp t2_src, t2_dst
  FileUtils::cp tissues_src, tissues_dst
  FileUtils::cp struct_src, struct_dst
end
