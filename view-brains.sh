#!/bin/bash

rview=~/GIT/Viewer/build/fltk/rview

for i in resampled/CC*-t40.nii.gz; do
	$rview $i atlas/templates/t2w/t40.00.nii.gz
done
