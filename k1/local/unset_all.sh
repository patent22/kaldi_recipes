#!/bin/bash
# 														EMCS Labs
# 														Hyungwon Yang
# 														hyung8758@gmail.com

# This script remove all the trained or interrupted data files
# and reset variables in order to prevent any problems
# during the new training process.


curdir=$PWD
check_dir=`echo $curdir | grep "k1"`

if [ -z $check_dir ]; then
	echo "k1 directory is not found. Please restore the main 'k1' directory name if"
	echo "it is modified. Training should be proceeded in the k1 directory." && exit 1
fi

listup=`ls $curdir | tr '\t' '\n'`
list_num=`echo $listup | wc -w`

for check in $listup; do

	if [ "$check" == "README.md" ] || [ "$check" == "cmd.sh" ] || [ "$check" == "local" ] || [ "$check" == "run.sh" ] ||
	   [ "$check" == "run_cv.sh" ] || [ "$check" == "test.sh" ] || [ "$check" == "test_local" ]; then
	   this=1
	else
	   rm -rf $check
	fi
done
