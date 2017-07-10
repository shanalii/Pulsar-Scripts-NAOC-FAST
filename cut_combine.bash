#!/bin/bash
#A script to run pzc's cutting and combining scripts on Arecibo data.

#The file prefix for the files
filepre="p1693.20100502.Strip46.b0s1g0.00"

#The starting file number
startfnum=500

#The ending file number (doesn't change)
endfnum=527

#Length between starting subint and ending subint (length of cut -1)
length=71

#Starting subint for first file
startn=0

#Overlap increment
overlap=24

#Strip number
stripnum=0



while [ $startfnum -le $endfnum ]; do

	#increment strip number for naming
	stripnum=$(($stripnum + 1))

	if (( $startn == 128 )); then
		startn=0
	fi

	#check if the starting subint number is greater than 129; if so, get the starting n of the next file
	if (( $startn > 128 )); then 
		startn=$(($startn % 128 - 1))
		startfnum=$(($startfnum + 1))
	fi

	#The starting filename
	startfile="${filepre}${startfnum}.fits"

	#Ending subint
	endn=$(($startn + $length))

	#check if the ending subint number is greater than 129; if so, get the ending n of the next file and combine; else, just cut
	if (( $endn > 128 )); then 
		#for combining:

		endn=$(($endn % 128 - 1))

		#The next file number
		nextfnum=$(($startfnum + 1))

		#The ending filename; the one immediately after the starting filename
		nextfile="${filepre}${nextfnum}.fits"

		#combine
		echo "Combine: $startfile: from $startn to 128; $nextfile: from 0 to $endn."
		python /home/pzc/pulsar_search/AO_201707/combine_Arecibopsrfits_freq_time_splitpol.py 0 1023 $startn $endn $startfile $nextfile >> /dev/null

	else
		#for cutting:

		#cut
		echo "Cutting: $startfile: from $startn to $endn."
		python /home/pzc/pulsar_search/AO_201707/cut_Arecibopsrfits_freq_time_splitpol.py $startfile 0 1023 $startn $endn >> /dev/null

	fi
	
	#set next startn
	startn=$(($startn + $overlap))

	#rename file
	mv Arecibo_Out.fits Arecibo_Out_$stripnum.fits

	echo "Saved as Arecibo_Out_$stripnum.fits."

done


