# 														EMCS Labs
# 														Hyungwon Yang
# 														hyung8758@gmail.com
"""
This script generates textgrid files.

2 input arguments:
    1. source data:
    2. result file.

"""

import os
import sys
import re

# Arguments check.
if len(sys.argv) != 6:
    print(len(sys.argv))
    raise ValueError('The number of input arguments is wrong.')

source_dir=sys.argv[1]
word_file=sys.argv[2]
text_num=sys.argv[3]
save_dir=sys.argv[4]
word_opt=sys.argv[5]

if not os.path.exists(save_dir):
    os.makedirs(save_dir)

# Reading data.
# Search directories.
dir_list = os.listdir(source_dir)
txt_box=[]
file_name=[]
for check in dir_list:
    if len(re.findall('txt',check)) != 0:
        file_name.append(check)
        # Read all files
        with open('/'.join([source_dir,check]),'r') as txt:
            txt_box.append(txt.read().split('\n')[1::])

# Data for second tier.
rg_list=[]
with open(word_file,'r') as rgl:
    rg_lexicon=rgl.readlines()
    for rg_box in rg_lexicon:
        rg_list.append(rg_box.split(' ')[0:-1])

# Sorting data.
best=0
order_list=[]
whole_list=[]
for up in range(len(txt_box)):
    up_txt = txt_box[up]
    best=0
    for down_num in range(len(up_txt)):
        roll=0
        while roll <= len(up_txt):
            init=float("{0:.2f}".format(float(up_txt[roll].split('\t')[-2])))
            if init == best:
                order_list.append(up_txt[roll])
                best =float("{0:.2f}".format(float(up_txt[roll].split('\t')[-1])))
                break
            roll +=1

    whole_list.append(order_list)
    order_list=[]

# text_num file.
with open(text_num,'r') as tn:
    tn_list=tn.readlines()
# Adding SIL numbers.
tn_hold=[]
for interm in whole_list:
    tn_count=0
    for interm_list in interm:
        if re.findall('SIL',interm_list) != []:
            tn_count +=1
    tn_hold.append(str(tn_count))



# Writing textgrid.
rg_rem = 0
for piece in range(len(file_name)):
    new_name=re.sub('txt','TextGrid',file_name[piece])
    # text numbers
    tn_box=str(int(tn_list[piece][0]) + int(tn_hold[piece]))
    with open('/'.join([save_dir,new_name]),'w') as tg:
        tg.write('File type = "ooTextFile short"\n')
        tg.write('"TextGrid"\n\n')
        end_time=float(txt_box[piece][0].split('\t')[-3])
        # change the number of the last line 1 to 2 or 3 depending on the tier numbers.
        tg.write('0\n' + str(end_time) + '\n' + '<exists>\n' + '2\n')
        tg.write('"IntervalTier"\n')

        # Phone tier.
        mid=whole_list[piece]
        tg.write('"Phoneme"\n' + '0\n' + str(end_time) + '\n')
        tg.write(str(len(whole_list[piece])) + '\n')
        counting=0
        for down in mid:
            '''
            Divide into 3 types. First line, last line and rest lines.
            This division is needed because of the characteristics of TextGrid type.
            More detail: Due to the slight time difference, separation is occurred.
            '''
            counting +=1
            # First line.
            if counting == 1:
                tg.write('0' + '\n' + "{0:.2f}".format(float(down.split('\t')[-1])) + '\n')
                if re.findall('[<>]',down.split('\t')[-5]) != []:
                    tg.write('"' + down.split('\t')[-5] + '"' + '\n')
                else:
                    tg.write('"' + down.split('\t')[-5][0:2] + '"' + '\n')
            # Last line.
            elif counting == len(mid):
                tg.write("{0:.2f}".format(float(down.split('\t')[-2])) + '\n' + str(end_time) + '\n')
                if re.findall('[<>]',down.split('\t')[-5]) != []:
                    tg.write('"' + down.split('\t')[-5] + '"')
                else:
                    tg.write('"' + down.split('\t')[-5][0:2] + '"')
            # Mid lines.
            else:
                tg.write("{0:.2f}".format(float(down.split('\t')[-2])) + '\n' + "{0:.2f}".format(float(down.split('\t')[-1])) + '\n')
                if re.findall('[<>]',down.split('\t')[-5]) != []:
                    tg.write('"' + down.split('\t')[-5] + '"' + '\n')
                else:
                    tg.write('"' + down.split('\t')[-5][0:2] + '"' + '\n')

        # Word tier.
        tg.write('\n"IntervalTier"\n')
        tg.write('"Word"\n' + '0\n' + str(end_time) + '\n')
        tg.write(tn_box + '\n')
        rgc=0
        time=[]
        for down in range(len(mid)):
            rgc +=1
            # First line.
            if rgc == 1:
                if re.findall('[<>]', mid[down].split('\t')[-5]) != []:
                    tg.write('0' + '\n' + "{0:.2f}".format(float(mid[down].split('\t')[-1])) + '\n')
                    tg.write('"' + mid[down].split('\t')[-5] + '"' + '\n')
                else:
                    tg.write('0' + '\n')
            # Last line
            elif down == len(mid) and rgc - 1 == len(mid):
                tg.write("{0:.2f}".format(float(mid[down].split('\t')[-2])) + '\n' + str(end_time) + '\n')
                tg.write('"' + mid[down].split('\t')[-5] + '"')
            # Symbols
            elif re.findall('[<>]',mid[down].split('\t')[-5]) != []:
                tg.write("{0:.2f}".format(float(mid[down].split('\t')[-2])) + '\n' + "{0:.2f}".format(float(mid[down].split('\t')[-1])) + '\n')
                tg.write('"' + mid[down].split('\t')[-5] + '"' + '\n')
            # Mid lines.
            elif re.findall('[<>]', mid[down].split('\t')[-5]) == [] and rgc - 1 == down:
                str_len = len(rg_list[rg_rem]) - 2
                for i in range(str_len):
                    # Time marking
                    if rg_list[rg_rem][2 + i] == mid[rgc - 1].split('\t')[-5][0:2]:
                        time.append(mid[rgc - 1].split('\t')[-2])
                        time.append(mid[rgc - 1].split('\t')[-1])
                        rgc += 1
                tg.write("{0:.2f}".format(float(time[0])) + '\n' + "{0:.2f}".format(float(time[-1])) + '\n')
                tg.write('"' + rg_list[rg_rem][int(word_opt)] + '"' + '\n')
                rg_rem += 1
                rgc -= 1
                time=[]
            else:
                rgc -= 1

print("TextGrid for all the sound files are successfully generated.")