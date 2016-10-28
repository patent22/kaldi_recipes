# -*- coding: utf-8 -*-
"""
Created by Yeonjung Hong 2016-04-27
Edited by Hyungwon Yang 2016-08-10


2 arguments:
    1. input aligned files: final_ali.txt
    2. save the file as:
"""

import sys
import os

# Arguments check.
if len(sys.argv) != 3:
    print(len(sys.argv))
    raise ValueError('The number of input arguments is wrong.')


input_ali=sys.argv[1]
save=sys.argv[2]

flist = []
with open(input_ali) as f:
        for line in f:
            columns=line.split("\t")
            if columns[1] not in flist:
                flist.append(columns[1])
                #name = name of first text file in final_ali.txt
                name = str(flist[0])
                #name_fin = name of final text file in final_ali.txt
                name_fin = str(flist[-1])

# Make directory for saving splited text files.
tmp_folder='/'.join([save,"tmp_fa"])
if not os.path.exists(tmp_folder):
        os.makedirs(tmp_folder)

results=[]
# split list by file and write a text file for each
try:
    with open(input_ali) as f:
        for line in f:
            columns=line.split("\t")
            name_prev = name
            name = columns[1]
            if (name_prev != name):
                try:   
                    with open('/'.join([tmp_folder, name_prev + ".txt"]),'w') as fwrite:
                        fwrite.write('utt_id\tfile_id\tphone_id\tutt_num\tstart_ph_inutt\tdur_ph\tphone\tstart_utt\tend_utt\tstart_ph\tend_ph')
                        fwrite.writelines('\n'+i for i in results)
                #print name
                except Exception as e:
                    print("Failed to write file",e)
                    sys.exit(2)
                del results[:]
                results.append(line[0:-1])
            else:
                results.append(line[0:-1])
except Exception as e:
    print("Failed to read file",e)
    sys.exit(1)

# this prints out the last textfile (nothing following it to compare with)
try:
    with open('/'.join([tmp_folder, name_prev + ".txt"]),'w') as fwrite:
        fwrite.write('utt_id\tfile_id\tphone_id\tutt_num\tstart_ph\tdur_ph\tphone\tstart_utt\tend_utt\tstart_real\tend_real')
        fwrite.writelines('\n'+i for i in results)
#print name
except Exception as e:
    print("Failed to write file",e)
    sys.exit(2)

input_ali_name = input_ali.split('/')[-1]
print(input_ali_name + " is successfully splited and saved into " + tmp_folder + ".")