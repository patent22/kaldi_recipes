#!/bin/bash
#
# Copyright 2016 Media Zen & 
#				 Korea University & EMCS Labs (author: Hyungwon Yang)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# *** INTRODUCTION ***
# This is the forced alignment toolkit developed by EMCS labs.
# Run this script in the folder in which force_align.sh presented.
# It means that the user needs to nevigate to this folder in linux or
# mac OSX terminal and then run this script. Otherwise this script
# won't work properly.
# Do not move the parts of scripts or folders or run the main script
# from outside of this folder. 

# Kaldi directory ./kaldi
kaldi=/Users/hyungwonyang/kaldi
# Model directory
fa_model=model4fa
# lexicon directory
dict_dir=main/data/local/dict
# language directory
lang_dir=main/data/lang
# FA data directory
data_dir=
trans_dir=main/data/trans_data
# align data directory
ali_dir=fa_dir
# result direcotry
result_dir=tmp/result
# Code directory
code_dir=main/local/core
# log directory
log_dir=tmp/log
# Number of jobs(just fix it to one)
mfcc_nj=1
align_nj=1
passing=0
fail_num=0

# Check kaldi directory.
if [ ! -d $kaldi ]; then
	echo -e "ERROR: Kaldi directory is not found. Please reset the kaldi directory by editing force_align.sh.\nCurrent kaldi directory : $kaldi" && exit 1
fi

# Option Parsing and checking. 
# Option default.
tg_word_opt=
tg_phone_opt=
usage="=======================================================\n\
\t         The Usage of Korean Foreced Aligner.         \n\
=======================================================\n\
\t*** OPTION ARGUMENT ***\n\
-h  | --help    : Print the direction.\n\
-nw | --no-word : This opiton excludes word label from TextGrid.\n\
-np | --no-phone: This option excludes phone label from TextGrid.\n\
\t*** INPUT ARGUMENT ***\n\
File directory. ex) example/my_record\n\n\
\t*** USAGE ***\n\
bash forced_align.sh [option] [data directory]\n\
bash forced_align.sh -np example/my_record\n"

if [ $# -gt 3 ]; then
   echo "Wrong option arguments." 
   echo "Sound and text file saved directory should be provided."  && exit 1
fi

arg_num=$#
while [ $arg_num -gt 1 ] ; do 
  case "$1" in
    -h) echo -e $usage; return; break ;;
    -nw) tg_word_opt="--no-word"; shift; arg_num=$((arg_num-1)) ;;
    -np) tg_phone_opt="--no-phone"; shift; arg_num=$((arg_num-1)) ;;

    --help) echo -e $usage; return; break ;;
    --no-word) tg_word_opt="--no-word"; shift; arg_num=$((arg_num-1)) ;; 
    --no-phone) tg_phone_opt="--no-phone"; shift; arg_num=$((arg_num-1)) ;;
    -*) echo "unknown option: $1" ; return ;;
    --*) echo "unknown option: $1" ; return ;;
  esac
  if [ $arg_num -eq 1 ]; then
  	arg_num=0
  fi
done

# Folder directory that contains wav and text files.
tmp_data_dir=$1
if [ "$tmp_data_dir" == "" ]; then
	echo "ERROR: data directory is not provided." && exit 1
fi
# Check data_dir
alias realpath="perl -MCwd -e 'print Cwd::realpath(\$ARGV[0]),qq<\n>'"
data_dir=`realpath $tmp_data_dir`
echo "data directory= $data_dir"
if [ ! -d $data_dir ]; then
	echo "ERROR: $data_dir is not present. Please check the data directory."  && exit 1
fi
# This is just test line remove when the script is completed.
rm -rf log main/data
[ -d tmp ] && rm -rf tmp

# Directory check.
source path.sh $kaldi
[ ! -d tmp ] && mkdir -p tmp
[ ! -d main/data/local/dict ] && mkdir -p main/data/local/dict
[ ! -d main/data/source_wav ] && mkdir -p main/data/source_wav
[ ! -d main/data/lang ] && mkdir -p main/data/lang
[ ! -d main/data/trans_data ] && mkdir -p $trans_dir
[ ! -d tmp/model_ali ] && mkdir -p tmp/model_ali
[ ! -d tmp/log ] && mkdir -p tmp/log

# Check the text files. 
python3 main/local/check_text.py $data_dir || exit 1
wav_list=`ls $data_dir | grep .wav `
wav_num=`echo $wav_list | tr ' ' '\n' | wc -l`
txt_list=`ls $data_dir | grep .txt `
txt_num=`echo $txt_list | tr ' ' '\n' | wc -l`
if [ $wav_num != $txt_num ]; then
	echo "ERROR: The number of audio and text files are not matched. Please check the input data." 
	echo "Audio list: "$wav_list
	echo "Text  list: "$txt_list && exit 1
