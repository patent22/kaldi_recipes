#!/bin/bash
# 														EMCS Labs
# 														Hyungwon Yang
# 														hyung8758@gmail.com

# This scripts generate prerequsite datasets.
# text, utt2spk, wav.scp, segments.

# ./data/local/data => text, utt2spk, wav.scp, segments, glm, stm
# ./conf => phones.60-48-39.map 
# ./local/dict => lexicon.txt
# ./wavtxt => raw wav와 txt 파일

if [ $# -ne 3 ]; then
   echo "Three arguments should be assigned." 
   echo "1. Source data."
   echo "2. Current directory."
   echo "3. The folder generated files saved." && exit 1
fi

# Corpus directory: ./krs_data
data=$1
# Current directory.
curdir=$2
# Result directory: ./data/local/data
save=$3

echo ======================================================================
echo "                              NOTICE                                "
echo ""
echo "krs_prep_data.sh: Generate wav.scp."
echo "CURRENT SHELL: $0"
echo -e "INPUT ARGUMENTS:\n$@"

# requirement check
if [ ! -d $data ]; then
	echo "Corpus data is not present." && exit 1
	echo ""
	echo ======================================================================
fi
for check in wav.scp ; do
	if [ -f $save/$check ] && [ ! -z $save/$check ]; then
		echo -e "$check is already present but it will be overwritten."
	fi
done
echo ""
echo ======================================================================

if [ ! -d $save ]; then
	mkdir -p $save
fi

# wav.scp
if [ -f $save/wav.scp ] && [ ! -z $save/wav.scp ]; then
	echo '' > $save/wav.scp
	echo '* Previous wav.scp file was removed.'

	data_num=`ls $data | wc -w`
	data_list=`ls $data`

	for txt in `seq 1 $data_num`; do
		data_name=`echo $data_list | cut -d' ' -f$txt`
		snt_list=`ls $data/$data_name | grep .TextGrid`
		snt_num=`echo $snt_list | wc -w`

		for snt in `seq 1 $snt_num`; do
			get_snt=`echo $snt_list | cut -d' ' -f$snt`
			wav_snt=`echo $get_snt | sed 's/.TextGrid//g'`
			fix_snt=`echo $get_snt | sed 's/.TextGrid/.wav/g'`
			echo "$wav_snt $data/$data_name/$fix_snt" >> $save/wav.scp || exit 1
		done
	done
	sed '1d' $save/wav.scp > $save/tmp; cat $save/tmp > $save/wav.scp; rm $save/tmp

else
	data_num=`ls $data | wc -w`
	data_list=`ls $data`

	for txt in `seq 1 $data_num`; do
		data_name=`echo $data_list | cut -d' ' -f$txt`
		snt_list=`ls $data/$data_name | grep .TextGrid`
		snt_num=`echo $snt_list | wc -w`

		for snt in `seq 1 $snt_num`; do
			get_snt=`echo $snt_list | cut -d' ' -f$snt`
			wav_snt=`echo $get_snt | sed 's/.TextGrid//g'`
			fix_snt=`echo $get_snt | sed 's/.TextGrid/.wav/g'`
			echo "$wav_snt $data/$data_name/$fix_snt" >> $save/wav.scp || exit 1
		done
	done
fi
echo "wav.scp file was generated."

