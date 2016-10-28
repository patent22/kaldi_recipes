#!/bin/bash

# Training data with spectrogram features.

# Kaldi root: Where is your kaldi directory?
kaldi=/Users/hyungwonyang/kaldi
# Source data: Where is your source (wavefile) data directory?
# In the source directory, datasets should be assigned in two directories: train, and test.
source=/Users/hyungwonyang/Documents/data/krs_data
# Current directory.
curdir=$PWD
# Log file: Log file will be saved with the name set below.
logfile=1st_test
# Log directory.
logdir=$curdir/log
# Result file name
resultfile=result.txt
# Number of jobs.
train_nj=1
test_nj=1

# Start logging.
mkdir -p $logdir
echo ====================================================================== | tee $logdir/$logfile.log
echo "                       Kaldi ASR Project	                		  " | tee -a $logdir/$logfile.log
echo ====================================================================== | tee -a $logdir/$logfile.log
echo Tracking the training procedure on: `date` | tee -a $logdir/$logfile.log
echo KALDI_ROOT: $kaldi | tee -a $logdir/$logfile.log
echo DATA_ROOT: $source | tee -a $logdir/$logfile.log
START=`date +%s`

# This step will generate path.sh based on written path above.
. local/make_path.sh $kaldi $curdir
  source path.sh
. cmd.sh
. local/check_code.sh $kaldi


echo ====================================================================== | tee -a $logdir/$logfile.log
echo "                       Data Preparation	                		  " | tee -a $logdir/$logfile.log 
echo ====================================================================== | tee -a $logdir/$logfile.log 
start1=`date +%s`; log_s1=`date | awk '{print $4}'`
echo $log_s1 >> $logdir/$logfile.log 
echo START TIME: $log_s1 | tee -a $logdir/$logfile.log 

# Check source file is ready to be used. Does train and test folders exist inside the source folder?
if [ ! -d $source/train -o ! -d $source/test ] ; then
	echo "train and test folders are not present in $source directory." || exit 1
fi

# In each train and test data folder, distribute 'text', 'textraw', 'utt2spk', 'spk2utt', 'wav.scp', 'segments'.
for set in train test; do
	echo -e "Generating prerequisite files...\nSource directory:$source/$set" | tee -a $logdir/$logfile.log 
	local/krs_prep_data.sh \
		$source/$set \
		$curdir \
		$curdir/data/$set || exit 1
done

end1=`date +%s`; log_e1=`date | awk '{print $4}'`
taken1=`local/track_time.sh $start1 $end1`
echo END TIME: $log_e1  | tee -a $logdir/$logfile.log 
echo PROCESS TIME: $taken1 sec  | tee -a $logdir/$logfile.log


echo ====================================================================== | tee -a $logdir/$logfile.log 
echo "                       Language Modeling	                		  " | tee -a $logdir/$logfile.log 
echo ====================================================================== | tee -a $logdir/$logfile.log 
start2=`date +%s`; log_s2=`date | awk '{print $4}'`
echo $log_s2 >> $logdir/$logfile.log 
echo START TIME: $log_s2 | tee -a $logdir/$logfile.log 

# Generate lexicon, lexiconp, silence, nonsilence, optional_silence, extra_questions
# from the train dataset.
echo "Generating dictionary related files..." | tee -a $logdir/$logfile.log 
local/krs_prep_dict.sh \
	$source/train \
	$curdir \
	$curdir/data/local/dict || exit 1

# Insert <UNK> in the lexicon.txt and lexiconp.txt.
sed -i '1 i\<UNK> <UNK>' $curdir/data/local/dict/lexicon.txt
sed -i '1 i\<UNK> 1.0 <UNK>' $curdir/data/local/dict/lexiconp.txt

# Make ./data/lang folder and other files.
echo "Generating language models..." | tee -a $logdir/$logfile.log 
utils/prepare_lang.sh \
	$curdir/data/local/dict \
	"<UNK>" \
	$curdir/data/local/lang \
	$curdir/data/lang

# Set ngram-count folder.
if [[ -z $(find $KALDI_ROOT/tools/srilm/bin -name ngram-count) ]]; then
	echo "SRILM might not be installed on your computer. Please find kaldi/tools/install_srilm.sh and install the package." #&& exit 1
else
	nc=`find $KALDI_ROOT/tools/srilm/bin -name ngram-count`
	# Make lm.arpa from textraw.
	$nc -text $curdir/data/train/textraw -lm $curdir/data/lang/lm.arpa
fi

# Make G.fst from lm.arpa.
echo "Generating G.fst from lm.arpa..." | tee -a $logdir/$logfile.log
cat $curdir/data/lang/lm.arpa | $KALDI_ROOT/src/lmbin/arpa2fst --disambig-symbol=#0 --read-symbol-table=$curdir/data/lang/words.txt - $curdir/data/lang/G.fst
# Check .fst is stochastic or not.
$KALDI_ROOT/src/fstbin/fstisstochastic $curdir/data/lang/G.fst


end2=`date +%s`; log_e2=`date | awk '{print $4}'`
taken2=`local/track_time.sh $start2 $end2`
echo END TIME: $log_e2  | tee -a $logdir/$logfile.log 
echo PROCESS TIME: $taken2 sec  | tee -a $logdir/$logfile.log


echo ====================================================================== | tee -a $logdir/$logfile.log 
echo "                   Acoustic Feature Extraction	             	  " | tee -a $logdir/$logfile.log 
echo ====================================================================== | tee -a $logdir/$logfile.log 
start3=`date +%s`; log_s3=`date | awk '{print $4}'`
echo $log_s3 >> $logdir/$logfile.log 
echo START TIME: $log_s3 | tee -a $logdir/$logfile.log 