fi

echo ===================================================================
echo "                    Korean Forced Aligner                        "    
echo ===================================================================
echo The number of audio files: $wav_num
echo The number of text  files: $txt_num

# Main loop for alignment.
for turn in `seq 1 $wav_num`; do
	mkdir -p main/data/source_wav/source$turn
	mkdir -p $trans_dir/trans$turn
	sel_wav=`echo $wav_list | tr ' ' '\n' | sed -n ${turn}p`
	sel_txt=`echo $txt_list | tr ' ' '\n' | sed -n ${turn}p`
	source_dir=$PWD/main/data/source_wav/source$turn
	echo Alinging: $sel_wav '('$turn /$wav_num')'
	cp $data_dir/$sel_wav $source_dir
	cp $data_dir/$sel_txt $source_dir
	echo "Procedure: $turn " > $log_dir/process.$turn.log
	echo "Audio: $data_dir/$sel_wav, Text: $data_dir/$sel_txt." >> $log_dir/process.$turn.log

	python3 main/local/fa_prep_data.py $source_dir $trans_dir/trans$turn >> $log_dir/process.$turn.log || exit 1
	$code_dir/utt2spk_to_spk2utt.pl $trans_dir/trans$turn/utt2spk > $trans_dir/trans$turn/spk2utt 
	echo "spk2utt file was generated." >> $log_dir/process.$turn.log

	# Romanize the text file.
	[ ! -d tmp/romanized ] && mkdir -p tmp/romanized
	words=`cat $source_dir/$sel_txt`
	txt_rename=`echo $sel_txt | sed -e "s/txt/rom/g"`
	python3 main/local/romanize.py "$words" > tmp/romanized/$txt_rename
	echo "Romanized: " >> $log_dir/process.$turn.log
	cat tmp/romanized/$txt_rename >> $log_dir/process.$turn.log

	# g2p text file.
	[ ! -d tmp/prono ] && mkdir -p tmp/prono
	[ -f tmp/prono/new_lexicon ] && rm tmp/prono/new_lexicon
	# For first column in lexcion.txt: word.
	words=`cat $source_dir/$sel_txt`
	echo $words | tr ' ' '\n' > tmp/prono/words_list
	# For second column in lexcion.txt: pronunciation.
	python3 main/local/g2p.py "$words" | tr ' ' '\n' | sed 's/\(..\)/\1 /g' > tmp/prono/prono_list
	paste -d' ' tmp/prono/{words_list,prono_list} >> tmp/prono/new_lexicon
	echo "Lexicon: " >> $log_dir/process.$turn.log
	cat tmp/prono/new_lexicon >> $log_dir/process.$turn.log

	# Language modeling.
	paste -d'\n' tmp/prono/new_lexicon model/lexicon.txt | sort | uniq | sed '/^\s*$/d' > $dict_dir/lexicon.txt
	bash main/local/prepare_new_lang.sh $dict_dir $lang_dir "<UNK>" >/dev/null

	# MFCC default setting.
	echo "Extracting the features from the input data." >> $log_dir/process.$turn.log
	mfccdir=mfcc
	cmd="$code_dir/run.pl"

	# wav file sanitiy check.
	wav_ch=`sox --i $source_dir/$sel_wav | grep "Channels" | awk '{print $3}'`
	if [ $wav_ch -ne 1 ]; then
		sox $source_dir/$sel_wav -c 1 $source_dir/ch_tmp.wav
		mv $source_dir/ch_tmp.wav $source_dir/$sel_wav; fi
		echo "$sel_wav channel changed." >> $log_dir/process.$turn.log
	wav_sr=`sox --i $source_dir/$sel_wav | grep "Sample Rate" | awk '{print $4}'`
	if [ $wav_sr -ne 16000 ]; then
		sox $source_dir/$sel_wav -r 16000 $source_dir/sr_tmp.wav
		echo "$sel_wav sampling rate changed." >> $log_dir/process.$turn.log
		mv $source_dir/sr_tmp.wav $source_dir/$sel_wav; fi

	# Extracting MFCC features and calculate CMVN.
	$code_dir/make_mfcc.sh --nj $mfcc_nj --cmd "$cmd" $trans_dir/trans$turn $log_dir tmp/$mfccdir >> $log_dir/process.$turn.log
	$code_dir/fix_data_dir.sh $trans_dir/trans$turn >> $log_dir/process.$turn.log
	$code_dir/compute_cmvn_stats.sh $trans_dir/trans$turn $log_dir tmp/$mfccdir >> $log_dir/process.$turn.log
	$code_dir/fix_data_dir.sh $trans_dir/trans$turn >> $log_dir/process.$turn.log
	
	# Forced alignment: aligning data.
	echo "Force aligning the input data." >> $log_dir/process.$turn.log
	for pass in 1 2 3 4; do
		if [ $pass == 1 ]; then
			beam=10
			retry_beam=40
		elif [ $pass == 2 ]; then
			beam=50
			retry_beam=60
		elif [ $pass == 3 ]; then
			beam=70
			retry_beam=80;
		elif [ $pass == 4 ]; then
			beam=90
			retry_beam=100; 
		fi
		$code_dir/align_si.sh --nj $align_nj --cmd "$cmd" \
							$trans_dir/trans$turn \
							$lang_dir \
							model/$fa_model \
							tmp/model_ali \
							$beam \
							$retry_beam \
							$turn >> $log_dir/process.$turn.log 2>/dev/null

		decode_check=`cat tmp/log/align.$turn.log | grep "Did not successfully decode file" | wc -w`
		if [ $decode_check == 0 ]; then
			break
		elif [ $decode_check == 0 ] && [ $pass == 4 ]; then
			echo "WARNNING: $sel_wav was difficult to align, the result might be unsatisfactory."
			break
		elif [ $decode_check != 0 ] && [ $pass == 4 ]; then
			echo -e "Fail Alignment: $sel_wav might be corrupted.\n" | tee -a $log_dir/process.$turn.log
			fail_num=$((fail_num+1))
			passing=1
		fi
	done
	if [ $passing -ne 1 ]; then
		# CTM file conversion.
		$kaldi/src/bin/ali-to-phones --ctm-output model/$fa_model/final.mdl ark:"gunzip -c tmp/model_ali/ali.1.gz|" - > tmp/model_ali/ali.1.ctm 
		echo "ctm result: " >> $log_dir/process.$turn.log
		cat tmp/model_ali/ali.1.ctm >> $log_dir/process.$turn.log

		[ ! -d $result_dir ] && mkdir -p $result_dir
		cat tmp/model_ali/*.ctm > $result_dir/merged_ali.txt

		# Move requisite files.
		cp main/data/lang/phones.txt $result_dir
		cp $trans_dir/trans$turn/segments $result_dir

		# id to phone conversion.
		echo "Reconstructing the alinged data." >> $log_dir/process.$turn.log
		python3 main/local/id2phone.py  $result_dir/phones.txt \
										$result_dir/segments \
										$result_dir/merged_ali.txt \
										$result_dir/final_ali.txt >> $log_dir/process.$turn.log || exit 1;
		echo "final_ali result: " >> $log_dir/process.$turn.log
		cat $result_dir/final_ali.txt >> $log_dir/process.$turn.log

		# Split the whole text files.
		echo "Spliting the whole aligned data." >> $log_dir/process.$turn.log
		python3 main/local/splitAlignments.py $result_dir/final_ali.txt $result_dir >> $log_dir/process.$turn.log || exit 1;

		# Combining prono and rom texts. (It also generate text_num.)
		bash main/local/make_rg_lexicon.sh >/dev/null || exit 1;

		# Generate Textgrid files and save it to the data directory.
		echo "Organizing the aligned data to textgrid format." >> $log_dir/process.$turn.log
		# Word tier language selection. 0: English graphemes 1: Korean
		echo $tg_word_opt $tg_phone_opt
		python3 main/local/generate_textgrid.py $tg_word_opt $tg_phone_opt \
								$result_dir/tmp_fa \
								tmp/romanized/rom_graph_lexicon.txt \
								tmp/romanized/text_num \
								$source_dir >/dev/null || exit 1;
		echo -e "$sel_wav was successfully aligned.\n" | tee -a $log_dir/process.$turn.log
		mv $source_dir/*.TextGrid $data_dir
	fi

	passing=0
	rm -rf tmp/{mfcc,model_ali,prono,result,romanized}/*
	rm -rf $source_dir
done

echo "===================== FORCED ALIGNMENT FINISHED  =====================" | tee -a $log_dir/process.$turn.log
echo "** Result Information on $(date) **									" | tee -a $log_dir/process.$turn.log
echo "Total Trials:" $wav_num									        	  | tee -a $log_dir/process.$turn.log
echo "Success     :" $((wav_num-fail_num))									  | tee -a $log_dir/process.$turn.log
echo "Fail        :" $fail_num												  | tee -a $log_dir/process.$turn.log
echo "----------------------------------------------------------------------" | tee -a $log_dir/process.$turn.log
echo "Result      :" $((wav_num-fail_num)) /$wav_num "(Success / Total)"	  | tee -a $log_dir/process.$turn.log
echo

mv tmp/log .
rm -rf tmp