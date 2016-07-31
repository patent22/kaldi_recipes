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
source=/Users/hyungwonyang/Documents/data/krs_data
# Log file: Log file will be saved with the name set below.
logfile=1st_test
# current directory.
curdir=$PWD
# Number of jobs.
nj=2

# 5 datasets will be used for cross validation.


echo ====================================================================== 
echo "                         Split Datasets	                		  " 
echo ====================================================================== 







echo ====================================================================== 
echo "                         Cross Validation	                		  " 
echo ====================================================================== 










