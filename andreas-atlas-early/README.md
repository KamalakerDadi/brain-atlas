# Construct early brain atlases

See `../andreas-atlas` for Andreas' original atlas work.

This version builds atlases for the early weeks where we have many fewer
sample brains. 

Link the server input and output directories here:

```
$ ./bin/mklinks.sh
```

Search the server and find all scans and scan ages.

```
$ ./bin/mkparticipants_full.rb > participants_full.tsv
```

Pick out just the weeks you want:

```
$ mkdir -p inputs/config
$ ./bin/mkconfig.rb participants_full.tsv 29 36 > inputs/config/ages.csv
```

Make `inputs/config/subjects.csv` by dropping column two.

Get all the QC and search for fails:

```
$ ./bin/qc.rb > x.csv
```

Look for the "should fail, but pass" section and copy those scan names into
`inputs/config/blacklist.csv`.

Get the source images:

```
$ ./bin/fetch_images.rb inputs/config/subjects.csv
```

Generate the global normalisation dofs:

```
$ ./bin/make_global_normalization.rb 
```

To build dofs in `inputs/global/dof`.

Use `rview` to check the dofs. Without the transform, flicking between A and B
will produce a large shift:

```
$ rview etc/reference/serag-t40.nii.gz inputs/images/t2w/CC00063AN06-15102.nii.gz 
```

Add the transform, and the brain stem should be locked in place.

```
$ rview etc/reference/serag-t40.nii.gz inputs/images/t2w/CC00063AN06-15102.nii.gz inputs/global/dof/CC00063AN06-15102.dof.gz 
```

Check them all:

```
$ ./bin/view_global_normalization.rb 
```

These brains fail for some reason -- investigate.

| Subject | Notes |
| ------- | ----- |
| 136     | miss |
| 284     | miss |
| 576     | 90 degree miss |
| 617     | miss |
| 618     | miss |
| 621     | miss |
| 661     | miss |
| 666     | miss |
| 747     | miss, brain looks odd |
| 792     | miss |
| 805     | miss, brain very young? |

Add lines from `subject.csv` for failing scans to
`inputs/config/blacklist.csv`.

Filter ages and subjects by blacklist.

```
$ ./bin/blacklist.rb 
```

Copy over the rois from Andreas' version:

```
$ mkdir -p inputs/global/roi
$ cp ../andreas-atlas/inputs/global/roi/domain.nii.gz inputs/global/roi
```

Build the atlas:

```
$ mirtk construct-atlas john-adaptive-sigma_1.00-nmi.json
```


