#!/bin/bash
# modified by jk 07/07/2016
# modified by hw 08/02/2016
# This script might be adopted for youngsun's run_fold script.

subdir=$2
point=$3
for x in $subdir*/exp/$point*/decode*; do [ -d $x ] && echo $x | grep "${1:-.*}" >/dev/null && grep WER $x/wer_* 2>/dev/null | utils/best_wer.sh; done
for x in $subdir*/exp/$point*/decode*; do [ -d $x ] && echo $x | grep "${1:-.*}" >/dev/null && grep Sum $x/score_*/*.sys 2>/dev/null | utils/best_wer.sh; done
exit 0
