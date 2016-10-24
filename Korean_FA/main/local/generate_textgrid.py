# 														Hyungwon Yang
# 														EMCS Labs
# 														hyung8758@gmail.com
"""
This script generates textgrid files.

2 input arguments:
    1. source data:
    2. result file.

"""

import os
import re
import optparse

# Arguments check.
parser = optparse.OptionParser()
parser.add_option("--no-word", action="store_true", dest="no_word", default="False",
                  help="This option excludes word label(tier) from TextGrid.")
parser.add_option("--no-phone", action="store_true", dest="no_phone", default="False",
                  help="This option excludes phone label(tier) from TextGrid.")
# This is not yet applicable.
# parser.add_option('--state-label', action="store", dest="state_option", default="true",
#                   help="This option inserts HMM state label(tier) to TextGrid. default=true")
(options,args) = parser.parse_args()
word_option = options.no_word
phone_option = options.no_phone

if len(args) != 4:
    raise ValueError('4 input arguments should be provided.\nProvided:\nThe number of Input Arguments: '
                     + str(len(args)) + '\nThe contents of Input Arguments: ' + ' '.join(args))

# Import arguments.
source_dir=args[0]
word_file=args[1]
text_num=args[2]
save_dir=args[3]

tier_num = 0
# Option setting
# word_option true means no word tier. phone_options true means no phone tier.
if word_option is 'False':
    tier_num+=1
elif word_option is 'True':
    print("Word label is excluded from TextGrid.")
print(tier_num)
if phone_option is 'False':
    tier_num+=1
elif phone_option is 'True':
    print("Phone label is excluded from TextGrid.")
print(tier_num)
if tier_num == 0:
    print("WARNNING: Both word and phone labels cannot be excluded. --no-word option is set to 'False'.")
    word_option = 'False'
    tier_num=1
