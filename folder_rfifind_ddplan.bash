#!/bin/bash
#Part 1/3 of data processing; login node: make folder, rfifind, DDplan.
#don't forget to do this on n04 -X! (BJ server)
#modified for use on the GZNU server.

#command line arguments are in the format: ddscript.bash directory filename
#boolean to check whether or not everything is in the right format and if the directory and filename are valid

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


#------------jobgrid does prepsubband, realfft, accelsearch------------
qsub -q low -d ./ $RPPPS_DIR/qsub_template.bash

#------------login node does accelsift, prepfold-------------


ENDTIME="$(date -u +%s)"
echo -e "Total time elapsed: $(($ENDTIME - $STARTTIME)) seconds.\n"

exit 0
