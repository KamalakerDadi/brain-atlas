#!/bin/bash

register() {
	first=$1
	shift

	while [ $# -ne 0 ]; do
		next=$1
		shift

		first_file=$(basename $first)
		next_file=$(basename $next)
		t1=${first_file%%.*}
		t2=${next_file%%.*}
		dof=$t1-$t2.dof

		echo "register $next "
		echo "     and $first to $dof ..."
		mkdir -p dofs
		mirtk register \
			-image $next -image $first -dofout dofs/$dof -v 0 || { 
			echo register failed
			exit 1
		}

		first=$next
	done
}

register atlas/templates/t2w/*

