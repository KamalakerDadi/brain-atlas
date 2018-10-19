#!/bin/bash

groupwise=~/vol/dhcp-derived-data/volumetric-atlases/groupwise

rm -rf inputs

mkdir -p inputs

for i in config global images labels ; do
  ln -s $groupwise/$i inputs/
done

ln -s ~/vol/dhcp-derived-data/volumetric-atlases/jcupitt output
