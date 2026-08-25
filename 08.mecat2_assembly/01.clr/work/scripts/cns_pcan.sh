#!/bin/bash

export PATH=${DATA_ROOT}/Download/MECAT2/Linux-amd64/bin:${DATA_ROOT}/Download/MECAT2/Linux-amd64/bin:$PATH
retVal=0
if [ $retVal -eq 0 ]; then
  ${DATA_ROOT}/Download/MECAT2/Linux-amd64/bin/mecat2pcan -p 100000 -k 100 -t 48 ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/1-consensus/cns_pm_dir ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/1-consensus/cns_cns_dir ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/1-consensus/cns_pm.seqidx
  temp_result=$?
  if [ $retVal -eq 0 ]; then
    retVal=$temp_result
  fi
fi

echo $retVal > ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/scripts/cns_pcan.sh.done
