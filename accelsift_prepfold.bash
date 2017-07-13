#!/bin/bash
#Part 3/3 for data processing; for login node: accelsift, prepfold

STARTTIME="$(date -u +%s)"

#set variables for directory and filename
directory=$1
filename=$2

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


#fold best candidates: (referenced from Maura's siftandfold.bash)
echo "*************************************************************"
echo "Folding candidates:"
START="$(date -u +%s)"
echo -e "Start time: $START\n"
#make list of candidate names
candlist=`grep "ACCEL" cands.txt | awk '{print $1}'`
#make into array
candarr=($candlist)

#make list of respective DMs of best candidates from cands.txt
dmslist=`grep "ACCEL" cands.txt | awk '{print $2}'`
#make into array
dmsarr=($dmslist)

#make list of respective periods of best candidates
periodslist=`grep "ACCEL" cands.txt | awk '{print $8/1000.}'`
#make into array
periodsarr=($periodslist)

#get total number of best candidates to loop through them
tot=`grep "ACCEL" cands.txt | wc | awk '{print $1}'`

nsub=`readfile $filename.fits | grep "samples per spectra" | awk '{print $5}'`

#loop prepfold through all viable candidates
for (( i=0; i<tot; i++ ))
do
	echo "Running prepfold on candidate # $(( $i+1 )) out of $tot:"
	
	#get filename of ACCEL_0 cands file and candnum
	line=${candarr[$i]}
	accelfilename="$(cut -d':' -f1 <<< $line)"
	candnum="${line: -1}"

	#get dat filename
	length=$(( ${#accelfilename}-8 ))
	datfilename="${accelfilename: 0:$length}"

	#run prepfold command
	echo -e "File: $datfilename; Candidate number: $candnum; DM: ${dmsarr[$i]}; nsub: $nsub \n"
	
	#fold raw data
	prepfold -mask ${filename}_rfifind.mask -dm ${dmsarr[$i]} $filename.fits -accelfile $accelfilename.cand -accelcand $candnum -noxwin -nosearch -o ${filename}_${dmsarr[$i]} >> /dev/null

done

echo -e "\nDone. Moving png files to folder:"
ls *.png
cp *.png ../results_png
END="$(date -u +%s)"
echo "End time: $END"
echo "Time for folding candidates: $(($END - $START)) seconds."
echo -e "*************************************************************\n"
#open all the plots
#eog *.png

ENDTIME="$(date -u +%s)"
echo -e "Total time elapsed: $(($ENDTIME - $STARTTIME)) seconds.\n"

exit 0
