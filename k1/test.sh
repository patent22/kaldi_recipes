#!/bin/bash



echo "$name is exist!"






# if [[ -z $(find $KALDI_ROOT/tools/srilm/bin -name ngram-count) ]]; then
# 	echo "SRILM might not be installed on your computer. Please find kaldi/tools/install_srilm.sh and install the package." #&& exit 1
# else
# 	nc=`find $KALDI_ROOT/tools/srilm/bin -name ngram-count`
# 	# Make lm.arpa from textraw.
# 	$nc -text $curdir/data/train/textraw -lm $curdir/data/lang/lm.arpa
# fi























# for folder in 1 2 3 4 5; do
# 	mkdir -p $save/part$folder

# 	if [ $split_num -eq 5 ]; then
# 		name=${s_set[((folder-1))]}
# 		ln -s $data/$name $save/part$folder
# 		echo "split_num: $split_num"
# 		echo 

# 	elif [ $split_num -eq 20 ]; then
# 		for data in 0 1 2 3; do
# 			name=${m_set[((data+con))]}
# 			ln -s $data/$name $save/part$folder
# 		done
# 		con=$((con+4))

# 	elif [ $split_num -eq 115 ]; then
# 		for data in `seq 0 22`; do
# 			name=${l_set[((data+cin))]}
# 			ln -s $data/$name $save/part$folder
# 		done
# 		cin=$((cin+23))
# 	fi
# done




















## or / and with multiple conditions
# split_num=116

# if [ $split_num -ne 5 ] && [ $split_num -ne 20 ] && [ $split_num -ne 115 ]; then
# 	echo "Data split option is incorrect. Please set it 5, 20, or 115." # && exit 1
# else
# 	echo "GOOD JOB!!"
# fi

##
# Check data numbers.
# dir_path=/Users/hyungwonyang/documents/data/korean_readspeech
# dir_num=`ls $dir_path | wc -w`

# for i in `seq 1 $dir_num`; do
# 	folder_name=`ls $dir_path | awk 'NR==line' line=$i`
# 	sub_total=`ls $dir_path/$folder_name | wc -w`
# 	sub_number=$((sub_total/3))
# 	echo "$i wav numbers/$folder_name: $sub_number" >> wavnum.txt
# 	echo "$folder_name" >> wavfolder.txt

# done



# unset tmp_norm_vars
# unset tmp_norm_means
# unset tmp_power
# unset norm_vars
# unset norm_means
# unset power
# unset dim_opt
# unset splice_opt


# tmp_dim_opt=(20 30 40 50 60)
# tmp_splice_opt=(2 3 4 5 6)
# tmp_randprune_opt=4.0

# for x in ${tmp_dim_opt[@]}; do
#     for y in ${tmp_splice_opt[@]}; do

#         dim_opt+=($x)
#         splice_opt+=($y)
#     done
# done

# echo "dim_opt:  ${dim_opt[@]}"
# echo "splice_opt: ${splice_opt[@]}"