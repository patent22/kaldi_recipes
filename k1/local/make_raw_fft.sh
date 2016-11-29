#!/bin/bash

# fft directory.
tmp_fft=$1
# save directory.
fftdir=$2

source ../path.sh
list_name=`ls $tmp_fft`
list_num=`ls $tmp_fft | wc -w`
if [ $list_num -ne 1 ]; then
	echo "This script reads only one file. Please provide one file in the directory."
	exit 1
fi

### FFT ###
# mfcc feature extraction.
[ ! -d $fftdir ] && mkdir $fftdir
echo "Extracting fft features..."
# save the fft features in fft_feature directory.
fftnj=1
for JOB in `seq $fftnj`; do
    copy-feats --compress=true ark:$tmp_fft/$list_name \
	       ark,scp:$fftdir/raw_fft_train.$JOB.ark,$fftdir/raw_fft_train.$JOB.scp
done
echo "raw_fft file is saved in $tmp_fft."

