#!/bin/bash
# 														Jaekoo Kang
# 														Hyungwon Yang
# 														EMCS Labs
#
# This script combine romanized and pronunciation texts together.
# It will be used for second word tier in Textgrid.
[ -f tmp/romanized/text_num ] && rm tmp/romanized/text_num
[ -f tmp/romanized/rom_graph_lexicon.txt ] && rm tmp/romanized/rom_graph_lexicon.txt
if [ -f "tmp/romanized/list_test01.rom" ]; then
	for lst in tmp/romanized/list*.rom; do
		rm $lst; done; fi

list=`ls tmp/romanized`
for l in $list; do
	cat tmp/romanized/$l | tr ' ' '\n' > tmp/romanized/list_$l
	cat tmp/romanized/$l | wc -w | awk '{print $1}'>> tmp/romanized/text_num
done

cat tmp/romanized/list* > tmp/romanized/rom_lexicon
paste -d ' ' tmp/romanized/rom_lexicon tmp/prono/new_lexicon > tmp/romanized/rom_graph_lexicon.txt

echo "rom_graph_lexicon.txt and text_num are generated in tmp/romanized folder."

