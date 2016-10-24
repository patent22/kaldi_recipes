# 														Hyungwon Yang
# 														EMCS Labs
# 														hyung8758@gmail.com
"""
This script reads the text files and checks sentences.
Multiple spaces, tabs, and nuw lines will be removed.

"""
import sys
import os
import re
import time

# Arguments check.
if len(sys.argv) != 2:
    print(len(sys.argv))
    raise ValueError('The number of input arguments is wrong.')

# text directory
data_dir = sys.argv[1]

# Import text files.
data_list = os.listdir(data_dir)
text_list=[]
tg_list=[]
for one in data_list:
    if re.findall('txt',one) != []:
        text_list.append(one)
for tg in data_list:
    if re.findall('TextGrid',tg) != []:
        tg_list.append(tg)
# Check whether textgrids are already present or not. If so, remove all of them.
if len(tg_list) is not 0:
    print("WARNNING: TextGrids are already present. However, newly generated TextGrids will replace remained TextGrids.")
    for tg_rm in tg_list:
        os.remove('/'.join([data_dir,tg_rm]))

# Fix the problem if it exists.
inform=0
text_cont=[]
for rd in text_list:
    with open ('/'.join([data_dir,rd]),'r') as txt:

        # Check.
        text_try=txt.read()
        if re.findall('\s{2,}|[\t\n]',text_try) != [] and inform == 0:
            print("=============================== IMPORTANT ===============================")
            print("Text file is contaminated. However it will be fixed automatically.")
            print("Please check the text files again, because the result could be corrupted.")
            print("=========================================================================")
            time.sleep(3)
            inform += 1
        elif len(text_try) == 0:
            print("=============================== ERROR ===============================")
            print(rd + " file is empty. Please check the text files again.")
            print("=====================================================================")
            raise ValueError("Shut down the process.")

        # Fix.
        txt_tmp=re.sub('\s{2,}|[\t\n]',' ',text_try)
        txt_fixed=re.sub('\s$','',txt_tmp)

    with open('/'.join([data_dir,rd]),'w') as wr:
        wr.write(txt_fixed)

print("Text files have been checked.")
