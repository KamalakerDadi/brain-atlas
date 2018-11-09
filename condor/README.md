# Test Condor setup

See https://biomedia.doc.ic.ac.uk/internal/computer-resources/condor/ for
notes.

Log into a doc machine and clone this repo into your home area. It needs to be
on a publically visible path, such as `/homes/jcupitt/GIT/brain-atlas/condor`.

Install condor ... htcondor in Debian.

# Reset files

```
$ rm -rf log out
$ mkdir log out
```

# Submitting jobs

```
$ condor_submit foo.condor
```

# Results

```
log/foo_condor-0.err
log/foo_condor-1.err
log/foo_condor-2.err
log/foo_condor-3.err
log/foo_condor-4.err
```

Hopefully all empty.

```
log/foo_condor.log
```

Log of actions during job run. This incluses stats on memory use, CPU time,
etc. etc. 

```
out/foo_condor-0.out
out/foo_condor-1.out
out/foo_condor-2.out
out/foo_condor-3.out
out/foo_condor-4.out
```

The results. The hostname of each of the machines that the job ran on.



