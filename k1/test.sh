#!/bin/bash



# kaldi=/Users/hyungwonyang/kaldi
# # Current directory
# curdir=$PWD
# # Model directory ./tri3
# fa_model=gmm
# # lexicon directory
# lexcion_dir=lang
# # FA data directory
# data_dir=example_new
# # align data directory
# ali_dir=fa_dir
# # log directory
# mkdir -p $curdir/tmp/log
# # Number of jobs(just fix it to one)
# nj=1

# . main/local/path.sh
# # Check codes and run path.sh.
# # if [ ! -f path.sh ]; then
# # 	main/local/make_path_fa.sh $kaldi
# # 	source path.sh
# # fi
# # bash main/local/check_code.sh $kaldi

# # Directory check.
# if [ ! -d tmp ]; then
# 	mkdir -p tmp
# fi

# # Sound data preprocessing.
# echo "preprocessing the input data..."  
# python3 main/local/fa_prep_data.py $curdir/$data_dir $curdir/main/data/trans_data || exit 1
# utils/utt2spk_to_spk2utt.pl main/data/trans_data/utt2spk > main/data/trans_data/spk2utt 

# # G2P part.


# # MFCC default setting.
# echo "Extracting the features from the input data..."
# mfccdir=mfcc
# train_cmd="utils/run.pl"
# decode_cmd="utils/run.pl"
# freq_set=16000

# # wav file sanitiy check.
# wav_list=`ls $data_dir | grep ".wav"`
# for wav in $wav_list; do
# 	wav_ch=`sox --i $data_dir/$wav | grep "Channels" | awk '{print $3}'`
# 	if [ $wav_ch -ne 1 ]; then
# 		echo "$wav chanel changed"
# 		sox $data_dir/$wav -c 1 $data_dir/$wav avg -l; fi
# 	wav_sr=`sox --i $data_dir/$wav | grep "Sample Rate" | awk '{print $4}'`
# 	if [ $wav_sr -ne 16000 ]; then
# 		echo "$wav sampling rate changed"
# 		sox $data_dir/$wav -r 16000 $data_dir/tmp.wav
# 		mv $data_dir/tmp.wav $data_dir/$wav
# 		rm $data_dir/tmp.wav ;fi
# done



opt_val1=(15 15 20 20 25 25)
opt_val2=(5 10 5 10 5 10)

num_param=`echo ${opt_val1[@]} | wc -w`

for ting in `seq 0 $((num_param-1))`; do
	echo ${opt_val1[i]} ${opt_val2[i]}
done












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