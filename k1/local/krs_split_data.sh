#!/bin/bash
# 														EMCS Labs
# 														Hyungwon Yang
# 														hyung8758@gmail.com

# This scripts split Korean readspeech dataset into 5 parts.
# 3 options (s_set:5, m_set:20, l_set:115) will be provided.
# Following folders are carefully pre-selected. Please do not change below settings.
s_set=("fv01" "fx03" "mv02" "mw01" "mw17")
m_set=("fv01" "fv03" "fv04" "fv05" "fv07" "fx03" "fx05" "fx06" "fx10" "fx11" "mv02" "mv04" "mv05" "mv06" "mv07" "mw01" "mw04" "mw10" "mw17" "mw18")
l_set=("fv01" "fv02" "fv03" "fv04" "fv05" "fx06" "fx07" "fx08" "fx09" "fx10" "mv11" "mv12" "mv13" "mv16" "mv17" "my01" "my02" "my03" "my04" "fy02" "fy03" "fy17" "fy18" "fv06" "fv07" "fv08" "fv09" "fv10" "fx11" "fx12" "fx13" "fx14" "fx15" "mv18" "mv19" "mv20" "mw01" "mw02" "my05" "my06" "my07" "my08" "fy05" "fy06" "fz05" "mv14" "fv11" "fv12" "fv13" "fv14" "fv15" "fx16" "fx17" "fx18" "fx19" "fx20" "mw03" "mw04" "mw05" "mw06" "mw07" "my09" "my10" "my11" "mz01" "fy07" "fy08" "fy09" "mw19" "fv16" "fv17" "fv18" "fv19" "fv20" "mv01" "mv02" "mv03" "mv04" "mv05" "mw08" "mw09" "mw10" "mw11" "mw13" "mz02" "mz03" "mz04" "mz05" "fy10" "fy11" "fy12" "mw20" "fx01" "fx02" "fx03" "fx04" "fx05" "mv06" "mv07" "mv08" "mv09" "mv10" "mw14" "mw15" "mw16" "mw17" "mw18" "mz06" "mz07" "mz08" "mz09" "fy13" "fy14" "fy16" "fy04")
# How many datasets should be splited into each part?


if [ $# -ne 3 ]; then
   echo "Three arguments should be assigned." 
   echo "1. Source data."
   echo "2. Spliting number. 4 options are avaiable: 5, 20, 115(whole datasets)"
   echo "3. The folder generated files saved." && exit 1
fi

# Corpus directory: ./krs_data
data=$1
# The number of spliting data.
split_num=$2
# Result directory: ./data/local/data
save=$3


if [ $split_num -ne 5 ] && [ $split_num -ne 20 ] && [ $split_num -ne 115 ]; then
	echo "Data split option is incorrect. Please set it 5, 20, or 115." && exit 1
fi

# Generate directories.
if [ -d $save ]; then
	rm -rf $save
	echo "Previous splited datasets have been removed."
	mkdir -p $save
else
	mkdir -p $save
fi

# split datasets and distribute them to each folders.
# This will not copy or move original source data directly to the part folders but
# it will soft link the source data.
con=0
cin=0
for folder in 1 2 3 4 5; do
	mkdir -p $save/part$folder

	if [ $split_num -eq 5 ]; then
		name=${s_set[((folder-1))]}
		ln -s $data/$name $save/part$folder

	elif [ $split_num -eq 20 ]; then
		for subfd in 0 1 2 3; do
			name=${m_set[((subfd+con))]}
			ln -s $data/$name $save/part$folder
		done
		con=$((con+4))

	elif [ $split_num -eq 115 ]; then
		for subfd in `seq 0 22`; do
			name=${l_set[((subfd+cin))]}
			ln -s $data/$name $save/part$folder
		done
		cin=$((cin+23))
	fi
done

echo "Dataset has been splited into 5 parts."





