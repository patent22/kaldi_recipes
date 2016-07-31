#!/bin/bash
# 														EMCS Labs
# 														Hyungwon Yang
# 														hyung8758@gmail.com

# This script split the dataset into n-number of groups and it
# runs the cross validation through 5 divdied datasets.

# Kaldi root: Where is your kaldi directory?
kaldi=/Users/hyungwonyang/kaldi
# Source data: Where is your source (wavefile) data directory?
# In the source directory, datasets should be assigned in two directories: train, and test.
source=/Users/hyungwonyang/Documents/data/1_corpus/Korean_Readspeech/korean_readspeech
# current directory.
curdir=$PWD
# Log file: Log file will be saved with the name set below.
logfile=1st_cv_test
# Log directory.
logdir=$curdir/log
# corpus data direcotry names.
prep_data=data4cv
prep_cv_data=cv_data
# The number of splited dataset.
split_num=5
# Number of jobs.
nj=2

# 5 datasets will be used for cross validation.
# Start logging.
mkdir -p $curdir/log
echo ====================================================================== | tee $logdir/$logfile.log
echo "                       Kaldi ASR Project	                		  " | tee -a $logdir/$logfile.log
echo ====================================================================== | tee -a $logdir/$logfile.log
echo Tracking the training procedure on: `date` | tee -a $logdir/$logfile.log
echo KALDI_ROOT: $kaldi | tee -a $logdir/$logfile.log
echo DATA_ROOT: $source | tee -a $logdir/$logfile.log
START=`date +%s`

# This step will generate path.sh based on written path above.
. ./local/make_path.sh $kaldi 
. ./cmd.sh
. ./local/check_code.sh $kaldi

echo ====================================================================== 
echo "                         Split Datasets	                		  " 
echo ====================================================================== 

# From the corpus data folder, total 5 'part#' named folders will be generated
# and source files will be distributed there.
# This is very basic steps for training datasets. For those who just have a corpus
# that contains 117 speaker datasets and did not separated it into 5 parts, this 
# split datasets process needs to be started. If the datasets are already splited,
# please skip this process.

# split the data into 5 folders.
# The number of speaker datasets needs to be chosen.
# There are 4 options: 5, 20, and 117(whole datasets) speakers.
# krs_split_data function will copy the original corpus data in order to
. local/krs_split_data.sh $source 5 $curdir/$prep_data

# Prepare datasets for training. (including  testing.)
. local/krs_prep_cv.sh $curdir/data4cv $curdir/$prep_cv_data


echo ====================================================================== 
echo "                         Cross Validation	                		  " 
echo ====================================================================== 

# Main loop:
# In this process, tmp folder will be generated to contain 5 cv folders.
# In each cv folder, training and decoding will be activated and the results
# and rest files will be moved to cv_result folders.

if [ ! -d ./tmp ]; then
	mkdir -p tmp
else 
	rm -rf tmp
	mkdir -p tmp
fi

