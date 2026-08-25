#!/bin/bash

export PATH=${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:$PATH
retVal=0
if [ $retVal -eq 0 ]; then
  cat ${REPO_ROOT}/09.necat_assembly/01.ont/work/5-align_contigs/rawread2ctg.m4a_0 | ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/pigz  -f -p 48 - -c > ${REPO_ROOT}/09.necat_assembly/01.ont/work/5-align_contigs/rawread2ctg.m4a.gz
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

echo $retVal > ${REPO_ROOT}/09.necat_assembly/01.ont/work/scripts/r2c_cat_vol.sh.done
