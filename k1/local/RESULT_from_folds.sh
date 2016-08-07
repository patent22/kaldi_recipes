#!/bin/bash

# This is the script that derives best wer from the folds folder.

if [ $# -ne 3 ]; then
    echo "Three options are needed as arguments."
    echo "1. The folder directory that contains param folders. ex) folds" 
    echo "2. The trained material. ex) ./mono"
    echo "3. train or test folder. Choose one of them. ex) train" && exit 1
fi

# param saved folder ./folds
data=$1
# to be checked experiment folder ./mono
myexp=$2
# which data will you use? test or train
opt=$3

# Sanity and option checks.
if [ ! -d $PWD/$data ]; then
    echo "Please run this script when your current directory possess $data folder." && exit 1
fi

if [ ! -d $data/param1/5fold1/exp/$myexp ]; then
    echo "$myexp directory is not present. Make sure $myexp was trained." && exit 1
fi

# opt match
optcatch=`find $data/param1/5fold1/exp/$myexp -type d | grep "$opt"`
if [ -z $optcatch ]; then
    echo "$opt directory is not present in the $myexp directory. $opt data might not be decoded." && exit 1
fi


# data sanity check
param_check=`ls $data | grep "param1" | head -1`
if [ -z $param_check ]; then
    echo param folders are not present in your $data directory && exit 1
fi

if [ -e folds/new_result.txt ]; then
    rm folds/new_result.txt
    echo exist new_result.txt is removed.
fi

fold_num=`ls -l $data | grep "^d" | awk '{print $NF}' | wc -w` 
for folder in `seq 1 $fold_num`; do

    for sub in 1 2 3 4 5; do
	
	# doing in *fold* folder. ex 5fold1
	rm $data/param$folder/5fold$sub/result/*
	bash local/result_calc.sh $opt $data/param$folder/5fold$sub $myexp > $data/param$folder/5fold$sub/result/"result_5fold$sub.txt"
    done
    # doing in param folder. This is related to run_param.sh
    avg_wer=`bash local/get_avg_wer.sh $data/param$folder`
    echo "$folder/$fold_num... result: avg: $avg_wer" >> $data/new_result.txt
done
echo new_result.txt file is generated in $data
 
