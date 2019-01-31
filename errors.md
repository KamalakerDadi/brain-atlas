# Metadata fixes necessary for struct pipeline QC

This summarizes the problems in 

    /vol/dhcp-derived-data/derived_02Jun2018/participants.tsv

on Wed 30 Jan 17:15:46 GMT 2019.

## Bad gender 

These scans have gender as `n/a`. We need the gender to be able to calculate
some QC metrics.

Actions:

* Find the gender for CC00785XX19 and CC00824XX16.

## CC00136AN13 and CC00136BN13

These are the same subject and same scans, but AN13 had a validation error.
BN13 is the same thing but fixed. BN13 `sessions.tsv` has an erroneous extra
line.

Actions:

* Remove CC00136AN13
* Remove the final line from `sub-CC00136BN13_sessions.tsv`

## Bad session id

These subjects have a line in their `sessions.tsv` file with a session id of 0.
Most of the time it's an extra redundant line (the date matches another real
session), but sometimes it seems to be naming a real but missing session.

Actions:

* Fix `sessions.tsv` for CC00085XX12 CC00087BN14 CC00106XX07 CC00112XX05 
  CC00136BN13 CC00144XX13 CC00164XX08 CC00166XX10 CC00177XX13 CC00181XX09 
  CC00218BN12 CC00227XX13 CC00281AN10 CC00284AN13 CC00338BN17

The subjects have a session id of `n/a`.

Actions: 

* Fix the missing id for CC00112XX05 CC00121XX06 CC00287BN16 CC00447XX19 
  CC00520XX09 CC00529BN18 CC00637XX19 CC00642XX16 CC00660XX09 CC00668XX17 
  CC00713XX12 CC00714XX13 CC00716XX15 CC00736XX19 CC00737XX20

# Missing `sessions.tsv`

These subjects have empty `sessions.tsv` files, though there are processed
images.

Actions:

* Find the session ids and ages for CC00783XX17 CC00787XX21 CC00789XX23 
  CC00791XX17 CC00793XX19 CC00797XX23 CC00799XX25 CC00801XX09 CC00810XX10
  CC00811XX11 CC00815XX15 CC00816XX16 CC00818XX18 CC00824XX16 CC00832XX16
  CC00843XX19 CC00850XX09 CC00851XX10 CC00853XX12 CC00854XX13 CC00860XX11
  CC00867XX18 CC00879XX22 CC00889AN24 CC00889BN24 CC00907XX16

