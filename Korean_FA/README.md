# Korean_FA: Forced-Alginer  
                                        Hyungwon Yang
                                        Jaekoo Kang
                                        2016.08.14
                                        EMCS lab    

### MacOSX and Linux
----------------------------------------------------------------
Mac OSX (El Capitan 10.11.6) : Tested successfully.
Linux (Ubuntu 14.04) : Tested successfully.

Bash
Python 3.5
(This script was not tested on the other versions.)


### PREREQUEISTE
1. **Install Kaldi**
 - Type below in command line.
    $ git clone https://github.com/kaldi-asr/kaldi.git kaldi --origin upstream
    $ cd kaldi
    $ git pull 
 - Read INSTALL and follow the direction written there.

2. **Install Sox, xlrd**
 -  On mac
    - $ brew install sox
    - $ pip3 install xlrd (Make sure to install xlrd into python3 library not in python2. If you use anaconda then you have to install in there. Otherwise, install it into proper directory.)
 - On Ubuntu


### MATERIALS
1. **Wave files.** (sampling rate 16000)
 - If the sampling rate of wave files is not set to 16000 it will be changed automatically.
2. **Text files.**
 - Name your text files with numbers such as name01.txt, name02.txt, etc.
 - Do not add any symbols or marks such as period, comma in the text file which contains one full sentence. (period, semicolon, etc)
 - Since this is Korean Forced-Aligner, sentences should be written in Korean letters and less spaces between characters are strongly recommended.
    - For example, write the sentence as the speaker read, not followed by any grammatical or spacing words rule.
    - If a speaker reads... "나는 그시절 사람들과 사는것이 좋았어요"
    - Bad example: "나는 그 시절 사람들과 사는 것이 좋았어요"
    - Good example: "나는 그시절 사람들과 사는것이 좋았어요"
3. Remove any white space or tap in the end of the line.

### DIRECTION

1. Nevigate to 'Korean_FA' directory.
2. Open force_align.sh and reassign a kaldi directory variable.
3. Run the code. 
 - ex) $ force_align.sh dnn $PWD/example/readspeech
 -     $ (Main code: force_align.sh) (Model option) (Abosolute path to the data directory)
 - Choose different models(dnn, gmm, sgmm_mmi) and check the different results.
5. Textgrid will be saved into data directoy.

### CONTACTS
---

Hosung Nam / hnam@korea.ac.kr

Jaekoo Kang / Jaekoo.jk@gmail.com

Hyungwon Yang / hyung8758@gmail.com




