# 														EMCS Labs
# 														Hyungwon Yang
# 														hyung8758@gmail.com
'''
This script generates lexicon.txt and lexiconp.txt files based on corpus data.
Running on python3.
'''

import sys
import os
import re


# Arguments check.
'''
if len(sys.argv) != 3:
    print(len(sys.argv))
    raise ValueError('The number of input arguments is wrong.')

# corpus data directory
text_dir=sys.argv[1]
outputfile = sys.argv[2]
'''
text_dir='/Users/hyungwonyang/Documents/data/1_corpus/Korean_Readspeech/korean_readspeech'
outputfile='/Users/hyungwonyang/Documents/ASR_project/kaldi_project/exp/kaldi_recipes/k1/data/local/dict'

# Search directories.
dir_list = os.listdir(text_dir)
sub_dir = []
for check in dir_list:
    if len(re.findall('[0-9]',check)) != 0:
        sub_dir.append(check)

# Get Text list.
sub_list=[]
abs_list=[]
for sub in sub_dir:
    tmp = os.listdir('/'.join([text_dir,sub]))
    tg_reg= re.compile(".*.TextGrid")
    tx_reg= re.compile(".*.txt")
    sub_list.append([k.group(0) for i in tmp for k in [tg_reg.search(i)] if k])
    abs_list.append([k.group(0) for i in tmp for k in [tx_reg.search(i)] if k])
if len(sub_list) == 0 or len(abs_list) == 0:
    raise ValueError('TextGrid or txt files are not present.')

# Search all TextGrid files and make word and phoneme lists.
word_con=[]
phone_con=[]
korean_con=[]
for d in range(len(sub_dir)):

    for s in sub_list[d]:
        with open('/'.join([text_dir,sub_dir[d],s]),'r',encoding="utf-") as tg:
            lines = tg.read().split()

            phone_idx = lines.index('"phoneme"')
            word_idx = lines.index('"word"')
            phone_list = lines[phone_idx+7:word_idx-4]
            word_list = lines[word_idx+7:-3]

            for beg_wt in range(0,len(word_list),3):
                word_box = beg_wt
                phone_box = 0
                box = 0
                con_idx = []

                while box < 2:
                    if word_list[word_box] == phone_list[phone_box]:
                        con_idx.append(phone_box)
                        word_box+=1
                        phone_box+=1
                        box += 1
                    else:
                        phone_box += 1

                # Final word list.
                word_con.append(word_list[beg_wt+2])
                # Final phoneme list.
                phone_time=phone_list[con_idx[0]+2:con_idx[1]+2]
                phone_group=[k.group(0) for i in phone_time for k in [re.search('"[a-z0-9]*"', i)] if k]
                phone_con.append(phone_group)

    for t in abs_list[d]:

        with open('/'.join([text_dir,sub_dir[d],t]),'r',encoding="utf-8") as tx:
            lines = tx.read().split()
            for new_split in lines:
                korean_con.append(new_split)


# Rearrange the data for writing text files.
context=[]
term=-1
for idx in range(len(word_con)):
    # Remove 'sp', '"'
    if re.findall('"sp"',word_con[idx]) == []:
        term+=1
        phone_join = ' '.join(phone_con[idx])
        phone_text = re.sub('"', '', phone_join)
        context.append(korean_con[term] + '\t' + phone_text + ' \n')

# final_context=list(set(context))
# final_context.sort()
final_context=context

# Write a lexicon.txt file.
with open('/'.join([outputfile,'lexicon.txt']),'w',encoding="utf-8") as otxt:
    for num in range(len(final_context)):
        otxt.write(final_context[num])

# Write a lexiconp.txt file.
with open('/'.join([outputfile,'lexiconp.txt']),'w',encoding="utf-8") as otxt:
    for num in range(len(final_context)):
        prob_in = re.sub('\t','\t1.0\t',final_context[num])
        otxt.write(prob_in)

