#!/bin/bash

export PATH=${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:$PATH
retVal=0
if [ $retVal -eq 0 ]; then
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/oc2renumberSeqs ${REPO_ROOT}/09.necat_assembly/01.ont/work/1-consensus/cns_final.fasta.gz ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/renum_reads.fasta
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
  echo ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/renum_reads.fasta > ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/read_list.txt
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

echo $retVal > ${REPO_ROOT}/09.necat_assembly/01.ont/work/scripts/tr_renum.sh.done
