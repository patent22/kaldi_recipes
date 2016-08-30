# -*- coding: utf-8 -*-
'''
g2p.py

created 2016 - 08 - 11
Written by Jaekoo Kang
jaekoo.jk@gmail.com
Modified by Hyungwon Yang
EMCS labs

This script converts Korean graphemes to romanized phones
and then to pronunciation.
  (1) graph2phone(graphs): convert Korean graphemes to romanized phones
  (2) phone2prono(phones): convert romanized phones to pronunciation

How to use:
in Terminal

   (grapheme -> pronunciation)

   $ python g2p.py '없었습니다'
   $ python g2p.py '값도 핥아 미닫이' (space is allowed)
   
   or

   $ string="토끼 거북이 사슴"
   $ python g2p.py "$string"

'''

import sys
import re
import math

# get text string (eojeol)
graphemes = sys.argv[1]


# check xlrd module
# xlrd enables reading .xls files
try:
    import xlrd
except ImportError:
    print('\nxlrd is not installed\nPlease install it first')

# check rules_g2p.xls
try:
    rule_book = xlrd.open_workbook('main/local/rules_g2p.xls')
except IOError:
    print('\nrules_g2p.xls does not exist or is corrupted')
    print('\nLocate rules_g2p.xls in the same folder as in g2p.py')

# read rules_g2p.xls
rule_sheet = rule_book.sheet_by_name(u'ruleset')
var = rule_sheet.cell(0, 0).value

rule_in = []
rule_out = []
for idx in range(0, rule_sheet.nrows):
    rule_in.append(rule_sheet.cell(idx, 0).value)
    rule_out.append(rule_sheet.cell(idx, 1).value)


def checkSpaceElement(var_list):
    '''
    This function checks if an element in a list is 32 or not
    32 is a representation of 16-bit unsigned integer 
    of space character ' '

    If 32, it returns 1
    If not empty, it returns 0
    '''
    checked = []
    for i in range(len(var_list)):
        if var_list[i] == 32:
            checked.append(1)
        else:
            checked.append(0)
    return checked


def graph2phone(graphs):
    '''
    This function converts Korean graphemes to romanized phones
    '''
    # encode graphemes as utf8
    try:
        graphs = graphs.decode('utf-8')
    except:
        pass
    integers = []
    for i in range(len(graphs)):
        integers.append(ord(graphs[i]))

    # romanization
    phones = ''
    ONS = ['k0', 'kk', 'nn', 't0', 'tt', 'rr', 'mm', 'p0', 'pp',
           's0', 'ss', 'oh', 'c0', 'cc', 'ch', 'kh', 'th', 'ph', 'hh']
    NUC = ['aa', 'qq', 'ya', 'yq', 'vv', 'ee', 'yv', 'ye', 'oo', 'wa',
           'wq', 'wo', 'yo', 'uu', 'wv', 'we', 'wi', 'yu', 'xx', 'xi', 'ii']
    COD = ['', 'kf', 'kk', 'ks', 'nf', 'nc', 'nh', 'tf',
           'll', 'lk', 'lm', 'lb', 'ls', 'lt', 'lp', 'lh',
           'mf', 'pf', 'ps', 's0', 'ss', 'oh', 'c0', 'ch',
           'kh', 'th', 'ph', 'hh']

    # pronunciation
    idx = checkSpaceElement(integers)
    iElement = 0
    while iElement < len(integers):
        if idx[iElement] == 0:  # not space characters
            base = 44032
            df = int(integers[iElement]) - base
            iONS = int(math.floor(df / 588)) + 1
            iNUC = int(math.floor((df % 588) / 28)) + 1
            iCOD = int((df % 588) % 28) + 1

            s1 = '-' + ONS[iONS - 1]  # onset
            s2 = NUC[iNUC - 1]        # nucleus

            if COD[iCOD - 1]:         # coda
                s3 = COD[iCOD - 1]
            else:
                s3 = ''
            tmp = s1 + s2 + s3
            phones = phones + tmp
        elif idx[iElement] == 1:  # space character
            tmp = ' '
            phones = phones + tmp
        phones = re.sub('-(oh)', '-', phones)
        iElement += 1
        tmp = ''

    # final velar nasal
    phones = re.sub('^oh', '', phones)
    phones = re.sub('-(oh)', '', phones)
    phones = re.sub('oh-', 'ng-', phones)
    phones = re.sub('oh$', 'ng', phones)
    phones = re.sub('oh ', 'ng ', phones)

    phones = re.sub('(\W+)\-', '\\1', phones)
    phones = re.sub('\W+$', '', phones)
    phones = re.sub('^\-', '', phones)
    return phones


def phone2prono(phones):
    '''
    This function converts romanized phones to pronunciation
    '''
    # apply g2p rules
    for pattern, replacement in zip(rule_in, rule_out):
        phones = re.sub(pattern, replacement, phones)
        prono = phones
    return prono

# run g2p.py
romanized = graph2phone(graphemes)

print(romanized)

