#!/bin/bash
# 														EMCS Labs
# 														Hyungwon Yang
# 														hyung8758@gmail.com


if [ $# -ne 2 ]; then
   echo "Three arguments should be assigned." 
   echo "1. Source data."
   echo "2. Spliting number. 4 options are avaiable: 5, 20, 115(whole datasets)"
   echo "3. The folder generated files saved." &&  exit 1
fi

# Corpus directory: ./data4cv
# dataset needs to be divided into 5 parts.
data=$1
# Result directory: ./cv_data
save=$2
return_dir=$PWD
# Make result directory.
if [ -d $save ]; then
	rm -rf $save
	echo "Previous $save folder has been removed."
	mkdir -p $save
else
	mkdir -p $save
fi

# Soft link datasets into $save directory.
roll=1
for cross in 1 2 3 4 5; do 
	mkdir -p $save/cv$cross
	mkdir -p $save/cv$cross/train
	mkdir -p $save/cv$cross/test

	for get in 1 2 3 4 5; do

		if [ $get -ne $roll ]; then
			for inside in $data/part$get/*; do
				tmp_path=`readlink $inside`
				cd $tmp_path
				ln ./* $save/cv$cross/train
			done
		else
			for inside in $data/part$get/*; do
				tmp_path=`readlink $inside`
				cd $tmp_path
				ln ./* $save/cv$cross/test
			done
		fi
	
	done
	roll=$((roll+1))
	echo "cv$cross folder is generated."
done

cd $return_dir

echo "cv-data spliting into train and test datasets has been finished successfully."








