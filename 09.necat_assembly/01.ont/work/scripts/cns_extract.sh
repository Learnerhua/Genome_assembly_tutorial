#!/bin/bash

export PATH=${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:$PATH
retVal=0
if [ $retVal -eq 0 ]; then
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/fsa_rd_tools longest --ifname=${REPO_ROOT}/09.necat_assembly/01.ont/work/1-consensus/cns_iter2/cns.fasta.gz --ofname=${REPO_ROOT}/09.necat_assembly/01.ont/work/1-consensus/cns_final.fasta --base_size=364717380
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
if [ $retVal -eq 0 ]; then
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/pigz -f  -p 48 ${REPO_ROOT}/09.necat_assembly/01.ont/work/1-consensus/cns_final.fasta
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

echo $retVal > ${REPO_ROOT}/09.necat_assembly/01.ont/work/scripts/cns_extract.sh.done
