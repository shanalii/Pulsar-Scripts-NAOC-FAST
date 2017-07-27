#!/bin/bash
#Part 1 of Arecibo data processing for jobgrid, includes folder making, rfifind, manual prepsubband, realfft, accelsearch.

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


echo “prepsubband -nsub 1024 -lodm 0 -dmstep 0.03 -numdms 1736 -numout 288000 -downsamp 2 -mask ${filename}_rfifind.mask -o $filename $filename.fits >> /dev/null”

prepsubband -nsub 1024 -lodm 0 -dmstep 0.03 -numdms 1736 -numout 288000 -downsamp 2 -mask ${filename}_rfifind.mask -o $filename $filename.fits >> /dev/null


echo “prepsubband -nsub 1024 -lodm 52.08 -dmstep 0.05 -numdms 817 -numout 144000 -downsamp 4 -mask ${filename}_rfifind.mask -o $filename $filename.fits >> /dev/null”

prepsubband -nsub 1024 -lodm 52.08 -dmstep 0.05 -numdms 817 -numout 144000 -downsamp 4 -mask ${filename}_rfifind.mask -o $filename $filename.fits >> /dev/null


echo “prepsubband -nsub 1024 -lodm 92.93 -dmstep 0.1 -numdms 901 -numout 72000 -downsamp 8 -mask ${filename}_rfifind.mask -o $filename $filename.fits >> /dev/null”

prepsubband -nsub 1024 -lodm 92.93 -dmstep 0.1 -numdms 901 -numout 72000 -downsamp 8 -mask ${filename}_rfifind.mask -o $filename $filename.fits >> /dev/null


echo “prepsubband -nsub 1024 -lodm 183.03 -dmstep 0.3 -numdms 825 -numout 36000 -downsamp 16 -mask ${filename}_rfifind.mask -o $filename $filename.fits >> /dev/null”

prepsubband -nsub 1024 -lodm 183.03 -dmstep 0.3 -numdms 825 -numout 36000 -downsamp 16 -mask ${filename}_rfifind.mask -o $filename $filename.fits >> /dev/null


echo “prepsubband -nsub 1024 -lodm 430.53 -dmstep 0.5 -numdms 720 -numout 18000 -downsamp 32 -mask ${filename}_rfifind.mask -o $filename $filename.fits >> /dev/null”

prepsubband -nsub 1024 -lodm 430.53 -dmstep 0.5 -numdms 720 -numout 18000 -downsamp 32 -mask ${filename}_rfifind.mask -o $filename $filename.fits >> /dev/null


echo “prepsubband -nsub 1024 -lodm 790.53 -dmstep 1 -numdms 790 -numout 9000 -downsamp 64 -mask ${filename}_rfifind.mask -o $filename $filename.fits >> /dev/null”

prepsubband -nsub 1024 -lodm 790.53 -dmstep 1 -numdms 790 -numout 9000 -downsamp 64 -mask ${filename}_rfifind.mask -o $filename $filename.fits >> /dev/null


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
echo -e "Total time elapsed for processing $filename: $(($ENDTIME - $STARTTIME)) 
    seconds.\n" 

exit 0