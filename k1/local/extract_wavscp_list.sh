#!/bin/bash

# Hyungwon Yang
# EMCS

# This script picks out the wav files that only were written in wav.scp file from the whole corpus.
# If you retrieved unbalanced wav.scp from the whole dataset due to some remained error in corpus data,
# apply this function in order to extract the wav files that in wav.scp and excludes rest.


dir=/Users/hyungwonyang/Documents/data/krs_data/tmp_train
list=`ls $dir`
wav_path=/Users/hyungwonyang/Documents/ASR_project/kaldi_project/exp/kaldi_recipes/data/train/feats.scp
wav_list=`cat $wav_path | awk '{print $1}'`
save_dir=/Users/hyungwonyang/Documents/data/krs_data/krs_91


[ ! -d $save_dir ] && mkdir $save_dir

for d in $list; do
	# find the wav list.
	dir_wav=`ls $dir/$d | grep .wav`
	match_list=`echo $dir_wav | cut -c 1-4 | uniq`
	[ ! -d $save_dir/$match_list ] && mkdir -p $save_dir/$match_list
	get_list=`echo $wav_list | tr ' ' '\n' | grep $match_list`
	for p in $dir_wav; do
		pick=`echo $p | sed s/.wav//g`
		comp=`echo $get_list | tr ' ' '\n' | grep $pick`
		if [ "$comp" != "" ]; then
			mv $dir/$d/$pick.wav $save_dir/$match_list
			mv $dir/$d/$pick.txt $save_dir/$match_list >/dev/null
			mv $dir/$d/$pick.TextGrid $save_dir/$match_list >/dev/null
		fi
	done
done
