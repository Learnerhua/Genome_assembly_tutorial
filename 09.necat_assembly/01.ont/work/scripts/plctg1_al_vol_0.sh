#!/bin/bash

export PATH=${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:$PATH
retVal=0
if [ $retVal -eq 0 ]; then
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/oc2rm_worker -t 48 -u 1 -z 20 ${REPO_ROOT}/09.necat_assembly/01.ont/work/6-bridge_contigs/pac_reads ${REPO_ROOT}/09.necat_assembly/01.ont/work/6-bridge_contigs/bridged_contigs.fasta ${REPO_ROOT}/09.necat_assembly/01.ont/work/6-bridge_contigs/rd2ctg.m4_0 -mn 0 1
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

echo $retVal > ${REPO_ROOT}/09.necat_assembly/01.ont/work/scripts/plctg1_al_vol_0.sh.done