print(tier_num)
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
            init=float("{0:.3f}".format(float(up_txt[roll].split('\t')[-2])))
            if init == best:
                order_list.append(up_txt[roll])
                best =float("{0:.3f}".format(float(up_txt[roll].split('\t')[-1])))
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
    new_name=re.sub('txt','TextGrid',file_name[piece])
    with open('/'.join([save_dir,new_name]),'w') as tg:
        tg.write('File type = "ooTextFile short"\n')
        tg.write('"TextGrid"\n\n')
        end_time=float(txt_box[piece][0].split('\t')[-3])
        # change the number of the last line 1 to 2 or 3 depending on the tier numbers.
        tg.write('0\n' + str(end_time) + '\n' + '<exists>\n' + str(tier_num) +'\n')

        # Phone tier.
        mid = whole_list[piece]
        if phone_option == 'False':
            tg.write('"IntervalTier"\n')
            tg.write('"phone"\n' + '0\n' + str(end_time) + '\n')
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
                    tg.write('0' + '\n' + "{0:.3f}".format(float(down.split('\t')[-1])) + '\n')
                    if re.findall('[<>]',down.split('\t')[-5]) != []:
                        tg.write('"' + down.split('\t')[-5] + '"' + '\n')
                    else:
                        tg.write('"' + down.split('\t')[-5][0:2] + '"' + '\n')
                # Last line.
                elif counting == len(mid):
                    tg.write("{0:.3f}".format(float(down.split('\t')[-2])) + '\n' + str(end_time) + '\n')
                    if re.findall('[<>]',down.split('\t')[-5]) != []:
                        tg.write('"' + down.split('\t')[-5] + '"')
                    else:
                        tg.write('"' + down.split('\t')[-5][0:2] + '"')
                # Mid lines.
                else:
                    tg.write("{0:.3f}".format(float(down.split('\t')[-2])) + '\n' + "{0:.3f}".format(float(down.split('\t')[-1])) + '\n')
                    if re.findall('[<>]',down.split('\t')[-5]) != []:
                        tg.write('"' + down.split('\t')[-5] + '"' + '\n')
                    else:
                        tg.write('"' + down.split('\t')[-5][0:2] + '"' + '\n')

        # Word tier.
        if word_option == 'False':
            tg.write('\n"IntervalTier"\n')
            tg.write('"word"\n' + '0\n' + str(end_time) + '\n')
            tg.write(tn_hold[piece] + '\n')
            rgc=0
            time=[]

            # Phone begin/end index for each word
            phone_seq = [mid[ibeg].split('\t')[-5] for ibeg in range(len(mid))]  # total sequence of phones given a sound
            phones_beg_idx = [i for i, x in enumerate(phone_seq) if
                              re.search('.\_B', x)]  # begining index of each word (in .ctm)
            phones_end_idx = [i for i, x in enumerate(phone_seq) if
                              re.search('.\_E', x)]  # end index of each word (in .ctm)

            mono_syl = [i for i, x in enumerate(phone_seq) if re.search('.\_S', x)]
            if len(mono_syl) != 0:  # check for mono syllable word
                phones_beg_idx = phones_beg_idx + mono_syl  # add time mark for mono syllable words (e.g. ii_S, aa_S as they do not have '_B' or '_E' tag)
                phones_end_idx = phones_end_idx + mono_syl
                phones_beg_idx.sort()
                phones_end_idx.sort()

            # print(phone_seq)
            # print(phones_beg_idx)
            # print(phones_end_idx)

            word_loc=0

            for down in range(len(mid)):
                rgc +=1
                # First line. The reason for separating first line from rest is to mark 0 at the
                # beginning. If the first line is marked with 0.00 or 0.0 instead of 0 itself,
                # it causes error.
                if rgc == 1:
                    if re.findall('[<>]', mid[down].split('\t')[-5]) != []:
                        tg.write('0' + '\n' + "{0:.3f}".format(float(mid[down].split('\t')[-1])) + '\n')
                        tg.write('"' + mid[down].split('\t')[-5] + '"' + '\n')
                    elif re.findall('[<>]', mid[down].split('\t')[-5]) == [] and rgc - 1 == down:
                        str_len = len(rg_list[rg_rem]) - 2
                        for i in range(str_len):
                            # Time marking
                            if rg_list[rg_rem][2 + i] == mid[rgc - 1].split('\t')[-5][0:2]:
                                time.append(mid[rgc - 1].split('\t')[-2])
                                time.append(mid[rgc - 1].split('\t')[-1])
                                rgc += 1
                        tg.write('0' + '\n' + "{0:.3f}".format(float(time[-1])) + '\n')
                        tg.write('"' + rg_list[rg_rem][int(word_opt)] + '"' + '\n')
                        rg_rem += 1
                        rgc -= 1
                        time = []
                # Last line
                elif down == len(mid) and rgc - 1 == len(mid):
                    tg.write("{0:.3f}".format(float(mid[down].split('\t')[-2])) + '\n' + str(end_time) + '\n')
                    tg.write('"' + mid[down].split('\t')[-5] + '"')
                # Symbols
                elif re.findall('[<>]',mid[down].split('\t')[-5]) != []:
                    tg.write("{0:.3f}".format(float(mid[down].split('\t')[-2])) + '\n' + "{0:.3f}".format(float(mid[down].split('\t')[-1])) + '\n')
                    tg.write('"' + mid[down].split('\t')[-5] + '"' + '\n')
                # Mid lines.
                elif re.findall('[<>]', mid[down].split('\t')[-5]) == [] and rgc - 1 == down:
                    prono_in_rom = rg_list[rg_rem][2:]  # e.g. ['c0', 'ii', 'nf', 'hh', 'qq', 'ng']
                    prono_in_ctm = phone_seq[phones_beg_idx[word_loc]:phones_end_idx[word_loc] + 1]
                    prono_in_ctm = [re.sub(r'(..)_.', r'\1', iphone) for iphone in
                                    prono_in_ctm]  # e.g. ['c0', 'ii', 'nf', 'qq', 'ng']

                    # if prono_in_rom != prono_in_ctm --> overwrite to prono_in_ctm
                    if prono_in_rom is not prono_in_ctm:
                        rg_list[rg_rem] = rg_list[rg_rem][:2] + prono_in_ctm

                    str_len = len(rg_list[rg_rem]) - 2
                    for i in range(str_len):
                        # Time marking
                        if rg_list[rg_rem][2 + i] == mid[rgc - 1].split('\t')[-5][0:2]:
                            time.append(mid[rgc - 1].split('\t')[-2])
                            time.append(mid[rgc - 1].split('\t')[-1])
                            rgc += 1
                    tg.write("{0:.3f}".format(float(time[0])) + '\n' + "{0:.3f}".format(float(time[-1])) + '\n')
                    tg.write('"' + rg_list[rg_rem][1] + '"' + '\n')
                    rg_rem += 1
                    rgc -= 1
                    time=[]
                    word_loc +=1
                else:
                    rgc -= 1

print("TextGrid for all the sound files are successfully generated.")
