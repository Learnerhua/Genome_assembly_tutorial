#!/bin/bash

export PATH=${DATA_ROOT}/Download/MECAT2/Linux-amd64/bin:${DATA_ROOT}/Download/MECAT2/Linux-amd64/bin:$PATH
retVal=0
if [ $retVal -eq 0 ]; then
  ${DATA_ROOT}/Download/MECAT2/Linux-amd64/bin/mecat2pm4 -p 100000 -k 100 -t 48 ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/2-trim_bases/trim_pm_dir ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/2-trim_bases/trim_pm4_dir ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/2-trim_bases/trim_pm_dir/trim_pm.m4x
  temp_result=$?
  if [ $retVal -eq 0 ]; then
    retVal=$temp_result
  fi
fi

echo $retVal > ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/scripts/tr_pm4.sh.done
