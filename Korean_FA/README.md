# Korean_FA: Force-Alginer  
                                                                         Hyungwon Yang
                                                                           Jaekoo Kang
                                                                            2016.08.14
                                                                              EMCS lab    

### MacOSX and Linux(Testing is on going. unstable by now.)
----------------------------------------------------------------

Bash
Python 3.5
(This script was not tested on the other versions.)


### PREREQUEISTE
1. Install Kaldi
2. Install Sox, xlrd

### MATERIALS
1. Wave files. (sampling rate 16000)
- If the sampling rate of wave files is not set to 16000 it will be changed automatically.
2. Text files.
- Do not add any symbols or marks. (period, semicolon, etc)
- Remove any white pace in the end of the line.

### DIRECTION

1. Nevigate to 'Korean_FA' directory.
2. Open force_align.sh and reassign a kaldi directory variable.
3. Run the code. 
- ex) $ force_align.sh dnn $PWD/example/readspeech
-     $ (Main code: force_align.sh) (Model option) (Abosolute path to the data directory)
- Choose different models(dnn, gmm, sgmm_mmi) and check the different results.
5. Textgrid will be saved into data directoy. ex) $PWD/example/readspeech


### CONTACTS
---

Hosung Nam / hnam@korea.ac.kr

Jaekoo Kang / Jaekoo.jk@gmail.com
Hyungwon Yang / hyung8758@gmail.com




