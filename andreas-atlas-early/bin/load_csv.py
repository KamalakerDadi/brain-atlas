#!/usr/bin/python3

import re
import sys
import csv

csv_filename = sys.argv[1]
struct_files = "/vol/dhcp-derived-data/derived_02Jun2018/derivatives"

for row in csv.reader(open(csv_filename, "r")):
    subject = row[0]

    # all data rows have "CC" at the start of the subject
    if not re.match("CC", subject):
        continue

    session = row[1]
    antonis1 = row[2]
    antonis2 = row[3]
    antonis3 = row[4]
    antonis_median = row[5]

    # construct a filename from subjects and session
    filename = "{0}/sub-{1}/ses-{2}/anat/sub-{1}_ses-{2}_T2w.nii.gz" \
        .format(struct_files, subject, session)

    print("subject =", subject)
    print("session =", session)
    print("filename =", filename)
    print("median QC =", antonis_median)
