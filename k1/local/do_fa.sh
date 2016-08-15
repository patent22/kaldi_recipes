#!/bin/bash

# Kaldi directory ./kaldi
kaldi=/Users/hyungwonyang/kaldi
# Current directory
curdir=$PWD
# Model directory ./tri3
model_dir="tri3"
# lexicon directory
lexcion_dir=lang
# FA data directory
data_dir=train_data
# decoding data
de_data=test
# align data directory
ali_dir=fa_dir
# log directory
log_dir=log
mkdir -p $curdir/log
# Number of jobs(just fix it to one)
nj="1"

. ../local/make_path.sh $kaldi $curdir
source path.sh
. cmd.sh
. local/check_code.sh $kaldi

# Sound data preprocessing.
echo -e "Generating prerequisite files...\nSource directory:$source/$set" | tee -a $logdir/$logfile.log 
local/krs_prep_data.sh \
		$data_dir \
		$curdir \
		$curdir/data/$de_data || exit 1

# Make a dictionary
echo "Generating dictionary related files..." | tee -a $logdir/$logfile.log 
local/krs_prep_dict.sh \
	$data_dir \
	$curdir \
	$curdir/data/local/dict 

sed -i '1 i\<UNK> <UNK>' $curdir/data/local/dict/lexicon.txt
sed -i '1 i\<UNK> 1.0 <UNK>' $curdir/data/local/dict/lexiconp.txt

echo "Generating language models..." | tee -a $logdir/$logfile.log 
utils/prepare_lang.sh \
	$curdir/data/local/dict \
	"<UNK>" \
	$curdir/data/local/lang \
	$curdir/data/lang

nc=`find $KALDI_ROOT/tools/srilm/bin -name ngram-count`
$nc -text $curdir/data/$de_data/textraw -lm $curdir/data/lang/lm.arpa

echo "Generating G.fst from lm.arpa..." | tee -a $logdir/$logfile.log
cat $curdir/data/lang/lm.arpa | $KALDI_ROOT/src/lmbin/arpa2fst --disambig-symbol=#0 --read-symbol-table=$curdir/data/lang/words.txt - $curdir/data/lang/G.fst
# Check .fst is stochastic or not.
$KALDI_ROOT/src/fstbin/fstisstochastic $curdir/data/lang/G.fst


#------ extract MFCC features
mfccdir=mfcc
train_cmd="utils/run.pl"
decode_cmd="utils/run.pl"

mkdir -p conf
echo -e '--use-energy=false\n--sample-frequency=16000' > conf/mfcc.conf
steps/make_mfcc.sh --cmd "$train_cmd" $curdir/data/$de_data $log_dir $mfccdir
utils/fix_data_dir.sh $curdir/data/$de_data
steps/compute_cmvn_stats.sh $curdir/data/$de_data $log_dir $mfccdir
utils/fix_data_dir.sh $curdir/data/$de_data

#------ align data
# oov.int is needed.
steps/align_si.sh --nj $nj --cmd "$train_cmd" $curdir/data/$de_data $curdir/data/$lexcion_dir $curdir/exp/$model_dir $curdir/exp/$ali_dir || exit1;

#------ obtain CTM output from alignment files

for dir in $curdir/exp/$ali_dir/ali.*gz;
	do $kaldi/src/bin/ali-to-phones --ctm-output exp/$model_dir/final.mdl ark:"gunzip -c $dir|" -> ${dir%.gz}.ctm;
done;

#------ concatenate CTM file
[ ! -d $curdir/FA_result ] && mkdir -p $curdir/FA_result
cat $curdir/exp/$ali_dir/*.ctm > $curdir/FA_result/merged_alignment.txt

#------ convert time marks and phone IDs

# Move requisite files.

cp $curdir/data/lang/phones.txt $curdir/FA_result
cp $curdir/data/$de_data/segments $curdir/FA_result
cp $curdir/local/id2phone.py $curdir/FA_result
cp $curdir/local/splitAlignments.py $curdir/FA_result

python $curdir/FA_result/id2phone.py


#------ split final_ali.txt by file
python $curdir/FA_result/splitAlignments.py

#------ create TextGrid
/Applications/Praat.app/Contents/MacOS/Praat --run createtextgrid.praat


