#!/bin/bash
# # This scripts generate dictionray related parts.
# 														Hyungwon Yang
# 														hyung8758@gmail.com
# 														NAMZ & EMCS Labs


if [ $# -ne 2 ]; then
   echo "Three arguments should be assigned." 
   echo "1. Source data."
   echo "2. The folder in which generated files are saved." && exit 1
fi

# train data directory.
data=$1
# savining directory.
save=$2

echo ======================================================================
echo "                              NOTICE                                "
echo ""
echo -e "krs_prep_dict: Generate lexicon, lexiconp, silence, nonsilence, \n\toptional_silence, and extra_questions."
echo "CURRENT SHELL: $0"
echo -e "INPUT ARGUMENTS:\n$@"

for check in lexicon.txt lexiconp.txt silence.txt nonsilence.txt optional_silence.txt extra_questions.txt; do
	if [ -f $save/$check ] && [ ! -z $save/$check ]; then
		echo -e "$check is already present but it will be overwritten."
	fi
done
echo ""
echo ======================================================================

# lexicon.txt and lexiconp.txt
if [ ! -d $save ]; then
	mkdir -p $save
fi

echo "Generating lexicon.txt and lexiconp.txt."
# Get word list from text files.
dir_list=`ls $data`
echo "" > $save/lexicon.txt
for d in $dir_list; do
	txt_list=`ls $data/$d | grep ".txt"`
	for txt in $txt_list; do
		cat $data/$d/$txt | tr ' ' '\n' >> $save/tmp
	done
done

cat $save/tmp | sort -u | sed '/^\s*$/d' > $save/new_tmp
rm $save/tmp

# g2p process on word list.
word_count=`wc -l $save/new_tmp | awk '{print $1}'`
count=0
for word in `cat $save/new_tmp`; do
	count=$((count+1))
	python local/g2p.py $word >> $save/phones
	echo -ne "Processing... ($count / "$word_count") \r"
done

# Make lexicon.txt and lexiconp.txt
paste -d'\t' $save/new_tmp $save/phones > $save/lexicon.txt
perl -ape 's/(\S+\s+)(.+)/${1}1.0\t$2/;' < $save/lexicon.txt > $save/lexiconp.txt
rm $save/new_tmp $save/phones

echo "lexicon.txt and lexiconp.txt files were generated."


# silence.
echo -e "<SIL>\n<UNK>" >  $save/silence_phones.txt
echo "silence.txt file was generated."

# nonsilence.
awk '{$1=""; print $0}' $save/lexicon.txt | tr -s ' ' '\n' | sort -u | sed '/^$/d' >  $save/nonsilence_phones.txt
echo "nonsilence.txt file was generated."

# optional_silence.
echo '<SIL>' >  $save/optional_silence.txt
echo "optional_silence.txt file was generated."

# extra_questions.
cat $save/silence_phones.txt| awk '{printf("%s ", $1);} END{printf "\n";}' > $save/extra_questions.txt || #exit 1;
cat $save/nonsilence_phones.txt | perl -e 'while(<>){ foreach $p (split(" ", $_)) {  $p =~ m:^([^\d]+)(\d*)$: || die "Bad phone $_"; $q{$2} .= "$p "; } } foreach $l (values %q) {print "$l\n";}' >> $save/extra_questions.txt || exit 1;
echo "extra_questions.txt file was generated."

