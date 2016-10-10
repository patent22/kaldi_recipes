# 														EMCS Labs
# 														Hyungwon Yang
# 														hyung8758@gmail.com
"""
형원이형 이 스크립트는 내가 약간 수정을 했는데
발음 변이형이 여러 개 있을 경우, 해당 발음 변이형을 텍스트 그리드로 
나올 수 있도록 해두었어. 딱 그 정도만 해놨네.
형이 파이썬 최적화 잘하니까, 한번 괜찮은지 봐바~

수정한 부분에는 표시해두었어~
(깃헙을 잘 활용하면 좋긴할텐데..ㅜ)

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
dir_list.sort()

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
ct=0
for interm in whole_list:
    tn_count=0
    for interm_list in interm:
        if re.findall('SIL',interm_list) != []:
            tn_count +=1
    tn_hold.append(str(tn_count + int(tn_list[ct])))
    ct += 1


# Writing textgrid.
rg_rem = 0
for piece in range(len(file_name)):
    print('Filename: %s' % file_name[piece])
    print('Num of words in file %d/%d = %d' % (piece+1,len(file_name),int(tn_list[piece])))
    
    new_name=re.sub('txt','TextGrid',file_name[piece])
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
        tg.write(tn_hold[piece] + '\n')
        rgc=0
        time=[]

        #-----------------Added---------------------#
        # Phone begin/end index for each word
        phone_seq=[mid[ibeg].split('\t')[-5] for ibeg in range(len(mid))]           # total sequence of phones given a sound
        phones_beg_idx=[i for i, x in enumerate(phone_seq) if re.search('.\_B', x)]  # begining index of each word (in .ctm)
        phones_end_idx=[i for i, x in enumerate(phone_seq) if re.search('.\_E', x)]  # end index of each word (in .ctm)
        
        mono_syl=[i for i, x in enumerate(phone_seq) if re.search('.\_S', x)]
        if len(mono_syl) != 0:  # check for mono syllable word
            phones_beg_idx = phones_beg_idx + mono_syl   # add time mark for mono syllable words (e.g. ii_S, aa_S as they do not have '_B' or '_E' tag)
            phones_end_idx = phones_end_idx + mono_syl
            phones_beg_idx.sort()
            phones_end_idx.sort()

        print(phone_seq)
        print(phones_beg_idx)
        print(phones_end_idx)
        #-------------------------------------------#
        
        word_loc = 0 # <----------Added
        
        for down in range(len(mid)):
            rgc +=1
            # First line. The reason for separating first line from rest is to mark 0 at the
            # beginning. If the first line is marked with 0.00 or 0.0 instead of 0 itself,
            # it causes error.
            
            if rgc == 1:
                if re.findall('[<>]', mid[down].split('\t')[-5]) != []:
                    tg.write('0' + '\n' + "{0:.2f}".format(float(mid[down].split('\t')[-1])) + '\n')
                    tg.write('"' + mid[down].split('\t')[-5] + '"' + '\n')
                elif re.findall('[<>]', mid[down].split('\t')[-5]) == [] and rgc - 1 == down:
                    str_len = len(rg_list[rg_rem]) - 2
                    for i in range(str_len):
                        # Time marking
                        if rg_list[rg_rem][2 + i] == mid[rgc - 1].split('\t')[-5][0:2]:
                            time.append(mid[rgc - 1].split('\t')[-2])
                            time.append(mid[rgc - 1].split('\t')[-1])
                            rgc += 1
                    tg.write('0' + '\n' + "{0:.2f}".format(float(time[-1])) + '\n')
                    tg.write('"' + rg_list[rg_rem][int(word_opt)] + '"' + '\n')
                    rg_rem += 1
                    rgc -= 1
                    time = []
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
            	#-----------------Added/Edited---------------------#
                prono_in_rom = rg_list[rg_rem][2:]                                         # e.g. ['c0', 'ii', 'nf', 'hh', 'qq', 'ng']
                prono_in_ctm = phone_seq[phones_beg_idx[word_loc]:phones_end_idx[word_loc]+1]
                prono_in_ctm = [re.sub(r'(..)_.',r'\1',iphone) for iphone in prono_in_ctm] # e.g. ['c0', 'ii', 'nf', 'qq', 'ng']
                
                # if prono_in_rom ~= prono_in_ctm --> overwrite to prono_in_ctm
                if prono_in_rom is not prono_in_ctm:
                    rg_list[rg_rem] = rg_list[rg_rem][:2] + prono_in_ctm
                str_len = len(rg_list[rg_rem]) - 2
                #--------------------------------------------------#

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
                word_loc += 1  # <----------Added
            else:
                rgc -= 1

print("TextGrid for all the sound files are successfully generated.")

