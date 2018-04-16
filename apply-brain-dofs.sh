#!/bin/bash

# set -x
set -e

warp() {
	local brain=$1
	local out=$2
	local first=$3
	local age=$4

	if [ ! -f $first ]; then
		echo "  no dof $first"
		return
	fi

	if [ -f $out ]; then
		echo "  already made $out"
		return
	fi

	local dofs="-dofin $first"
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

	local cmd="mirtk transform-image $brain $out $dofs \
		-interp bspline -target atlas/templates/t2w/t40.00.nii.gz"
	echo $cmd
	$cmd 
}

while IFS='' read -r line || [[ -n "$line" ]]; do
	if [[ ! $line =~ parti*. ]]; then
		split=($line)
		code=${split[0]}
		age=${split[2]}
		brain=brains/sub-${code}_*

		echo processing brain $code ...

		# find nearest in atlas
		age=$(printf "%.0f\n" "$age")
		while [ ! -f atlas/templates/t2w/t$age.00.nii.gz ]; do
			if [ $age -gt 40 ]; then
				age=$((age - 1))
			else
				age=$((age + 1))
			fi
		done

		warp $brain resampled/$code-t$age-t40.nii.gz \
			dofs/$code-t$age.dof $age
	fi
done < brains/participants.tsv 
