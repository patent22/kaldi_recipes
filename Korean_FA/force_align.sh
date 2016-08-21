#!/bin/bash
# 														Jaekoo Kang
# 														Hyungwon Yang
# 														EMCS Labs
#
# This is the forced alignment toolkit developed by EMCS labs.
# Run this script in the folder in which force_align.sh presented.
# It means that the user needs to nevigate to this folder in linux or
# mac OSX terminal and then run this script. Otherwise this script
# won't work properly.
# Do not move the parts of scripts or folders or run the main script
# from outside of this folder. 

# Kaldi directory ./kaldi
kaldi=/Users/hyungwonyang/kaldi
# Word tier language selection. 0: English graphemes 1: Korean
word_opt=1
# Model directory ./tri3
fa_model=sgmm_mmi
# lexicon directory
dict_dir=main/data/local/dict
# language directory
lang_dir=main/data/lang
# FA data directory
data_dir=$PWD/example/readspeech
# align data directory
ali_dir=fa_dir
# result direcotry
result_dir=tmp/result
# log directory
log_dir=tmp/log
# Number of jobs(just fix it to one)
mfcc_nj=1
align_nj=1


if [ $# -ne 2 ]; then
   echo "Three arguments should be assigned." 
   echo "1. Model option: gmm, dnn(recommend), sgmm_mmi ."
   echo "2. Sound and text file saved directory." && exit 1
fi

# Model selection. dnn, gmm, sgmm_mmi
fa_model=$1
if [ $fa_model == "dnn" ] || [ $fa_model == "gmm" ] || [ $fa_model == "sgmm_mmi" ]; then
	echo "FA model option: $fa_model"
else
	echo "Model option is incorrect. Please choose among 'dnn', 'sgmm', or 'sgmm_mmi'." && exit 1
fi
# Folder directory that contains wav and text files.
data_dir=$2

# This is just test line remove when the script is completed.
echo "Previouse generated files were removed."
rm -rf mfcc conf tmp main/data

# Directory check.
source path.sh $kaldi
[ ! -d tmp ] && mkdir -p tmp
[ ! -d main/data/local/dict ] && mkdir -p main/data/local/dict
[ ! -d main/data/lang ] && mkdir -p main/data/lang
[ ! -d tmp/log ] && mkdir -p tmp/log

# Sound data preprocessing.
echo "preprocessing the input data..."  
python3 main/local/check_text.py $data_dir || exit 1
python3 main/local/fa_prep_data.py $data_dir main/data/trans_data || exit 1
utils/utt2spk_to_spk2utt.pl main/data/trans_data/utt2spk > main/data/trans_data/spk2utt 

# Romanize the text file.
[ ! -d tmp/romanized ] && mkdir -p tmp/romanized
txt_list=`ls $data_dir | grep ".txt"`
for txt in $txt_list; do
	words=`cat $data_dir/$txt`
	txt_rename=`echo $txt | sed -e "s/txt/rom/g"`
	python3 main/local/romanize.py "$words" > tmp/romanized/$txt_rename
done

# g2p text file.
[ ! -d tmp/prono ] && mkdir -p tmp/prono
[ -f tmp/prono/new_lexicon ] && rm tmp/prono/new_lexicon
for tlist in $txt_list; do
	words=`cat $data_dir/$tlist`
	# For first column in lexcion.txt: word.
	echo $words | tr ' ' '\n' > tmp/prono/words_list
	# For second column in lexcion.txt: pronunciation.
	python3 main/local/g2p.py "$words" | tr ' ' '\n' | sed 's/\(..\)/\1 /g' > tmp/prono/prono_list
	paste -d' ' tmp/prono/{words_list,prono_list} >> tmp/prono/new_lexicon
done

# Language modeling.
paste -d'\n' tmp/prono/new_lexicon model/lexicon.txt | sort | uniq | sed '/^\s*$/d' > $dict_dir/lexicon.txt
bash main/local/prepare_new_lang.sh $dict_dir $lang_dir main/data/trans_data "<UNK>"


# MFCC default setting.
echo "Extracting the features from the input data..."
mfccdir=mfcc
cmd="utils/run.pl"
freq_set=16000

# wav file sanitiy check.
wav_list=`ls $data_dir | grep ".wav"`
for wav in $wav_list; do
	wav_ch=`sox --i $data_dir/$wav | grep "Channels" | awk '{print $3}'`
	if [ $wav_ch -ne 1 ]; then
		echo "$wav chanel changed"
		sox $data_dir/$wav -c 1 $data_dir/$wav avg -l; fi
	wav_sr=`sox --i $data_dir/$wav | grep "Sample Rate" | awk '{print $4}'`
	if [ $wav_sr -ne 16000 ]; then
		echo "$wav sampling rate changed"
		sox $data_dir/$wav -r 16000 $data_dir/tmp.wav
		mv $data_dir/tmp.wav $data_dir/$wav; fi
done

# Extracting MFCC features and calculate CMVN.
mkdir -p conf
echo -e "--use-energy=false\n--sample-frequency=$freq_set" > conf/mfcc.conf
steps/make_mfcc.sh --nj $mfcc_nj --cmd "$cmd" main/data/trans_data $log_dir $mfccdir
utils/fix_data_dir.sh main/data/trans_data
steps/compute_cmvn_stats.sh main/data/trans_data $log_dir $mfccdir
utils/fix_data_dir.sh main/data/trans_data

# Forced alignment: aligning data.
if [ $fa_model == "gmm" ]; then
	echo "$fa_model : Force_aligning the input data..."
	steps/align_si.sh --nj $align_nj --cmd "$cmd" \
						main/data/trans_data \
						$lang_dir \
						model/$fa_model \
						tmp/model_ali || exit 1;
elif [ $fa_model == "dnn" ]; then
	echo "$fa_model : Force_aligning the input data..."
	steps/nnet2/align.sh --nj $align_nj --cmd "$cmd" \
						main/data/trans_data \
						$lang_dir \
						model/$fa_model \
						tmp/model_ali ||  exit 1;
elif [ $fa_model == "sgmm_mmi" ]; then
	echo "$fa_model : Force_aligning the input data..."
	steps/align_sgmm2.sh --nj $align_nj --cmd "$cmd" \
						main/data/trans_data \
						$lang_dir \
						model/$fa_model \
						tmp/model_ali ||  exit 1;						
fi

# CTM file conversion.

for dir in tmp/model_ali/ali.*gz;
	do $kaldi/src/bin/ali-to-phones --ctm-output model/$fa_model/final.mdl ark:"gunzip -c $dir|" -> ${dir%.gz}.ctm;
done;

[ ! -d $result_dir ] && mkdir -p $result_dir
cat tmp/model_ali/*.ctm > $result_dir/merged_ali.txt

# Move requisite files.
cp main/data/lang/phones.txt $result_dir
cp main/data/trans_data/segments $result_dir
cp main/local/id2phone.py $result_dir
cp main/local/splitAlignments.py $result_dir

# id to phone conversion.
echo "Reconstructing the alinged data..."
python3 $result_dir/id2phone.py  $result_dir/phones.txt \
								$result_dir/segments \
								$result_dir/merged_ali.txt \
								$result_dir/final_ali.txt || exit 1;

# Split the whole text files.
echo "Spliting the whole aligned data..."
python3 $result_dir/splitAlignments.py $result_dir/final_ali.txt $result_dir || exit 1;

# Combining prono and rom texts. (It also generate text_num.)
bash main/local/make_rg_lexicon.sh || exit 1;


# Generate Textgrid files and save it to the data directory.
echo "Organizing the aligned data to textgrid format."
# Word tier language selection. 0: English graphemes 1: Korean
python3 main/local/generate_textgrid.py \
						$result_dir/tmp_fa \
						tmp/romanized/rom_graph_lexicon.txt \
						tmp/romanized/text_num \
						$data_dir \
						$word_opt || exit 1;

echo "Aligning the input data has been successfully finished."
echo "===================== FINISHED SUCCESSFULLY ====================="
echo "$(date)"
echo
