#!/bin/bash

# set -x
set -e

model=Rigid+Affine+SVFFD
out=dofs

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

		# register to atlas
		if [ ! -f $out/$code-t$age.dof ]; then 
			echo register to $age ...
			mirtk register \
				-image atlas/templates/t2w/t$age.00.nii.gz \
				-image $brain \
				-dofout $out/$code-t$age.dof \
				-model $model \
				-v 0 
		fi
	fi
done < brains/participants.tsv 
