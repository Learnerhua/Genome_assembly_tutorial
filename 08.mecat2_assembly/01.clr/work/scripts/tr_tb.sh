#!/bin/bash

export PATH=${DATA_ROOT}/Download/MECAT2/Linux-amd64/bin:${DATA_ROOT}/Download/MECAT2/Linux-amd64/bin:$PATH
retVal=0
if [ $retVal -eq 0 ]; then
  ${DATA_ROOT}/Download/MECAT2/Linux-amd64/bin/mecat2trimbases ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/2-trim_bases/trim_pm_dir ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/2-trim_bases/sr.txt 1 ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/2-trim_bases/trimReads.fasta
  temp_result=$?
  if [ $retVal -eq 0 ]; then
    retVal=$temp_result
  fi
fi

echo $retVal > ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/scripts/tr_tb.sh.done
