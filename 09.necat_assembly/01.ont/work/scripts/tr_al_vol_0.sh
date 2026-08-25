#!/bin/bash

export PATH=${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:$PATH
retVal=0
if [ $retVal -eq 0 ]; then
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/oc2asmpm -n 100 -z 10 -b 2000 -e 0.5 -j 1 -u 0 -a 400 -u 1 -t 48 ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/pac_in 0 ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/pac_in/pm_result_0
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

echo $retVal > ${REPO_ROOT}/09.necat_assembly/01.ont/work/scripts/tr_al_vol_0.sh.done
