#!/bin/bash

apply() {
	new_dir=$1
	shift

	while [ $# -ne 0 ]; do
		brain=$1
		shift

		dir=$(dirname $brain)
		file=$(basename $brain)
		# get before the first .
		t=${file%%.*}
		# swap first path component for "resampled/"
		new_dir=resampled/${dir#*/}
		mkdir -p $new_dir
		out=$new_dir/$t-t40.nii.gz

		if [[ $t =~ t([0-9]+) ]]; then
			time=${BASH_REMATCH[1]}
			dofs=

			while [ $time -ne 40 ]; do
				if [ $time -gt 40 ]; then
					new_time=$((time - 1))
					dofs+=" -dofin_i "
					dofs+="dofs/t$new_time-t$time.dof"
				else
					new_time=$((time + 1))
					dofs+=" -dofin "
					dofs+="dofs/t$time-t$new_time.dof"
				fi

				time=$new_time
			done

			echo generating $out ...
			if [ x"$dofs" == x ]; then
				cp $brain $out
			else
				mirtk transform-image \
					$brain $out $dofs \
					-interp "Fast cubic BSpline" || { 
					echo transform-image failed
					exit 1
				}
			fi
		fi
	done
}

apply atlas/labels/structures/*
apply atlas/labels/tissues/*
apply atlas/templates/t1w/*
apply atlas/templates/t2w/*

