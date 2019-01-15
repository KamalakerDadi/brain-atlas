# Test Condor DAGMAN setup

* https://biomedia.doc.ic.ac.uk/internal/computer-resources/condor for notes on condor setup.

* http://research.cs.wisc.edu/htcondor/manual/v8.8/DAGManApplications.html
for the DAGMAN manual.

* https://research.cs.wisc.edu/htcondor/HTCondorWeek2017/presentations/TueMichael_Dagman.pdf for a DAGMAN tutorial.

Log into a doc machine and clone this repo into your home area. It needs to be
on a publically visible path, such as `/homes/jcupitt/GIT/brain-atlas/dagman`.

# Reset everything


```
rm *.sub *.log *.out *.err *.metrics *.rescue*
kinit
```

# Running the DAG

```
condor_submit_dag diamond.dag
```
