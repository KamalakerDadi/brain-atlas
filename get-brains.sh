#!/bin/bash

src_dir=~/vol/dhcp-reconstructed-images/UpdatedReconstructions/ReconstructionsRelease03
derived=~/vol/dhcp-derived-data/derived_v1.1_github/ReconstructionsRelease03/derivatives

# 3rd col of participants.tsv is the scan age
#echo first 50 brains
#sort -nk 3,3 <$src_dir/participants.tsv | head -n 50
# be careful to avoid subjects with more than one scan 

ids="CC00112XX05 CC00309BN12 CC00248XX18 CC00218BN12 CC00281BN10 CC00308XX11 CC00261XX06 CC00187XX15"

rm -rf brains
mkdir -p brains

echo participant_id	gender	birth_ga > brains/participants.tsv
for i in $ids; do
	echo fetching $i ...
	grep $i $src_dir/participants.tsv >> brains/participants.tsv
	cp -r $derived/sub-$i/ses*/anat/sub-*_T2w.nii.gz brains/
done
