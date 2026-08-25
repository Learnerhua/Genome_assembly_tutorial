#!/bin/bash

export PATH=${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:$PATH
retVal=0
if [ $retVal -eq 0 ]; then
  cat ${REPO_ROOT}/09.necat_assembly/01.ont/work/4-fsa/rd2ctg.m4_0 > ${REPO_ROOT}/09.necat_assembly/01.ont/work/4-fsa/rd2ctg.m4
  temp_result=(${PIPESTATUS[*]})
  for i in ${temp_result[*]} 
  do
    if [ $retVal -eq 0 ]; then
      retVal=$i
    else
      break
    fi
  done
fi

echo $retVal > ${REPO_ROOT}/09.necat_assembly/01.ont/work/scripts/plctg0_cat_vol.sh.done
