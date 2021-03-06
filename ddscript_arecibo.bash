#!/bin/bash
#A script to process a single file, involving making a link to said file and running 
#rfifind, DDplan.py, prepdata, realfft, accelsearch, accelsift, and prepfold on it.
#don't forget to do this on n04 -X! (BJ server)
#modified for use on the GZNU server.

#command line arguments are in the format: ddscript.bash directory filename
#boolean to check whether or not everything is in the right format and if the 
#directory and filename are valid

STARTTIME="$(date -u +%s)"

echo "*************************************************************"
echo "PRESTO data processing"
echo -e "by Shana Li\n"
echo "Arguments should be in the format: directory filename."
echo "Filename should be sans file extension (.fits)."
echo "*************************************************************"

#set variables for directory and filename
directory=$1
filename=$2

echo -e "\n*************************************************************"
echo "Directory: $directory"
echo "Filename: $filename"

#if directory is invalid, exit
if [ ! -d $directory ]; then
	echo "Invalid directory."
	echo -e "*************************************************************\n"
	exit 0
fi

#if file doesn't exist, exit
if [ ! -e "$directory/$filename.fits" ]; then
	echo "Invalid filename."
	echo -e "*************************************************************\n"
	exit 0
fi

#if folder for this particular file already exists, delete it
if [ -d $filename ]; then
	echo -e "\nExisting files found, overwriting them now."
	rm -r $filename
	echo -e "Done.\n"
fi

#create new folder for data files
mkdir $filename
cd $filename

#create link to file in current directory in the folder
echo "Making link to file:"
ln -s $directory/$filename.fits ./ >> /dev/null
echo "Done."
echo -e "*************************************************************\n"


echo "*************************************************************"
#run rfifind
echo "Running rfifind:"
START="$(date -u +%s)"
echo -e "Start time: $START\n"
echo "Filename: $filename.fits"
echo -e "Time: 2 \n"

rfifind $filename.fits -time 2 -o $filename >> /dev/null

echo "Done."
END="$(date -u +%s)"
echo "End time: $END"
echo "Time for rfifind: $(($END - $START)) seconds."
echo -e "*************************************************************\n"


echo "*************************************************************"
echo "Running DDplan.py:"
START="$(date -u +%s)"
echo -e "Start time: $START\n"
#run DDplan.py:
#get variables needed:
#low dm
ldm=0
#high dm - changed from 4000 to 2000 for Arecibo data
hdm=2000
#time resolution
tres=0.5
#central frequency
cfreq=`readfile $filename.fits | grep "Central freq" | awk '{print $5}'`
#number of channels
numchan=`readfile $filename.fits | grep "Number of channels" | awk '{print $5}'`
#bandwidth
bandw=`readfile $filename.fits | grep "Total Bandwidth" | awk '{print $5}'`
#sample time
sampletime=`readfile $filename.fits | grep "Sample time" | awk '{print $5}'`
sampletime=0.000$sampletime
#spectra per file
numout=`readfile $filename.fits | grep "Spectra per file" | awk '{print $5}'`

#run DDplan.py
echo "Central Frequency: $cfreq"
echo "Number of Channels: $numchan"
echo "Total Bandwidth: $bandw"
echo -e "Sample Time: $sampletime \n"

DDplan.py -l $ldm -d $hdm -f $cfreq -b $bandw -n $numchan -t $sampletime -r $tres -o $filename > ${filename}_ddplaninfo.txt
echo "Done."
END="$(date -u +%s)"
echo "End time: $END"
echo "Time for DDplan: $(($END - $START)) seconds."
echo -e "*************************************************************\n"


echo "*************************************************************"
#subband de-dispersion: call prepsubband on each call in DDplan
#count the lines that contain the information for each call
echo "Running subband de-dispersion:"
START="$(date -u +%s)"
echo -e "Start time: $START\n"
lastline=14
line=`head -$lastline ${filename}_ddplaninfo.txt | tail -1`
while [ "$line" != "" ]; do
	((lastline++))
	line=`head -$lastline ${filename}_ddplaninfo.txt | tail -1`
done
echo -e "Looping prepsubband for $(( $lastline-14 )) calls.\n"

#loop prepsubband for all calls in ddplaninfo
for (( i=14; i<lastline; i++ ))
do
	#get the call from the current line in the file
	call=`head -$i ${filename}_ddplaninfo.txt | tail -1`

	#put call into an array
	IFS=' ' read -a arr <<<"$call"

	#get all the variables:
	#nsub
	nsub=`readfile $filename.fits | grep "samples per spectra" | awk '{print $5}'`

	#low dm
	ldm=${arr[0]}

	#dm step
	dms=${arr[2]}
	
	#number of dms
	ndm=${arr[4]}

	#downsamp
	ds=${arr[3]}

	#numout (numout from DDplan / downsamp)
	numo=$(( $numout / $ds ))
	
	#run prepsubband command
	echo "nsub: $nsub; Low DM: $ldm; DM step: $dms; Number of DMs: $ndm; Numout: $numo; Downsample: $ds"
	prepsubband -nsub $nsub -lodm $ldm -dmstep $dms -numdms $ndm -numout $numo -downsamp $ds -mask ${filename}_rfifind.mask -o $filename $filename.fits >> /dev/null
	echo -e "Done.\n"
done
END="$(date -u +%s)"
echo "End time: $END"
echo "Time for prepsubband: $(($END - $START)) seconds."
echo -e "*************************************************************\n"


#run realfft:
echo "*************************************************************"
echo "Running realfft:"
START="$(date -u +%s)"
echo -e "Start time: $START\n"
ls *.dat | xargs -n 1 --replace realfft {} >> /dev/null
echo "Done."
END="$(date -u +%s)"
echo "End time: $END"
echo "Time for realfft: $(($END - $START)) seconds."
echo -e "*************************************************************\n"

#accelsearch for periodic signals
echo "Running accelsearch:"
START="$(date -u +%s)"
echo -e "Start time: $START\n"
ls *.fft | xargs -n 1 accelsearch -zmax 0 >> /dev/null
echo "Done."
END="$(date -u +%s)"
echo "End time: $END"
echo "Time for accelsearch: $(($END - $START)) seconds."
echo -e "*************************************************************\n"

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
echo -e "Total time elapsed for processing $filename: $(($ENDTIME - $STARTTIME)) 
    seconds.\n" 

exit 0
