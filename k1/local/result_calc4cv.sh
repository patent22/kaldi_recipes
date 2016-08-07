#!/bin/bash

# exp/* directory ex. tri1 or mono
int_dir=$1
# train or test directory
point=$2
for x in $int_dir/$point; do [ -d $x ] && echo $x | grep "${1:-.*}" >/dev/null && grep WER $x/wer_* 2>/dev/null | utils/best_wer.sh; done
for x in $int_dir/$point; do [ -d $x ] && echo $x | grep "${1:-.*}" >/dev/null && grep Sum $x/score_*/*.sys 2>/dev/null | utils/best_wer.sh; done
exit 0
