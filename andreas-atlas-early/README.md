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

Login to a doc machine and clone this repo into your home area. It needs to
be on a public path, such as
`/homes/jcupitt/GIT/brain-atlas/andreas-atlas-early`.

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
