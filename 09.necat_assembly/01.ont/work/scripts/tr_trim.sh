#!/bin/bash

export PATH=${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:$PATH
retVal=0
if [ $retVal -eq 0 ]; then
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/oc2pm4 ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/pac_in ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/pm.m4 0.1 48
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
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/oc2lcr ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/pm.m4 ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/pac_in 0.1 1 1 1000 48 ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/clipped_ranges.txt
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
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/oc2etr ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/clipped_ranges.txt ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/renum_reads.fasta ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/pm.m4 ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/complete_reads.fasta ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/uncomplete_reads.fasta ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/tmp_pm.m4
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
  echo ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/uncomplete_reads.fasta > ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/uncomplete_read_list.txt
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
  echo ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/complete_reads.fasta > ${REPO_ROOT}/09.necat_assembly/01.ont/work/2-trim_bases/complete_read_list.txt
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

echo $retVal > ${REPO_ROOT}/09.necat_assembly/01.ont/work/scripts/tr_trim.sh.done
