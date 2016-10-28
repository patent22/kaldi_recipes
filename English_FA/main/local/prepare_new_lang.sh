#!/bin/bash
#                             EMCS Labs
#                             Hyungwon Yang
#                             hyung8758@gmail.com


if [ $# -ne 4 ]; then
   echo "Three arguments should be assigned." 
   echo "1. dictionary directory."
   echo "2. language directory."
   echo "3. data directory."
   echo "4. oov_word" && exit 1
fi

# dictionary directory.
dict_dir=$1
# language directory.
lang_dir=$2
# Data directory.
data_dir=$3
# oov word.
oov_word=$4

### dict directory ###
# lexcionp.
perl -ape 's/(\S+\s+)(.+)/${1}1.0\t$2/;' < $dict_dir/lexicon.txt > $dict_dir/lexiconp.txt

# silence. 1
echo -e "pau\nsil" >  $dict_dir/silence.txt
echo "silence.txt file was generated."

# one_state. 22
echo -e "pcl\nbcl\ntcl\ndcl\nkcl\ngcl\nb\nd\ng\np\nt\nk\ndx\njh\nch\nax-h\nm\nn\nng\nnx\nl\nr" | sort -u  >  $dict_dir/one_state.txt
echo "one_state.txt file was generated."

# three_state. 28
echo -e "w\ny\nhh\nhv\ns\nz\nsh\nzh\nf\nv\nth\ndh\naa\nae\nah\nao\nax\naxr\neh\ner\ney\nih\nix\niy\now\nuh\nuw\nux" | sort -u >  $dict_dir/three_state.txt
echo "three_state.txt file was generated."

# five_state. 3
echo -e "ay\naw\noy" | sort -u >  $dict_dir/five_state.txt
echo "five_state.txt file was generated."

# optional_silence.
echo 'sil' >  $dict_dir/optional_silence.txt
echo "optional_silence.txt file was generated."

# extra_questions.
echo "pau sil" > $dict_dir/extra_questions.txt || exit 1;
echo "extra_questions.txt file was generated."

# Insert <UNK> in the lexicon.txt and lexiconp.txt.
sed -i '1 i\pau pau' $dict_dir/lexicon.txt
sed -i '1 i\pau 1.0 pau' $dict_dir/lexiconp.txt

### lang directory ###
utils/prepare_lang_4phonesets.sh $dict_dir $oov_word main/data/local/lang $lang_dir >/dev/null


