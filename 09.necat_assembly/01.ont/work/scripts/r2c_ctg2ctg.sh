#!/bin/bash

export PATH=${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:$PATH
retVal=0
if [ $retVal -eq 0 ]; then
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/oc2SplitCtgs ${REPO_ROOT}/09.necat_assembly/01.ont/work/4-fsa/contigs.fasta ${REPO_ROOT}/09.necat_assembly/01.ont/work/5-align_contigs/temp/ctg_reads.fasta
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
  echo "${REPO_ROOT}/09.necat_assembly/01.ont/work/5-align_contigs/temp/ctg_reads.fasta"> ${REPO_ROOT}/09.necat_assembly/01.ont/work/5-align_contigs/temp/ctg_read_list.txt
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
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/oc2mkdb ${REPO_ROOT}/09.necat_assembly/01.ont/work/5-align_contigs/temp ${REPO_ROOT}/09.necat_assembly/01.ont/work/5-align_contigs/temp/ctg_read_list.txt
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
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/oc2pm -t 48 -j 0 ${REPO_ROOT}/09.necat_assembly/01.ont/work/5-align_contigs/temp ${REPO_ROOT}/09.necat_assembly/01.ont/work/5-align_contigs/temp/tmp_candidates.txt
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
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/oc2FixCanInfo ${REPO_ROOT}/09.necat_assembly/01.ont/work/5-align_contigs/temp/ctg_reads.fasta ${REPO_ROOT}/09.necat_assembly/01.ont/work/5-align_contigs/temp/tmp_candidates.txt ${REPO_ROOT}/09.necat_assembly/01.ont/work/5-align_contigs/temp/candidates.txt
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
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/oc2ctgpm -t 48 ${REPO_ROOT}/09.necat_assembly/01.ont/work/4-fsa/contigs.fasta ${REPO_ROOT}/09.necat_assembly/01.ont/work/5-align_contigs/temp/candidates.txt ${REPO_ROOT}/09.necat_assembly/01.ont/work/5-align_contigs/ctg2ctg.m4a
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
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/pigz  -f -p 48 ${REPO_ROOT}/09.necat_assembly/01.ont/work/5-align_contigs/ctg2ctg.m4a
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

echo $retVal > ${REPO_ROOT}/09.necat_assembly/01.ont/work/scripts/r2c_ctg2ctg.sh.done
