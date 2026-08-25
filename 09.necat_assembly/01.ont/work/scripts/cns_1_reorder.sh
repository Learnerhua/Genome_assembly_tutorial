#!/bin/bash

export PATH=${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:$PATH
retVal=0
if [ $retVal -eq 0 ]; then
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/oc2ReorderCnsReads ${REPO_ROOT}/09.necat_assembly/01.ont/work/1-consensus/cns_iter1/tmp_cns.fasta ${REPO_ROOT}/09.necat_assembly/01.ont/work/1-consensus/cns_iter1/tmp_raw.fasta ${REPO_ROOT}/09.necat_assembly/01.ont/work/1-consensus/cns_iter1/cns.fasta ${REPO_ROOT}/09.necat_assembly/01.ont/work/1-consensus/cns_iter1/raw.fasta
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
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/pigz -f  -p 48 ${REPO_ROOT}/09.necat_assembly/01.ont/work/1-consensus/cns_iter1/cns.fasta
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
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/pigz -f  -p 48 ${REPO_ROOT}/09.necat_assembly/01.ont/work/1-consensus/cns_iter1/raw.fasta
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
  echo ${REPO_ROOT}/09.necat_assembly/01.ont/work/1-consensus/cns_iter1/cns.fasta.gz > ${REPO_ROOT}/09.necat_assembly/01.ont/work/1-consensus/cns_iter1/read_list.txt
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
  echo ${REPO_ROOT}/09.necat_assembly/01.ont/work/1-consensus/cns_iter1/raw.fasta.gz >> ${REPO_ROOT}/09.necat_assembly/01.ont/work/1-consensus/cns_iter1/read_list.txt
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

echo $retVal > ${REPO_ROOT}/09.necat_assembly/01.ont/work/scripts/cns_1_reorder.sh.done
