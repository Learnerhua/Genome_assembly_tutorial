#!/bin/bash

export PATH=${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:$PATH
retVal=0
if [ $retVal -eq 0 ]; then
  cat ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/uu_ovlps/pm_result_0  > ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/uu_ovlps.rm.m4
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

echo $retVal > ${REPO_ROOT}/09.necat_assembly/01.ont/work/scripts/tr_u2u_cat_vol.sh.done