for turn in 1 2 3 4 5; do
	mv -r $curdir/$prep_cv_data/cv$turn $curdir/tmp
	source_dir=$curdir/$prep_cv_data
	main_dir=$curdir/tmp/cv$turn

	echo ====================================================================== | tee -a $logdir/$logfile.log
	echo "                       Data Preparation	                		  " | tee -a $logdir/$logfile.log 
	echo ====================================================================== | tee -a $logdir/$logfile.log 
	start1=`date +%s`; log_s1=`date | awk '{print $4}'`
	echo $log_s1 >> $logdir/$logfile.log 
	echo START TIME: $log_s1 | tee -a $logdir/$logfile.log 

	# Check source file is ready to be used. Does train and test folders exist inside the source folder?
	if [ ! -d $source_dir/train -o ! -d $source_dir/test ] ; then
		echo "train and test folders are not present in $source_dir directory." || exit 1
	fi

	# In each train and test data folder, distribute 'text', 'utt2spk', 'spk2utt', 'wav.scp', 'segments'.
	for set in train test; do
		echo -e "Generating prerequisite files...\nSource directory:$source/$set" | tee -a $logdir/$logfile.log 
		. ./local/krs_prep_data.sh $source_dir/$set $main_dir/data/$set || exit 1
	done


	end1=`date +%s`; log_e1=`date | awk '{print $4}'`
	taken1=`. $main_dir/local/track_time.sh $start1 $end1`
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
	. ./local/krs_prep_dict.sh $source_dir/train $main_dir/data/local/dict || exit 1

	# Insert <UNK> in the lexicon.txt and lexiconp.txt.
	sed -i '1 i\<UNK> <UNK>' $main_dir/data/local/dict/lexicon.txt
	sed -i '1 i\<UNK> 1.0 <UNK>' $main_dir/data/local/dict/lexiconp.txt

	# Make ./data/lang folder and other files.
	echo "Generating language models..." | tee -a $logdir/$logfile.log 
	utils/prepare_lang.sh $main_dir/data/local/dict "<UNK>" $main_dir/data/local/lang $main_dir/data/lang

	# Set ngram-count folder.
	nc=`find $KALDI_ROOT/tools/srilm/bin -name ngram-count`
	# Make lm.arpa from textraw.
	$nc -text $main_dir/data/train/textraw -lm $main_dir/data/lang/lm.arpa

	# Make G.fst from lm.arpa.
	cat $main_dir/data/lang/lm.arpa | $KALDI_ROOT/src/lmbin/arpa2fst --disambig-symbol=#0 --read-symbol-table=$main_dir/data/lang/words.txt - $main_dir/data/lang/G.fst
	# Check .fst is stochastic or not.
	$KALDI_ROOT/src/fstbin/fstisstochastic $main_dir/data/lang/G.fst


	end2=`date +%s`; log_e2=`date | awk '{print $4}'`
	taken2=`. $curdir/local/track_time.sh $start2 $end2`
	echo END TIME: $log_e2  | tee -a $logdir/$logfile.log 
	echo PROCESS TIME: $taken2 sec  | tee -a $logdir/$logfile.log


	echo ====================================================================== | tee -a $logdir/$logfile.log 
	echo "                   Acoustic Feature Extraction	             	  " | tee -a $logdir/$logfile.log 
	echo ====================================================================== | tee -a $logdir/$logfile.log 
	start3=`date +%s`; log_s3=`date | awk '{print $4}'`
	echo $log_s3 >> $logdir/$logfile.log 
	echo START TIME: $log_s3 | tee -a $logdir/$logfile.log 

	### MFCC ###
	# Generate mfcc configure.
	mkdir -p $main_dir/conf
	echo -e '--use-energy=false\n--sample-frequency=16000' > $main_dir/conf/mfcc.conf
	# mfcc feature extraction.
	echo "Extracting MFCC features..." | tee -a $logdir/$logfile.log 
	mfccdir=mfcc
	steps/make_mfcc.sh $main_dir/data/train $main_dir/exp/make_mfcc/train $mfccdir
	# Compute cvnm. (This steps should be processed right after mfcc features are extracted.)
	echo "Computing CMVN on MFCC..." | tee -a $logdir/$logfile.log 
	steps/compute_cmvn_stats.sh $main_dir/data/train $main_dir/exp/make_mfcc/train $main_dir/$mfccdir

	### PLP ###
	echo -e '--sample-frequency=16000' > $main_dir/conf/plp.conf
	plpdir=plp
	echo "Extracting PLP features..." | tee -a $logdir/$logfile.log 
	steps/make_plp.sh $main_dir/data/train $main_dir/exp/make_plp/train $main_dir/$plpdir
	# Compute cvnm. (This steps should be processed right after plp features are extracted.)
	echo "Computing CMVN on PLP..." | tee -a $logdir/$logfile.log 
	steps/compute_cmvn_stats.sh $main_dir/data/train $main_dir/exp/make_plp/train $main_dir/$plpdir

	# data directories sanity check.
	echo "Examining generated datasets..." | tee -a $logdir/$logfile.log 
	utils/validate_data_dir.sh $main_dir/data/train
	utils/fix_data_dir.sh $main_dir/data/train


	end3=`date +%s`; log_e3=`date | awk '{print $4}'`
	taken3=`. $main_dir/local/track_time.sh $start3 $end3`
	echo END TIME: $log_e3  | tee -a $logdir/$logfile.log 
	echo PROCESS TIME: $taken3 sec  | tee -a $logdir/$logfile.log


	echo ====================================================================== | tee -a $logdir/$logfile.log 
	echo "                    Train & Decode: Monophone	                 	  " | tee -a $logdir/$logfile.log 
	echo ====================================================================== | tee -a $logdir/$logfile.log 
	start4=`date +%s`; log_s4=`date | awk '{print $4}'`
	echo $log_s4 >> $logdir/$logfile.log 
	echo START TIME: $log_s4 | tee -a $logdir/$logfile.log 

	# Monophone option setting.
	mono_train_opt="--boost-silence 1.25 --nj $nj --cmd $train_cmd"
	mono_decode_opt="--nj $nj --cmd $decode_cmd"
	echo "Monophone trainig options: $mono_train_opt"
	echo "Monophone decoding options: $mono_decode_opt"

	# Monophone train.
	echo "Training monophone..." | tee -a $logdir/$logfile.log 
	steps/train_mono.sh $mono_train_opt $main_dir/data/train $main_dir/data/lang $main_dir/exp/mono ||  exit1

	# Graph structuring.
	# make HCLG graph (optional! train과는 무관, 오직 decode만을 위해.)
	# This script creates a fully expanded decoding graph (HCLG) that represents
	# all the language-model, pronunciation dictionary (lexicon), context-dependency,
	# and HMM structure in our model.  The output is a Finite State Transducer
	# that has word-ids on the output, and pdf-ids on the input (these are indexes
	# that resolve to Gaussian Mixture Models).
	# exp/mono/graph에 가면 결과 graph가 만들어져 있음
	echo "Generating monophone graph..." | tee -a $logdir/$logfile.log 
	utils/mkgraph.sh $main_dir/data/lang $main_dir/exp/mono $main_dir/exp/mono/graph 

	# Monophone aglinment.
	# train된 model파일인 mdl과 occs로부터 새로운 align을 생성
	echo "Aligning..." | tee -a $logdir/$logfile.log 
	steps/align_si.sh $mono_decode_opt $main_dir/data/train $main_dir/data/lang $main_dir/exp/mono $main_dir/exp/mono_ali || exit 1

	### Optional ###
	# Data decoding.
	# (This is just decoding the trained model, not part of training process.)
	echo "Decoding with monophone model..." | tee -a $logdir/$logfile.log 
	steps/decode.sh $mono_decode_opt $main_dir/exp/mono/graph $main_dir/data/train $main_dir/exp/mono/decode_train

	# tree structuring.
	$KALDI_ROOT/src/bin/draw-tree $main_dir/data/lang/phones.txt $main_dir/exp/mono/tree \
	| dot -Tps -Gsize=8,10.5 | ps2pdf - tree.pdf 2>/dev/null


	end4=`date +%s`; log_e4=`date | awk '{print $4}'`
	taken4=`. $curdir/local/track_time.sh $start4 $end4`
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
	tri1_decode_opt="--nj $nj --cmd $decode_cmd"
	echo "Triphone1 training options: $tri1_train_opt"
	echo "Triphone1 decoding options: $tri1_decode_opt"

	# Triphone1 training.
	echo "Training delta+double-delta..." | tee -a $logdir/$logfile.log 
	steps/train_deltas.sh $tri1_train_opt 2000 10000 $main_dir/data/train $main_dir/data/lang $main_dir/exp/mono_ali $main_dir/exp/tri1

	# Graph drawing.
	echo "Generating delta+double-delta graph..." | tee -a $logdir/$logfile.log 
	utils/mkgraph.sh $main_dir/data/lang $main_dir/exp/tri1 $main_dir/exp/tri1/graph

	# Triphone1 aglining.
	echo "Aligning..." | tee -a $logdir/$logfile.log 
	steps/align_si.sh $tri1_decode_opt $main_dir/data/train $main_dir/data/lang $main_dir/exp/tri1 $main_dir/exp/tri1_ali

	# Data decoding.
	echo "Decoding with delta+double-delta model..." | tee -a $logdir/$logfile.log 
	steps/decode.sh $tri1_decode_opt $main_dir/exp/tri1/graph $main_dir/data/train $main_dir/exp/tri1/decode_train


	end5=`date +%s`; log_e5=`date | awk '{print $4}'`
	taken5=`. $curdir/local/track_time.sh $start5 $end5`
	echo END TIME: $log_e5  | tee -a $logdir/$logfile.log 
	echo PROCESS TIME: $taken5 sec  | tee -a $logdir/$logfile.log


	echo ====================================================================== | tee -a $logdir/$logfile.log 
	echo "               Train & Decode: Triphone2 [LDA+MLLT]	         	  " | tee -a $logdir/$logfile.log 
	echo ====================================================================== | tee -a $logdir/$logfile.log 
	start6=`date +%s`; log_s6=`date | awk '{print $4}'`
	echo $log_s6 >> $logdir/$logfile.log 
	echo START TIME: $log_s6 | tee -a $logdir/$logfile.log 

	# Triphone2 option setting.
	tri2_train_opt="--cmd $train_cmd"
	tri2_decode_opt="--nj $nj --cmd $decode_cmd"
	echo "Triphone2 trainig options: $tri2_train_opt"
	echo "Triphone2 decoding options: $tri2_decode_opt"

	# Triphone2 training.
	echo "Training LDA+MLLT..." | tee -a $logdir/$logfile.log 
	steps/train_lda_mllt.sh $tri2_train_opt 2500 15000 $main_dir/data/train $main_dir/data/lang $main_dir/exp/tri1_ali $main_dir/exp/tri2

	# Graph drawing.
	echo "Generating LDA+MLLT graph..." | tee -a $logdir/$logfile.log
	utils/mkgraph.sh $main_dir/data/lang $main_dir/exp/tri2 $main_dir/exp/tri2/graph

	# Triphone2 aglining.
	echo "Aligning..." | tee -a $logdir/$logfile.log
	steps/align_si.sh $tri2_decode_opt $main_dir/data/train $main_dir/data/lang $main_dir/exp/tri2 $main_dir/exp/tri2_ali

	# Data decoding.
	echo "Decoding with LDA+MLLT model..." | tee -a $logdir/$logfile.log
	steps/decode.sh $tri2_decode_opt $main_dir/exp/tri2/graph $main_dir/data/train $main_dir/exp/tri2/decode_train


	end6=`date +%s`; log_e6=`date | awk '{print $4}'`
	taken6=`. $curdir/local/track_time.sh $start6 $end6`
	echo END TIME: $log_e6  | tee -a $logdir/$logfile.log 
	echo PROCESS TIME: $taken6 sec  | tee -a $logdir/$logfile.log


	echo ====================================================================== | tee -a $logdir/$logfile.log 
	echo "             Train & Decode: Triphone3 [LDA+MLLT+SAT]	         	  " | tee -a $logdir/$logfile.log 
	echo ====================================================================== | tee -a $logdir/$logfile.log 
	start7=`date +%s`; log_s7=`date | awk '{print $4}'`
	echo $log_s7 >> $logdir/$logfile.log 
	echo START TIME: $log_s7 | tee -a $logdir/$logfile.log 

	# Triphone3 option setting.
	tri3_train_opt="--cmd $train_cmd"
	tri3_decode_opt="--nj $nj --cmd $decode_cmd"
	echo "Triphone3 trainig options: $tri3_train_opt"
	echo "Tirphone3 decoding options: $tri3_decode_opt"

	# Triphone3 training.
	echo "Training LDA+MLLT+SAT..." | tee -a $logdir/$logfile.log
	steps/train_sat.sh $tri3_train_opt 2500 15000 $main_dir/data/train $main_dir/data/lang $main_dir/exp/tri2_ali $main_dir/exp/tri3

	# Graph drawing.
	echo "Generating LDA+MLLT+SAT graph..." | tee -a $logdir/$logfile.log
	utils/mkgraph.sh $main_dir/data/lang $main_dir/exp/tri3 $main_dir/exp/tri3/graph

	# Triphone3 aglining.
	echo "ALigning..." | tee -a $logdir/$logfile.log
	steps/align_fmllr.sh $tri3_decode_opt $main_dir/data/train $main_dir/data/lang $main_dir/exp/tri3 $main_dir/exp/tri3_ali

	# Data decoding: train dataset.
	echo "Decoding with Training LDA+MLLT+SAT model..." | tee -a $logdir/$logfile.log
	steps/decode_fmllr.sh $tri3_decode_opt $main_dir/exp/tri3/graph $main_dir/data/train $main_dir/exp/tri3/decode_train
	# Data decoding: test dataset.
	steps/decode_fmllr.sh $tri3_decode_opt $main_dir/exp/tri3/graph $main_dir/data/test $main_dir/exp/tri3/decode_test


	end7=`date +%s`; log_e7=`date | awk '{print $4}'`
	taken7=`. $curdir/local/track_time.sh $start7 $end7`
	echo END TIME: $log_e7  | tee -a $logdir/$logfile.log 
	echo PROCESS TIME: $taken7 sec  | tee -a $logdir/$logfile.log


	echo ====================================================================== | tee -a $logdir/$logfile.log 
	echo "                       Train & Decode: SGMM2 	               	      " | tee -a $logdir/$logfile.log 
	echo ====================================================================== | tee -a $logdir/$logfile.log 
	start8=`date +%s`; log_s8=`date | awk '{print $4}'`
	echo $log_s8 >> $logdir/$logfile.log 
	echo START TIME: $log_s8 | tee -a $logdir/$logfile.log 

	# SGMM training, with speaker vectors.  This script would normally be called on
	# top of fMLLR features obtained from a conventional system, but it also works
	# on top of any type of speaker-independent features (based on
	# deltas+delta-deltas or LDA+MLLT).  For more info on SGMMs, see the paper "The
	# subspace Gaussian mixture model--A structured model for speech recognition".
	# (Computer Speech and Language, 2011).

	# SGMM2 option setting.
	sgmm2_train_opt="--cmd $train_cmd"
	sgmm2_decode_opt="--nj $nj --cmd $decode_cmd --transform-dir"
	echo "SGMM2 trainig options: $sgmm2_train_opt"
	echo "SGMM2 decoding options: $sgmm2_decode_opt"

	# UBM training.
	echo "Training UBM..." | tee -a $logdir/$logfile.log
	steps/train_ubm.sh 400 $main_dir/data/train $main_dir/data/lang $main_dir/exp/tri3_ali $main_dir/exp/ubm

	# SGMM2 training.
	echo "Training SGMM2..." | tee -a $logdir/$logfile.log
	steps/train_sgmm2.sh $sgmm2_train_opt 5000 8000 $main_dir/data/train $main_dir/data/lang $main_dir/exp/tri3_ali $main_dir/exp/ubm/final.ubm $main_dir/exp/sgmm

	# Graph drawing.
	echo "Generating SGMM2 graph..." | tee -a $logdir/$logfile.log
	utils/mkgraph.sh $main_dir/data/lang $main_dir/exp/sgmm $main_dir/exp/sgmm/graph

	# SGMM2 aglining.
	echo "Aligning..." | tee -a $logdir/$logfile.log
	steps/align_sgmm2.sh $sgmm2_train_opt --transform-dir $main_dir/exp/tri3_ali $main_dir/data/train $main_dir/data/lang $main_dir/exp/sgmm $main_dir/exp/sgmm_ali

	# Data decoding: train dataset.
	echo "Decoding with SGMM2 model..." | tee -a $logdir/$logfile.log
	steps/decode_sgmm2.sh $sgmm2_decode_opt $main_dir/exp/tri3_ali $main_dir/exp/sgmm/graph $main_dir/data/train $main_dir/exp/sgmm/decode_train

	# Data decoding: test dataset.
	steps/decode_sgmm2.sh $sgmm2_decode_opt $main_dir/exp/tri3/decode_test $main_dir/exp/sgmm/graph $main_dir/data/test $main_dir/exp/sgmm/decode_test


	end8=`date +%s`; log_e8=`date | awk '{print $4}'`
	taken8=`. $curdir/local/track_time.sh $start8 $end8`
	echo END TIME: $log_e8  | tee -a $logdir/$logfile.log 
	echo PROCESS TIME: $taken8 sec  | tee -a $logdir/$logfile.log


	echo ====================================================================== | tee -a $logdir/$logfile.log 
	echo "                     Train & Decode: SGMM2+MMI 	           	      " | tee -a $logdir/$logfile.log 
	echo ====================================================================== | tee -a $logdir/$logfile.log 
	start9=`date +%s`; log_s9=`date | awk '{print $4}'`
	echo $log_s9 >> $logdir/$logfile.log 
	echo START TIME: $log_s9 | tee -a $logdir/$logfile.log 

	# SGMM training, with speaker vectors.  This script would normally be called on
	# top of fMLLR features obtained from a conventional system, but it also works
	# on top of any type of speaker-independent features (based on
	# deltas+delta-deltas or LDA+MLLT).  For more info on SGMMs, see the paper "The
	# subspace Gaussian mixture model--A structured model for speech recognition".
	# (Computer Speech and Language, 2011).

	# SGMM2 option setting.
	sgmmi_train_opt="--cmd $train_cmd"
	sgmmi_decode_opt="--transform-dir"
	echo "SGMM2+MMI trainig options: $sgmmi_train_opt"
	echo "SGMM2+MMI decoding options: $sgmmi_decode_opt"

	# SGMM2+MMI training.
	echo "Training SGMM2+MMI..." | tee -a $logdir/$logfile.log
	steps/make_denlats_sgmm2.sh --nj "$nj" --sub-split 40 --transform-dir $main_dir/exp/tri3_ali $main_dir/data/train $main_dir/data/lang $main_dir/exp/sgmm_ali $main_dir/exp/sgmm_denlats
	steps/train_mmi_sgmm2.sh $sgmmi_train_opt $main_dir/exp/tri3_ali $main_dir/data/train $main_dir/data/lang $main_dir/exp/sgmm_ali $main_dir/exp/sgmm_denlats $main_dir/exp/sgmm_mmi

	# Data decoding: train dataset.
	echo "Decoding with SGMM2+MMI model..." | tee -a $logdir/$logfile.log
	steps/decode_sgmm2_rescore.sh $sgmmi_decode_opt $main_dir/exp/tri3/decode_train $main_dir/data/lang $main_dir/data/train $main_dir/exp/sgmm/decode_train $main_dir/exp/sgmm_mmi/decode_train

	# Data decoding: test dataset.
	steps/decode_sgmm2_rescore.sh $sgmmi_decode_opt $main_dir/exp/tri3/decode_test $main_dir/data/lang $main_dir/data/test $main_dir/exp/sgmm/decode_test $main_dir/exp/sgmm_mmi/decode_test


	end9=`date +%s`; log_e9=`date | awk '{print $4}'`
	taken9=`. $main_dir/local/track_time.sh $start9 $end9`
	echo END TIME: $log_e9  | tee -a $logdir/$logfile.log 
	echo PROCESS TIME: $taken9 sec  | tee -a $logdir/$logfile.log


	echo ====================================================================== | tee -a $logdir/$logfile.log 
	echo "                       Train & Decode: DNN  	            	      " | tee -a $logdir/$logfile.log 
	echo ====================================================================== | tee -a $logdir/$logfile.log 
	start10=`date +%s`; log_s10=`date | awk '{print $4}'`
	echo $log_s10 >> $logdir/$logfile.log 
	echo START TIME: $log_s10 | tee -a $logdir/$logfile.log 

	# SGMM training, with speaker vectors.  This script would normally be called on
	# top of fMLLR features obtained from a conventional system, but it also works
	# on top of any type of speaker-independent features (based on
	# deltas+delta-deltas or LDA+MLLT).  For more info on SGMMs, see the paper "The
	# subspace Gaussian mixture model--A structured model for speech recognition".
	# (Computer Speech and Language, 2011).

	# SGMM2 option setting.
	dnn1_train_opt=""
	dnn1_decode_opt="--nj $nj --transform-dir"
	dnn_function="train_tanh_fast.sh"
	echo "DNN($dnn_function) trainig options: $dnn1_train_opt"
	echo "DNN($dnn_function) decoding options: $dnn1_decode_opt"

	# DNN training.
	# train_tanh_fast.sh
	echo "Training DNN..." | tee -a $logdir/$logfile.log
	steps/nnet2/train_tanh_fast.sh $dnn1_train_opt $main_dir/data/train $main_dir/data/lang $main_dir/exp/tri3_ali $main_dir/exp/tri4
	# train_multisplice_accel2.sh

	# train_tdnn.sh

	echo "Decoding with DNN model..." | tee -a $logdir/$logfile.log
	# Data decoding: train dataset.
	steps/nnet2/decode.sh $dnn1_decode_opt $main_dir/exp/tri3/decode_train $main_dir/exp/tri3/graph $main_dir/data/train $main_dir/exp/tri4/decode_train

	# Data decoding: test dataset.
	steps/nnet2/decode.sh $dnn1_decode_opt $main_dir/exp/tri3/decode_test $main_dir/exp/tri3/graph $main_dir/data/test $main_dir/exp/tri4/decode_test


	end10=`date +%s`; log_e10=`date | awk '{print $4}'`
	taken10=`. $main_dir/local/track_time.sh $start10 $end10`
	echo END TIME: $log_e10  | tee -a $logdir/$logfile.log 
	echo PROCESS TIME: $taken10 sec  | tee -a $logdir/$logfile.log


	echo ====================================================================== | tee -a $logdir/$logfile.log 
	echo "                             RESULTS  	                	      " | tee -a $logdir/$logfile.log 
	echo ====================================================================== | tee -a $logdir/$logfile.log 
	echo "Displaying results" | tee -a $logdir/$logfile.log



	##########################################################
	# This is for final log.
	echo "Training procedure finished successfully..." | tee -a $logdir/$logfile.log
	END=`date +%s`
	taken=`. $curdir/local/track_time.sh $START $END`
	echo TOTAL TIME: $taken sec  | tee -a $logdir/$logfile.log 





