#!/bin/bash

server=/vol/dhcp-derived-data/volumetric-atlases/jcupitt

rm -f inputs output
ln -s $server/inputs inputs
ln -s $server/output output
