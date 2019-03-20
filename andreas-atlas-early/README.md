# Construct early brain atlases

See `../andreas-atlas` for Andreas' original atlas work.

This version builds atlases for the early weeks where we have many fewer
sample brains. 

# Before you start

You need an up-to-date MIRTK install on a doc machine in a globally visible
directory, such as `/homes/jcupitt/mirtk`. Put that area on your `PATH` by
adding to your `.bashrc`:

```
export MIRTK_ROOT=/homes/jcupitt/mirtk

export PATH="$MIRTK_ROOT/bin:$PATH"
export LD_LIBRARY_PATH=$MIRTK_ROOT/lib:$LD_LIBRARY_PATH

# completions for mirtk
[ ! -f "$MIRTK_ROOT/share/mirtk/completion/bash/mirtk" ] ||
  source "$MIRTK_ROOT/share/mirtk/completion/bash/mirtk"
```

The quota on the home dir is too small for this, so use a scratch area like
`/data/jcupitt/GIT`for the build itself.

```
cd /data/jcupitt
mkdir GIT
cd GIT
```

Ubuntu 16.04 cmake is too old. Build!

```
git clone https://github.com/Kitware/CMake.git
cd CMake
./bootstrap --prefix=/homes/jcupitt/mirtk
make
make install
```

You may need to update `PATH` to see the new `cmake`.

Next, ITK:

```
cd /data/jcupitt/GIT
git clone https://github.com/InsightSoftwareConsortium/ITK.git
cd ITK
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/homes/jcupitt/mirtk -DBUILD_EXAMPLES=OFF -DBUILD_SHARED_LIBS=ON -DBUILD_TESTING=OFF ..
make
make install
```

Now VTK:

```
cd /data/jcupitt/GIT
git clone https://github.com/Kitware/VTK.git
cd VTK
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/homes/jcupitt/mirtk ..
make
make install
```

Now Eigen:

```
cd /data/jcupitt
wget http://bitbucket.org/eigen/eigen/get/3.3.5.tar.bz2
tar xf 3.3.5.tar.bz2 
cd eigen*
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/homes/jcupitt/mirtk ..
make
make install
```

And finally MIRTK:

```
cd /data/jcupitt/GIT
git clone --recursive https://github.com/BioMedIA/MIRTK.git
cd MIRTK
git submodule update
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/homes/jcupitt/mirtk \
    -DMODULE_Deformable=ON \
    -DMODULE_DrawEM=ON \
    -DMODULE_Mapping=ON \
    -DMODULE_Scripting=ON \
    -DWITH_VTK=ON \
    -DWITH_TBB=ON \
    -DWITH_Python=ON \
    ..
make
make install
```

# This repo

Login to a doc machine and clone this repo into your
home area. It needs to be on a public path, such as
`/homes/jcupitt/GIT/brain-atlas/andreas-atlas-early`.

Link the server input and output directories here:

```
$ ./bin/mklinks.sh
```

Search the server and find all scans and scan ages.

```
$ ./bin/mkparticipants_full.rb 
```

Pick out just the weeks you want:

```
$ mkdir -p inputs/config
$ ./bin/mkconfig.rb participants_full.tsv 28 45 > inputs/config/ages.csv
```

Make `inputs/config/subjects.csv` by dropping column two.

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

Remove any old run (if you want to restart everything):

```
$ rm -rf output/dhcp-w29-35-adaptive-sigma_1.00-nmi
```

Ask for a loooong (1000 hour) timeout on your Kerberos token (jobs will
start failing after a few hours without this):

```
$ kinit -l 1000h
```

Build the atlas:

```
$ mirtk construct-atlas john-adaptive-sigma_1.00-nmi.json
```

## Progress

Currently fails at step 8 when run on Condor:

```
2018-Nov-19 19:22:29 INFO Creating final mean shape templates
2018-Nov-19 19:22:29 INFO Deform images to discrete time points (step=8)
2018-Nov-19 19:22:33 INFO Submitted batch 'defimgs' (id=106, #jobs=440, #tasks=1760)
2018-Nov-19 19:23:36 WAIT 440 pending, 0 running, 0 suspended, 0 held, 0 completed
2018-Nov-19 19:24:36 WAIT 78 pending, 255 running, 0 suspended, 0 held, 107 completed
2018-Nov-19 19:25:30 WAIT 1 pending, 238 running, 0 suspended, 0 held, 201 completed
2018-Nov-19 19:26:04 WAIT 0 pending, 39 running, 0 suspended, 0 held, 401 completed
2018-Nov-19 19:26:34 WAIT 0 pending, 8 running, 0 suspended, 0 held, 432 completed
2018-Nov-19 19:27:05 WAIT 0 pending, 4 running, 0 suspended, 0 held, 436 completed
2018-Nov-19 19:27:35 WAIT 0 pending, 1 running, 0 suspended, 0 held, 439 completed
2018-Nov-19 19:28:05 WAIT 0 pending, 1 running, 0 suspended, 0 held, 439 completed
2018-Nov-19 19:28:35 WAIT 0 pending, 1 running, 0 suspended, 0 held, 439 completed
2018-Nov-19 19:29:06 WAIT 0 pending, 1 running, 0 suspended, 0 held, 439 completed
2018-Nov-19 19:29:36 WAIT 0 pending, 1 running, 0 suspended, 0 held, 439 completed
2018-Nov-19 19:30:06 WAIT 0 pending, 1 running, 0 suspended, 0 held, 439 completed
2018-Nov-19 19:30:36 WAIT 0 pending, 0 running, 0 suspended, 0 held, 440 completed
2018-Nov-19 19:31:32 DONE 292 succeeded, 148 failed
Traceback (most recent call last):
  File "/homes/jcupitt/mirtk/lib/tools/construct-atlas", line 147, in <module>
    atlas.construct(start=args.start, niter=args.steps - args.start)
  File "/homes/jcupitt/mirtk/lib/python/mirtk/atlas/spatiotemporal.py", line 1148, in construct
    self.wait(job, interval=30, verbose=1)
  File "/homes/jcupitt/mirtk/lib/python/mirtk/atlas/spatiotemporal.py", line 254, in wait
    raise Exception("Not all HTCondor jobs finished successfully!")
Exception: Not all HTCondor jobs finished successfully!
Error: construct-atlas command returned non-zero exit status 1
```
