#!/bin/bash
#for jobgrid: prepsubband, realfft, accelsearch

STARTTIME="$(date -u +%s)"

#set variables for directory and filename
directory=$1
filename=$2

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

#spectra per file
numout=`readfile $filename.fits | grep "Spectra per file" | awk '{print $5}'`

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

ENDTIME="$(date -u +%s)"
echo -e "Total time elapsed: $(($ENDTIME - $STARTTIME)) seconds.\n"

exit 0
