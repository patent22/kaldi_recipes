#This script trains Korean and English read-speech datasets


### NOTICE
1. The recipes on this github is still under the development.
2. Please contact me if you have any questions.

### Process
1. e1: Not started.

2. k1: Working on.

3. k2: Not started.

#### k1 structure
1. Data materials: local(folder), path.sh, cmd.sh, run_cv.sh, run.sh
2. run.sh: This script shows general training structure. it trains korean_readspeech without cross validation.
3. run_cv.sh: This script trains korean_readspeech corpus by cross validation. Dataset will be divided into 5 parts and speaker datasets will be distributed proportionally into each part based on the 3 options: 5, 20, and 115 speaker datasets.


-----
- Name: Hyungwon Yang
- e-mail: hyung8758@gmail.com