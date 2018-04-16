#!/bin/bash

set -e

register() {
	mode=$1
	shift
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
			-image $next -image $first -dofout dofs/$dof \
			-model $model \
			-v 0 

		first=$next
	done
}

templates=atlas/templates/t2w
model=Rigid+Affine+SVFFD
echo "registering $templates using $model"
register $model $templates/*