### FFT ###
# Generate mfcc configure.
mkdir -p conf
echo -e '--use-energy=false\n--sample-frequency=16000' > conf/mfcc.conf
# mfcc feature extraction.
fftdir=$curdir/fft
[ ! -d $fftdir ] && mkdir $fftdir
echo "Extracting fft features..." | tee -a $logdir/$logfile.log
# fft feature should be prepared by matlab code.
# save the fft features in fft_feature directory.
tmp_fft=$curdir/fft_feature
fftnj=1
for JOB in `seq $fftnj`; do
	copy-feats --compress=true ark:$tmp_fft/new_fft.$JOB.ark \
		ark,scp:$fftdir/raw_fft_train.$JOB.ark,$fftdir/raw_fft_train.$JOB.scp
done

steps/compute_cmvn_stats.sh \
	 	$curdir/data/train \
	 	$curdir/exp/make_fft/train \
	 	$fftdir

for n in `seq $fftnj`; do
  cat $fftdir/raw_fft_train.$n.scp || exit 1;
done > $curdir/data/train/feats.scp


end3=`date +%s`; log_e3=`date | awk '{print $4}'`
taken3=`local/track_time.sh $start3 $end3`
echo END TIME: $log_e3  | tee -a $logdir/$logfile.log 
echo PROCESS TIME: $taken3 sec  | tee -a $logdir/$logfile.log


echo ====================================================================== | tee -a $logdir/$logfile.log 
echo "                    Train & Decode: Monophone	                 	  " | tee -a $logdir/$logfile.log 
echo ====================================================================== | tee -a $logdir/$logfile.log 
start4=`date +%s`; log_s4=`date | awk '{print $4}'`
echo $log_s4 >> $logdir/$logfile.log 
echo START TIME: $log_s4 | tee -a $logdir/$logfile.log 

# Monophone option setting.
mono_train_opt="--boost-silence 1.25 --nj $train_nj --cmd $train_cmd"
mono_align_opt="--nj $train_nj --cmd $decode_cmd"
mono_decode_opt="--nj $train_nj --cmd $decode_cmd"

# Monophone train.
echo "Training monophone..." | tee -a $logdir/$logfile.log 
local/train_mono_with_fft.sh \
	$mono_train_opt \
	$curdir/data/train \
	$curdir/data/lang \
	$curdir/exp/mono \
	$curdir/fft_feature


# Graph structuring.
echo "Generating monophone graph..." | tee -a $logdir/$logfile.log 
utils/mkgraph.sh $curdir/data/lang $curdir/exp/mono $curdir/exp/mono/graph 

# Monophone aglinment.
# train된 model파일인 mdl과 occs로부터 새로운 align을 생성
echo "Aligning..." | tee -a $logdir/$logfile.log 
steps/align_si.sh \
	$mono_align_opt \
	$curdir/data/train \
	$curdir/data/lang \
	$curdir/exp/mono \
	$curdir/exp/mono_ali || exit 1


end4=`date +%s`; log_e4=`date | awk '{print $4}'`
taken4=`local/track_time.sh $start4 $end4`
echo END TIME: $log_e4  | tee -a $logdir/$logfile.log 
echo PROCESS TIME: $taken4 sec  | tee -a $logdir/$logfile.log


echo ====================================================================== | tee -a $logdir/$logfile.log 
echo "           Train & Decode: Triphone1 [delta+delta-delta]	       	  " | tee -a $logdir/$logfile.log 
echo ====================================================================== | tee -a $logdir/$logfile.log 
start5=`date +%s`; log_s5=`date | awk '{print $4}'`
echo $log_s5 >> $logdir/$logfile.log 
echo START TIME: $log_s5 | tee -a $logdir/$logfile.log 

# Triphone1 option setting.
tri1_train_opt="--cmd $train_cmd"
tri1_align_opt="--nj $train_nj --cmd $decode_cmd"
tri1_decode_opt="--nj $train_nj --cmd $decode_cmd"

echo "Triphone1 training options: $tri1_train_opt"	| tee -a $logdir/$logfile.log
echo "Triphone1 aligning options: $tri1_align_opt"	| tee -a $logdir/$logfile.log
echo "Triphone1 decoding options: $tri1_decode_opt"	| tee -a $logdir/$logfile.log

# Triphone1 training.
echo "Training delta+double-delta..." | tee -a $logdir/$logfile.log 
steps/train_deltas.sh \
	$tri1_train_opt \
	2000 \
	10000 \
	$curdir/data/train \
	$curdir/data/lang \
	$curdir/exp/mono_ali \
	$curdir/exp/tri1 || exit 1

# Graph drawing.
echo "Generating delta+double-delta graph..." | tee -a $logdir/$logfile.log 
utils/mkgraph.sh \
	$curdir/data/lang \
	$curdir/exp/tri1 \
	$curdir/exp/tri1/graph

# Triphone1 aglining.
echo "Aligning..." | tee -a $logdir/$logfile.log 
steps/align_si.sh \
	$tri1_align_opt \
	$curdir/data/train \
	$curdir/data/lang \
	$curdir/exp/tri1 \
	$curdir/exp/tri1_ali ||  exit 1


end5=`date +%s`; log_e5=`date | awk '{print $4}'`
taken5=`local/track_time.sh $start5 $end5`
echo END TIME: $log_e5  | tee -a $logdir/$logfile.log 
echo PROCESS TIME: $taken5 sec  | tee -a $logdir/$logfile.log