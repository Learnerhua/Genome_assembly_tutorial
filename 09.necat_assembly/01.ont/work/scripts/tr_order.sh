#!/bin/bash

export PATH=${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:$PATH
retVal=0
if [ $retVal -eq 0 ]; then
  cat ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/complete_reads.fasta ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/uncomplete_reads.fasta > ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/tmp_trimReads.fasta
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
  cat ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/cu_ovlps.rm.m4 ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/uu_ovlps.rm.m4 >> ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/tmp_pm.m4
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
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/oc2orderResults ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/tmp_trimReads.fasta ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/tmp_pm.m4 ${REPO_ROOT}/09.necat_assembly/01.ont/work/trimReads.fasta ${REPO_ROOT}/09.necat_assembly/01.ont/work/3-assembly/pm.m4
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
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/pigz  -f -p 48 ${REPO_ROOT}/09.necat_assembly/01.ont/work/trimReads.fasta
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
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/pigz  -f -p 48 ${REPO_ROOT}/09.necat_assembly/01.ont/work/3-assembly/pm.m4
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

echo $retVal > ${REPO_ROOT}/09.necat_assembly/01.ont/work/scripts/tr_order.sh.done
