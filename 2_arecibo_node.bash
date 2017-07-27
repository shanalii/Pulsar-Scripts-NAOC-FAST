#!/bin/bash
#Part 2 of Arecibo data processing, for login node. Includes accelsift.

directory=$1
filename=$2

cd $filename

#sift through periodic candidates
echo "*************************************************************"
echo -e "Running ACCEL_sift.py:"
START="$(date -u +%s)"
echo -e "Start time: $START\n"

#in GZNU server, re-direct X11 interface to admin1
tmp=`echo $DISPLAY`
export DISPLAY=10.10.10.24:38.0
python $PRESTO/python/ACCEL_sift.py > cands.txt
export DISPLAY=$tmp
#cd $tmp
echo "Done. Candidate info saved in cands.txt."
END="$(date -u +%s)"
echo "End time: $END"
echo "Time for ACCEL_sift: $(($END - $START)) seconds."
echo -e "*************************************************************\n"