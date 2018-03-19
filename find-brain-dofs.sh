#!/bin/bash

# set -x

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
		if [ ! -f dofs/$code-t$age.dof ]; then 
			echo register to $age ...
			mirtk register \
				-image atlas/templates/t2w/t$age.00.nii.gz \
				-image $brain \
				-dofout dofs/$code-t$age.dof \
				-v 0 || { 
				echo register failed
				exit 1
			}
		fi
	fi
done < brains/participants.tsv 
