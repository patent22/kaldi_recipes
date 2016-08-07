#!/bin/bash
# 														EMCS Labs
# 														Hyungwon Yang
# 														hyung8758@gmail.com

# This script gathers the information of best_wer and displays
# the training result.

if [ $# -ne 3 ]; then
   echo "Three arguments should be assigned." 
   echo "1. Result contained directory. (./exp)"
   echo "2. Result saving folder." 
   echo "3. Result file name." && exit 1
fi

# Result contained directory. (./exp)
data=$1
# Result saving folder. (./log)
save=$2
# Result file name. (reulst5-1)
filename=$3

if [ ! -d $save ]; then
	mkdir -p $save
fi

echo ====================================================================== | > $save/$filename.txt 
echo "                             RESULTS  	                	      " | >> $save/$filename.txt 
echo ====================================================================== | >> $save/$filename.txt 
echo RESULT REPORT ON... `date` >> $save/$filename.txt
echo  																		  >> $save/$filename.txt
echo  																		  >> $save/$filename.txt
# Result calculation.
exam_list=`ls $data`
exam_num=`echo $exam_list | wc -w`

for skim in $exam_list; do

	test_skim=`ls $data/$skim | grep "decode"`
	if [ ${#test_skim} -ne 0 ]; then

		train_box=`ls $data/$skim | grep "train" | head -1`
		test_box=`ls $data/$skim | grep "test" | head -1`

		title_name=`echo $skim | tr '[:lower:]' '[:upper:]'`
		echo "$title_name   													    " >> $save/$filename.txt
		echo "======================================================================" >> $save/$filename.txt
		echo "																	    " >> $save/$filename.txt
		if [ ${#train_box} -ne 0 ]; then
			train_best=`cat $data/$skim/$train_box/scoring_kaldi/best_wer`
			train_forward=`echo $train_best | cut -c2- | awk -F']' '{print $1}'`
			train_backword=`echo $train_best | cut -c2- | awk -F']' '{print $2}' | cut -c2-`
			echo "TRAIN DATA														   " >> $save/$filename.txt
			echo "- BEST : $train_forward											   " >> $save/$filename.txt
			echo "		 : $train_backword											   " >> $save/$filename.txt
			echo "																	   " >> $save/$filename.txt
		else
			echo "TRAIN DATA: DIRECTORY IS NOT FOUND			   					   " >> $save/$filename.txt
			echo "																	   " >> $save/$filename.txt
		fi
		if [ ${#test_box} -ne 0 ]; then
			test_best=`cat $data/$skim/$test_box/scoring_kaldi/best_wer`
			test_forward=`echo $test_best | cut -c2- | awk -F']' '{print $1}'`
			test_backword=`echo $test_best | cut -c2- | awk -F']' '{print $2}' | cut -c2-`			
			echo "TEST DATA 														   " >> $save/$filename.txt
			echo "- BEST : $test_forward											   " >> $save/$filename.txt
			echo "       : $test_backword											   " >> $save/$filename.txt
			echo "																	   " >> $save/$filename.txt
		else
			echo "TEST DATA: DIRECTORY IS NOT FOUND			   					       " >> $save/$filename.txt
			echo "																	   " >> $save/$filename.txt
		fi
		echo ====================================================================== >> $save/$filename.txt
		echo "																		   " >> $save/$filename.txt
	fi
done




