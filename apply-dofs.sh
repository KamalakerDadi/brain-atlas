#!/bin/bash

warp() {
	local brain=$1
	local out=$2
	local age=$3

	if [ -f $out ]; then
		echo "  already made $out"
		return
	fi

	local dofs=""
	local new_age
	local dof_flag
	local dof

	while [ $age -ne 40 ]; do
		if [ $age -gt 40 ]; then
			new_age=$((age - 1))
			dof_flag="-dofin_i"
			dof="dofs/t$new_age-t$age.dof"
		else
			new_age=$((age + 1))
			dof_flag="-dofin"
			dof="dofs/t$age-t$new_age.dof"
		fi

		if [ -f $dof ]; then
			dofs+=" $dof_flag $dof "
		fi

		age=$new_age
	done

	if [ x"$dofs" == x ]; then
		local cmd="cp $brain $out"
	else
		local cmd="mirtk transform-image $brain $out $dofs \
			-interp bspline \
			-target atlas/templates/t2w/t40.00.nii.gz"
	fi

	echo $cmd
	$cmd || { 
		echo transform-image failed
		exit 1
	}
}

apply() {
	while [ $# -ne 0 ]; do
		local brain=$1
		shift

		local dir=$(dirname $brain)
		local file=$(basename $brain)
		# get before the first .
		local t=${file%%.*}
		# swap first path component for "resampled/"
		local new_dir=resampled/${dir#*/}
		mkdir -p $new_dir
		local out=$new_dir/$t-t40.nii.gz

		if [[ ! $t =~ t([0-9]+) ]]; then
			echo bad t $t
			exit 1
		fi
		age=${BASH_REMATCH[1]}

		warp $brain $out $age
	done
}

apply atlas/labels/structures/*
apply atlas/labels/tissues/*
apply atlas/scaled/t1w/*
apply atlas/scaled/t2w/*
apply atlas/templates/t1w/*
apply atlas/templates/t2w/*

