"""
Copyright 2016  Korea University & EMCS Labs  (Author: Hyungwon Yang)
Apache 2.0

*** Introduction ***
This script generates lexicon.txt and lexiconp.txt files based on corpus data.

*** USAGE ***
Ex. python3 text2lexicon.py $text_directory $save_directory
"""

import sys
import os
import re


# Arguments check.
if len(sys.argv) != 3:
    print(len(sys.argv))
    print("Input arguments are incorrectly provided. Two argument should be assigned.")
    print("1. Text directory.")
    print("2. Save directory.")
    print("*** USAGE ***")
    print("Ex. python3 text2lexicon.py $text_directory $save_directory")
    raise ValueError('RETURN')

# corpus data directory
text_dir=sys.argv[1]
outputfile = sys.argv[2]

# Search directories.
dir_list = os.listdir(text_dir)
sub_dir = []
for check in dir_list:
    if len(re.findall('[0-9]',check)) != 0:
        sub_dir.append(check)

# Get TextGrid list.
sub_list=[]
for sub in sub_dir:
    tmp = os.listdir('/'.join([text_dir,sub]))
    tg_reg= re.compile(".*.TextGrid")
    sub_list.append([k.group(0) for i in tmp for k in [tg_reg.search(i)] if k])

# Search all TextGrid files and make word and phoneme lists.
word_con=[]
phone_con=[]
for d in range(len(sub_dir)):

    for s in sub_list[d]:

        with open('/'.join([text_dir,sub_dir[d],s]),'r') as tg:
            lines = tg.read().splitlines()
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

# Rearrange the data for writing text files.
context=[]
for idx in range(len(word_con)):
    # Remove 'sp', '"'
    if re.findall('"sp"',word_con[idx]) == []:
        word_text = re.sub('"', '', word_con[idx])
        phone_join = ' '.join(phone_con[idx])
        phone_text = re.sub('"', '', phone_join)
        context.append(word_text + '\t' + phone_text + ' \n')
final_context=list(set(context))
final_context.sort()


# Write a lexicon.txt file.
with open(outputfile+'.txt','w') as otxt:
    for num in range(len(final_context)):
        otxt.write(final_context[num])

# Write a lexiconp.txt file.
with open(outputfile+'p.txt','w') as otxt:
    for num in range(len(final_context)):
        prob_in = re.sub('\t','\t1.0\t',final_context[num])
        otxt.write(prob_in)
