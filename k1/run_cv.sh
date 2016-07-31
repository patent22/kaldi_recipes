#!/bin/bash
# 														EMCS Labs
# 														Hyungwon Yang
# 														hyung8758@gmail.com

# This script split the dataset into n-number of groups and it
# runs the cross validation through 5 divdied datasets.

# The number of splited dataset.
split_num=5
# Kaldi root: Where is your kaldi directory?
kaldi=/Users/hyungwonyang/kaldi
# Source data: Where is your source (wavefile) data directory?
# In the source directory, datasets should be assigned in two directories: train, and test.
source=/Users/hyungwonyang/Documents/data/korean_readspeech
# Log file: Log file will be saved with the name set below.
logfile=1st_cv_test
# current directory.
curdir=$PWD
# Number of jobs.
nj=2

# 5 datasets will be used for cross validation.


echo ====================================================================== 
echo "                         Split Datasets	                		  " 
echo ====================================================================== 

# From the corpus data folder, total 5 'part#' named folders will be generated
# and source files will be distributed there.
# This is very basic steps for training datasets. For those who just have a corpus
# that contains 117 speaker datasets and did not separated it into 5 parts, this 
# split datasets process needs to be started. If the datasets are already splited,
# please skip this process.

# split the data into 5 folders.
# The number of speaker datasets needs to be chosen.
# There are 4 options: 5, 20, and 117(whole datasets) speakers.
ln -s $source $curdir/krs_corpus

. ./local/krs_split_data.sh $curdir/krs_corpus 5 $curdir/data4cv





echo ====================================================================== 
echo "                         Cross Validation	                		  " 
echo ====================================================================== 










